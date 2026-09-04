extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const PolyominoModuleNodeScript = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const RolloverSwitchScript = preload("res://scenes/board/machinery/rollover_switch.gd")
const PopBumperScript = preload("res://scenes/board/machinery/pop_bumper.gd")
const DropTargetScript = preload("res://scenes/board/machinery/drop_target.gd")
const WireGateScript = preload("res://scenes/board/machinery/wire_gate.gd")
const SlingshotKickerScript = preload("res://scenes/board/machinery/slingshot_kicker.gd")
const BallScript = preload("res://scenes/balls/ball.gd")

func _init() -> void:
	suite_name = "PinballMachinery"

func run() -> void:
	test_rollover_switch_and_bank_completion()
	test_pop_bumper_impulse_and_energy()
	test_drop_target_registration_and_reset()
	test_wire_gate_directional_passage()
	test_slingshot_kicker_impulse()

func _create_mock_ball(pos: Vector2 = Vector2.ZERO, vel: Vector2 = Vector2.ZERO, start_energy: int = 10) -> RigidBody2D:
	var ball := RigidBody2D.new()
	ball.set_script(BallScript)
	ball._ready()
	ball.position = pos
	ball.linear_velocity = vel
	ball.set_total_energy_display(start_energy)
	return ball

func test_rollover_switch_and_bank_completion() -> void:
	begin("Rollover switch lights on contact and emits bank_completed when all switches lit")
	var mod_data := PolyominoModuleData.new()
	mod_data.module_id = &"rollover_bank_test"
	mod_data.cells = [Vector2i(0, 0), Vector2i(1, 0)]
	mod_data.set_cell_type_at(Vector2i(0, 0), PolyominoModuleData.CellType.ROLLOVER_SWITCH)
	mod_data.set_cell_type_at(Vector2i(1, 0), PolyominoModuleData.CellType.ROLLOVER_SWITCH)

	var item := JunkBoxItem.new(&"item_roll", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data

	var module_node: Node2D = PolyominoModuleNodeScript.new()
	module_node.setup_module(item, Vector2i(0, 0), 0)

	var bank_result: Array = [false]
	module_node.bank_completed.connect(func(_id, _type, _val): bank_result[0] = true)

	var sw0: Node = module_node.get_component_at_local_cell(Vector2i(0, 0))
	var sw1: Node = module_node.get_component_at_local_cell(Vector2i(1, 0))

	assert_false(sw0.get("is_lit"), "sw0 starts unlit")
	assert_false(sw1.get("is_lit"), "sw1 starts unlit")

	var ball := _create_mock_ball(Vector2.ZERO, Vector2(0, 50), 10)

	sw0.trigger_activation(ball, 10)
	assert_true(sw0.get("is_lit"), "sw0 becomes lit on activation")
	assert_false(bank_result[0], "bank not completed with only 1/2 switches lit")

	sw1.trigger_activation(ball, 20)
	assert_true(sw1.get("is_lit"), "sw1 becomes lit on activation")
	assert_true(bank_result[0], "bank_completed emitted when all bank switches lit")

	ball.free()
	module_node.free()

func test_pop_bumper_impulse_and_energy() -> void:
	begin("Pop bumper applies strong outward impulse and grants bonus energy")
	var pop: Node = PopBumperScript.new()
	pop._ready()
	pop.position = Vector2(100, 100)

	var ball := _create_mock_ball(Vector2(100, 80), Vector2(0, 50), 10)
	var res: Dictionary = pop.trigger_activation(ball, 10)

	assert_true(res.get("activated", false), "pop bumper activates on contact")
	assert_eq(res.get("energy_granted", 0), 1, "pop bumper grants +1 energy")
	assert_eq(ball.get_total_energy(), 11, "ball total energy updated to 11")

	var impulse: Vector2 = res.get("impulse_applied", Vector2.ZERO)
	assert_true(impulse.y < -100.0, "pop bumper flings ball upward away from bumper")

	ball.free()
	pop.free()

func test_drop_target_registration_and_reset() -> void:
	begin("Drop target drops on hit, becomes permeable, and resets cleanly")
	var target: Node = DropTargetScript.new()
	target._ready()
	target.position = Vector2(50, 50)

	assert_false(target.get("is_dropped"), "target starts undropped")

	var ball := _create_mock_ball(Vector2(50, 50), Vector2(0, 50), 10)
	var res1: Dictionary = target.trigger_activation(ball, 10)

	assert_true(res1.get("activated", false), "drop target activates on hit")
	assert_true(target.get("is_dropped"), "target is marked dropped")
	assert_true(target.get("is_permeable"), "target becomes permeable when dropped")

	var res2: Dictionary = target.trigger_activation(ball, 20)
	assert_false(res2.get("activated", false), "dropped target ignores subsequent hits")

	target.reset_target()
	assert_false(target.get("is_dropped"), "target is restored on reset")
	assert_false(target.get("is_permeable"), "target is no longer permeable after reset")

	ball.free()
	target.free()

func test_wire_gate_directional_passage() -> void:
	begin("One-way wire gate allows forward passage and deflects reverse motion")
	var gate: Node = WireGateScript.new()
	gate._ready()
	gate.position = Vector2(100, 100)
	gate.direction = Vector2.DOWN

	var ball1 := _create_mock_ball(Vector2(100, 100), Vector2(0, 100), 10)
	var res1: Dictionary = gate.trigger_activation(ball1, 10)
	assert_true(res1.get("activated", false), "wire gate allows forward ball passage")
	assert_gt(ball1.linear_velocity.y, 0.0, "forward ball continues downward")

	var ball2 := _create_mock_ball(Vector2(100, 100), Vector2(0, -100), 10)
	var res2: Dictionary = gate.trigger_activation(ball2, 20)
	assert_true(res2.get("activated", false), "wire gate interacts with reverse ball")
	assert_gt(ball2.linear_velocity.y, 0.0, "reverse ball is bounced back downward")

	ball1.free()
	ball2.free()
	gate.free()

func test_slingshot_kicker_impulse() -> void:
	begin("Slingshot kicker bounces ball across open chamber")
	var kicker: Node = SlingshotKickerScript.new()
	kicker._ready()
	kicker.position = Vector2(200, 200)

	var ball := _create_mock_ball(Vector2(200, 180), Vector2(0, 50), 10)
	var res: Dictionary = kicker.trigger_activation(ball, 10)

	assert_true(res.get("activated", false), "slingshot kicker activates")
	assert_eq(res.get("energy_granted", 0), 6, "slingshot kicker grants +6 energy")
	assert_gt(res.get("impulse_applied", Vector2.ZERO).length(), 100.0, "slingshot kicker applies strong impulse")

	ball.free()
	kicker.free()
