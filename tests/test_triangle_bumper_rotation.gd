extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoModuleNodeScript = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const SlingshotKickerScript = preload("res://scenes/board/machinery/slingshot_kicker.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const CellType = PolyominoModuleData.CellType

class MockBall extends Node2D:
	var peg_energy: int = 0
	var linear_velocity: Vector2 = Vector2.ZERO
	var ball_id: int = 202
	func get_ball_id() -> int: return ball_id

func _init() -> void:
	suite_name = "TriangleBumperRotation"

func run() -> void:
	test_slingshot_kicker_rotations()
	test_slingshot_collision_shape_rotates()
	test_polyomino_module_node_rotates_slingshots()
	test_unified_slingshot_rotation()

func test_slingshot_kicker_rotations() -> void:
	begin("SlingshotKicker vertices, direction, and impulse rotate across all 4 rotation steps")
	var tri := SlingshotKickerScript.new() as SlingshotKicker
	autofree(tri)
	var ball := MockBall.new()
	autofree(ball)

	# Step 0: unrotated (top-left corner)
	tri.rotation_step = 0
	assert_eq(tri.segment_p1, Vector2(-36, 36), "Step 0: p1 is bottom-left")
	assert_eq(tri.segment_p2, Vector2(36, -36), "Step 0: p2 is top-right")
	assert_eq(tri.corner_p3, Vector2(-36, -36), "Step 0: corner_p3 is top-left")
	assert_true(tri.direction.x > 0.0 and tri.direction.y > 0.0, "Step 0: direction points down-right")
	var imp0: Vector2 = tri._compute_impulse(ball)
	assert_true(imp0.x > 0.0 and imp0.y > 0.0, "Step 0: impulse points down-right into playfield")

	# Step 1: 90 deg CW (top-right corner)
	tri.rotation_step = 1
	assert_eq(tri.segment_p1, Vector2(-36, -36), "Step 1: p1 is top-left")
	assert_eq(tri.segment_p2, Vector2(36, 36), "Step 1: p2 is bottom-right")
	assert_eq(tri.corner_p3, Vector2(36, -36), "Step 1: corner_p3 is top-right")
	assert_true(tri.direction.x < 0.0 and tri.direction.y > 0.0, "Step 1: direction points down-left")
	var imp1: Vector2 = tri._compute_impulse(ball)
	assert_true(imp1.x < 0.0 and imp1.y > 0.0, "Step 1: impulse points down-left into playfield")

	# Step 2: 180 deg CW (bottom-right corner)
	tri.rotation_step = 2
	assert_eq(tri.segment_p1, Vector2(36, -36), "Step 2: p1 is top-right")
	assert_eq(tri.segment_p2, Vector2(-36, 36), "Step 2: p2 is bottom-left")
	assert_eq(tri.corner_p3, Vector2(36, 36), "Step 2: corner_p3 is bottom-right")
	assert_true(tri.direction.x < 0.0 and tri.direction.y < 0.0, "Step 2: direction points up-left")
	var imp2: Vector2 = tri._compute_impulse(ball)
	assert_true(imp2.x < 0.0 and imp2.y < 0.0, "Step 2: impulse points up-left into playfield")

	# Step 3: 270 deg CW (bottom-left corner)
	tri.rotation_step = 3
	assert_eq(tri.segment_p1, Vector2(36, 36), "Step 3: p1 is bottom-right")
	assert_eq(tri.segment_p2, Vector2(-36, -36), "Step 3: p2 is top-left")
	assert_eq(tri.corner_p3, Vector2(-36, 36), "Step 3: corner_p3 is bottom-left")
	assert_true(tri.direction.x > 0.0 and tri.direction.y < 0.0, "Step 3: direction points up-right")
	var imp3: Vector2 = tri._compute_impulse(ball)
	assert_true(imp3.x > 0.0 and imp3.y < 0.0, "Step 3: impulse points up-right into playfield")

func test_slingshot_collision_shape_rotates() -> void:
	begin("SlingshotKicker collision SegmentShape2D endpoints rotate with rotation_step")
	var tri := SlingshotKickerScript.new() as SlingshotKicker
	autofree(tri)
	tri.rotation_step = 0
	tri._ready()

	var col: CollisionShape2D = tri.get_collision_shape_node()
	assert_true(col != null, "Collision shape node exists")
	assert_true(col.shape is SegmentShape2D, "Collision shape is SegmentShape2D")
	var seg: SegmentShape2D = col.shape as SegmentShape2D
	assert_eq(seg.a, Vector2(-36, 36), "Initial seg.a is (-36, 36)")
	assert_eq(seg.b, Vector2(36, -36), "Initial seg.b is (36, -36)")

	tri.rotation_step = 1
	assert_eq(seg.a, Vector2(-36, -36), "Step 1 seg.a is (-36, -36)")
	assert_eq(seg.b, Vector2(36, 36), "Step 1 seg.b is (36, 36)")

	tri.rotation_step = 2
	assert_eq(seg.a, Vector2(36, -36), "Step 2 seg.a is (36, -36)")
	assert_eq(seg.b, Vector2(-36, 36), "Step 2 seg.b is (-36, 36)")

	tri.rotation_step = 3
	assert_eq(seg.a, Vector2(36, 36), "Step 3 seg.a is (36, 36)")
	assert_eq(seg.b, Vector2(-36, -36), "Step 3 seg.b is (-36, -36)")

func test_polyomino_module_node_rotates_slingshots() -> void:
	begin("PolyominoModuleNode sets rotation_step on spawned slingshot components")
	var mod_data := PolyominoRelicDatabase.create_module_for_relic(&"detonation_triangle_acute")
	assert_true(mod_data != null, "Acute triangle relic exists in database")

	var item := JunkBoxItem.new(&"item_acute", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data

	for rot in range(4):
		var module_node := PolyominoModuleNodeScript.new() as PolyominoModuleNode
		autofree(module_node)
		module_node.setup_module(item, Vector2i.ZERO, rot)

		var comps: Array = module_node.get_all_components()
		assert_eq(comps.size(), 1, "Module has 1 component at rot %d" % rot)
		var tri: SlingshotKicker = comps[0] as SlingshotKicker
		assert_true(tri != null, "Component is SlingshotKicker at rot %d" % rot)
		assert_eq(tri.rotation_step, rot, "Component rotation_step is %d" % rot)

		var exp_p1: Vector2 = SlingshotKicker._rotate_vec(Vector2(-36, 36), rot)
		assert_eq(tri.segment_p1, exp_p1, "Rot %d: segment_p1 matches rotated" % rot)

func test_unified_slingshot_rotation() -> void:
	begin("Unified Corner Slingshot updates footprint and rotates geometry")
	var mod_data := PolyominoRelicDatabase.create_module_for_relic(&"corner_slingshot")
	assert_true(mod_data != null, "Corner slingshot relic exists")

	var item := JunkBoxItem.new(&"item_corner_slingshot", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data

	for rot in range(4):
		var module_node := PolyominoModuleNodeScript.new() as PolyominoModuleNode
		autofree(module_node)
		module_node.setup_module(item, Vector2i.ZERO, rot)

		var tri: SlingshotKicker = module_node.get_unified_component() as SlingshotKicker
		assert_true(tri != null, "Unified component is SlingshotKicker at rot %d" % rot)
		assert_eq(tri.rotation_step, rot, "Unified rot is %d" % rot)

		var exp_corner: Vector2 = SlingshotKicker._rotate_vec(Vector2(-39, -42), rot)
		assert_eq(tri.corner_p3, exp_corner, "Unified corner_p3 matches rotated at rot %d" % rot)
