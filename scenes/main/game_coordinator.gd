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

## Old wall-break peg IDs in TestScenario.starting_upgrades → grant peg counts (no longer stored as wall-break upgrades).
const _LEGACY_PEG_UPGRADE_ID_TO_KIND: Dictionary = {
	"add_bomb_peg": "bomb",
	"add_trampoline_peg": "trampoline",
	"add_goblin_reset_node": "goblin_reset",
	"add_eternal_peg": "eternal",
	"add_extreme_bouncer_peg": "extreme_bouncer",
	"add_magnet_peg": "magnet",
	"add_splitter_peg": "splitter",
	"add_gold_peg": "gold",
	"add_lucky_gold_peg": "lucky_gold",
	"add_gravity_well_peg": "gravity_well",
	"add_phase_peg": "phase",
	"add_wrench_peg": "wrench",
}

func _test_scenario_add_peg_stacks(kind: String, stacks: int) -> void:
	for _i in stacks:
		match kind:
			"bomb":
				GameState.bomb_peg_count += 1
			"trampoline":
				GameState.trampoline_peg_count += 1
			"goblin_reset":
				GameState.goblin_reset_node_count += 1
			"eternal":
				GameState.eternal_peg_count += 1
			"extreme_bouncer":
				GameState.extreme_bouncer_peg_count += 1
			"magnet":
				GameState.magnet_peg_count += 1
			"splitter":
				GameState.splitter_peg_count += 1
			"gold":
				GameState.gold_peg_count += 1
			"lucky_gold":
				GameState.lucky_gold_peg_count += 1
			"gravity_well":
				GameState.gravity_well_peg_count += 1
			"phase":
				GameState.phase_peg_count += 1
			"wrench":
				GameState.wrench_peg_count += 1
			_:
				pass

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
				GameState.cannon_charge_reduction += Constants.legacy_internal_energy_to_current(int(value))
			"main_charge":
				GameState.main_charge_bonus += float(value)
			"door_interval":
				GameState.conduit_wave_interval_scale = maxf(0.5, GameState.conduit_wave_interval_scale - float(value))
			"door_duration":
				GameState.conduit_open_duration_scale += float(value)
			"plain_surge":
				GameState.plain_surge_stacks = mini(5, GameState.plain_surge_stacks + int(value))
			"plain_horde":
				GameState.plain_horde_stacks = mini(3, GameState.plain_horde_stacks + int(value))
			"plain_momentum":
				GameState.plain_momentum_stacks = mini(3, GameState.plain_momentum_stacks + int(value))
	for entry in TestScenario.starting_upgrades:
		if entry is String:
			var s_uid: String = entry as String
			if _LEGACY_PEG_UPGRADE_ID_TO_KIND.has(s_uid):
				_test_scenario_add_peg_stacks(str(_LEGACY_PEG_UPGRADE_ID_TO_KIND[s_uid]), 1)
			else:
				GameState.add_wall_break_upgrade(StringName(entry), 1)
		elif entry is Dictionary:
			var uid: String = entry.get("id", "")
			var stacks: int = entry.get("stacks", 1)
			if not uid.is_empty():
				if _LEGACY_PEG_UPGRADE_ID_TO_KIND.has(uid):
					_test_scenario_add_peg_stacks(str(_LEGACY_PEG_UPGRADE_ID_TO_KIND[uid]), stacks)
				else:
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

func _defer_arm_board_event_test() -> void:
	if not _board:
		return
	var bec: Node = _board.get_node_or_null("BoardEventController")
	if bec and bec.has_method("arm_immediate_spawn_if_test"):
		bec.arm_immediate_spawn_if_test()
	var tcc: Node = _board.get_node_or_null("TreasureChestController")
	if tcc and tcc.has_method("arm_immediate_spawn_if_test"):
		tcc.arm_immediate_spawn_if_test()
	var btc: Node = _board.get_node_or_null("BuffetTableController")
	if btc and btc.has_method("arm_immediate_spawn_if_test"):
		btc.arm_immediate_spawn_if_test()
	var ssc: Node = _board.get_node_or_null("StickySlimeController")
	if ssc and ssc.has_method("arm_immediate_spawn_if_test"):
		ssc.arm_immediate_spawn_if_test()
	var bhc: Node = _board.get_node_or_null("BlackHoleController")
	if bhc and bhc.has_method("arm_immediate_spawn_if_test"):
		bhc.arm_immediate_spawn_if_test()

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
		for _i in to_hopper:
			_hopper.add_balls_with_definition(1, main_def.duplicate(true))
	for _i in range(total - to_hopper):
		_bag_queue.append(main_def.duplicate(true))
	if GameState:
		GameState.record_ball_ability_in_run("Plain")

func _spawn_test_scenario_balls() -> void:
	for entry in TestScenario.starting_balls:
		if not entry is Dictionary:
			continue
		var ability: String = entry.get("ability", "")
		var count: int = entry.get("count", 1)
		var ball_def: BallDefinition = TestScenario.make_ball_definition(ability)
		if not ability.is_empty():
			GameState.record_ball_ability_in_run(ability)
		elif count > 0:
			GameState.record_ball_ability_in_run("Plain")
		var in_hopper: int = _hopper.get_stored_ball_count() if _hopper and _hopper.has_method("get_stored_ball_count") else 0
		var room: int = HOPPER_MAX_BALLS - in_hopper
		var to_hopper: int = mini(count, room)
		if to_hopper > 0 and _hopper and _hopper.has_method("add_balls_with_definition"):
			for _i in to_hopper:
				_hopper.add_balls_with_definition(1, ball_def.duplicate(true))
		for _i in range(count - to_hopper):
			_bag_queue.append(ball_def.duplicate(true))

func reset_starting_ball_pool() -> void:
	_bag_queue.clear()
	if _hopper and _hopper.has_method("clear_stored_balls"):
		_hopper.clear_stored_balls()
	_spawn_initial_balls()

func _plain_ball_def(alignment: int) -> BallDefinition:
	var d: BallDefinition = BallDefinition.new()
	d.ability_name = ""
	d.base_energy = Constants.legacy_display_energy_to_current(20)
	d.city_weights = {0: 100}
	d.alignment = alignment
	d.rarity = Constants.RARITY_COMMON
	d.tier = 1
	d.shape_type = -1
	d.status_effects = {}
	return d

func _is_plain_ball_def(def: Resource) -> bool:
	if def == null:
		return true
	if def is BallDefinition:
		return (def as BallDefinition).ability_name.is_empty()
	return false

## Add plain balls (hopper first, rest queued for the bag). Used for milestone board event +5 and legacy BASIC_BATCH apply.
func add_basic_balls(count: int) -> void:
	if count <= 0:
		return
	if GameState:
		GameState.record_ball_ability_in_run("Plain")
	var main_def: BallDefinition = _plain_ball_def(Constants.ALIGNMENT_MAIN)
	var in_hopper: int = _hopper.get_stored_ball_count() if _hopper and _hopper.has_method("get_stored_ball_count") else 0
	var room: int = HOPPER_MAX_BALLS - in_hopper
	var to_hopper: int = mini(count, room)
	if to_hopper > 0 and _hopper and _hopper.has_method("add_balls_with_definition"):
		for _i in to_hopper:
			_hopper.add_balls_with_definition(1, main_def.duplicate(true))
	for _i in range(count - to_hopper):
		_bag_queue.append(main_def.duplicate(true))

func count_plain_balls_in_play() -> int:
	var n: int = 0
	if _hopper and _hopper.has_method("get_stored_balls"):
		for ball in _hopper.get_stored_balls():
			if not is_instance_valid(ball):
				continue
			var def: Resource = ball.get_definition() if ball.has_method("get_definition") else null
			if _is_plain_ball_def(def):
				n += 1
	var main: Node = get_parent()
	var balls_container: Node = main.get_node_or_null("BallsContainer") if main else null
	if balls_container:
		for ball in balls_container.get_children():
			if not is_instance_valid(ball):
				continue
			if ball.has_method("is_split_twin") and ball.is_split_twin():
				continue
			var def: Resource = ball.get_definition() if ball.has_method("get_definition") else null
			if _is_plain_ball_def(def):
				n += 1
	for def in _bag_queue:
		if def is BallDefinition and _is_plain_ball_def(def):
			n += 1
	return n

## Convert one plain ball to the given ability (hopper, then board, then bag queue).
func apply_ball_upgrade_conversion(def: BallDefinition) -> bool:
	if def == null:
		return false
	var up: BallDefinition = def.duplicate(true)
	if _hopper and _hopper.has_method("get_stored_balls"):
		for ball in _hopper.get_stored_balls():
			if not is_instance_valid(ball):
				continue
			if not ball.has_method("get_definition") or not ball.has_method("set_definition"):
				continue
			var bdef: Resource = ball.get_definition()
			if _is_plain_ball_def(bdef):
				ball.set_definition(up.duplicate(true))
				GameState.record_ball_ability_in_run(up.ability_name)
				return true
	var main: Node = get_parent()
	var balls_container: Node = main.get_node_or_null("BallsContainer") if main else null
	if balls_container:
		for ball in balls_container.get_children():
			if not is_instance_valid(ball):
				continue
			if ball.has_method("is_split_twin") and ball.is_split_twin():
				continue
			if not ball.has_method("get_definition") or not ball.has_method("set_definition"):
				continue
			var bdef: Resource = ball.get_definition()
			if _is_plain_ball_def(bdef):
				ball.set_definition(up.duplicate(true))
				GameState.record_ball_ability_in_run(up.ability_name)
				return true
	var i: int = 0
	while i < _bag_queue.size():
		var qdef: Variant = _bag_queue[i]
		if qdef is BallDefinition and _is_plain_ball_def(qdef):
			_bag_queue[i] = up.duplicate(true)
			GameState.record_ball_ability_in_run(up.ability_name)
			return true
		i += 1
	return false

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
		if _board.has_signal("gold_gained"):
			_board.gold_gained.connect(_on_gold_gained)
	if _milestone_tracker and _milestone_tracker.has_signal("milestone_reached"):
		_milestone_tracker.milestone_reached.connect(_on_milestone_reached)
	if _combat_manager:
		if _combat_manager.has_signal("wall_destroyed"):
			_combat_manager.wall_destroyed.connect(_on_wall_destroyed)
		if _combat_manager.has_signal("time_expired"):
			_combat_manager.time_expired.connect(_on_time_expired)
	if _rewards_manager and _rewards_manager.has_signal("wall_break_reward_completed"):
		_rewards_manager.wall_break_reward_completed.connect(_on_wall_break_reward_completed)
	if _rewards_manager and _rewards_manager.has_signal("boss_reward_completed"):
		_rewards_manager.boss_reward_completed.connect(_on_boss_reward_completed)
	if _energy_router and _energy_router.has_signal("energy_allocated"):
		_energy_router.energy_allocated.connect(_on_energy_allocated_vfx)
	if _battlefield and _battlefield.has_method("set_main_cannon"):
		var mc: Node = _systems_container.get_node_or_null("MainCannon") if _systems_container else null
		_battlefield.set_main_cannon(mc)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var vp: Viewport = get_viewport()
	if key_event.keycode == KEY_F3 or key_event.keycode == KEY_QUOTELEFT:
		if _debug_overlay:
			_debug_overlay.visible = !_debug_overlay.visible
		if vp:
			vp.set_input_as_handled()
	elif key_event.keycode == KEY_I or key_event.keycode == KEY_B:
		_toggle_junk_box()
		if vp:
			vp.set_input_as_handled()
	elif key_event.keycode == KEY_ESCAPE:
		# Open inventory; let other ESC handlers (almanac, inventory close, debug modals) run first.
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
		if vp:
			vp.set_input_as_handled()
	elif key_event.keycode == KEY_L or key_event.keycode == KEY_TAB:
		_on_almanac_pressed()
		if vp:
			vp.set_input_as_handled()
	elif key_event.keycode == KEY_P:
		if not _game_over and not _victory:
			if get_tree():
				get_tree().paused = !get_tree().paused
			if vp:
				vp.set_input_as_handled()

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
		if _board.has_signal("gold_gained") and _board.gold_gained.is_connected(_on_gold_gained):
			_board.gold_gained.disconnect(_on_gold_gained)
	if _milestone_tracker and _milestone_tracker.has_signal("milestone_reached"):
		_milestone_tracker.milestone_reached.disconnect(_on_milestone_reached)
	if _combat_manager:
		if _combat_manager.has_signal("wall_destroyed"):
			_combat_manager.wall_destroyed.disconnect(_on_wall_destroyed)
		if _combat_manager.has_signal("time_expired") and _combat_manager.time_expired.is_connected(_on_time_expired):
			_combat_manager.time_expired.disconnect(_on_time_expired)
	if _rewards_manager and _rewards_manager.has_signal("wall_break_reward_completed") and _rewards_manager.wall_break_reward_completed.is_connected(_on_wall_break_reward_completed):
		_rewards_manager.wall_break_reward_completed.disconnect(_on_wall_break_reward_completed)
	if _rewards_manager and _rewards_manager.has_signal("boss_reward_completed") and _rewards_manager.boss_reward_completed.is_connected(_on_boss_reward_completed):
		_rewards_manager.boss_reward_completed.disconnect(_on_boss_reward_completed)
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
	if _hopper and _hopper.has_method("get_stored_ball_count") and _hopper.get_stored_ball_count() < HOPPER_MAX_BALLS and not _bag_queue.is_empty():
		var gate_open: bool = _hopper.is_gate_open() if _hopper.has_method("is_gate_open") else false
		if not gate_open and _hopper.has_method("add_balls_with_definition"):
			var next_def: Resource = _bag_queue.pop_front()
			_hopper.add_balls_with_definition(1, next_def)
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
	if reason == 1:
		return
	## Board.REASON_BLACK_HOLE — delayed hopper return (split twins destroyed, no fragment echo).
	if reason == 4:
		_on_ball_exited_black_hole(ball)
		return
	if ball.has_method("is_split_twin") and ball.is_split_twin():
		if GameState and GameState.has_wall_break_upgrade(&"fragment_echo") and ball.has_method("has_fragment_echo_used") and not ball.has_fragment_echo_used():
			ball.mark_fragment_echo_used()
			if _board and _board.has_method("respawn_fragment_at_top"):
				_board.respawn_fragment_at_top(ball)
			return
		ball.queue_free()
		return
	if ball.has_method("is_bloom_spawn") and ball.is_bloom_spawn():
		ball.queue_free()
		return
	var gate_open: bool = _hopper.is_gate_open() if _hopper and _hopper.has_method("is_gate_open") else false
	if not gate_open and _hopper and _hopper.has_method("return_ball"):
		_hopper.return_ball(ball)
		return
	var plain: BallDefinition = _plain_ball_def(Constants.ALIGNMENT_MAIN)
	var def_to_store: BallDefinition = plain.duplicate(true)
	if ball.has_method("get_definition"):
		var bd: Resource = ball.get_definition()
		if bd is BallDefinition:
			def_to_store = (bd as BallDefinition).duplicate(true)
	_bag_queue.append(def_to_store)
	ball.queue_free()

func _on_ball_exited_black_hole(ball: Node) -> void:
	if not ball or not is_instance_valid(ball):
		return
	if ball.has_method("is_bloom_spawn") and ball.is_bloom_spawn():
		ball.queue_free()
		return
	if ball.has_method("is_split_twin") and ball.is_split_twin():
		ball.queue_free()
		return
	var def_to_store: BallDefinition = _plain_ball_def(Constants.ALIGNMENT_MAIN)
	if ball.has_method("get_definition"):
		var bd: Resource = ball.get_definition()
		if bd is BallDefinition:
			def_to_store = (bd as BallDefinition).duplicate(true)
	ball.queue_free()
	var delay: float = Constants.BLACK_HOLE_RESPAWN_DELAY_SEC
	get_tree().create_timer(delay).timeout.connect(_finish_black_hole_delayed_return.bind(def_to_store))

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
	if count <= 0:
		return
	var plain: BallDefinition = _plain_ball_def(Constants.ALIGNMENT_MAIN)
	var in_hopper: int = _hopper.get_stored_ball_count() if _hopper and _hopper.has_method("get_stored_ball_count") else 0
	var room: int = HOPPER_MAX_BALLS - in_hopper
	var to_hopper: int = mini(count, room)
	if to_hopper > 0 and _hopper and _hopper.has_method("add_balls_with_definition"):
		for _i in to_hopper:
			_hopper.add_balls_with_definition(1, plain.duplicate(true))
	for _i in range(count - to_hopper):
		_bag_queue.append(plain.duplicate(true))

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
	_wall_break_is_last_wall = false
	if _combat_manager and _combat_manager.has_method("get_current_wall_index") and _combat_manager.has_method("get_wall_names"):
		var idx: int = _combat_manager.get_current_wall_index()
		var names: Array = _combat_manager.get_wall_names()
		_wall_break_is_last_wall = (idx >= names.size() - 1)
	if _hopper and _hopper.has_method("set_gate_open"):
		_hopper.set_gate_open(false)
	GameState.set_run_flow_state(GameState.RunFlowState.WALL_BREAK_TRANSITION)
	if _battlefield and _battlefield.has_method("play_wall_destroyed_transition"):
		_battlefield.play_wall_destroyed_transition()
	if _center_panel_ui and _center_panel_ui.has_method("animate_wall_cleared"):
		_center_panel_ui.animate_wall_cleared()
	get_tree().create_timer(2.2).timeout.connect(_on_wall_break_transition_finished)

func _on_wall_break_transition_finished() -> void:
	if _wall_break_is_last_wall and _rewards_manager:
		if GameState.endless_mode and _rewards_manager.has_method("on_wall_break"):
			_rewards_manager.on_wall_break()
		elif _rewards_manager.has_method("on_boss_reward"):
			_rewards_manager.on_boss_reward()
	elif _rewards_manager and _rewards_manager.has_method("on_wall_break"):
		_rewards_manager.on_wall_break()

func _on_wall_break_reward_completed() -> void:
	if _combat_manager and _combat_manager.has_method("advance_to_next_wall"):
		_combat_manager.advance_to_next_wall()
	_refresh_conquest_ui()
	_sync_battlefield_wall_index()
	GameState.set_run_flow_state(GameState.RunFlowState.WALL_BREAK_TRANSITION)
	var wall_name: String = ""
	if _combat_manager and _combat_manager.has_method("get_current_gate_name"):
		wall_name = _combat_manager.get_current_gate_name()
	if wall_name.is_empty():
		wall_name = "Next Wall"
	_show_wall_title_card(wall_name, "", _begin_next_wall_intro)

func _on_boss_reward_completed() -> void:
	var is_last_city: bool = (GameState.current_city_id >= Constants.CITY_DEFINITION_PATHS.size() - 1)
	if is_last_city:
		_victory = true
		_show_victory_screen()
		return
	if _combat_manager and _combat_manager.has_method("advance_to_next_wall"):
		_combat_manager.advance_to_next_wall()
	GameState.current_city_id += 1
	_init_from_current_city()
	_refresh_conquest_ui()
	_sync_battlefield_wall_index()
	GameState.set_run_flow_state(GameState.RunFlowState.WALL_BREAK_TRANSITION)
	var city_name: String = ""
	if _combat_manager and _combat_manager.has_method("get_city_display_name"):
		city_name = _combat_manager.get_city_display_name()
	if city_name.is_empty():
		city_name = "New Territory"
	var wall_name: String = ""
	if _combat_manager and _combat_manager.has_method("get_current_gate_name"):
		wall_name = _combat_manager.get_current_gate_name()
	_show_wall_title_card(city_name, wall_name, _begin_next_wall_intro)

func _begin_next_wall_intro() -> void:
	if _battlefield and _battlefield.has_method("play_next_wall_intro"):
		_battlefield.play_next_wall_intro()
	get_tree().create_timer(1.5).timeout.connect(_on_next_wall_intro_finished)

func _on_next_wall_intro_finished() -> void:
	GameState.set_run_flow_state(GameState.RunFlowState.FIGHTING)

func _show_wall_title_card(title_text: String, subtitle_text: String, on_finished: Callable) -> void:
	var overlay: CanvasLayer = CanvasLayer.new()
	overlay.layer = 15
	overlay.name = "WallTitleCard"
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS

	var center_y: float = 290.0
	var band_total_height: float = 180.0

	# Gradient band via GradientTexture2D for soft top/bottom edges
	var grad: Gradient = Gradient.new()
	var v: Color = MonsterPalette.VOID()
	grad.colors = PackedColorArray([Color(v.r, v.g, v.b, 0), Color(v.r, v.g, v.b, 0.88), Color(v.r, v.g, v.b, 0.88), Color(v.r, v.g, v.b, 0)])
	grad.offsets = PackedFloat32Array([0.0, 0.22, 0.78, 1.0])
	var grad_tex: GradientTexture2D = GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill_from = Vector2(0.5, 0.0)
	grad_tex.fill_to = Vector2(0.5, 1.0)
	grad_tex.width = 4
	grad_tex.height = 128
	var band: TextureRect = TextureRect.new()
	band.texture = grad_tex
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.position = Vector2(0, center_y)
	band.size = Vector2(1280, band_total_height)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.modulate.a = 0.0
	overlay.add_child(band)

	# Decorative line above title
	var line_top: ColorRect = ColorRect.new()
	line_top.color = MonsterPalette.TITLE_CARD_LINE()
	line_top.size = Vector2(340, 1)
	line_top.position = Vector2(470, center_y + 58)
	line_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_top.modulate.a = 0.0
	overlay.add_child(line_top)

	# Title label
	var title_label: Label = Label.new()
	title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", 44)
	title_label.add_theme_color_override("font_color", MonsterPalette.TITLE_CARD_TITLE())
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(40, center_y + 64)
	title_label.size = Vector2(1280, 54)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.modulate.a = 0.0
	overlay.add_child(title_label)

	# Decorative line below title
	var line_bottom: ColorRect = ColorRect.new()
	line_bottom.color = MonsterPalette.TITLE_CARD_LINE()
	line_bottom.size = Vector2(340, 1)
	line_bottom.position = Vector2(470, center_y + 122)
	line_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_bottom.modulate.a = 0.0
	overlay.add_child(line_bottom)

	# Subtitle label (shown below title when provided)
	var sub_label: Label = null
	if not subtitle_text.is_empty():
		sub_label = Label.new()
		sub_label.text = subtitle_text
		sub_label.add_theme_font_size_override("font_size", 20)
		sub_label.add_theme_color_override("font_color", MonsterPalette.TITLE_CARD_SUB())
		sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_label.position = Vector2(0, center_y + 126)
		sub_label.size = Vector2(1280, 30)
		sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sub_label.modulate.a = 0.0
		overlay.add_child(sub_label)

	get_parent().add_child(overlay)

	# --- Animation timeline ---
	var tween: Tween = create_tween()

	# Fade in (parallel)
	tween.set_parallel(true)
	tween.tween_property(band, "modulate:a", 1.0, 0.7).set_ease(Tween.EASE_OUT)
	tween.tween_property(line_top, "modulate:a", 1.0, 0.6).set_delay(0.15)
	tween.tween_property(line_bottom, "modulate:a", 1.0, 0.6).set_delay(0.15)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.9).set_delay(0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_label, "position:x", 0.0, 0.9).set_delay(0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if sub_label:
		tween.tween_property(sub_label, "modulate:a", 1.0, 0.7).set_delay(0.45).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)

	# Hold
	tween.tween_interval(1.6)

	# Fade out (parallel)
	tween.set_parallel(true)
	tween.tween_property(band, "modulate:a", 0.0, 0.65).set_ease(Tween.EASE_IN)
	tween.tween_property(title_label, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tween.tween_property(line_top, "modulate:a", 0.0, 0.5)
	tween.tween_property(line_bottom, "modulate:a", 0.0, 0.5)
	if sub_label:
		tween.tween_property(sub_label, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)

	# Cleanup and trigger next phase
	tween.tween_callback(overlay.queue_free)
	tween.tween_callback(on_finished)

func _on_time_expired() -> void:
	_game_over = true
	_show_fail_screen()

func _show_fail_screen() -> void:
	GameState.paused = true
	_fail_screen = _build_end_screen("TIME'S UP!", MonsterPalette.RUST(), "Restart")
	var main: Node = get_parent()
	if main:
		var overlay: CanvasLayer = CanvasLayer.new()
		overlay.layer = 20
		overlay.name = "FailOverlay"
		main.add_child(overlay)
		overlay.add_child(_fail_screen)

func _show_victory_screen() -> void:
	GameState.paused = true
	var screen: Control = _build_victory_screen()
	var main: Node = get_parent()
	if main:
		var overlay: CanvasLayer = CanvasLayer.new()
		overlay.layer = 20
		overlay.name = "VictoryOverlay"
		main.add_child(overlay)
		overlay.add_child(screen)

func _build_victory_screen() -> Control:
	var root: ColorRect = ColorRect.new()
	root.color = MonsterPalette.UI_DIM()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.process_mode = Node.PROCESS_MODE_ALWAYS

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	vbox.custom_minimum_size = Vector2(400, 220)
	vbox.position = Vector2(-200, -110)
	root.add_child(vbox)

	var title: Label = Label.new()
	title.text = "VICTORY!"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", MonsterPalette.MINT())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var btn_play: Button = Button.new()
	btn_play.text = "Play Again"
	btn_play.custom_minimum_size = Vector2(220, 56)
	btn_play.add_theme_font_size_override("font_size", 24)
	btn_play.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_play.pressed.connect(_on_restart_pressed)
	vbox.add_child(btn_play)

	var btn_endless: Button = Button.new()
	btn_endless.text = "Endless Mode"
	btn_endless.custom_minimum_size = Vector2(160, 36)
	btn_endless.add_theme_font_size_override("font_size", 16)
	btn_endless.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_endless.pressed.connect(_on_endless_mode_pressed)
	vbox.add_child(btn_endless)

	return root

func _on_endless_mode_pressed() -> void:
	var main: Node = get_parent()
	if main:
		var overlay: Node = main.get_node_or_null("VictoryOverlay")
		if overlay:
			overlay.queue_free()
	GameState.paused = false
	_victory = false
	GameState.endless_mode = true
	if _combat_manager and _combat_manager.has_method("start_endless_wave"):
		_combat_manager.start_endless_wave(1)
	_refresh_conquest_ui()
	_sync_battlefield_wall_index()
	GameState.set_run_flow_state(GameState.RunFlowState.WALL_BREAK_TRANSITION)
	_show_wall_title_card("Endless Mode", "Wave 1", _begin_next_wall_intro)

func _build_end_screen(title_text: String, title_color: Color, button_text: String) -> Control:
	var root: ColorRect = ColorRect.new()
	root.color = MonsterPalette.UI_DIM()
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

func _create_inventory_ui() -> void:
	var main: Node = get_parent()
	if not main:
		return
	var overlay: CanvasLayer = CanvasLayer.new()
	overlay.layer = 8
	overlay.name = "InventoryOverlay"
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(overlay)
	var panel_scene: PackedScene = load("res://scenes/ui/inventory_panel.tscn") as PackedScene
	if panel_scene:
		_inventory_panel = panel_scene.instantiate() as Control
		if _inventory_panel:
			overlay.add_child(_inventory_panel)
			if _inventory_panel.has_method("setup"):
				_inventory_panel.setup(self, _reward_handler)
	var junk_box_scene: PackedScene = load("res://scenes/ui/junk_box/junk_box_panel.tscn") as PackedScene
	if junk_box_scene:
		_junk_box_panel = junk_box_scene.instantiate() as Control
		if _junk_box_panel:
			overlay.add_child(_junk_box_panel)
			if _junk_box_panel.has_method("setup"):
				_junk_box_panel.setup(self, _reward_handler)
			if _board and _junk_box_panel.has_method("set_board"):
				_junk_box_panel.set_board(_board)
	var almanac_scene: PackedScene = load("res://scenes/ui/almanac_panel.tscn") as PackedScene
	if almanac_scene:
		_almanac_panel = almanac_scene.instantiate() as Control
		if _almanac_panel:
			overlay.add_child(_almanac_panel)
			if _almanac_panel.has_method("setup"):
				_almanac_panel.setup(self, _reward_handler)
	_create_debug_event_spawn_ui(main)
	_create_debug_full_store_ui(main)
	_create_debug_city_jump_ui(main)
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
			left_panel.add_child(_build_debug_tools_column())

func _build_debug_tools_column() -> Control:
	var col: VBoxContainer = VBoxContainer.new()
	col.name = "DebugTools"
	col.position = Vector2(8, 8)
	col.add_theme_constant_override("separation", 4)
	col.process_mode = Node.PROCESS_MODE_ALWAYS
	var gold_btn: Button = _build_debug_tool_button("+100 Gold", "Add +100 gold to your run (debug)")
	gold_btn.pressed.connect(_on_debug_add_gold_pressed)
	var shop_btn: Button = _build_debug_tool_button("Merchant", "Trigger merchant shop immediately (debug)")
	shop_btn.pressed.connect(_on_debug_milestone_shop_pressed)
	var events_btn: Button = _build_debug_tool_button("Events", "Spawn or trigger board event types (debug)")
	events_btn.pressed.connect(_on_debug_spawn_event_menu_pressed)
	var full_store_btn: Button = _build_debug_tool_button("Full store", "Open catalog to purchase any item directly (debug)")
	full_store_btn.pressed.connect(_on_debug_full_store_pressed)
	var city_jump_btn: Button = _build_debug_tool_button("Go to city…", "Jump directly to any city and wall index (debug)")
	city_jump_btn.pressed.connect(_on_debug_city_jump_pressed)
	col.add_child(gold_btn)
	col.add_child(shop_btn)
	col.add_child(events_btn)
	col.add_child(full_store_btn)
	col.add_child(city_jump_btn)
	return col

func _build_debug_tool_button(text: String, tooltip: String) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.tooltip_text = tooltip
	btn.custom_minimum_size = Vector2(112, 28)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = MonsterPalette.DEBUG_BTN_BG()
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = MonsterPalette.DEBUG_BTN_BORDER()
	btn_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	btn_hover.bg_color = MonsterPalette.DEBUG_BTN_HOVER()
	btn.add_theme_stylebox_override("hover", btn_hover)
	var btn_pressed_style: StyleBoxFlat = btn_style.duplicate()
	btn_pressed_style.bg_color = MonsterPalette.RUST().lerp(MonsterPalette.WARM_BROWN(), 0.25)
	btn.add_theme_stylebox_override("pressed", btn_pressed_style)
	btn.add_theme_font_size_override("font_size", 13)
	return btn

func _on_debug_add_gold_pressed() -> void:
	if _game_over or _victory:
		return
	if GameState:
		GameState.add_run_gold(100)
	if _center_panel_ui and _center_panel_ui.has_method("set_run_gold") and GameState:
		_center_panel_ui.set_run_gold(GameState.run_gold)

func _on_debug_milestone_shop_pressed() -> void:
	debug_trigger_milestone_shop()

func _on_debug_spawn_event_menu_pressed() -> void:
	if _game_over or _victory:
		return
	if _debug_event_spawn_modal and _debug_event_spawn_modal.has_method("show_modal"):
		_debug_event_spawn_modal.show_modal()

func debug_spawn_board_milestone_event() -> void:
	if _game_over or _victory:
		return
	var bec: Node = _board.get_node_or_null("BoardEventController") if _board else null
	if bec and bec.has_method("debug_arm_immediate_spawn"):
		if not bec.debug_arm_immediate_spawn():
			push_warning("Debug: milestone board event not armed (need FIGHTING flow and idle BoardEventController).")

func debug_spawn_treasure_chest_event() -> void:
	if _game_over or _victory:
		return
	var tcc: Node = _board.get_node_or_null("TreasureChestController") if _board else null
	if tcc and tcc.has_method("debug_arm_immediate_spawn"):
		if not tcc.debug_arm_immediate_spawn():
			push_warning("Debug: treasure chest event not armed (need FIGHTING flow and idle TreasureChestController).")

func debug_spawn_sticky_slime_event() -> void:
	if _game_over or _victory:
		return
	var ssc: Node = _board.get_node_or_null("StickySlimeController") if _board else null
	if ssc and ssc.has_method("debug_arm_immediate_spawn"):
		if not ssc.debug_arm_immediate_spawn():
			push_warning("Debug: sticky slime event not armed (Human Kingdom, FIGHTING flow, idle controller).")

func debug_spawn_black_hole_event() -> void:
	if _game_over or _victory:
		return
	var bhc: Node = _board.get_node_or_null("BlackHoleController") if _board else null
	if bhc and bhc.has_method("debug_arm_immediate_spawn"):
		if not bhc.debug_arm_immediate_spawn():
			push_warning("Debug: black hole event not armed (Elf Palace, FIGHTING flow, idle controller).")

func debug_trigger_milestone_shop() -> void:
	if _game_over or _victory:
		return
	if _rewards_manager and _rewards_manager.has_method("on_milestone_reached"):
		_rewards_manager.on_milestone_reached(0, 0)

func debug_trigger_wall_break_reward() -> void:
	if _game_over or _victory:
		return
	if _rewards_manager and _rewards_manager.has_method("on_wall_break"):
		_rewards_manager.on_wall_break()

func debug_trigger_boss_reward() -> void:
	if _game_over or _victory:
		return
	if _rewards_manager and _rewards_manager.has_method("on_boss_reward"):
		_rewards_manager.on_boss_reward()

func _create_debug_event_spawn_ui(main: Node) -> void:
	if not main:
		return
	var event_layer: CanvasLayer = CanvasLayer.new()
	event_layer.layer = 11
	event_layer.name = "DebugEventSpawnLayer"
	event_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(event_layer)
	var modal_script: GDScript = load("res://scenes/ui/debug_event_spawn_modal.gd") as GDScript
	if not modal_script:
		return
	_debug_event_spawn_modal = modal_script.new() as Control
	event_layer.add_child(_debug_event_spawn_modal)
	if _debug_event_spawn_modal.has_method("setup"):
		_debug_event_spawn_modal.setup(self)

func _create_debug_full_store_ui(main: Node) -> void:
	if not main:
		return
	var store_layer: CanvasLayer = CanvasLayer.new()
	store_layer.layer = 12
	store_layer.name = "DebugFullStoreLayer"
	store_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(store_layer)
	var store_script: GDScript = load("res://scenes/ui/debug_full_store_modal.gd") as GDScript
	if not store_script:
		return
	_debug_full_store_modal = store_script.new() as Control
	store_layer.add_child(_debug_full_store_modal)
	if _debug_full_store_modal.has_method("setup"):
		_debug_full_store_modal.setup(self, _reward_handler)

func _on_debug_full_store_pressed() -> void:
	if _game_over or _victory:
		return
	if _debug_full_store_modal and _debug_full_store_modal.has_method("show_modal"):
		_debug_full_store_modal.show_modal()

func _on_debug_city_jump_pressed() -> void:
	if _debug_city_jump_modal and _debug_city_jump_modal.has_method("show_modal"):
		_debug_city_jump_modal.show_modal()

## Debug: set city index and wall index (0 = World 1), refresh combat and UI; does not reset run inventory/upgrades.
func debug_jump_to_city_and_wall(city_index: int, wall_index: int) -> void:
	var main: Node = get_parent()
	if main:
		var vo: Node = main.get_node_or_null("VictoryOverlay")
		if vo:
			vo.queue_free()
		var fo: Node = main.get_node_or_null("FailOverlay")
		if fo:
			fo.queue_free()
	GameState.paused = false
	Engine.time_scale = 1.0
	get_tree().paused = false
	_game_over = false
	_victory = false
	_fail_screen = null
	if _rewards_manager and _rewards_manager.has_method("debug_discard_open_reward_ui"):
		_rewards_manager.debug_discard_open_reward_ui()
	if _debug_event_spawn_modal and _debug_event_spawn_modal.has_method("hide_modal"):
		_debug_event_spawn_modal.hide_modal()
	if _debug_full_store_modal and _debug_full_store_modal.has_method("hide_modal"):
		_debug_full_store_modal.hide_modal()
	GameState.endless_mode = false
	GameState.current_city_id = clampi(city_index, 0, Constants.CITY_DEFINITION_PATHS.size() - 1)
	var city: CityDefinition = GameState.get_current_city_definition()
	if city == null:
		return
	if _combat_manager and _combat_manager.has_method("init_from_city_at_wall"):
		_combat_manager.init_from_city_at_wall(city, wall_index)
	if _milestone_tracker and _milestone_tracker.has_method("set_thresholds_from_city"):
		_milestone_tracker.set_thresholds_from_city(city.get_milestone_thresholds_int())
	_refresh_conquest_ui()
	_sync_battlefield_wall_index()
	GameState.set_run_flow_state(GameState.RunFlowState.FIGHTING)

func _create_debug_city_jump_ui(main: Node) -> void:
	if not main:
		return
	var jump_layer: CanvasLayer = CanvasLayer.new()
	jump_layer.layer = 13
	jump_layer.name = "DebugCityJumpLayer"
	jump_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(jump_layer)
	var jump_script: GDScript = load("res://scenes/ui/debug_city_jump_modal.gd") as GDScript
	if not jump_script:
		return
	_debug_city_jump_modal = jump_script.new() as Control
	jump_layer.add_child(_debug_city_jump_modal)
	if _debug_city_jump_modal.has_method("setup"):
		_debug_city_jump_modal.setup(self)

func _build_almanac_button() -> Button:
	var btn: Button = Button.new()
	btn.text = ""
	btn.tooltip_text = "Almanac (L): Open the catalog of all balls, pegs, and relics."
	btn.custom_minimum_size = Vector2(36, 32)
	btn.position = Vector2(198, 8)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = MonsterPalette.ALMANAC_BTN_BG()
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = MonsterPalette.ALMANAC_BTN_BORDER()
	btn_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	var hc: Color = MonsterPalette.SLATE().lerp(MonsterPalette.INDIGO(), 0.4)
	btn_hover.bg_color = Color(hc.r, hc.g, hc.b, 0.95)
	btn.add_theme_stylebox_override("hover", btn_hover)
	var btn_pressed_style: StyleBoxFlat = btn_style.duplicate()
	var pc: Color = MonsterPalette.INDIGO().lerp(MonsterPalette.VOID(), 0.2)
	btn_pressed_style.bg_color = Color(pc.r, pc.g, pc.b, 0.95)
	btn.add_theme_stylebox_override("pressed", btn_pressed_style)
	var book_icon: Image = _create_book_icon_image()
	if book_icon:
		btn.icon = ImageTexture.create_from_image(book_icon)
	btn.pressed.connect(_on_almanac_pressed)
	return btn

func _create_book_icon_image() -> Image:
	var s: int = 20
	var img: Image = Image.create(s, s, false, Image.FORMAT_RGBA8)
	var paper: Color = MonsterPalette.SWATCH_CREAM()
	var ink: Color = MonsterPalette.INDIGO()
	for y in range(4, 17):
		for x in range(5, 10):
			img.set_pixel(x, y, paper)
		for x in range(11, 16):
			img.set_pixel(x, y, paper)
	for x in range(5, 16):
		img.set_pixel(x, 4, ink)
		img.set_pixel(x, 16, ink)
	for y in range(4, 17):
		img.set_pixel(5, y, ink)
		img.set_pixel(15, y, ink)
	for x in range(7, 14):
		img.set_pixel(x, 8, ink)
		img.set_pixel(x, 11, ink)
	return img

func _build_bag_button() -> Button:
	var btn: Button = Button.new()
	btn.text = ""
	btn.tooltip_text = "Junk Box (I / B / Esc): Open your Junk Box inventory and drag modules to the board."
	btn.custom_minimum_size = Vector2(36, 32)
	btn.position = Vector2(240, 8)  # to the right of almanac (198 + 36 + 6 gap)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = MonsterPalette.BAG_BTN_BG()
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = MonsterPalette.BAG_BTN_BORDER()
	btn_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	var bag_h: Color = MonsterPalette.INDIGO().lerp(MonsterPalette.TAN(), 0.15)
	btn_hover.bg_color = Color(bag_h.r, bag_h.g, bag_h.b, 0.95)
	btn.add_theme_stylebox_override("hover", btn_hover)
	var btn_pressed_style: StyleBoxFlat = btn_style.duplicate()
	var bag_p: Color = MonsterPalette.WARM_BROWN().lerp(MonsterPalette.INDIGO(), 0.35)
	btn_pressed_style.bg_color = Color(bag_p.r, bag_p.g, bag_p.b, 0.95)
	btn.add_theme_stylebox_override("pressed", btn_pressed_style)
	var bag_icon: Image = _create_bag_icon_image()
	if bag_icon:
		btn.icon = ImageTexture.create_from_image(bag_icon)
	
	var badge: Label = Label.new()
	badge.name = "ItemCountBadge"
	badge.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	badge.anchor_left = 1.0
	badge.anchor_top = 1.0
	badge.anchor_right = 1.0
	badge.anchor_bottom = 1.0
	badge.offset_left = -16.0
	badge.offset_top = -14.0
	badge.offset_right = 2.0
	badge.offset_bottom = 2.0
	badge.theme_override_font_sizes/font_size = 10
	badge.theme_override_colors/font_color = MonsterPalette.SWATCH_CREAM()
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	btn.add_child(badge)

	btn.pressed.connect(_on_inventory_pressed)
	return btn

func _update_bag_button_badge() -> void:
	var count: int = GameState.junk_box.get_item_count() if GameState.junk_box != null else 0
	if _inventory_btn:
		var badge: Label = _inventory_btn.get_node_or_null("ItemCountBadge") as Label
		if badge:
			badge.text = str(count) if count > 0 else ""
	var main: Node = get_parent()
	if main:
		var bag_lbl: Label = main.get_node_or_null("UILayer/CenterPanel/BagPanel/BagLabel") as Label
		if bag_lbl:
			bag_lbl.text = "JUNK: %d" % count

func _create_bag_icon_image() -> Image:
	var s: int = 20
	var img: Image = Image.create(s, s, false, Image.FORMAT_RGBA8)
	var gold: Color = MonsterPalette.SWATCH_CREAM()
	var dark_gold: Color = MonsterPalette.DARK_OLIVE()
	# Bag body (trapezoid: narrow top, wider bottom)
	for y in range(8, 18):
		var t: float = float(y - 8) / 9.0
		var half_w: int = int(lerpf(5.0, 8.0, t))
		for x in range(s / 2 - half_w, s / 2 + half_w):
			img.set_pixel(x, y, gold)
	# Top edge (tie)
	for x in range(5, 15):
		img.set_pixel(x, 8, dark_gold)
	# Drawstring arc
	for x in range(7, 14):
		img.set_pixel(x, 5, gold)
	img.set_pixel(6, 6, gold)
	img.set_pixel(7, 6, gold)
	img.set_pixel(13, 6, gold)
	img.set_pixel(14, 6, gold)
	img.set_pixel(6, 7, gold)
	img.set_pixel(14, 7, gold)
	return img

func _on_inventory_pressed() -> void:
	if _game_over or _victory:
		return
	_toggle_junk_box()

func _on_almanac_pressed() -> void:
	if _game_over or _victory:
		return
	if _almanac_panel and _almanac_panel.has_method("toggle"):
		_almanac_panel.toggle()

func _ball_catalog_key_from_def(def: BallDefinition) -> String:
	var ab: String = def.ability_name if not def.ability_name.is_empty() else "Plain"
	return "%s|%d" % [ab, def.tier]

func get_ball_catalog_key_for_definition(def: BallDefinition) -> String:
	return _ball_catalog_key_from_def(def)

func _ball_ability_ledger_key(def: BallDefinition) -> String:
	return def.ability_name if not def.ability_name.is_empty() else "Plain"

## Sum of balls across all tiers for one ability (almanac).
func get_ball_total_count_for_ability(ability_ledger_key: String) -> int:
	var counts: Dictionary = get_ball_definition_counts()
	var n: int = 0
	for k in counts.keys():
		if String(k).get_slice("|", 0) == ability_ledger_key:
			n += int(counts[k])
	return n

func _accumulate_ball_def_count(counts: Dictionary, def: Resource) -> void:
	if not def is BallDefinition:
		return
	var d: BallDefinition = def as BallDefinition
	var key: String = _ball_catalog_key_from_def(d)
	counts[key] = counts.get(key, 0) + 1

## Counts balls in hopper, on board, and in the bag queue by ability_name + tier (e.g. Split|2 → 3).
func get_ball_definition_counts() -> Dictionary:
	var counts: Dictionary = {}
	var main: Node = get_parent()
	if _hopper and _hopper.has_method("get_stored_balls"):
		for ball in _hopper.get_stored_balls():
			if not is_instance_valid(ball):
				continue
			var def: Resource = ball.get_definition() if ball.has_method("get_definition") else null
			_accumulate_ball_def_count(counts, def)
	var balls_container: Node = main.get_node_or_null("BallsContainer") if main else null
	if balls_container:
		for ball in balls_container.get_children():
			if not is_instance_valid(ball):
				continue
			if ball.has_method("is_split_twin") and ball.is_split_twin():
				continue
			var def2: Resource = ball.get_definition() if ball.has_method("get_definition") else null
			_accumulate_ball_def_count(counts, def2)
	for def3 in _bag_queue:
		_accumulate_ball_def_count(counts, def3)
	return counts

func get_debug_shop_ball_definitions() -> Array:
	var out: Array = []
	out.append(_plain_ball_def(Constants.ALIGNMENT_MAIN).duplicate(true))
	if _reward_handler and _reward_handler.has_method("get_catalog_ball_definitions"):
		out.append_array(_reward_handler.get_catalog_ball_definitions())
	return out

## Remove one ball matching this definition (bag queue, then hopper, then board). Updates run ability list when last of that ability is gone.
func remove_one_ball_matching_definition(template: BallDefinition) -> bool:
	if not template:
		return false
	var key: String = _ball_catalog_key_from_def(template)
	for i in range(_bag_queue.size()):
		var d: Variant = _bag_queue[i]
		if d is BallDefinition and _ball_catalog_key_from_def(d as BallDefinition) == key:
			_bag_queue.remove_at(i)
			_prune_ball_ability_record_after_remove(key)
			_update_center_ui()
			return true
	var match_pred: Callable = func(ball: Node) -> bool:
		var def: Resource = ball.get_definition() if ball.has_method("get_definition") else null
		if not def is BallDefinition:
			return false
		return _ball_catalog_key_from_def(def as BallDefinition) == key
	if _hopper and _hopper.has_method("remove_and_destroy_one_stored_ball_if"):
		if _hopper.remove_and_destroy_one_stored_ball_if(match_pred):
			_prune_ball_ability_record_after_remove(key)
			_update_center_ui()
			return true
	var main: Node = get_parent()
	var board: Node = main.get_node_or_null("Board") if main else null
	if board and board.has_method("remove_and_destroy_one_ball_if"):
		if board.remove_and_destroy_one_ball_if(match_pred):
			_prune_ball_ability_record_after_remove(key)
			_update_center_ui()
			return true
	return false

## Remove one ball with this ability (any tier). Bag, then hopper, then board.
func remove_one_ball_for_ability(ability_ledger_key: String) -> bool:
	var lk: String = ability_ledger_key
	var match_same_ability := func(d: BallDefinition) -> bool:
		return _ball_ability_ledger_key(d) == lk
	for i in range(_bag_queue.size()):
		var d: Variant = _bag_queue[i]
		if d is BallDefinition and match_same_ability.call(d):
			_bag_queue.remove_at(i)
			_prune_ball_ability_record_after_remove(lk + "|1")
			_update_center_ui()
			return true
	var match_pred: Callable = func(ball: Node) -> bool:
		var def: Resource = ball.get_definition() if ball.has_method("get_definition") else null
		if not def is BallDefinition:
			return false
		return match_same_ability.call(def as BallDefinition)
	if _hopper and _hopper.has_method("remove_and_destroy_one_stored_ball_if"):
		if _hopper.remove_and_destroy_one_stored_ball_if(match_pred):
			_prune_ball_ability_record_after_remove(lk + "|1")
			_update_center_ui()
			return true
	var main: Node = get_parent()
	var board: Node = main.get_node_or_null("Board") if main else null
	if board and board.has_method("remove_and_destroy_one_ball_if"):
		if board.remove_and_destroy_one_ball_if(match_pred):
			_prune_ball_ability_record_after_remove(lk + "|1")
			_update_center_ui()
			return true
	return false

func _prune_ball_ability_record_after_remove(catalog_key: String) -> void:
	var ability: String = catalog_key.get_slice("|", 0)
	if ability == "Plain":
		return
	var counts: Dictionary = get_ball_definition_counts()
	for k in counts.keys():
		if String(k).begins_with(ability + "|") and int(counts[k]) > 0:
			return
	if GameState and ability in GameState.ball_ability_names_in_run:
		GameState.ball_ability_names_in_run.erase(ability)

func remove_one_peg_unlock_for_almanac(kind: String) -> bool:
	if not _reward_handler or not _reward_handler.has_method("remove_one_peg_unlock_for_almanac"):
		return false
	return _reward_handler.remove_one_peg_unlock_for_almanac(kind, _board)

func remove_one_wall_break_for_almanac(uid: StringName) -> bool:
	if not _reward_handler or not _reward_handler.has_method("remove_one_almanac_wall_break"):
		return false
	return _reward_handler.remove_one_almanac_wall_break(uid)

func remove_one_boss_for_almanac(uid: StringName) -> bool:
	if not _reward_handler or not _reward_handler.has_method("remove_one_almanac_boss"):
		return false
	return _reward_handler.remove_one_almanac_boss(uid)

func get_bag_count() -> int:
	return _bag_queue.size()

func get_ball_inventory() -> Dictionary:
	var counts: Dictionary = {}
	var main: Node = get_parent()
	var balls_container: Node = main.get_node_or_null("BallsContainer") if main else null
	if not balls_container:
		return counts
	for ball in balls_container.get_children():
		if not is_instance_valid(ball):
			continue
		if ball.has_method("is_split_twin") and ball.is_split_twin():
			continue
		var ball_def: Resource = ball.get_definition() if ball.has_method("get_definition") else null
		var ability: String = "Plain"
		if ball_def is BallDefinition:
			var name_str: String = (ball_def as BallDefinition).ability_name
			ability = name_str if not name_str.is_empty() else "Plain"
		counts[ability] = counts.get(ability, 0) + 1
	return counts

func _update_center_ui() -> void:
	if not _center_panel_ui:
		return
	var wall_hp: int = 200
	var wall_max: int = 200
	if _combat_manager:
		if _combat_manager.has_method("get_wall_hp"):
			wall_hp = _combat_manager.get_wall_hp()
		if _combat_manager.has_method("get_wall_hp_max"):
			wall_max = _combat_manager.get_wall_hp_max()
	if _center_panel_ui.has_method("set_fortification"):
		_center_panel_ui.set_fortification(wall_hp, wall_max)
	if _center_panel_ui.has_method("set_run_gold") and GameState:
		_center_panel_ui.set_run_gold(GameState.run_gold)
	if _center_panel_ui.has_method("set_bag"):
		_center_panel_ui.set_bag(_bag_queue.size())
	var main_energy: int = 0
	if _systems_container:
		var mc: Node = _systems_container.get_node_or_null("MainCannon")
		if mc and mc.has_method("get_current_energy"):
			main_energy = mc.get_current_energy()
	var charge_max: int = Constants.main_cannon_charge_internal()
	if _systems_container:
		var mc: Node = _systems_container.get_node_or_null("MainCannon")
		if mc and mc.has_method("get_charge_threshold"):
			charge_max = mc.get_charge_threshold()
	if _center_panel_ui.has_method("set_charge"):
		_center_panel_ui.set_charge(main_energy, charge_max)
	# Timer display
	if _center_panel_ui.has_method("set_timer") and _combat_manager and _combat_manager.has_method("get_timer_seconds_remaining"):
		_center_panel_ui.set_timer(_combat_manager.get_timer_seconds_remaining())
