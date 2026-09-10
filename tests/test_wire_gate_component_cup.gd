extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoModuleNodeScript = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const WireGateScript = preload("res://scenes/board/machinery/wire_gate.gd")
const BallScript = preload("res://scenes/balls/ball.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")

func _init() -> void:
	suite_name = "WireGateComponentCup"

func run() -> void:
	test_multi_cell_cup_footprint_scaling()
	test_ball_retention_physics_and_movement()
	test_activation_requirements_gate_control()
	test_polyomino_module_integration_wire_gate_cup()
	test_wire_gate_auto_close_after_balls_exit()

var _mock_ball_counter: int = 100

func _create_mock_ball(pos: Vector2 = Vector2.ZERO, vel: Vector2 = Vector2.ZERO, start_energy: int = 10) -> RigidBody2D:
	var ball := RigidBody2D.new()
	ball.set_script(BallScript)
	ball._ready()
	ball.set_ball_id(_mock_ball_counter)
	_mock_ball_counter += 1
	ball.position = pos
	ball.linear_velocity = vel
	ball.set_total_energy_display(start_energy)
	return ball

func test_multi_cell_cup_footprint_scaling() -> void:
	begin("Wire gate scales cup footprint, capacity, and impulse for multi-cell layouts")
	var gate: WireGate = WireGateScript.new()
	gate._ready()

	# 1. Default / 1-cell footprint
	assert_eq(gate.max_capacity, 3, "default capacity is 3")
	assert_eq(gate.component_radius, 20.0, "default radius is 20")
	assert_eq(gate.release_impulse_strength, 320.0, "default impulse is 320")

	# 2. 2-cell footprint
	gate.configure_footprint(2)
	assert_eq(gate.max_capacity, 4, "2-cell capacity scales to 4")
	assert_eq(gate.component_radius, 38.0, "2-cell radius scales to 38")
	assert_eq(gate.release_impulse_strength, 380.0, "2-cell impulse scales to 380")
	assert_gt(gate.cup_rect.size.x, 0.0, "cup rect has valid width")

	# 3. 4-cell footprint
	gate.configure_footprint(4)
	assert_eq(gate.max_capacity, 5, "4-cell capacity scales to 5")
	assert_eq(gate.component_radius, 54.0, "4-cell radius scales to 54")
	assert_eq(gate.release_impulse_strength, 440.0, "4-cell impulse scales to 440")

	# 4. 9-cell footprint
	gate.configure_footprint(9)
	assert_eq(gate.max_capacity, 6, "9-cell capacity scales to 6")
	assert_eq(gate.component_radius, 76.0, "9-cell radius scales to 76")
	assert_eq(gate.release_impulse_strength, 500.0, "9-cell impulse scales to 500")

	gate.free()

func test_ball_retention_physics_and_movement() -> void:
	begin("Trapped balls move inside cup without pinning to single peg and stay bounded")
	var gate: WireGate = WireGateScript.new()
	gate._ready()
	gate.configure_footprint(4) # radius 54.0
	gate.position = Vector2(100, 100)
	gate.direction = Vector2.DOWN

	var ball1 := _create_mock_ball(Vector2(100, 100), Vector2(0, 80), 10)
	gate.trigger_activation(ball1, 10)

	assert_eq(gate.retained_balls.size(), 1, "ball is retained in cup")
	assert_false(gate.is_open, "gate remains closed")

	# Ball moves inside cup interior: position should NOT be reset to center (100, 100)
	ball1.position = Vector2(115, 110)
	gate._process(0.016)
	assert_eq(ball1.position, Vector2(115, 110), "ball position is preserved inside cup interior")

	# Ball moves beyond cup radius: process clamps it inside
	ball1.position = Vector2(250, 100)
	gate._process(0.016)
	var offset: Vector2 = ball1.position - gate.position
	assert_lt(offset.length(), 60.0, "ball is constrained inside cup boundary")

	# Ball moves past gate barrier in forward direction: gate blocks it
	ball1.position = Vector2(100, 180) # far below down gate
	gate._process(0.016)
	var forward_y: float = ball1.position.y - gate.position.y
	assert_lt(forward_y, 50.0, "closed gate barrier stops ball from crossing exit")

	ball1.free()
	gate.free()

func test_activation_requirements_gate_control() -> void:
	begin("Gate remains closed until activation requirements are satisfied")
	var gate: WireGate = WireGateScript.new()
	gate._ready()
	gate.requires_external_activation = true
	gate.max_capacity = 3
	gate.position = Vector2(200, 200)
	gate.direction = Vector2.DOWN

	var ball1 := _create_mock_ball(Vector2(200, 200), Vector2(0, 60), 10)
	var ball2 := _create_mock_ball(Vector2(200, 200), Vector2(0, 60), 10)
	var ball3 := _create_mock_ball(Vector2(200, 200), Vector2(0, 60), 10)

	gate.trigger_activation(ball1, 10)
	gate.trigger_activation(ball2, 20)
	gate.trigger_activation(ball3, 30)

	# Even though max_capacity (3) is reached, gate must remain closed because external activation is not met
	assert_eq(gate.retained_balls.size(), 3, "all 3 balls retained in holding cup")
	assert_false(gate.is_open, "gate stays closed because requirements are not satisfied")
	assert_false(gate.is_requirement_satisfied, "requirement is not yet marked satisfied")

	# Fourth ball arriving while closed and full should bounce off entrance
	var ball4 := _create_mock_ball(Vector2(200, 200), Vector2(0, 60), 10)
	var res4: Dictionary = gate.trigger_activation(ball4, 40)
	assert_eq(gate.retained_balls.size(), 3, "cup does not exceed max capacity")
	assert_lt(ball4.linear_velocity.y, 0.0, "overflow ball bounced backward away from cup")

	# Now satisfy the activation requirement
	var cascade_emitted: Array = [false]
	gate.cascade_released.connect(func(_g, _balls): cascade_emitted[0] = true)

	var released_balls: Array = gate.satisfy_activation_requirement()
	assert_true(gate.is_open, "gate opens upon satisfying activation requirements")
	assert_true(gate.is_requirement_satisfied, "requirement is marked satisfied")
	assert_true(cascade_emitted[0], "cascade_released signal emitted")
	assert_eq(released_balls.size(), 3, "all 3 trapped balls released in cascade")
	assert_eq(gate.retained_balls.size(), 0, "retained balls array emptied on release")

	ball1.free()
	ball2.free()
	ball3.free()
	ball4.free()
	gate.free()

func test_polyomino_module_integration_wire_gate_cup() -> void:
	begin("PolyominoModuleNode automatically links wire gate to module activation goal")
	var mod_data := PolyominoModuleData.new()
	mod_data.module_id = &"wire_gate_cup_module"
	mod_data.cells = [Vector2i(0, 0), Vector2i(0, 1)]
	mod_data.layout_mode = PolyominoModuleData.MachineryLayoutMode.UNIFIED
	mod_data.unified_component_type = PolyominoModuleData.CellType.WIRE_GATE
	mod_data.activation_threshold = 3 # Requires 3 hits to complete goal

	var item := JunkBoxItem.new(&"wire_gate_cup_module", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data
	var module_node := PolyominoModuleNodeScript.new()
	module_node.setup_module(item, Vector2i.ZERO, 0)

	assert_eq(module_node._components.size(), 1, "module created unified component")
	var gate: WireGate = module_node._components[0] as WireGate
	assert_true(gate != null, "unified component is WireGate")
	assert_true(gate.requires_external_activation, "module sets requires_external_activation on gate")
	assert_false(gate.is_open, "gate starts closed")

	var ball1 := _create_mock_ball(gate.position, Vector2(0, 50), 10)
	var ball2 := _create_mock_ball(gate.position, Vector2(0, 50), 10)
	var ball3 := _create_mock_ball(gate.position, Vector2(0, 50), 10)

	# First ball enters: 1 hit, retained, gate remains closed
	gate.trigger_activation(ball1, 10)
	assert_eq(gate.retained_balls.size(), 1, "1 ball held in cup")
	assert_false(gate.is_open, "gate remains closed on 1 hit")

	# Second ball enters: 2 hits, retained, gate remains closed
	gate.trigger_activation(ball2, 20)
	assert_eq(gate.retained_balls.size(), 2, "2 balls held in cup")
	assert_false(gate.is_open, "gate remains closed on 2 hits")

	# Third ball enters: 3 hits meets activation threshold! Goal triggers and releases all balls
	gate.trigger_activation(ball3, 30)
	assert_true(gate.is_open, "module goal completion automatically opens wire gate")
	assert_eq(gate.retained_balls.size(), 0, "all balls were cascaded out of cup upon goal completion")

	ball1.free()
	ball2.free()
	ball3.free()
	module_node.free()

func test_wire_gate_auto_close_after_balls_exit() -> void:
	begin("Wire gate automatically closes after all released balls exit component bounds")
	var gate: WireGate = WireGateScript.new()
	gate._ready()
	gate.position = Vector2(100, 100)
	gate.direction = Vector2.DOWN

	var ball1 := _create_mock_ball(Vector2(100, 100), Vector2(0, 50), 10)
	gate.trigger_activation(ball1, 10)
	gate.release_retained_balls()

	assert_true(gate.is_open, "gate is open on release")

	# While ball is still near gate center, gate stays open
	ball1.position = Vector2(100, 110)
	gate._process(0.016)
	assert_true(gate.is_open, "gate stays open while released ball is still exiting")

	# When ball moves far outside the cup bounds, gate detects exit and closes
	ball1.position = Vector2(100, 200)
	gate._process(0.016)
	assert_false(gate.is_open, "gate automatically closes after ball exits component bounds")

	ball1.free()
	gate.free()
