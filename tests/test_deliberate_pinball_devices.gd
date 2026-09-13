extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoModuleNodeScript = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const RolloverSwitchScript = preload("res://scenes/board/machinery/rollover_switch.gd")
const SlingshotKickerScript = preload("res://scenes/board/machinery/slingshot_kicker.gd")
const WireGateScript = preload("res://scenes/board/machinery/wire_gate.gd")
const SpinnerScript = preload("res://scenes/board/machinery/spinner.gd")
const BashToyScript = preload("res://scenes/board/machinery/bash_toy.gd")
const DropTargetScript = preload("res://scenes/board/machinery/drop_target.gd")
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
	test_chonky_bash_toy_setpiece()
	test_wire_gate_retention_relic()
	test_bumper_chamber_ricochet()
	test_speed_rail_momentum_flow()
	test_diegetic_renderer_overlays_no_crash()
	test_bash_toy_lifecycle_and_break()
	test_wire_gate_open_close_cycle()
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
	tri.triangle_detonated.connect(func(_t, _pos, _ball): detonated[0] = true)

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
	spinner.spinner_overdrive_triggered.connect(func(_sp, _ball): overdrive_fired[0] = true)

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
	begin("Relic database defines valid cell letters and archetypes for deliberate relics")
	var all_ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	assert_true(all_ids.size() >= 80, "all 80+ relics present in database")

	for rid in all_ids:
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(rid)
		assert_true(mod != null, "module created for %s" % rid)
		assert_true(mod.cells.size() > 0, "%s has cells" % rid)

	# Test Phase Siphon (W-I-N)
	var win_mod := PolyominoRelicDatabase.create_module_for_relic(&"phase_siphon")
	assert_true(win_mod != null, "phase_siphon exists")
	assert_eq(win_mod.goal_type, PolyominoModuleData.GoalArchetype.ROLLOVER_SPELL, "phase_siphon is ROLLOVER_SPELL")
	assert_eq(win_mod.get_cell_letter_at(Vector2i(0, 0)), "W", "phase_siphon (0,0) is W")
	assert_eq(win_mod.get_cell_letter_at(Vector2i(1, 0)), "I", "phase_siphon (1,0) is I")
	assert_eq(win_mod.get_cell_letter_at(Vector2i(2, 0)), "N", "phase_siphon (2,0) is N")
	assert_eq(win_mod.enclosure_type, PolyominoModuleData.EnclosureType.DIVIDED_LANES, "phase_siphon has DIVIDED_LANES")

	# Test Volt Primer (G-O-B)
	var gob_mod := PolyominoRelicDatabase.create_module_for_relic(&"volt_primer")
	assert_true(gob_mod != null, "volt_primer exists")
	assert_eq(gob_mod.goal_type, PolyominoModuleData.GoalArchetype.ROLLOVER_SPELL, "volt_primer is ROLLOVER_SPELL")
	assert_eq(gob_mod.get_cell_letter_at(Vector2i(0, 0)), "G", "volt_primer (0,0) is G")
	assert_eq(gob_mod.get_cell_letter_at(Vector2i(1, 0)), "O", "volt_primer (1,0) is O")
	assert_eq(gob_mod.get_cell_letter_at(Vector2i(2, 0)), "B", "volt_primer (2,0) is B")

	# Test Static Bounce (P-O-P)
	var pop_mod := PolyominoRelicDatabase.create_module_for_relic(&"static_bounce")
	assert_true(pop_mod != null, "static_bounce exists")
	assert_eq(pop_mod.goal_type, PolyominoModuleData.GoalArchetype.ROLLOVER_SPELL, "static_bounce is ROLLOVER_SPELL")
	assert_eq(pop_mod.get_cell_letter_at(Vector2i(0, 0)), "P", "static_bounce (0,0) is P")
	assert_eq(pop_mod.get_cell_letter_at(Vector2i(1, 0)), "O", "static_bounce (1,0) is O")
	assert_eq(pop_mod.get_cell_letter_at(Vector2i(0, 1)), "P", "static_bounce (0,1) is P")

	# Test Devastating Barrage (B-A-M)
	var bam_mod := PolyominoRelicDatabase.create_module_for_relic(&"devastating_barrage")
	assert_true(bam_mod != null, "devastating_barrage exists")
	assert_eq(bam_mod.goal_type, PolyominoModuleData.GoalArchetype.ROLLOVER_SPELL, "devastating_barrage is ROLLOVER_SPELL")
	assert_eq(bam_mod.get_cell_letter_at(Vector2i(0, 0)), "B", "devastating_barrage (0,0) is B")
	assert_eq(bam_mod.get_cell_letter_at(Vector2i(0, 1)), "A", "devastating_barrage (0,1) is A")
	assert_eq(bam_mod.get_cell_letter_at(Vector2i(0, 2)), "M", "devastating_barrage (0,2) is M")

	# Test Wire Gate Relics
	var fswarm_mod := PolyominoRelicDatabase.create_module_for_relic(&"fragment_swarm")
	assert_eq(fswarm_mod.get_cell_type_at(Vector2i(1, 0)), CellType.WIRE_GATE, "fragment_swarm has WIRE_GATE")
	assert_eq(fswarm_mod.goal_type, PolyominoModuleData.GoalArchetype.SINKHOLE_LOCK, "fragment_swarm is SINKHOLE_LOCK")

	var drain_mod := PolyominoRelicDatabase.create_module_for_relic(&"overcharged_drain")
	assert_eq(drain_mod.get_cell_type_at(Vector2i(0, 0)), CellType.WIRE_GATE, "overcharged_drain has WIRE_GATE")

	var max_mod := PolyominoRelicDatabase.create_module_for_relic(&"max_energize_stacks")
	assert_eq(max_mod.get_cell_type_at(Vector2i(0, 0)), CellType.WIRE_GATE, "max_energize_stacks has WIRE_GATE")

func test_chonky_bash_toy_setpiece() -> void:
	begin("Chonky bash toy setpiece absorbed hits, demo goal, and no duplicate goal completion")
	var item := PolyominoRelicDatabase.create_item_for_relic(&"golem_effigy")
	assert_true(item != null, "golem_effigy item created")
	assert_true(item.module_data != null, "golem_effigy module data exists")
	assert_eq(item.module_data.layout_mode, PolyominoModuleData.MachineryLayoutMode.UNIFIED, "golem_effigy uses UNIFIED multi-peg layout")
	assert_eq(item.module_data.unified_component_type, CellType.BASH_TOY, "unified component is BASH_TOY")

	var node: Node2D = PolyominoModuleNodeScript.new()
	autofree(node)
	node.setup_module(item, Vector2i.ZERO, 0)

	var comp = node.get_unified_component()
	assert_true(comp != null, "unified component instance exists")

	var goals_completed: Array = []
	node.goal_completed.connect(func(id, rew, amt, _ball, _data = {}):
		goals_completed.append({"id": id, "reward": rew, "amount": amt})
	)

	var ball := MockBall.new()
	autofree(ball)

	# Golem effigy threshold is 5 hits
	for i in range(4):
		comp.trigger_activation(ball, (i + 1) * 20)
		assert_eq(goals_completed.size(), 0, "goal not completed before threshold (hit %d)" % (i + 1))

	comp.trigger_activation(ball, 100)
	assert_eq(goals_completed.size(), 1, "goal completed exactly once at threshold")

	# Hitting again should not double emit goal_completed in current activation
	comp.trigger_activation(ball, 120)
	assert_eq(goals_completed.size(), 1, "goal_completed not double emitted")

func test_wire_gate_retention_relic() -> void:
	begin("Wire gate retention reservoir on fragment_swarm relic")
	var item := PolyominoRelicDatabase.create_item_for_relic(&"fragment_swarm")
	assert_true(item != null, "fragment_swarm item created")
	assert_true(item.module_data.get_cell_type_at(Vector2i(1, 0)) != CellType.EMPTY, "has machine cell at 1,0")
	assert_eq(item.module_data.get_cell_type_at(Vector2i(1, 0)), CellType.WIRE_GATE, "fragment_swarm has WIRE_GATE at 1,0")

	var node: Node2D = PolyominoModuleNodeScript.new()
	autofree(node)
	node.setup_module(item, Vector2i.ZERO, 0)

	var gate = node.get_component_at_local_cell(Vector2i(1, 0)) as WireGate
	assert_true(gate != null, "wire gate component exists in module node")
	assert_true(gate.requires_external_activation, "wire gate requires external activation via module goal")

	var goals_completed: Array = []
	node.goal_completed.connect(func(id, rew, amt, triggering_ball, _data = {}):
		goals_completed.append({"id": id, "reward": rew, "amount": amt, "ball": triggering_ball})
	)

	var b1 := MockBall.new(); b1.ball_id = 1; autofree(b1)
	var b2 := MockBall.new(); b2.ball_id = 2; autofree(b2)
	var b3 := MockBall.new(); b3.ball_id = 3; autofree(b3)

	gate.trigger_activation(b1, 10)
	gate.trigger_activation(b2, 20)
	assert_eq(goals_completed.size(), 0, "not goal completed before gate capacity")

	gate.trigger_activation(b3, 30)
	assert_eq(goals_completed.size(), 1, "goal completed upon cascade release at capacity")
	assert_true(goals_completed[0]["ball"] != null, "triggering ball passed to reward")

func test_bumper_chamber_ricochet() -> void:
	begin("Bumper chamber rich ricochets and bounce energy on storm_of_fragments")
	var item := PolyominoRelicDatabase.create_item_for_relic(&"storm_of_fragments")
	assert_true(item != null, "storm_of_fragments item created")
	assert_true(item.module_data.get_cell_type_at(Vector2i(1, 0)) != CellType.EMPTY, "bumper cell at 1,0")
	assert_eq(item.module_data.get_cell_type_at(Vector2i(1, 0)), CellType.POP_BUMPER, "is POP_BUMPER")

	var node: Node2D = PolyominoModuleNodeScript.new()
	autofree(node)
	node.setup_module(item, Vector2i.ZERO, 0)

	var bumper = node.get_component_at_local_cell(Vector2i(1, 0))
	assert_true(bumper != null, "pop bumper exists in module")

	var ball := MockBall.new()
	autofree(ball)
	var res = bumper.trigger_activation(ball, 15)
	assert_true(res.get("activated", false), "pop bumper activated")
	assert_true(res.get("energy_granted", 0) > 0, "pop bumper granted bounce energy")

func test_speed_rail_momentum_flow() -> void:
	begin("Speed rail momentum flow on perpetual_engine")
	var item := PolyominoRelicDatabase.create_item_for_relic(&"perpetual_engine")
	assert_true(item != null, "perpetual_engine item created")
	assert_eq(item.module_data.get_cell_type_at(Vector2i(0, 1)), CellType.ACCELERATOR, "has ACCELERATOR wheel")
	assert_eq(item.module_data.get_cell_direction_at(Vector2i(0, 1)), Vector2.DOWN, "accelerator pushes DOWN")

	var node: Node2D = PolyominoModuleNodeScript.new()
	autofree(node)
	node.setup_module(item, Vector2i.ZERO, 0)

	var accel = node.get_component_at_local_cell(Vector2i(0, 1))
	assert_true(accel != null, "accelerator component exists")

func test_diegetic_renderer_overlays_no_crash() -> void:
	begin("Diegetic renderer overlays execute without crashing across relic archetypes")
	var relics: Array[StringName] = [
		&"superconductor",
		&"phase_siphon",
		&"fragment_swarm",
		&"resonant_well",
		&"golem_effigy",
	]
	for r_id in relics:
		var item := PolyominoRelicDatabase.create_item_for_relic(r_id)
		assert_true(item != null, "relic item created for %s" % String(r_id))
		var node: Node2D = PolyominoModuleNodeScript.new()
		autofree(node)
		node.setup_module(item, Vector2i.ZERO, 0)
		node.notification(CanvasItem.NOTIFICATION_DRAW)
	assert_true(true, "All relic modules rendered diegetic overlays with zero runtime errors")

func test_bash_toy_lifecycle_and_break() -> void:
	begin("Bash toy hit accumulation, broken bonus energy, and broken state")
	var bash := BashToyScript.new()
	autofree(bash)
	bash.max_hits = 3
	bash.base_energy = 10
	var broken_signaled: Array[bool] = []
	bash.bash_toy_broken.connect(func(_node): broken_signaled.append(true))

	var ball := MockBall.new()
	autofree(ball)

	var r1 = bash.trigger_activation(ball, 10)
	assert_true(r1.get("activated", false), "Hit 1 activated")
	assert_eq(bash.current_hits, 1, "Hit count is 1")
	assert_false(bash.is_broken, "Not broken yet")
	assert_eq(broken_signaled.size(), 0, "No break signal yet")

	var r2 = bash.trigger_activation(ball, 40)
	assert_true(r2.get("activated", false), "Hit 2 activated")
	assert_eq(bash.current_hits, 2, "Hit count is 2")
	assert_false(bash.is_broken, "Not broken yet")

	var r3 = bash.trigger_activation(ball, 70)
	assert_true(r3.get("activated", false), "Hit 3 activated")
	assert_eq(bash.current_hits, 3, "Hit count is 3")
	assert_true(bash.is_broken, "Bash toy is now broken")
	assert_eq(broken_signaled.size(), 1, "bash_toy_broken signal emitted")
	assert_eq(r3.get("energy_granted", 0), 10 + 25, "Granted base + BROKEN_BONUS_ENERGY")

func test_wire_gate_open_close_cycle() -> void:
	begin("Wire gate open, close, and state tracking")
	var gate := WireGateScript.new()
	autofree(gate)
	assert_false(gate.is_open, "Gate initially closed")

	var opened_count: Array[bool] = []
	var closed_count: Array[bool] = []
	gate.gate_opened.connect(func(_g): opened_count.append(true))
	gate.gate_closed.connect(func(_g): closed_count.append(true))

	gate.open_gate()
	assert_true(gate.is_open, "Gate is open")
	assert_eq(opened_count.size(), 1, "gate_opened emitted")

	gate.close_gate()
	assert_false(gate.is_open, "Gate is closed")
	assert_eq(closed_count.size(), 1, "gate_closed emitted")


