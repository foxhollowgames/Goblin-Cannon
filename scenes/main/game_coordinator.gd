extends Node
## GameCoordinator. Wiring only; no peg buffering (Board does that).
## Runs per-sim-tick order; fixed-step accumulator for slow-mo.

const START_BALLS: int = 10
const HOPPER_MAX_BALLS: int = 100

var _sim_tick: int = 0
var _sim_accumulator: float = 0.0
var _bag_count: int = 0
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
var _pending_energy_vfx_positions: Array[Vector2] = []
var _pending_energy_alignments: Array[int] = []
var _game_over: bool = false
var _victory: bool = false
var _fail_screen: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_acquire_children()
	_wire_signals()
	if _debug_overlay:
		_debug_overlay.visible = false
	GameState.start_run()
	_apply_test_scenario()
	_init_from_current_city()
	call_deferred("_spawn_initial_balls")

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
	if not TestScenario or not TestScenario.enabled:
		return
	if TestScenario.starting_city_id >= 0:
		GameState.current_city_id = TestScenario.starting_city_id
	for stat_key in TestScenario.starting_stats:
		var value = TestScenario.starting_stats[stat_key]
		match stat_key:
			"cannon_damage":
				GameState.cannon_base_damage_bonus += int(value)
			"cannon_energy":
				GameState.cannon_charge_reduction += int(value)
			"main_charge":
				GameState.main_charge_bonus += float(value)
			"door_interval":
				GameState.conduit_wave_interval_scale = maxf(0.5, GameState.conduit_wave_interval_scale - float(value))
			"door_duration":
				GameState.conduit_open_duration_scale += float(value)
	for entry in TestScenario.starting_upgrades:
		if entry is String:
			GameState.add_wall_break_upgrade(StringName(entry), 1)
		elif entry is Dictionary:
			var uid: String = entry.get("id", "")
			var stacks: int = entry.get("stacks", 1)
			if not uid.is_empty():
				GameState.add_wall_break_upgrade(StringName(uid), stacks)
	if TestScenario.starting_peg_counts.has("bomb"):
		GameState.bomb_peg_count += int(TestScenario.starting_peg_counts["bomb"])
	if TestScenario.starting_peg_counts.has("trampoline"):
		GameState.trampoline_peg_count += int(TestScenario.starting_peg_counts["trampoline"])
	if TestScenario.starting_peg_counts.has("goblin_reset"):
		GameState.goblin_reset_node_count += int(TestScenario.starting_peg_counts["goblin_reset"])
	var summary: String = TestScenario.get_summary()
	if not summary.is_empty():
		print("[TestScenario] ACTIVE — %s" % summary)

func _spawn_initial_balls() -> void:
	if TestScenario and TestScenario.enabled and not TestScenario.starting_balls.is_empty():
		_spawn_test_scenario_balls()
		return
	var main_def: BallDefinition = _plain_ball_def(Constants.ALIGNMENT_MAIN)
	var total: int = START_BALLS
	var in_hopper: int = _hopper.get_stored_ball_count() if _hopper and _hopper.has_method("get_stored_ball_count") else 0
	var room: int = HOPPER_MAX_BALLS - in_hopper
	var to_hopper: int = mini(total, room)
	if to_hopper > 0 and _hopper and _hopper.has_method("add_balls_with_definition"):
		_hopper.add_balls_with_definition(to_hopper, main_def)
	_bag_count += (total - to_hopper)

func _spawn_test_scenario_balls() -> void:
	for entry in TestScenario.starting_balls:
		if not entry is Dictionary:
			continue
		var ability: String = entry.get("ability", "")
		var count: int = entry.get("count", 1)
		var ball_def: BallDefinition = TestScenario.make_ball_definition(ability)
		if not ability.is_empty():
			GameState.record_ball_ability_in_run(ability)
		var in_hopper: int = _hopper.get_stored_ball_count() if _hopper and _hopper.has_method("get_stored_ball_count") else 0
		var room: int = HOPPER_MAX_BALLS - in_hopper
		var to_hopper: int = mini(count, room)
		if to_hopper > 0 and _hopper and _hopper.has_method("add_balls_with_definition"):
			_hopper.add_balls_with_definition(to_hopper, ball_def)
		_bag_count += (count - to_hopper)

func reset_starting_ball_pool() -> void:
	_bag_count = 0
	if _hopper and _hopper.has_method("clear_stored_balls"):
		_hopper.clear_stored_balls()
	_spawn_initial_balls()

func _plain_ball_def(alignment: int) -> BallDefinition:
	var d: BallDefinition = BallDefinition.new()
	d.ability_name = ""
	d.base_energy = 20
	d.city_weights = {0: 100}
	d.alignment = alignment
	d.rarity = Constants.RARITY_UNCOMMON
	d.tier = 1
	d.shape_type = -1
	d.status_effects = {}
	return d

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

func _wire_signals() -> void:
	if _hopper and _hopper.has_signal("ball_entered_board"):
		_hopper.ball_entered_board.connect(_on_ball_entered_board)
	if _board:
		if _board.has_signal("ball_reached_bottom"):
			_board.ball_reached_bottom.connect(_on_ball_reached_bottom)
		if _board.has_signal("ball_ability_on_peg_hit"):
			_board.ball_ability_on_peg_hit.connect(_on_ball_ability_on_peg_hit)
		if _board.has_signal("ball_exited_board"):
			_board.ball_exited_board.connect(_on_ball_exited_board)
		if _board.has_signal("leech_drain"):
			_board.leech_drain.connect(_on_leech_drain)
	if _milestone_tracker and _milestone_tracker.has_signal("milestone_reached"):
		_milestone_tracker.milestone_reached.connect(_on_milestone_reached)
	if _combat_manager:
		if _combat_manager.has_signal("wall_destroyed"):
			_combat_manager.wall_destroyed.connect(_on_wall_destroyed)
		if _combat_manager.has_signal("time_expired"):
			_combat_manager.time_expired.connect(_on_time_expired)
	if _rewards_manager and _rewards_manager.has_signal("wall_break_reward_completed"):
		_rewards_manager.wall_break_reward_completed.connect(_on_wall_break_reward_completed)
	if _energy_router and _energy_router.has_signal("energy_allocated"):
		_energy_router.energy_allocated.connect(_on_energy_allocated_vfx)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_D:
		if _debug_overlay:
			_debug_overlay.visible = !_debug_overlay.visible
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_P:
		if not _game_over and not _victory:
			get_tree().paused = !get_tree().paused
			get_viewport().set_input_as_handled()

func _disconnect_signals() -> void:
	if _hopper and _hopper.has_signal("ball_entered_board"):
		_hopper.ball_entered_board.disconnect(_on_ball_entered_board)
	if _board:
		if _board.has_signal("ball_reached_bottom"):
			_board.ball_reached_bottom.disconnect(_on_ball_reached_bottom)
		if _board.has_signal("ball_ability_on_peg_hit") and _board.ball_ability_on_peg_hit.is_connected(_on_ball_ability_on_peg_hit):
			_board.ball_ability_on_peg_hit.disconnect(_on_ball_ability_on_peg_hit)
		if _board.has_signal("ball_exited_board"):
			_board.ball_exited_board.disconnect(_on_ball_exited_board)
		if _board.has_signal("leech_drain") and _board.leech_drain.is_connected(_on_leech_drain):
			_board.leech_drain.disconnect(_on_leech_drain)
	if _milestone_tracker and _milestone_tracker.has_signal("milestone_reached"):
		_milestone_tracker.milestone_reached.disconnect(_on_milestone_reached)
	if _combat_manager:
		if _combat_manager.has_signal("wall_destroyed"):
			_combat_manager.wall_destroyed.disconnect(_on_wall_destroyed)
		if _combat_manager.has_signal("time_expired") and _combat_manager.time_expired.is_connected(_on_time_expired):
			_combat_manager.time_expired.disconnect(_on_time_expired)
	if _rewards_manager and _rewards_manager.has_signal("wall_break_reward_completed") and _rewards_manager.wall_break_reward_completed.is_connected(_on_wall_break_reward_completed):
		_rewards_manager.wall_break_reward_completed.disconnect(_on_wall_break_reward_completed)
	if _energy_router and _energy_router.has_signal("energy_allocated"):
		_energy_router.energy_allocated.disconnect(_on_energy_allocated_vfx)

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	if GameState.paused:
		return
	if _game_over or _victory:
		return
	_sim_accumulator += delta * GameState.sim_speed * float(Constants.SIM_TICKS_PER_SECOND)
	var max_steps: int = 4
	while _sim_accumulator >= 1.0 and max_steps > 0:
		_run_one_sim_tick()
		_sim_accumulator -= 1.0
		max_steps -= 1
	GameState.sim_step_alpha = clampf(_sim_accumulator, 0.0, 1.0)

func _run_one_sim_tick() -> void:
	_sim_tick += 1
	if _hopper and _hopper.has_method("get_stored_ball_count") and _hopper.get_stored_ball_count() < HOPPER_MAX_BALLS and _bag_count > 0:
		var gate_open: bool = _hopper.is_gate_open() if _hopper.has_method("is_gate_open") else false
		if not gate_open and _hopper.has_method("add_balls"):
			_hopper.add_balls(1)
			_bag_count -= 1
	if _conduit and _conduit.has_method("request_ball"):
		_conduit.request_ball()
	if _board and _board.has_method("run_ball_steps"):
		_board.run_ball_steps(_sim_tick)
	if _board and _board.has_method("flush_tick"):
		_board.flush_tick(_sim_tick)
	if _systems_container:
		for child in _systems_container.get_children():
			if child.has_method("sim_tick"):
				child.sim_tick(_sim_tick)
	if _combat_manager and _combat_manager.has_method("sim_tick"):
		_combat_manager.sim_tick(_sim_tick)
	_update_center_ui()

func _on_ball_entered_board(ball: Node) -> void:
	if _board and _board.has_method("spawn_ball_at_start"):
		_board.spawn_ball_at_start(ball)

func _on_ball_reached_bottom(ball_id: int, total_energy_display: int, alignment: int, exit_position: Vector2 = Vector2.ZERO, _status_effects: Dictionary = {}) -> void:
	_pending_energy_vfx_positions.append(exit_position)
	_pending_energy_alignments.append(alignment)
	if _energy_manager and _energy_manager.has_method("on_ball_reached_bottom"):
		_energy_manager.on_ball_reached_bottom(ball_id, total_energy_display, alignment)
	if _milestone_tracker and _milestone_tracker.has_method("add_display_energy"):
		_milestone_tracker.add_display_energy(total_energy_display)

func _on_leech_drain(amount_display: int, alignment: int, peg_id: int) -> void:
	if _energy_manager and _energy_manager.has_method("add_display_energy"):
		_energy_manager.add_display_energy(amount_display, alignment)
	if _milestone_tracker and _milestone_tracker.has_method("add_display_energy"):
		_milestone_tracker.add_display_energy(amount_display)
	var peg_pos: Vector2 = Vector2(480, 400)
	if _board and _board.has_method("get_peg_by_id"):
		var peg: Node = _board.get_peg_by_id(peg_id)
		if peg and peg.get("global_position") != null:
			peg_pos = peg.global_position
	var internal: int = amount_display * Constants.ENERGY_SCALE
	if _center_panel_ui and _center_panel_ui.has_method("show_energy_gain"):
		_center_panel_ui.show_energy_gain(internal, 0, 0, peg_pos, 0)

func _on_ball_ability_on_peg_hit(_status_effects: Dictionary) -> void:
	pass

func _on_ball_exited_board(ball: Node, reason: int) -> void:
	if reason == 1:
		return
	if ball.has_method("is_split_twin") and ball.is_split_twin():
		if GameState and GameState.has_wall_break_upgrade(&"fragment_echo") and ball.has_method("has_fragment_echo_used") and not ball.has_fragment_echo_used():
			ball.mark_fragment_echo_used()
			if _board and _board.has_method("respawn_fragment_at_top"):
				_board.respawn_fragment_at_top(ball)
			return
		ball.queue_free()
		return
	var gate_open: bool = _hopper.is_gate_open() if _hopper and _hopper.has_method("is_gate_open") else false
	if not gate_open and _hopper and _hopper.has_method("return_ball"):
		_hopper.return_ball(ball)
		return
	_bag_count += 1
	ball.queue_free()

func add_balls_to_reserve(count: int) -> void:
	if count <= 0:
		return
	var in_hopper: int = _hopper.get_stored_ball_count() if _hopper and _hopper.has_method("get_stored_ball_count") else 0
	var room: int = HOPPER_MAX_BALLS - in_hopper
	var to_hopper: int = mini(count, room)
	if to_hopper > 0 and _hopper and _hopper.has_method("add_balls"):
		_hopper.add_balls(to_hopper)
	_bag_count += (count - to_hopper)

func _on_energy_allocated_vfx(main_internal: int, _sidearm_internal: int, _shield_internal: int) -> void:
	var pos: Vector2 = _pending_energy_vfx_positions.pop_front() if _pending_energy_vfx_positions.size() > 0 else Vector2(480, 600)
	var _alignment: int = _pending_energy_alignments.pop_front() if _pending_energy_alignments.size() > 0 else 0
	if _center_panel_ui and _center_panel_ui.has_method("show_energy_gain"):
		_center_panel_ui.show_energy_gain(main_internal, 0, 0, pos, 0)

func _on_milestone_reached(milestone_index: int, total_energy_display: int) -> void:
	if _rewards_manager and _rewards_manager.has_method("on_milestone_reached"):
		_rewards_manager.on_milestone_reached(milestone_index, total_energy_display)

func _on_wall_destroyed() -> void:
	if _rewards_manager and _rewards_manager.has_method("on_wall_break"):
		_rewards_manager.on_wall_break()

func _on_wall_break_reward_completed() -> void:
	if _combat_manager and _combat_manager.has_method("advance_to_next_wall"):
		_combat_manager.advance_to_next_wall()
	if _combat_manager and _combat_manager.has_method("is_all_walls_destroyed") and _combat_manager.is_all_walls_destroyed():
		_victory = true
		_show_victory_screen()
	else:
		_refresh_conquest_ui()
		_sync_battlefield_wall_index()

func _on_time_expired() -> void:
	_game_over = true
	_show_fail_screen()

func _show_fail_screen() -> void:
	GameState.paused = true
	_fail_screen = _build_end_screen("TIME'S UP!", Color(0.85, 0.2, 0.15), "Restart")
	var main: Node = get_parent()
	if main:
		var overlay: CanvasLayer = CanvasLayer.new()
		overlay.layer = 20
		overlay.name = "FailOverlay"
		main.add_child(overlay)
		overlay.add_child(_fail_screen)

func _show_victory_screen() -> void:
	GameState.paused = true
	var screen: Control = _build_end_screen("VICTORY!", Color(0.2, 0.75, 0.3), "Play Again")
	var main: Node = get_parent()
	if main:
		var overlay: CanvasLayer = CanvasLayer.new()
		overlay.layer = 20
		overlay.name = "VictoryOverlay"
		main.add_child(overlay)
		overlay.add_child(screen)

func _build_end_screen(title_text: String, title_color: Color, button_text: String) -> Control:
	var root: ColorRect = ColorRect.new()
	root.color = Color(0.08, 0.08, 0.1, 0.85)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.process_mode = Node.PROCESS_MODE_ALWAYS

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 32)
	vbox.custom_minimum_size = Vector2(400, 200)
	vbox.position = Vector2(-200, -100)
	root.add_child(vbox)

	var title: Label = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", title_color)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var btn: Button = Button.new()
	btn.text = button_text
	btn.custom_minimum_size = Vector2(220, 56)
	btn.add_theme_font_size_override("font_size", 24)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(btn)

	return root

func _on_restart_pressed() -> void:
	GameState.paused = false
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()

func _update_center_ui() -> void:
	if not _center_panel_ui:
		return
	var wall_hp: int = 50
	var wall_max: int = 50
	if _combat_manager:
		if _combat_manager.has_method("get_wall_hp"):
			wall_hp = _combat_manager.get_wall_hp()
		if _combat_manager.has_method("get_wall_hp_max"):
			wall_max = _combat_manager.get_wall_hp_max()
	if _center_panel_ui.has_method("set_fortification"):
		_center_panel_ui.set_fortification(wall_hp, wall_max)
	var ball_count: int = _hopper.get_visible_count() if _hopper and _hopper.has_method("get_visible_count") else 0
	if _center_panel_ui.has_method("set_balls"):
		_center_panel_ui.set_balls(ball_count, HOPPER_MAX_BALLS)
	if _center_panel_ui.has_method("set_bag"):
		_center_panel_ui.set_bag(_bag_count)
	var main_energy: int = 0
	if _systems_container:
		var mc: Node = _systems_container.get_node_or_null("MainCannon")
		if mc and mc.has_method("get_current_energy"):
			main_energy = mc.get_current_energy()
	var charge_max: int = 80000
	if _systems_container:
		var mc: Node = _systems_container.get_node_or_null("MainCannon")
		if mc and mc.has_method("get_charge_threshold"):
			charge_max = mc.get_charge_threshold()
	if _center_panel_ui.has_method("set_charge"):
		_center_panel_ui.set_charge(main_energy, charge_max)
	if _center_panel_ui.has_method("set_next_bonus") and _milestone_tracker and _milestone_tracker.has_method("get_total_display") and _milestone_tracker.has_method("get_next_threshold"):
		_center_panel_ui.set_next_bonus(_milestone_tracker.get_total_display(), _milestone_tracker.get_next_threshold())
	# Timer display
	if _center_panel_ui.has_method("set_timer") and _combat_manager and _combat_manager.has_method("get_timer_seconds_remaining"):
		_center_panel_ui.set_timer(_combat_manager.get_timer_seconds_remaining())
