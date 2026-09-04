extends "res://tests/test_base.gd"

const BoardScript = preload("res://scenes/board/board.gd")
const JunkBoxPanelScript = preload("res://scenes/ui/junk_box/junk_box_panel.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoModuleNode = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")

const CellType = PolyominoModuleData.CellType
const GoalArchetype = PolyominoModuleData.GoalArchetype
const RewardType = PolyominoModuleData.RewardType

func _init() -> void:
	suite_name = "RelicPinballActivation"

func run() -> void:
	test_all_database_relics_expose_activation_requirements()
	test_pop_bumper_hit_accumulation_and_trigger()
	test_drop_target_hit_accumulation_and_trigger()
	test_standup_target_hit_accumulation()
	test_spinner_hit_accumulation()
	test_rollover_switch_hit_accumulation()
	test_junk_box_tooltip_exposes_activation_and_effect()
	test_on_board_tooltip_exposes_live_charge_progress()

func _ensure_clean_state() -> void:
	GameState.start_run(12345)
	GameState.applied_wall_break_upgrades.clear()
	GameState.applied_boss_upgrades.clear()

func test_all_database_relics_expose_activation_requirements() -> void:
	begin("All database relics expose clear activation requirements")
	_ensure_clean_state()

	var all_ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	assert_true(all_ids.size() >= 50, "database contains all campaign relics")

	for rid in all_ids:
		var req_str: String = PolyominoRelicDatabase.get_relic_activation_requirement(rid)
		assert_false(req_str.is_empty(), "%s has non-empty activation requirement" % rid)

		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(rid)
		assert_true(mod != null, "module creates cleanly for %s" % rid)
		assert_false(mod.get_activation_requirement().is_empty(), "%s mod has activation requirement" % rid)

		var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(rid)
		assert_true(item != null, "item creates cleanly for %s" % rid)
		assert_true(item.custom_payload.has("activation_requirement"), "%s payload has activation_requirement" % rid)
		assert_false(str(item.custom_payload.get("activation_requirement", "")).is_empty(), "%s payload activation_req is not empty" % rid)

func test_pop_bumper_hit_accumulation_and_trigger() -> void:
	begin("Pop Bumper hits increment counter and trigger active effect at threshold")
	_ensure_clean_state()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"storm_of_fragments")
	var node: PolyominoModuleNode = PolyominoModuleNode.new()
	node.setup_module(item, Vector2i.ZERO, 0)

	assert_eq(node.get_activation_threshold(), 3, "storm_of_fragments threshold is 3")
	assert_eq(node.get_current_hit_count(), 0, "initial hit count is 0")
	assert_eq(node.get_charge_progress(), 0.0, "initial charge progress is 0.0")

	var goal_triggers: Array = []
	node.goal_completed.connect(func(mod, g_type, r_type, ball, r_data) -> void:
		goal_triggers.append({"g_type": g_type, "r_type": r_type})
	)

	var pop_bumper: PolyominoMachineryComponent = null
	for comp in node.get_all_components():
		if comp.cell_type == CellType.POP_BUMPER:
			pop_bumper = comp
			break
	assert_true(pop_bumper != null, "storm_of_fragments contains pop bumper")

	var dummy_ball: Node2D = Node2D.new()

	pop_bumper.trigger_activation(dummy_ball, 1)
	assert_eq(node.get_widget_hit_count(CellType.POP_BUMPER), 1, "pop bumper hits == 1")
	assert_eq(node.get_current_hit_count(), 1, "current hit count == 1")
	assert_eq(node.get_progress_string(), "1 / 3", "progress string is 1 / 3")
	assert_eq(goal_triggers.size(), 0, "not triggered at 1 hit")

	pop_bumper.trigger_activation(dummy_ball, 10)
	assert_eq(node.get_widget_hit_count(CellType.POP_BUMPER), 2, "pop bumper hits == 2")
	assert_eq(node.get_current_hit_count(), 2, "current hit count == 2")
	assert_eq(node.get_progress_string(), "2 / 3", "progress string is 2 / 3")
	assert_eq(goal_triggers.size(), 0, "not triggered at 2 hits")

	pop_bumper.trigger_activation(dummy_ball, 20)
	assert_eq(goal_triggers.size(), 1, "goal completed on meeting threshold")
	assert_eq(goal_triggers[0]["r_type"], RewardType.MULTIBALL_CASCADE, "reward is MULTIBALL_CASCADE")

	dummy_ball.free()
	node.free()

func test_drop_target_hit_accumulation_and_trigger() -> void:
	begin("Drop Target hits accumulate and trigger active ability")
	_ensure_clean_state()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"energy_collapse")
	var node: PolyominoModuleNode = PolyominoModuleNode.new()
	node.setup_module(item, Vector2i.ZERO, 0)

	assert_eq(node.get_activation_threshold(), 2, "energy_collapse threshold is 2")

	var drop_targets: Array[PolyominoMachineryComponent] = []
	for comp in node.get_all_components():
		if comp.cell_type == CellType.DROP_TARGET:
			drop_targets.append(comp)
	assert_true(drop_targets.size() >= 2, "energy_collapse contains at least 2 drop targets")

	var triggers: Array = []
	node.goal_completed.connect(func(mod, g_type, r_type, ball, r_data) -> void:
		triggers.append(r_type)
	)

	var dummy_ball: Node2D = Node2D.new()
	drop_targets[0].trigger_activation(dummy_ball, 1)
	assert_eq(node.get_widget_hit_count(CellType.DROP_TARGET), 1, "drop target hits == 1")
	assert_eq(triggers.size(), 0, "not triggered at 1 hit")

	drop_targets[1].trigger_activation(dummy_ball, 10)
	assert_eq(triggers.size(), 1, "triggered at 2 hits threshold")
	assert_eq(triggers[0], RewardType.GLOBAL_BOARD_KNOCK, "reward is GLOBAL_BOARD_KNOCK")

	dummy_ball.free()
	node.free()

func test_standup_target_hit_accumulation() -> void:
	begin("Standup Target hit counter tracks accurately")
	_ensure_clean_state()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"supernova_peg")
	var node: PolyominoModuleNode = PolyominoModuleNode.new()
	node.setup_module(item, Vector2i.ZERO, 0)

	var standup: PolyominoMachineryComponent = null
	for comp in node.get_all_components():
		if comp.cell_type == CellType.STANDUP_TARGET:
			standup = comp
			break
	assert_true(standup != null, "supernova_peg has standup target")

	var dummy_ball: Node2D = Node2D.new()
	standup.trigger_activation(dummy_ball, 1)
	assert_eq(node.get_widget_hit_count(CellType.STANDUP_TARGET), 1, "standup hit count == 1")
	assert_eq(node.get_progress_string(), "1 / 2", "progress string is 1 / 2")

	dummy_ball.free()
	node.free()

func test_spinner_hit_accumulation() -> void:
	begin("Spinner hit counter increments on ball collision")
	_ensure_clean_state()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"hyper_elastic")
	var node: PolyominoModuleNode = PolyominoModuleNode.new()
	node.setup_module(item, Vector2i.ZERO, 0)

	var spinner: PolyominoMachineryComponent = null
	for comp in node.get_all_components():
		if comp.cell_type == CellType.SPINNER:
			spinner = comp
			break
	assert_true(spinner != null, "hyper_elastic contains spinner")

	var dummy_ball: Node2D = Node2D.new()
	spinner.trigger_activation(dummy_ball, 1)
	assert_eq(node.get_widget_hit_count(CellType.SPINNER), 1, "spinner hit count == 1")

	dummy_ball.free()
	node.free()

func test_rollover_switch_hit_accumulation() -> void:
	begin("Rollover Switch hit triggers active ability when meeting threshold")
	_ensure_clean_state()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"overcurrent_surge")
	var node: PolyominoModuleNode = PolyominoModuleNode.new()
	node.setup_module(item, Vector2i.ZERO, 0)

	var sw: PolyominoMachineryComponent = null
	for comp in node.get_all_components():
		if comp.cell_type == CellType.ROLLOVER_SWITCH:
			sw = comp
			break
	assert_true(sw != null, "overcurrent_surge has rollover switch")

	var triggers: Array = []
	node.goal_completed.connect(func(mod, g_type, r_type, ball, r_data) -> void:
		triggers.append(r_type)
	)

	assert_eq(node.get_activation_threshold(), 1, "threshold is 1")
	assert_eq(node.get_current_hit_count(), 0, "initial count is 0")

	var dummy_ball: Node2D = Node2D.new()
	sw.trigger_activation(dummy_ball, 1)
	assert_eq(triggers.size(), 1, "rollover switch meeting threshold 1 triggers goal")
	assert_eq(triggers[0], RewardType.ENERGY_SURGE, "reward is ENERGY_SURGE")

	dummy_ball.free()
	node.free()

func test_junk_box_tooltip_exposes_activation_and_effect() -> void:
	begin("JunkBoxPanel._format_item_tooltip exposes activation requirement and relic effect")
	var panel_inst = JunkBoxPanelScript.new()
	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"storm_of_fragments")

	var tip: String = panel_inst._format_item_tooltip(item)
	assert_true(tip.contains("[u]Activation Requirement[/u]"), "Junk Box contains Activation Requirement section")
	assert_true(tip.contains("Hit all 3 pop bumpers"), "Junk Box contains activation requirement text")
	assert_true(tip.contains("[u]Relic Effect[/u]"), "Junk Box contains Relic Effect section")
	assert_true(tip.contains("Multiball Cascade"), "Junk Box contains relic effect text")
	assert_false(tip.contains("Tier:"), "Junk Box omits Tier")
	assert_false(tip.contains("Size:"), "Junk Box omits Size")
	assert_false(tip.contains("Shape:"), "Junk Box omits Shape")

	panel_inst.free()

func test_on_board_tooltip_exposes_live_charge_progress() -> void:
	begin("Board._format_module_tooltip_body exposes live charge progress when slotted")
	var board_inst = BoardScript.new()
	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"storm_of_fragments")
	item.grid_position = Vector2i(2, 2)

	board_inst.place_module(item, Vector2i(2, 2), 0)

	var tip_before: String = board_inst._format_module_tooltip_body(item)
	assert_true(tip_before.contains("[u]Activation Requirement[/u]"), "Contains Activation Requirement")
	assert_true(tip_before.contains("[u]Charge Progress[/u]: 0 / 3"), "Shows 0 / 3 initial charge")

	var mod_node: PolyominoModuleNode = board_inst._placed_module_nodes.get(item.instance_id)
	assert_true(mod_node != null, "module node exists on board")

	var pop_bumper: PolyominoMachineryComponent = null
	for comp in mod_node.get_all_components():
		if comp.cell_type == CellType.POP_BUMPER:
			pop_bumper = comp
			break
	assert_true(pop_bumper != null, "has pop bumper")

	var dummy_ball: Node2D = Node2D.new()
	pop_bumper.trigger_activation(dummy_ball, 1)

	var tip_after: String = board_inst._format_module_tooltip_body(item)
	assert_true(tip_after.contains("[u]Charge Progress[/u]: 1 / 3"), "Shows 1 / 3 charge progress after hit")

	dummy_ball.free()
	board_inst.free()
