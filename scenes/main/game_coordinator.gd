extends Node
## GameCoordinator. Wiring only; no peg buffering (Board does that).
## Runs per-sim-tick order; fixed-step accumulator for slow-mo.

const START_BALLS: int = 10
const HOPPER_MAX_BALLS: int = 100

var _sim_tick: int = 0
var _sim_accumulator: float = 0.0
## Pending ball definitions to spawn into the hopper when there is room (gate closed).
var _bag_queue: Array = []
var _hopper: Node
var _conduit: Node
var _board: Node
var _energy_manager: Node
var _combat_manager: Node
var _rewards_manager: Node
var _systems_container: Node
var _milestone_tracker: Node
var _reward_handler: Node
var _energy_router: Node
var _center_panel_ui: Control
var _battlefield: Node
var _debug_overlay: Control
var _inventory_panel: Control
var _almanac_panel: Control
var _inventory_btn: Button
var _almanac_btn: Button
var _debug_event_spawn_modal: Control
var _debug_full_store_modal: Control
var _debug_city_jump_modal: Control
var _pending_energy_vfx_positions: Array[Vector2] = []
var _pending_energy_alignments: Array[int] = []
var _game_over: bool = false
var _victory: bool = false
var _fail_screen: Control = null
var _wall_break_is_last_wall: bool = false
var _junk_box_panel: Control
var _debug_manager: Node = null
var _input_manager: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_acquire_children()
	_wire_signals()
	call_deferred("_create_inventory_ui")
	if _debug_overlay:
		_debug_overlay.visible = false
	GameState.start_run()
	_apply_test_scenario()
	_init_from_current_city()
	call_deferred("_spawn_initial_balls")
	call_deferred("_defer_arm_board_event_test")

func _init_from_current_city() -> void:
	var city: CityDefinition = GameState.get_current_city_definition()
	if city == null:
		return
	if _combat_manager and _combat_manager.has_method("init_from_city"):
		_combat_manager.init_from_city(city)
	if TestScenario and TestScenario.enabled and TestScenario.starting_wall_index > 0:
		for _i in TestScenario.starting_wall_index:
			if _combat_manager and _combat_manager.has_method("advance_to_next_wall"):
				_combat_manager.advance_to_next_wall()
	if _milestone_tracker and _milestone_tracker.has_method("set_thresholds_from_city"):
		_milestone_tracker.set_thresholds_from_city(city.get_milestone_thresholds_int())
	_refresh_conquest_ui()
	_sync_battlefield_wall_index()

func _refresh_conquest_ui() -> void:
	if not _center_panel_ui:
		return
	if _combat_manager:
		if _center_panel_ui.has_method("set_gate_name") and _combat_manager.has_method("get_current_gate_name"):
			_center_panel_ui.set_gate_name(_combat_manager.get_current_gate_name())
		if _center_panel_ui.has_method("set_conquest_walls") and _combat_manager.has_method("get_wall_names") and _combat_manager.has_method("get_current_wall_index"):
			var goal_name: String = _combat_manager.get_city_display_name() if _combat_manager.has_method("get_city_display_name") else ""
			_center_panel_ui.set_conquest_walls(_combat_manager.get_wall_names(), _combat_manager.get_current_wall_index(), goal_name)

func _sync_battlefield_wall_index() -> void:
	if not _combat_manager or not _combat_manager.has_method("get_current_wall_index"):
		return
	var battlefield: Node = get_parent().get_node_or_null("CombatContainer/BattlefieldView") if get_parent() else null
	if battlefield and battlefield.has_method("set_wall_index"):
		battlefield.set_wall_index(_combat_manager.get_current_wall_index())

func _apply_test_scenario() -> void:
	var ts_script: Script = load("res://scenes/main/game_coordinator_test_scenario.gd") as Script
	if ts_script and ts_script.has_method("apply_test_scenario"):
		ts_script.call("apply_test_scenario")

func _defer_arm_board_event_test() -> void:
	if not _board:
		return
	for name_str in ["BoardEventController", "TreasureChestController", "BuffetTableController", "StickySlimeController", "BlackHoleController"]:
		var ctrl: Node = _board.get_node_or_null(name_str)
		if ctrl and ctrl.has_method("arm_immediate_spawn_if_test"):
			ctrl.arm_immediate_spawn_if_test()

func _spawn_initial_balls() -> void:
	GameBallManager.spawn_initial_balls(self)

func _spawn_test_scenario_balls() -> void:
	GameBallManager.spawn_test_scenario_balls(self)

func reset_starting_ball_pool() -> void:
	GameBallManager.reset_starting_ball_pool(self)

func _plain_ball_def(alignment: int) -> BallDefinition:
	var d: BallDefinition = GameBallManager.plain_ball_def(alignment)
	d.base_energy = Constants.legacy_display_energy_to_current(20)
	d.city_weights = {0: 100}
	d.rarity = Constants.RARITY_COMMON
	d.tier = 1
	d.shape_type = -1
	d.status_effects = {}
	return d

func _is_plain_ball_def(def: Resource) -> bool:
	return GameBallManager.is_plain_ball_def(def)

## Add plain balls (hopper first, rest queued for the bag). Used for milestone board event +5 and legacy BASIC_BATCH apply.
func add_basic_balls(count: int) -> void:
	GameBallManager.add_basic_balls(_hopper, _bag_queue, count, HOPPER_MAX_BALLS)

func count_plain_balls_in_play() -> int:
	return GameBallManager.count_plain_balls_in_play(get_parent(), _hopper, _bag_queue)

## Convert one plain ball to the given ability (hopper, then board, then bag queue).
func apply_ball_upgrade_conversion(def: BallDefinition) -> bool:
	return GameBallManager.apply_ball_upgrade_conversion(get_parent(), _hopper, _bag_queue, def)

func _exit_tree() -> void:
	_disconnect_signals()

func _acquire_children() -> void:
	var main: Node = get_parent()
	_hopper = main.get_node_or_null("Hopper")
	_conduit = main.get_node_or_null("Conduit")
	_board = main.get_node_or_null("Board")
	_energy_manager = main.get_node_or_null("EnergyManager")
	_combat_manager = main.get_node_or_null("CombatManager")
	_rewards_manager = main.get_node_or_null("RewardsManager")
	_systems_container = main.get_node_or_null("SystemsContainer")
	_milestone_tracker = main.get_node_or_null("MilestoneTracker")
	_reward_handler = main.get_node_or_null("RewardHandler")
	_energy_router = main.get_node_or_null("EnergyRouter")
	var ui_layer: Node = main.get_node_or_null("UILayer")
	if ui_layer:
		_center_panel_ui = ui_layer.get_node_or_null("CenterPanel") as Control
	_battlefield = main.get_node_or_null("CombatContainer/BattlefieldView")
	_debug_overlay = main.get_node_or_null("UI/DebugOverlay") as Control
	var debug_script: Script = load("res://scenes/main/game_coordinator_debug.gd") as Script
	if debug_script:
		_debug_manager = debug_script.new()
		add_child(_debug_manager)
		if _debug_manager.has_method("setup"):
			_debug_manager.setup(self)
	var input_script: Script = load("res://scenes/main/game_coordinator_input.gd") as Script
	if input_script:
		_input_manager = input_script.new()
		add_child(_input_manager)
		if _input_manager.has_method("setup"):
			_input_manager.setup(self)

func _wire_signals() -> void:
	GameCoordinatorSignals.wire_signals(self)

func _unhandled_input(event: InputEvent) -> void:
	if not _input_manager:
		var input_script: Script = load("res://scenes/main/game_coordinator_input.gd") as Script
		if input_script:
			_input_manager = input_script.new()
			add_child(_input_manager)
			if _input_manager.has_method("setup"):
				_input_manager.setup(self)
	if _input_manager and _input_manager.has_method("handle_unhandled_input"):
		_input_manager.handle_unhandled_input(event)

func _toggle_debug_overlay() -> void:
	if _debug_overlay:
		_debug_overlay.visible = not _debug_overlay.visible

func _handle_escape_key() -> void:
	if _game_over or _victory:
		return
	if _almanac_panel and _almanac_panel.visible:
		return
	if _inventory_panel and _inventory_panel.visible:
		return
	if _junk_box_panel and _junk_box_panel.visible:
		return
	if _debug_event_spawn_modal and _debug_event_spawn_modal.visible:
		return
	_toggle_junk_box()

func _toggle_pause_state() -> void:
	if not _game_over and not _victory and get_tree():
		get_tree().paused = not get_tree().paused

func _toggle_junk_box() -> void:
	if _junk_box_panel:
		if _junk_box_panel.has_method("toggle"):
			_junk_box_panel.toggle()
		else:
			_junk_box_panel.visible = not _junk_box_panel.visible
	elif _inventory_panel:
		if _inventory_panel.has_method("toggle"):
			_inventory_panel.toggle()
		else:
			_inventory_panel.visible = not _inventory_panel.visible

func _disconnect_signals() -> void:
	GameCoordinatorSignals.disconnect_signals(self)

func _physics_process(delta: float) -> void:
	GameCoordinatorSimulation.physics_process(self, delta)

func _on_ball_entered_board(ball: Node) -> void:
	if _board and _board.has_method("spawn_ball_at_start"):
		_board.spawn_ball_at_start(ball)

func _on_ball_reached_bottom(ball_id: int, total_energy_display: int, alignment: int, exit_position: Vector2 = Vector2.ZERO, _status_effects: Dictionary = {}) -> void:
	_pending_energy_vfx_positions.append(exit_position)
	_pending_energy_alignments.append(alignment)
	if _energy_manager and _energy_manager.has_method("on_ball_reached_bottom"):
		_energy_manager.on_ball_reached_bottom(ball_id, total_energy_display, alignment)

func _on_leech_drain(amount_display: int, alignment: int, peg_id: int) -> void:
	if _energy_manager and _energy_manager.has_method("add_display_energy"):
		_energy_manager.add_display_energy(amount_display, alignment)
	var peg_pos: Vector2 = Vector2(480, 400)
	if _board and _board.has_method("get_peg_by_id"):
		var peg: Node = _board.get_peg_by_id(peg_id)
		if peg and peg.get("global_position") != null:
			peg_pos = peg.global_position
	var internal: int = amount_display * Constants.ENERGY_SCALE
	if _center_panel_ui and _center_panel_ui.has_method("show_energy_gain"):
		_center_panel_ui.show_energy_gain(internal, 0, 0, peg_pos, 0)

func _on_gold_gained(amount: int, origin_position: Vector2) -> void:
	if _center_panel_ui and _center_panel_ui.has_method("show_gold_gain"):
		_center_panel_ui.show_gold_gain(amount, origin_position)
	elif GameState:
		GameState.add_run_gold(amount)

func _on_ball_ability_on_peg_hit(_status_effects: Dictionary) -> void:
	pass

func _on_ball_exited_board(ball: Node, reason: int) -> void:
	GameBallManager.on_ball_exited_board(self, ball, reason)

func _on_ball_exited_black_hole(ball: Node) -> void:
	GameBallManager.on_ball_exited_black_hole(self, ball)

func _finish_black_hole_delayed_return(def: BallDefinition) -> void:
	if not def:
		return
	var in_hopper: int = _hopper.get_stored_ball_count() if _hopper and _hopper.has_method("get_stored_ball_count") else 0
	var room: int = HOPPER_MAX_BALLS - in_hopper
	var gate_open: bool = _hopper.is_gate_open() if _hopper and _hopper.has_method("is_gate_open") else false
	if not gate_open and room > 0 and _hopper and _hopper.has_method("add_balls_with_definition"):
		_hopper.add_balls_with_definition(1, def)
	else:
		_bag_queue.append(def)

func add_balls_to_reserve(count: int) -> void:
	GameBallManager.add_balls_to_reserve(self, count)

func _on_energy_allocated_vfx(main_internal: int, _sidearm_internal: int, _shield_internal: int) -> void:
	var pos: Vector2 = _pending_energy_vfx_positions.pop_front() if _pending_energy_vfx_positions.size() > 0 else Vector2(480, 600)
	var _alignment: int = _pending_energy_alignments.pop_front() if _pending_energy_alignments.size() > 0 else 0
	if _center_panel_ui and _center_panel_ui.has_method("show_energy_gain"):
		_center_panel_ui.show_energy_gain(main_internal, 0, 0, pos, 0)

func _on_milestone_reached(milestone_index: int, total_energy_display: int) -> void:
	if _rewards_manager and _rewards_manager.has_method("on_milestone_reached"):
		_rewards_manager.on_milestone_reached(milestone_index, total_energy_display)

## Board milestone event peg destroyed; grants +5 plain balls then queues the milestone shop (same as legacy milestones).
func notify_milestone_reward_from_board() -> void:
	add_basic_balls(RewardGeneration.BASIC_BATCH_SIZE)
	if _milestone_tracker and _milestone_tracker.has_method("register_milestone_reward"):
		_milestone_tracker.register_milestone_reward()

## Treasure chest peg destroyed; queues onboard passive upgrade draft (same modal as conquest, different pool).
func notify_onboard_effect_from_board() -> void:
	if GameState and GameState.has_wall_break_upgrade(&"chest_random_ball") and _reward_handler and _reward_handler.has_method("grant_random_ball_from_city_pool"):
		_reward_handler.grant_random_ball_from_city_pool()
	if _rewards_manager and _rewards_manager.has_method("on_onboard_effect"):
		_rewards_manager.on_onboard_effect()

func _on_wall_destroyed() -> void:
	var flow_script: Script = load("res://scenes/main/game_coordinator_flow.gd") as Script
	if flow_script and flow_script.has_method("handle_wall_destroyed"):
		flow_script.call("handle_wall_destroyed", self)

func _on_wall_break_transition_finished() -> void:
	var flow_script: Script = load("res://scenes/main/game_coordinator_flow.gd") as Script
	if flow_script and flow_script.has_method("handle_wall_break_transition_finished"):
		flow_script.call("handle_wall_break_transition_finished", self)

func _on_wall_break_reward_completed() -> void:
	var flow_script: Script = load("res://scenes/main/game_coordinator_flow.gd") as Script
	if flow_script and flow_script.has_method("handle_wall_break_reward_completed"):
		flow_script.call("handle_wall_break_reward_completed", self)

func _on_boss_reward_completed() -> void:
	var flow_script: Script = load("res://scenes/main/game_coordinator_flow.gd") as Script
	if flow_script and flow_script.has_method("handle_boss_reward_completed"):
		flow_script.call("handle_boss_reward_completed", self)

func _begin_next_wall_intro() -> void:
	if _battlefield and _battlefield.has_method("play_next_wall_intro"):
		_battlefield.play_next_wall_intro()
	get_tree().create_timer(1.5).timeout.connect(_on_next_wall_intro_finished)

func _on_next_wall_intro_finished() -> void:
	GameState.set_run_flow_state(GameState.RunFlowState.FIGHTING)

func _show_wall_title_card(title_text: String, subtitle_text: String, on_finished: Callable) -> void:
	GameCoordinatorScreenBuilder.show_wall_title_card(get_parent(), title_text, subtitle_text, on_finished)

func _on_time_expired() -> void:
	_game_over = true
	_show_fail_screen()

func _show_fail_screen() -> void:
	var flow_script: Script = load("res://scenes/main/game_coordinator_flow.gd") as Script
	if flow_script and flow_script.has_method("show_fail_screen"):
		flow_script.call("show_fail_screen", self)

func _show_victory_screen() -> void:
	var flow_script: Script = load("res://scenes/main/game_coordinator_flow.gd") as Script
	if flow_script and flow_script.has_method("show_victory_screen"):
		flow_script.call("show_victory_screen", self)

func _build_victory_screen() -> Control:
	return GameCoordinatorScreenBuilder.build_victory_screen(_on_restart_pressed, _on_endless_mode_pressed)

func _on_endless_mode_pressed() -> void:
	var flow_script: Script = load("res://scenes/main/game_coordinator_flow.gd") as Script
	if flow_script and flow_script.has_method("handle_endless_mode_pressed"):
		flow_script.call("handle_endless_mode_pressed", self)

func _build_end_screen(title_text: String, title_color: Color, button_text: String) -> Control:
	return GameCoordinatorScreenBuilder.build_end_screen(title_text, title_color, button_text, _on_restart_pressed)

func _on_restart_pressed() -> void:
	GameState.paused = false
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()

func _create_inventory_ui() -> void:
	var main: Node = get_parent()
	var res: Dictionary = GameCoordinatorUI.create_inventory_ui(self, _reward_handler, _board)
	_inventory_panel = res.get("inventory_panel", null)
	_junk_box_panel = res.get("junk_box_panel", null)
	_almanac_panel = res.get("almanac_panel", null)
	if _debug_manager and _debug_manager.has_method("create_all_debug_modals") and main:
		var modals: Dictionary = _debug_manager.create_all_debug_modals(main, _reward_handler)
		_debug_event_spawn_modal = modals.get("event_spawn_modal", null)
		_debug_full_store_modal = modals.get("full_store_modal", null)
		_debug_city_jump_modal = modals.get("city_jump_modal", null)
	if main:
		var ui_layer: Node = main.get_node_or_null("UILayer")
		if ui_layer:
			var left_panel: Control = ui_layer.get_node_or_null("LeftPanel") as Control
			if left_panel:
				_almanac_btn = _build_almanac_button()
				left_panel.add_child(_almanac_btn)
				_inventory_btn = _build_bag_button()
				left_panel.add_child(_inventory_btn)
				if GameState.junk_box and not GameState.junk_box.inventory_changed.is_connected(_update_bag_button_badge):
					GameState.junk_box.inventory_changed.connect(_update_bag_button_badge)
				_update_bag_button_badge()
				if _debug_manager and _debug_manager.has_method("build_debug_tools_column"):
					left_panel.add_child(_debug_manager.build_debug_tools_column())

func _on_debug_add_gold_pressed() -> void:
	if not _game_over and not _victory and GameState:
		GameState.add_run_gold(100)
		if _center_panel_ui and _center_panel_ui.has_method("set_run_gold"):
			_center_panel_ui.set_run_gold(GameState.run_gold)

func _on_debug_milestone_shop_pressed() -> void:
	debug_trigger_milestone_shop()

func _on_debug_spawn_event_menu_pressed() -> void:
	if not _game_over and not _victory and _debug_event_spawn_modal and _debug_event_spawn_modal.has_method("show_modal"):
		_debug_event_spawn_modal.show_modal()

func debug_spawn_board_milestone_event() -> void:
	if not _game_over and not _victory and _debug_manager and _debug_manager.has_method("debug_spawn_board_milestone_event"): _debug_manager.debug_spawn_board_milestone_event(_board)

func debug_spawn_treasure_chest_event() -> void:
	if not _game_over and not _victory and _debug_manager and _debug_manager.has_method("debug_spawn_treasure_chest_event"): _debug_manager.debug_spawn_treasure_chest_event(_board)

func debug_spawn_sticky_slime_event() -> void:
	if not _game_over and not _victory and _debug_manager and _debug_manager.has_method("debug_spawn_sticky_slime_event"): _debug_manager.debug_spawn_sticky_slime_event(_board)

func debug_spawn_black_hole_event() -> void:
	if not _game_over and not _victory and _debug_manager and _debug_manager.has_method("debug_spawn_black_hole_event"): _debug_manager.debug_spawn_black_hole_event(_board)

func debug_trigger_milestone_shop() -> void:
	GameCoordinatorDebug.debug_trigger_milestone_shop(self)

func debug_trigger_wall_break_reward() -> void:
	GameCoordinatorDebug.debug_trigger_wall_break_reward(self)

func debug_trigger_boss_reward() -> void:
	GameCoordinatorDebug.debug_trigger_boss_reward(self)

func _on_debug_full_store_pressed() -> void:
	if not _game_over and not _victory and _debug_full_store_modal and _debug_full_store_modal.has_method("show_modal"):
		_debug_full_store_modal.show_modal()

func _on_debug_city_jump_pressed() -> void:
	if _debug_city_jump_modal and _debug_city_jump_modal.has_method("show_modal"):
		_debug_city_jump_modal.show_modal()

func debug_jump_to_city_and_wall(city_index: int, wall_index: int) -> void:
	var debug_script: Script = load("res://scenes/main/game_coordinator_debug.gd") as Script
	if debug_script and debug_script.has_method("jump_to_city_and_wall"):
		debug_script.call("jump_to_city_and_wall", self, city_index, wall_index)

func _build_almanac_button() -> Button:
	return GameCoordinatorUI.build_almanac_button(_on_almanac_pressed)

func _build_bag_button() -> Button:
	return GameCoordinatorUI.build_bag_button(_on_inventory_pressed)

func _update_bag_button_badge() -> void:
	GameCoordinatorUI.update_bag_button_badge(_inventory_btn, get_parent())

func _on_inventory_pressed() -> void:
	if not _game_over and not _victory:
		_toggle_junk_box()

func _on_almanac_pressed() -> void:
	if not _game_over and not _victory and _almanac_panel and _almanac_panel.has_method("toggle"):
		_almanac_panel.toggle()

func get_ball_catalog_key_for_definition(def: BallDefinition) -> String:
	return GameBallManager.catalog_key_from_def(def)

## Sum of balls across all tiers for one ability (almanac).
func get_ball_total_count_for_ability(ability_ledger_key: String) -> int:
	var counts: Dictionary = get_ball_definition_counts()
	var n: int = 0
	for k in counts.keys():
		if String(k).get_slice("|", 0) == ability_ledger_key:
			n += int(counts[k])
	return n

func get_ball_definition_counts() -> Dictionary:
	return GameBallManager.get_ball_definition_counts(get_parent(), _hopper, _bag_queue)

func get_debug_shop_ball_definitions() -> Array:
	var out: Array = []
	out.append(_plain_ball_def(Constants.ALIGNMENT_MAIN).duplicate(true))
	if _reward_handler and _reward_handler.has_method("get_catalog_ball_definitions"):
		out.append_array(_reward_handler.get_catalog_ball_definitions())
	return out

## Remove one ball matching this definition (bag queue, then hopper, then board). Updates run ability list when last of that ability is gone.
func remove_one_ball_matching_definition(template: BallDefinition) -> bool:
	var ok: bool = GameBallManager.remove_one_ball_matching_definition(get_parent(), _hopper, _bag_queue, template)
	if ok:
		_update_center_ui()
	return ok

func remove_one_ball_for_ability(ability_ledger_key: String) -> bool:
	var ok: bool = GameBallManager.remove_one_ball_for_ability(get_parent(), _hopper, _bag_queue, ability_ledger_key)
	if ok:
		_update_center_ui()
	return ok

func _prune_ball_ability_record_after_remove(catalog_key: String) -> void:
	GameBallManager.prune_ball_ability_record_after_remove(get_parent(), _hopper, _bag_queue, catalog_key)

func remove_one_peg_unlock_for_almanac(kind: String) -> bool:
	return _reward_handler.remove_one_peg_unlock_for_almanac(kind, _board) if _reward_handler and _reward_handler.has_method("remove_one_peg_unlock_for_almanac") else false

func remove_one_wall_break_for_almanac(uid: StringName) -> bool:
	return _reward_handler.remove_one_almanac_wall_break(uid) if _reward_handler and _reward_handler.has_method("remove_one_almanac_wall_break") else false

func remove_one_boss_for_almanac(uid: StringName) -> bool:
	return _reward_handler.remove_one_almanac_boss(uid) if _reward_handler and _reward_handler.has_method("remove_one_almanac_boss") else false

func get_bag_count() -> int:
	return _bag_queue.size()

func get_ball_inventory() -> Dictionary:
	return GameBallManager.get_ball_inventory(get_parent())

func _update_center_ui() -> void:
	GameCoordinatorUI.update_center_ui(_center_panel_ui, _combat_manager, _systems_container, _bag_queue.size())
