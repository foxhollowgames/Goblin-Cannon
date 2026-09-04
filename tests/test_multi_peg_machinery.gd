extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const PolyominoModuleNodeScript = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoMachineryComponentScript = preload("res://scenes/board/machinery/polyomino_machinery_component.gd")
const PopBumperScript = preload("res://scenes/board/machinery/pop_bumper.gd")
const ScoopSinkholeScript = preload("res://scenes/board/machinery/scoop_sinkhole.gd")
const BashToyScript = preload("res://scenes/board/machinery/bash_toy.gd")
const SlingshotKickerScript = preload("res://scenes/board/machinery/slingshot_kicker.gd")
const BallScript = preload("res://scenes/balls/ball.gd")

func _init() -> void:
	suite_name = "MultiPegMachinery"

func run() -> void:
	test_unified_module_spawning_and_centering()
	test_mega_pop_bumper_footprint_and_impulse()
	test_abyssal_maw_multiball_capture_and_ejection()
	test_golem_effigy_centerpiece_footprint()
	test_corner_slingshot_segment_normal_impulse()
	test_legacy_per_cell_modules_remain_functional()

var _next_mock_ball_id: int = 100

func _create_mock_ball(pos: Vector2 = Vector2.ZERO, vel: Vector2 = Vector2.ZERO, start_energy: int = 10) -> RigidBody2D:
	var ball := RigidBody2D.new()
	ball.set_script(BallScript)
	ball._ready()
	_next_mock_ball_id += 1
	ball.set_ball_id(_next_mock_ball_id)
	ball.position = pos
	ball.linear_velocity = vel
	ball.set_total_energy_display(start_energy)
	return ball

func test_unified_module_spawning_and_centering() -> void:
	begin("Unified 2x2 module spawns single component centered across cells")
	var mod_data := PolyominoModuleData.new()
	mod_data.module_id = &"test_unified_2x2"
	mod_data.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	mod_data.layout_mode = PolyominoModuleData.MachineryLayoutMode.UNIFIED
	mod_data.unified_component_type = PolyominoModuleData.CellType.POP_BUMPER

	var item := JunkBoxItem.new(&"item_u", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data

	var module_node: Node2D = PolyominoModuleNodeScript.new()
	module_node.setup_module(item, Vector2i(0, 0), 0)

	var comps: Array = module_node.get_all_components()
	assert_eq(comps.size(), 1, "Unified module spawns exactly one component")
	var comp: Node2D = comps[0]
	assert_eq(comp.position, Vector2(26.0, 28.0), "Component centered at average of 4 cells")

	for c in mod_data.cells:
		assert_eq(module_node.get_component_at_local_cell(c), comp, "All local cells map to unified component")

	module_node.queue_free()

func test_mega_pop_bumper_footprint_and_impulse() -> void:
	begin("Mega Pop Bumper uses 48px radius, grants 20 energy, and repels with 650 impulse")
	var mod_data: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(&"mega_pop_bumper")
	assert_true(mod_data != null, "Mega pop bumper relic definition exists")
	assert_eq(mod_data.layout_mode, PolyominoModuleData.MachineryLayoutMode.UNIFIED, "Layout mode is UNIFIED")

	var item := JunkBoxItem.new(&"item_mega_bumper", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data

	var module_node: Node2D = PolyominoModuleNodeScript.new()
	module_node.setup_module(item, Vector2i(0, 0), 0)

	var comp = module_node.get_all_components()[0]
	assert_true(comp is PopBumper, "Component is PopBumber")
	assert_eq(comp.component_radius, 48.0, "Radius scaled to 48px for 2x2 footprint")
	assert_eq(comp.base_energy, 20, "Base energy tuned to 20 for mega bumper")
	assert_eq(comp.impulse_strength, 650.0, "Impulse tuned to 650 for mega bumper")

	var ball := _create_mock_ball(Vector2(26.0, 28.0 - 45.0), Vector2(0, 50), 10)
	var hit_res: Dictionary = module_node.check_ball_collision(ball, 10)
	assert_true(hit_res.get("activated", false), "Ball within 48px radius triggers collision")
	assert_eq(hit_res.get("energy_granted", 0), 20, "Granted 20 energy on impact")

	ball.queue_free()
	module_node.queue_free()

func test_abyssal_maw_multiball_capture_and_ejection() -> void:
	begin("Abyssal Maw captures multiple balls simultaneously and ejects in volley")
	var mod_data: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(&"abyssal_maw")
	assert_true(mod_data != null, "Abyssal maw relic exists")

	var item := JunkBoxItem.new(&"item_abyssal", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data

	var module_node: Node2D = PolyominoModuleNodeScript.new()
	module_node.setup_module(item, Vector2i(0, 0), 0)

	var comp = module_node.get_all_components()[0]
	assert_true(comp is ScoopSinkhole, "Component is ScoopSinkhole")
	assert_eq(comp.component_radius, 48.0, "Radius is 48px")

	var ball1 := _create_mock_ball(Vector2(26.0, 28.0), Vector2(0, 100), 10)
	var ball2 := _create_mock_ball(Vector2(26.0, 28.0), Vector2(0, 100), 10)

	var hit1: Dictionary = comp.trigger_activation(ball1, 10)
	var hit2: Dictionary = comp.trigger_activation(ball2, 10)
	assert_true(hit1.get("activated", false), "Ball 1 captured")
	assert_true(hit2.get("activated", false), "Ball 2 captured")

	assert_eq(ball1.linear_velocity, Vector2.ZERO, "Ball 1 velocity halted")
	assert_eq(ball2.linear_velocity, Vector2.ZERO, "Ball 2 velocity halted")

	comp._on_hold_timeout()
	assert_true(ball1.linear_velocity.length() > 100.0, "Ball 1 launched with impulse")
	assert_true(ball2.linear_velocity.length() > 100.0, "Ball 2 launched with impulse")

	ball1.queue_free()
	ball2.queue_free()
	module_node.queue_free()

func test_golem_effigy_centerpiece_footprint() -> void:
	begin("Golem Effigy enforces minimum 2x2 footprint with 8 hit durability")
	var mod_data: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(&"golem_effigy")
	assert_true(mod_data != null, "Golem effigy relic exists")

	var item := JunkBoxItem.new(&"item_golem", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data

	var module_node: Node2D = PolyominoModuleNodeScript.new()
	module_node.setup_module(item, Vector2i(0, 0), 0)

	var comp = module_node.get_all_components()[0]
	assert_true(comp is BashToy, "Component is BashToy")
	assert_eq(comp.component_radius, 48.0, "Enforces minimum 48px centerpiece radius")
	assert_eq(comp.max_hits, 8, "Requires 8 hits to break")

	var ball := _create_mock_ball(Vector2(26.0, 28.0), Vector2(0, 50), 10)
	var res: Dictionary = comp.trigger_activation(ball, 10)
	assert_true(res.get("activated", false), "Bash toy activates on hit")
	assert_eq(comp.current_hits, 1, "Current hits incremented to 1")

	ball.queue_free()
	module_node.queue_free()

func test_corner_slingshot_segment_normal_impulse() -> void:
	begin("Corner Slingshot uses angled segment collision and inward normal impulse")
	var mod_data: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(&"corner_slingshot")
	assert_true(mod_data != null, "Corner slingshot relic exists")

	var item := JunkBoxItem.new(&"item_corner", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data

	var module_node: Node2D = PolyominoModuleNodeScript.new()
	module_node.setup_module(item, Vector2i(0, 0), 0)

	var comp = module_node.get_all_components()[0]
	assert_true(comp is SlingshotKicker, "Component is SlingshotKicker")
	assert_eq(comp.shape_type, PolyominoMachineryComponentScript.ShapeType.SEGMENT, "Shape type is SEGMENT")

	var ball := _create_mock_ball(Vector2.ZERO, Vector2(100, 100), 10)
	var impulse: Vector2 = comp._compute_impulse(ball)
	assert_true(impulse.length() > 400.0, "Impulse strength applied")

	ball.queue_free()
	module_node.queue_free()

func test_legacy_per_cell_modules_remain_functional() -> void:
	begin("Legacy per-cell modules spawn individual components at each cell coordinate")
	var mod_data := PolyominoModuleData.new()
	mod_data.module_id = &"test_legacy_domino"
	mod_data.cells = [Vector2i(0, 0), Vector2i(1, 0)]
	mod_data.layout_mode = PolyominoModuleData.MachineryLayoutMode.PER_CELL
	mod_data.set_cell_type_at(Vector2i(0, 0), PolyominoModuleData.CellType.POP_BUMPER)
	mod_data.set_cell_type_at(Vector2i(1, 0), PolyominoModuleData.CellType.POP_BUMPER)

	var item := JunkBoxItem.new(&"item_legacy", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data

	var module_node: Node2D = PolyominoModuleNodeScript.new()
	module_node.setup_module(item, Vector2i(0, 0), 0)

	var comps: Array = module_node.get_all_components()
	assert_eq(comps.size(), 2, "Per-cell mode spawns separate component per cell")
	assert_eq(comps[0].position, Vector2(0, 0), "First component at (0, 0)")
	assert_eq(comps[1].position, Vector2(52.0, 0), "Second component at (52, 0)")

	module_node.queue_free()
