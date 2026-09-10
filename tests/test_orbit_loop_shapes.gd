extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const PolyominoModuleNodeScript = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const OrbitLoopScript = preload("res://scenes/board/machinery/orbit_loop.gd")
const BallScript = preload("res://scenes/balls/ball.gd")

func _init() -> void:
	suite_name = "OrbitLoopShapes"

func run() -> void:
	test_v_shape_3_configuration_and_geometry()
	test_u_shape_5_configuration_and_geometry()
	test_u_shape_7_configuration_and_geometry()
	test_v_shape_ball_entry_and_exit_impulse_forward()
	test_v_shape_ball_entry_and_exit_impulse_reverse()
	test_u_shape_ball_entry_and_exit_impulse()
	test_unified_module_node_orbit_loop_relics()

var _next_mock_ball_id: int = 500

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

func test_v_shape_3_configuration_and_geometry() -> void:
	begin("3-cell V-shape configures turnaround waypoints and ports")
	var orbit: OrbitLoop = autofree(OrbitLoopScript.new())
	orbit.configure_v_shape_3()

	assert_eq(orbit.get_loop_shape(), OrbitLoopScript.LoopShape.V_SHAPE_3, "Shape is V_SHAPE_3")
	assert_eq(orbit.get_waypoints().size(), 3, "V-shape has 3 waypoints")
	assert_gt(orbit.component_radius, 40.0, "Component radius scaled for V-shape")
	assert_eq(orbit.base_energy, 15, "Base energy tuned to 15 for 3-cell V loop")
	assert_eq(orbit.impulse_strength, 500.0, "Impulse strength tuned to 500 for V loop")

	var pa: Vector2 = orbit.get_port_a()
	var pb: Vector2 = orbit.get_port_b()
	var apex: Vector2 = orbit.get_apex_point()
	assert_true(pa != pb, "Port A and Port B are distinct endpoints")
	assert_true(pa.x < apex.x and pb.x > apex.x, "Apex is horizontally centered between ports")

func test_u_shape_5_configuration_and_geometry() -> void:
	begin("5-cell U-shape configures wide channel turnaround waypoints")
	var orbit: OrbitLoop = autofree(OrbitLoopScript.new())
	orbit.configure_u_shape_5()

	assert_eq(orbit.get_loop_shape(), OrbitLoopScript.LoopShape.U_SHAPE_5, "Shape is U_SHAPE_5")
	assert_eq(orbit.get_waypoints().size(), 5, "5-cell U-shape has 5 waypoints")
	assert_gt(orbit.component_radius, 60.0, "Component radius scaled for 5-cell U-shape")
	assert_eq(orbit.base_energy, 25, "Base energy tuned to 25 for 5-cell U loop")
	assert_eq(orbit.impulse_strength, 600.0, "Impulse strength tuned to 600 for 5-cell U loop")

	var pa: Vector2 = orbit.get_port_a()
	var pb: Vector2 = orbit.get_port_b()
	assert_true(pa != pb, "Port A and Port B are distinct endpoints")

func test_u_shape_7_configuration_and_geometry() -> void:
	begin("7-cell U-shape configures deep grand circuit turnaround waypoints")
	var orbit: OrbitLoop = autofree(OrbitLoopScript.new())
	orbit.configure_u_shape_7()

	assert_eq(orbit.get_loop_shape(), OrbitLoopScript.LoopShape.U_SHAPE_7, "Shape is U_SHAPE_7")
	assert_eq(orbit.get_waypoints().size(), 7, "7-cell U-shape has 7 waypoints")
	assert_gt(orbit.component_radius, 80.0, "Component radius scaled for 7-cell U-shape")
	assert_eq(orbit.base_energy, 35, "Base energy tuned to 35 for 7-cell U loop")
	assert_eq(orbit.impulse_strength, 700.0, "Impulse strength tuned to 700 for 7-cell U loop")

func test_v_shape_ball_entry_and_exit_impulse_forward() -> void:
	begin("Ball entering Port A traverses V loop and exits Port B with impulse")
	var orbit: OrbitLoop = autofree(OrbitLoopScript.new())
	orbit.configure_v_shape_3()

	var traversed_emitted: Array = [false]
	orbit.orbit_traversed.connect(func(_node: Node, _b: Node): traversed_emitted[0] = true)

	var ball := autofree(_create_mock_ball(orbit.get_port_a(), Vector2(0, 50), 10))
	var res: Dictionary = orbit.trigger_activation(ball, 10)

	assert_true(res.get("activated", false), "Orbit loop activated upon ball entry")
	assert_true(traversed_emitted[0], "orbit_traversed signal emitted")
	assert_eq(orbit.traversal_count, 1, "Traversal count incremented to 1")

	var impulse: Vector2 = res.get("impulse_applied", Vector2.ZERO)
	assert_gt(impulse.length(), 400.0, "Exit impulse applied with high magnitude")

func test_v_shape_ball_entry_and_exit_impulse_reverse() -> void:
	begin("Ball entering Port B traverses V loop in reverse and exits Port A")
	var orbit: OrbitLoop = autofree(OrbitLoopScript.new())
	orbit.configure_v_shape_3()

	var traversed_emitted: Array = [false]
	orbit.orbit_traversed.connect(func(_node: Node, _b: Node): traversed_emitted[0] = true)

	var ball := autofree(_create_mock_ball(orbit.get_port_b(), Vector2(0, 50), 10))
	var res: Dictionary = orbit.trigger_activation(ball, 10)

	assert_true(res.get("activated", false), "Orbit loop activated in reverse direction")
	assert_true(traversed_emitted[0], "orbit_traversed signal emitted")
	assert_eq(orbit.traversal_count, 1, "Traversal count incremented to 1")

	var impulse: Vector2 = res.get("impulse_applied", Vector2.ZERO)
	assert_gt(impulse.length(), 400.0, "Exit impulse applied on reverse exit")

func test_u_shape_ball_entry_and_exit_impulse() -> void:
	begin("Ball entry through 5-cell and 7-cell U-shapes applies accelerated impulse")
	var orbit5: OrbitLoop = autofree(OrbitLoopScript.new())
	orbit5.configure_u_shape_5()
	var ball5 := autofree(_create_mock_ball(orbit5.get_port_a(), Vector2(0, 50), 10))
	var res5: Dictionary = orbit5.trigger_activation(ball5, 10)
	assert_true(res5.get("activated", false), "5-cell U-shape activated")
	assert_eq(res5.get("energy_granted", 0), 25, "Granted 25 energy for 5-cell U-shape")
	assert_gt(res5.get("impulse_applied", Vector2.ZERO).length(), 500.0, "Strong exit impulse applied")

	var orbit7: OrbitLoop = autofree(OrbitLoopScript.new())
	orbit7.configure_u_shape_7()
	var ball7 := autofree(_create_mock_ball(orbit7.get_port_a(), Vector2(0, 50), 10))
	var res7: Dictionary = orbit7.trigger_activation(ball7, 10)
	assert_true(res7.get("activated", false), "7-cell U-shape activated")
	assert_eq(res7.get("energy_granted", 0), 35, "Granted 35 energy for 7-cell U-shape")
	assert_gt(res7.get("impulse_applied", Vector2.ZERO).length(), 600.0, "Grand circuit exit impulse applied")

func test_unified_module_node_orbit_loop_relics() -> void:
	begin("Unified module node instantiates multi-cell OrbitLoop for relic definitions")
	var apex_mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(&"apex_orbit_loop")
	assert_true(apex_mod != null, "Apex orbit loop relic definition exists")
	assert_eq(apex_mod.layout_mode, PolyominoModuleData.MachineryLayoutMode.UNIFIED, "Layout mode is UNIFIED")

	var item := JunkBoxItem.new(&"item_apex", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = apex_mod

	var module_node: Node2D = PolyominoModuleNodeScript.new()
	module_node.setup_module(item, Vector2i(0, 0), 0)

	var comps: Array = module_node.get_all_components()
	assert_eq(comps.size(), 1, "Spawns exactly one unified OrbitLoop component")
	var comp = comps[0]
	assert_true(comp is OrbitLoop, "Component is OrbitLoop")
	assert_eq(comp.get_loop_shape(), OrbitLoopScript.LoopShape.V_SHAPE_3, "Component shape is V_SHAPE_3")

	var ball := _create_mock_ball(comp.position + comp.get_port_a(), Vector2(0, 50), 10)
	var hit_res: Dictionary = module_node.check_ball_collision(ball, 10)
	assert_true(hit_res.get("activated", false), "Ball collision activates unified orbit loop")
	assert_eq(hit_res.get("energy_granted", 0), 15, "Granted 15 energy on activation")

	ball.queue_free()
	module_node.queue_free()
