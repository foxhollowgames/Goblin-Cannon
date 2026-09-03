@tool
extends RefCounted

var suite_name: String = "Relic Enclosures"
var passed: int = 0
var failed: int = 0
var errors: Array[String] = []

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoModuleNode = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const JunkBoxItemScript = preload("res://resources/inventory/junk_box_item.gd")

func run() -> void:
	_test_enclosure_type_serialization()
	_test_open_frame_edge_segments()
	_test_full_enclosure_edge_segments()
	_test_directional_funnel_edge_segments()
	_test_divided_lanes_edge_segments()
	_test_rotation_transforms_for_edges()
	_test_relic_database_enclosure_assignments()
	_test_module_node_wall_collision()

func _assert(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		errors.append(message)

func _test_enclosure_type_serialization() -> void:
	var mod := PolyominoModuleData.new()
	mod.module_id = &"test_funnel"
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)]
	mod.enclosure_type = PolyominoModuleData.EnclosureType.DIRECTIONAL_FUNNEL
	mod.custom_wall_edges = { Vector2i(0, 0): ["N"] }

	var data: Dictionary = mod.serialize()
	_assert(data.get("enclosure_type", -1) == PolyominoModuleData.EnclosureType.DIRECTIONAL_FUNNEL, "Serialized enclosure_type should match DIRECTIONAL_FUNNEL")

	var restored: PolyominoModuleData = PolyominoModuleData.from_dictionary(data) as PolyominoModuleData
	_assert(restored != null, "Deserialized module data should not be null")
	_assert(restored.enclosure_type == PolyominoModuleData.EnclosureType.DIRECTIONAL_FUNNEL, "Restored enclosure_type should be DIRECTIONAL_FUNNEL")
	_assert(restored.custom_wall_edges.has(Vector2i(0, 0)), "Restored custom_wall_edges should contain key (0,0)")

func _test_open_frame_edge_segments() -> void:
	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)]
	mod.enclosure_type = PolyominoModuleData.EnclosureType.OPEN_FRAME

	var segs: Array[Dictionary] = mod.get_solid_edge_segments(0)
	_assert(segs.is_empty(), "OPEN_FRAME without custom walls should have 0 solid edge segments")

func _test_full_enclosure_edge_segments() -> void:
	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)]
	mod.enclosure_type = PolyominoModuleData.EnclosureType.FULL_ENCLOSURE

	var segs: Array[Dictionary] = mod.get_solid_edge_segments(0)
	_assert(segs.size() == 6, "FULL_ENCLOSURE 2-cell module should have 6 outer wall segments, got %d" % segs.size())

func _test_directional_funnel_edge_segments() -> void:
	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(0, 1)]
	mod.enclosure_type = PolyominoModuleData.EnclosureType.DIRECTIONAL_FUNNEL

	var segs: Array[Dictionary] = mod.get_solid_edge_segments(0)
	_assert(segs.size() == 4, "DIRECTIONAL_FUNNEL 2-cell vertical column should have 4 side wall segments, got %d" % segs.size())
	for s in segs:
		_assert(s["side"] == "W" or s["side"] == "E", "DIRECTIONAL_FUNNEL segments should be side walls (W or E)")

func _test_divided_lanes_edge_segments() -> void:
	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)]
	mod.enclosure_type = PolyominoModuleData.EnclosureType.DIVIDED_LANES

	var segs: Array[Dictionary] = mod.get_solid_edge_segments(0)
	_assert(segs.size() == 7, "DIVIDED_LANES 2-cell line should have 7 total wall segments, got %d" % segs.size())

	var internal_count: int = 0
	for s in segs:
		if s.get("is_internal", false):
			internal_count += 1
	_assert(internal_count == 1, "DIVIDED_LANES 2-cell line should have 1 internal partition segment, got %d" % internal_count)

func _test_rotation_transforms_for_edges() -> void:
	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(0, 1)]
	mod.enclosure_type = PolyominoModuleData.EnclosureType.FULL_ENCLOSURE

	var segs0: Array[Dictionary] = mod.get_solid_edge_segments(0)
	_assert(segs0.size() == 6, "Step 0 FULL_ENCLOSURE 2-cell segments count should be 6")

	var segs1: Array[Dictionary] = mod.get_solid_edge_segments(1)
	_assert(segs1.size() == 6, "Step 1 FULL_ENCLOSURE 2-cell segments count should be 6")

func _test_relic_database_enclosure_assignments() -> void:
	var perf := PolyominoRelicDatabase.create_module_for_relic(&"perpetual_engine")
	_assert(perf != null, "perpetual_engine module should load")
	_assert(perf.enclosure_type == PolyominoModuleData.EnclosureType.DIRECTIONAL_FUNNEL, "perpetual_engine enclosure_type should be DIRECTIONAL_FUNNEL")

	var super_c := PolyominoRelicDatabase.create_module_for_relic(&"superconductor")
	_assert(super_c != null, "superconductor module should load")
	_assert(super_c.enclosure_type == PolyominoModuleData.EnclosureType.FULL_ENCLOSURE, "superconductor enclosure_type should be FULL_ENCLOSURE")

	var twin := PolyominoRelicDatabase.create_module_for_relic(&"twin_mandate")
	_assert(twin != null, "twin_mandate module should load")
	_assert(twin.enclosure_type == PolyominoModuleData.EnclosureType.DIVIDED_LANES, "twin_mandate enclosure_type should be DIVIDED_LANES")

func _test_module_node_wall_collision() -> void:
	var node := PolyominoModuleNode.new()
	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0)]
	mod.enclosure_type = PolyominoModuleData.EnclosureType.FULL_ENCLOSURE

	var item := JunkBoxItemScript.new()
	item.module_data = mod
	node.setup_module(item, Vector2i(0, 0), 0)

	var ball := RigidBody2D.new()
	ball.position = Vector2(0.0, -25.0)
	ball.linear_velocity = Vector2(0.0, -100.0)

	var res: Dictionary = node.check_ball_collision(ball, 1)
	_assert(res.get("activated", false) == true, "Ball moving toward solid wall should trigger wall collision")
	_assert(res.get("wall_hit", false) == true, "Result should have wall_hit = true")
	node.free()
	ball.free()
