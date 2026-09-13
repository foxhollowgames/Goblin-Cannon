extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoModuleNodeScript = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const RolloverSwitchScript = preload("res://scenes/board/machinery/rollover_switch.gd")
const SlingshotKickerScript = preload("res://scenes/board/machinery/slingshot_kicker.gd")
const WireGateScript = preload("res://scenes/board/machinery/wire_gate.gd")
const SpinnerScript = preload("res://scenes/board/machinery/spinner.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")

const CellType = PolyominoModuleData.CellType

class MockBall extends Node2D:
	var peg_energy: int = 0
	var linear_velocity: Vector2 = Vector2.ZERO
	var ball_id: int = 101

	func add_peg_energy(amount: int) -> void:
		peg_energy += amount

	func get_ball_id() -> int:
		return ball_id

func _init() -> void:
	suite_name = "DeliberatePinballDevices"

func run() -> void:
	test_rollover_word_bank_energy_and_letters()
	test_crackling_detonation_triangle()
	test_retention_reservoir_wire_gate_cascade()
	test_funneled_spinner_overdrive_and_cooldown()
	test_database_word_bank_and_archetype_mapping()
	cleanup()

func test_rollover_word_bank_energy_and_letters() -> void:
	begin("Rollover word bank letters, unlit energy award, and bank completion")
	var mod_data := PolyominoModuleData.new()
	mod_data.module_id = &"word_bank_win"
	mod_data.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	mod_data.set_cell_type_at(Vector2i(0, 0), CellType.ROLLOVER_SWITCH)
	mod_data.set_cell_type_at(Vector2i(1, 0), CellType.ROLLOVER_SWITCH)
	mod_data.set_cell_type_at(Vector2i(2, 0), CellType.ROLLOVER_SWITCH)
	mod_data.set_cell_letter_at(Vector2i(0, 0), "W")
	mod_data.set_cell_letter_at(Vector2i(1, 0), "I")
	mod_data.set_cell_letter_at(Vector2i(2, 0), "N")

	var item := JunkBoxItem.new(&"item_win", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data

	var module_node: Node2D = PolyominoModuleNodeScript.new()
	autofree(module_node)
	module_node.setup_module(item, Vector2i.ZERO, 0)

	var sw0: RolloverSwitch = module_node.get_component_at_local_cell(Vector2i(0, 0)) as RolloverSwitch
	var sw1: RolloverSwitch = module_node.get_component_at_local_cell(Vector2i(1, 0)) as RolloverSwitch
	var sw2: RolloverSwitch = module_node.get_component_at_local_cell(Vector2i(2, 0)) as RolloverSwitch

	assert_true(sw0 != null, "sw0 exists")
	assert_true(sw1 != null, "sw1 exists")
	assert_true(sw2 != null, "sw2 exists")

	assert_eq(sw0.letter, "W", "sw0 has letter W")
	assert_eq(sw1.letter, "I", "sw1 has letter I")
	assert_eq(sw2.letter, "N", "sw2 has letter N")

	var ball := MockBall.new()
	autofree(ball)

	var res0: Dictionary = sw0.trigger_activation(ball, 1)
	assert_true(res0.get("activated", false), "sw0 activated")
	assert_true(sw0.is_lit, "sw0 is lit after activation")
	assert_eq(ball.peg_energy, 13, "ball received base 3 + 10 unlit bonus energy from sw0")

	# Second hit while lit should not grant another unlit bonus
	var res0_again: Dictionary = sw0.trigger_activation(ball, 20)
	assert_true(res0_again.get("activated", false), "sw0 activated again")
	assert_eq(ball.peg_energy, 16, "ball only received base energy on second hit")

	var bank_completed_fired: Array = [false]
	module_node.bank_completed.connect(func(_id, _reward, _val): bank_completed_fired[0] = true)

	sw1.trigger_activation(ball, 30)
	assert_false(bank_completed_fired[0], "bank not yet complete with 2 of 3 lit")

	sw2.trigger_activation(ball, 40)
	assert_true(bank_completed_fired[0], "bank completed fired when all 3 switches lit")

func test_crackling_detonation_triangle() -> void:
	begin("Crackling detonation triangle charge, procedural lightning, and blast")
	var tri := SlingshotKickerScript.new() as SlingshotKicker
	autofree(tri)
	tri.hits_to_detonate = 3
	tri.detonation_bonus_energy = 50
	tri._ready()

	assert_eq(tri.current_charge, 0, "initial charge is 0")
	assert_eq(tri.get_crackle_line_count(), 0, "initial crackle lines is 0")

	var ball := MockBall.new()
	autofree(ball)

	var detonated: Array = [false]
	tri.triangle_detonated.connect(func(_t, _pos): detonated[0] = true)

	# Hit 1
	tri.trigger_activation(ball, 1)
	assert_eq(tri.current_charge, 1, "current charge is 1 after hit 1")
	assert_true(tri.get_crackle_line_count() > 0, "procedural lightning crackles generated on charge")
	assert_false(detonated[0], "not detonated at charge 1")

	# Hit 2
	tri.trigger_activation(ball, 10)
	assert_eq(tri.current_charge, 2, "current charge is 2 after hit 2")
	assert_false(detonated[0], "not detonated at charge 2")

	# Hit 3 (reaches hits_to_detonate = 3)
	tri.trigger_activation(ball, 20)
	assert_true(detonated[0], "detonation emitted at full charge")
	assert_eq(tri.current_charge, 0, "current charge reset to 0 after blast")
	assert_eq(tri.get_crackle_line_count(), 0, "crackle lines cleared after blast")

func test_retention_reservoir_wire_gate_cascade() -> void:
	begin("Retention reservoir wire gate traps balls and bursts open at capacity")
	var gate := WireGateScript.new() as WireGate
	autofree(gate)
	gate.requires_external_activation = false
	gate.max_capacity = 3
	gate._ready()

	assert_false(gate.is_open, "gate starts closed as retention cup")
	assert_eq(gate.retained_balls.size(), 0, "held count starts at 0")

	var cascade_emitted: Array = [false]
	var cascade_count: Array = [0]
	gate.cascade_released.connect(func(_g, balls):
		cascade_emitted[0] = true
		cascade_count[0] = balls.size()
	)

	var b1 := MockBall.new(); b1.ball_id = 1; autofree(b1)
	var b2 := MockBall.new(); b2.ball_id = 2; autofree(b2)
	var b3 := MockBall.new(); b3.ball_id = 3; autofree(b3)

	gate.trigger_activation(b1, 10)
	assert_eq(gate.retained_balls.size(), 1, "1 ball held in cup")
	assert_false(gate.is_open, "remains closed with 1 ball")

	gate.trigger_activation(b2, 20)
	assert_eq(gate.retained_balls.size(), 2, "2 balls held in cup")
	assert_false(gate.is_open, "remains closed with 2 balls")

	# 3rd ball reaches capacity
	gate.trigger_activation(b3, 30)
	assert_true(cascade_emitted[0], "cascade release emitted on capacity reached")
	assert_eq(cascade_count[0], 3, "all 3 trapped balls released in cascade")
	assert_true(gate.is_open, "gate opened after cascade burst")

func test_funneled_spinner_overdrive_and_cooldown() -> void:
	begin("Funneled spinner overdrive threshold, cooldown, and continuous energy")
	var spinner := SpinnerScript.new() as Spinner
	autofree(spinner)
	spinner.rpm_trigger_threshold = 30.0
	spinner.effect_cooldown_duration = 2.0
	spinner._ready()

	var overdrive_fired: Array = [false]
	spinner.spinner_overdrive_triggered.connect(func(_sp): overdrive_fired[0] = true)

	var ball := MockBall.new()
	autofree(ball)

	# Normal activation below threshold (initial velocity 24.0 < 30.0)
	spinner.trigger_activation(ball, 1)
	assert_false(overdrive_fired[0], "not fired below RPM threshold")
	assert_true(spinner.effect_cooldown_timer <= 0.0, "not on cooldown below threshold")

	# Second activation pushes velocity from ~24 to ~48 (>= 30.0)
	spinner.trigger_activation(ball, 10)
	assert_true(overdrive_fired[0], "overdrive fired when exceeding RPM threshold")
	assert_true(spinner.effect_cooldown_timer > 0.0, "spinner entered cooldown after overdrive")

	# While on cooldown, physical spins and energy generation still operate
	overdrive_fired[0] = false
	var res: Dictionary = spinner.trigger_activation(ball, 20)
	assert_true(res.get("activated", false), "spinner activates and spins even while on overdrive cooldown")
	assert_true(res.get("energy_granted", 0) > 0, "spinner grants energy during cooldown")
	assert_false(overdrive_fired[0], "overdrive blocked during cooldown period")

func test_database_word_bank_and_archetype_mapping() -> void:
	begin("Relic database defines valid cell letters and archetypes for all campaign relics")
	var all_ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	assert_true(all_ids.size() >= 80, "all 80+ relics present in database")

	for rid in all_ids:
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(rid)
		assert_true(mod != null, "module created for %s" % rid)
		assert_true(mod.cells.size() > 0, "%s has cells" % rid)
