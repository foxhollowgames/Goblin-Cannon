extends Node
## GameCoordinator (§3, §6). Wiring only; no peg buffering (Board does that).
## Runs per-sim-tick order; fixed-step accumulator for slow-mo. Disconnects in _exit_tree.

## Starting ball mix: main cannon, sidearm, shield (no attributes).
const START_MAIN: int = 8
const START_SIDEARM: int = 2
const START_SHIELD: int = 2
## Max balls in the hopper; excess is stored in the bag and refills when hopper drops below this.
const HOPPER_MAX_BALLS: int = 100

var _sim_tick: int = 0
var _sim_accumulator: float = 0.0  ## §1.10: fixed-step for slow-mo; add delta * sim_speed * SIM_TICKS_PER_SECOND, run one step when >= 1
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # So we can receive P to unpause when tree is paused
	_acquire_children()
	_wire_signals()
	if _debug_overlay:
		_debug_overlay.visible = false  # Overlay only shown when pressing D
	GameState.start_run()
	_init_from_current_city()
	# Defer so Hopper and Board have run _ready() before we add balls and spawn
	call_deferred("_spawn_initial_balls")

func _init_from_current_city() -> void:
	var city: CityDefinition = GameState.get_current_city_definition()
	if city == null:
		return
	if _combat_manager and _combat_manager.has_method("init_from_city"):
		_combat_manager.init_from_city(city)
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

func _spawn_initial_balls() -> void:
	# 8 main cannon, 2 sidearm, 2 shield; no attributes (plain BallDefinitions).
	var main_def: BallDefinition = _plain_ball_def(Constants.ALIGNMENT_MAIN)
	var sidearm_def: BallDefinition = _plain_ball_def(Constants.ALIGNMENT_SIDEARM)
	var shield_def: BallDefinition = _plain_ball_def(Constants.ALIGNMENT_DEFENSE)
	var total: int = START_MAIN + START_SIDEARM + START_SHIELD
	var in_hopper: int = _hopper.get_stored_ball_count() if _hopper and _hopper.has_method("get_stored_ball_count") else 0
	var room: int = HOPPER_MAX_BALLS - in_hopper
	var added: int = 0
	if _hopper and _hopper.has_method("add_balls_with_definition"):
		var to_hopper_main: int = mini(START_MAIN, room)
		if to_hopper_main > 0:
			_hopper.add_balls_with_definition(to_hopper_main, main_def)
			room -= to_hopper_main
			added += to_hopper_main
		var to_hopper_sidearm: int = mini(START_SIDEARM, room)
		if to_hopper_sidearm > 0:
			_hopper.add_balls_with_definition(to_hopper_sidearm, sidearm_def)
			room -= to_hopper_sidearm
			added += to_hopper_sidearm
		var to_hopper_shield: int = mini(START_SHIELD, room)
		if to_hopper_shield > 0:
			_hopper.add_balls_with_definition(to_hopper_shield, shield_def)
			room -= to_hopper_shield
			added += to_hopper_shield
	_bag_count += (total - added)

## Plain ball definition for starting balls: no ability, default energy, rarity 0, alignment-based shape.
func _plain_ball_def(alignment: int) -> BallDefinition:
	var d: BallDefinition = BallDefinition.new()
	d.ability_name = ""
	d.base_energy = 20
	d.city_weights = {}
	d.alignment = alignment
	d.rarity = 0
	d.shape_type = -1
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
	if _milestone_tracker and _milestone_tracker.has_signal("milestone_reached"):
		_milestone_tracker.milestone_reached.connect(_on_milestone_reached)
	if _combat_manager and _combat_manager.has_signal("wall_destroyed"):
		_combat_manager.wall_destroyed.connect(_on_wall_destroyed)
	if _rewards_manager and _rewards_manager.has_signal("wall_break_reward_completed"):
		_rewards_manager.wall_break_reward_completed.connect(_on_wall_break_reward_completed)
	if _energy_router and _energy_router.has_signal("energy_allocated"):
		_energy_router.energy_allocated.connect(_on_energy_allocated_vfx)
	if _battlefield and _battlefield.has_signal("status_effect_applied") and _debug_overlay and _debug_overlay.has_method("add_status_alert"):
		_battlefield.status_effect_applied.connect(_debug_overlay.add_status_alert)

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
	if _milestone_tracker and _milestone_tracker.has_signal("milestone_reached"):
		_milestone_tracker.milestone_reached.disconnect(_on_milestone_reached)
	if _combat_manager and _combat_manager.has_signal("wall_destroyed"):
		_combat_manager.wall_destroyed.disconnect(_on_wall_destroyed)
	if _rewards_manager and _rewards_manager.has_signal("wall_break_reward_completed") and _rewards_manager.wall_break_reward_completed.is_connected(_on_wall_break_reward_completed):
		_rewards_manager.wall_break_reward_completed.disconnect(_on_wall_break_reward_completed)
	if _energy_router and _energy_router.has_signal("energy_allocated"):
		_energy_router.energy_allocated.disconnect(_on_energy_allocated_vfx)
	if _battlefield and _debug_overlay and _battlefield.has_signal("status_effect_applied") and _battlefield.status_effect_applied.is_connected(_debug_overlay.add_status_alert):
		_battlefield.status_effect_applied.disconnect(_debug_overlay.add_status_alert)

## §1.10: Fixed-step accumulator. When sim_speed < 1 (e.g. REWARD_SLOWMO), run fewer sim steps per real second.
## When tree is paused (P key), skip sim entirely so minions/pegs/balls don't advance.
func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	if GameState.paused:
		return
	_sim_accumulator += delta * GameState.sim_speed * float(Constants.SIM_TICKS_PER_SECOND)
	var max_steps: int = 4  # avoid spiral of death on hitches
	while _sim_accumulator >= 1.0 and max_steps > 0:
		_run_one_sim_tick()
		_sim_accumulator -= 1.0
		max_steps -= 1
	GameState.sim_step_alpha = clampf(_sim_accumulator, 0.0, 1.0)

func _run_one_sim_tick() -> void:
	_sim_tick += 1
	# 1. Refill hopper from bag when below 100 (balls spawn above hopper). Only when gate is closed so the new ball lands in the bin instead of falling through and being lost.
	if _hopper and _hopper.has_method("get_stored_ball_count") and _hopper.get_stored_ball_count() < HOPPER_MAX_BALLS and _bag_count > 0:
		var gate_open: bool = _hopper.is_gate_open() if _hopper.has_method("is_gate_open") else false
		if not gate_open and _hopper.has_method("add_balls"):
			_hopper.add_balls(1)
			_bag_count -= 1
	# 2. Conduit: maybe release ball(s)
	if _conduit and _conduit.has_method("request_ball"):
		_conduit.request_ball()
	# 3. Balls step (Board calls step_one_sim_tick for each ball)
	if _board and _board.has_method("run_ball_steps"):
		_board.run_ball_steps(_sim_tick)
	# 4. Board: resolve bottom, emit ball_reached_bottom (Board flushes in flush_tick)
	if _board and _board.has_method("flush_tick"):
		_board.flush_tick(_sim_tick)
	# 5. EnergyManager: route energy, fill pools (driven by ball_reached_bottom signals)
	# 6. Systems: try_fire (called by systems themselves on tick or from manager)
	if _systems_container:
		for child in _systems_container.get_children():
			if child.has_method("sim_tick"):
				child.sim_tick(_sim_tick)
	# 7. CombatManager: apply damage, advance waves
	if _combat_manager and _combat_manager.has_method("sim_tick"):
		_combat_manager.sim_tick(_sim_tick)
	# 8. RunFlow / victory-defeat (handled in rewards_manager on milestone_reached)
	_update_center_ui()

func _on_ball_entered_board(ball: Node) -> void:
	if _board and _board.has_method("spawn_ball_at_start"):
		_board.spawn_ball_at_start(ball)

func _on_ball_reached_bottom(ball_id: int, total_energy_display: int, alignment: int, exit_position: Vector2 = Vector2.ZERO, status_effects: Dictionary = {}) -> void:
	_pending_energy_vfx_positions.append(exit_position)
	_pending_energy_alignments.append(alignment)
	if _energy_manager and _energy_manager.has_method("on_ball_reached_bottom"):
		_energy_manager.on_ball_reached_bottom(ball_id, total_energy_display, alignment)
	if _milestone_tracker and _milestone_tracker.has_method("add_display_energy"):
		_milestone_tracker.add_display_energy(total_energy_display)
	# GDD §8: ball ability on ball_reached_bottom — apply status to frontmost minion
	if not status_effects.is_empty() and _combat_manager and _combat_manager.has_method("apply_ball_status"):
		_combat_manager.apply_ball_status(status_effects, "ball_reached_bottom")

func _on_ball_ability_on_peg_hit(status_effects: Dictionary) -> void:
	if status_effects.is_empty() or not _combat_manager or not _combat_manager.has_method("apply_ball_status"):
		return
	_combat_manager.apply_ball_status(status_effects, "peg_hit")

func _on_ball_exited_board(ball: Node, reason: int) -> void:
	# reason 0 = REASON_BOTTOM, 1 = REASON_STALL, 2 = REASON_OFF_SCREEN
	if reason == 1:  # stall_despawn — return ball to hopper (future)
		pass
		return
	var in_hopper: int = _hopper.get_stored_ball_count() if _hopper and _hopper.has_method("get_stored_ball_count") else 0
	var gate_open: bool = _hopper.is_gate_open() if _hopper and _hopper.has_method("is_gate_open") else false
	# Only return ball to hopper when gate is closed; otherwise it would fall through and be lost.
	if in_hopper < HOPPER_MAX_BALLS and not gate_open and _hopper and _hopper.has_method("return_ball"):
		_hopper.return_ball(ball)
		return
	# Hopper full or gate open: put ball back into the bag (count only; ball node is freed)
	_bag_count += 1
	ball.queue_free()

## Add balls to reserve: fill hopper up to HOPPER_MAX_BALLS, put the rest in the bag. Used by initial spawn and rewards.
func add_balls_to_reserve(count: int) -> void:
	if count <= 0:
		return
	var in_hopper: int = _hopper.get_stored_ball_count() if _hopper and _hopper.has_method("get_stored_ball_count") else 0
	var room: int = HOPPER_MAX_BALLS - in_hopper
	var to_hopper: int = mini(count, room)
	if to_hopper > 0 and _hopper and _hopper.has_method("add_balls"):
		_hopper.add_balls(to_hopper)
	_bag_count += (count - to_hopper)

func _on_energy_allocated_vfx(main_internal: int, sidearm_internal: int, shield_internal: int) -> void:
	var pos: Vector2 = _pending_energy_vfx_positions.pop_front() if _pending_energy_vfx_positions.size() > 0 else Vector2(480, 600)
	var alignment: int = _pending_energy_alignments.pop_front() if _pending_energy_alignments.size() > 0 else 0
	if _center_panel_ui and _center_panel_ui.has_method("show_energy_gain"):
		_center_panel_ui.show_energy_gain(main_internal, sidearm_internal, shield_internal, pos, alignment)

func _on_milestone_reached(milestone_index: int, total_energy_display: int) -> void:
	if _rewards_manager and _rewards_manager.has_method("on_milestone_reached"):
		_rewards_manager.on_milestone_reached(milestone_index, total_energy_display)

func _on_wall_destroyed() -> void:
	if _rewards_manager and _rewards_manager.has_method("on_wall_break"):
		_rewards_manager.on_wall_break()
	# Do not advance here — wall stays at 0/100 until player completes reward; then _on_wall_break_reward_completed advances and refreshes.

func _on_wall_break_reward_completed() -> void:
	if _combat_manager and _combat_manager.has_method("advance_to_next_wall"):
		_combat_manager.advance_to_next_wall()
	_refresh_conquest_ui()
	_sync_battlefield_wall_index()

func _update_center_ui() -> void:
	if not _center_panel_ui or not _center_panel_ui.has_method("set_fortification"):
		return
	var wall_hp: int = 100
	var wall_max: int = 100
	var cannon_hp: int = 100
	var cannon_max: int = 100
	if _combat_manager:
		if _combat_manager.has_method("get_wall_hp"):
			wall_hp = _combat_manager.get_wall_hp()
		if _combat_manager.has_method("get_wall_hp_max"):
			wall_max = _combat_manager.get_wall_hp_max()
		if _combat_manager.has_method("get_cannon_hp"):
			cannon_hp = _combat_manager.get_cannon_hp()
		if _combat_manager.has_method("get_cannon_hp_max"):
			cannon_max = _combat_manager.get_cannon_hp_max()
	_center_panel_ui.set_fortification(wall_hp, wall_max)
	_center_panel_ui.set_health(cannon_hp, cannon_max)
	var ball_count: int = _hopper.get_visible_count() if _hopper and _hopper.has_method("get_visible_count") else 0
	_center_panel_ui.set_balls(ball_count, HOPPER_MAX_BALLS)
	if _center_panel_ui.has_method("set_bag"):
		_center_panel_ui.set_bag(_bag_count)
	var main_energy: int = 0
	var shield_points: int = 0
	var sidearm_energy: int = 0
	if _systems_container:
		var mc: Node = _systems_container.get_node_or_null("MainCannon")
		if mc and mc.has_method("get_current_energy"):
			main_energy = mc.get_current_energy()
		var sp: Node = _systems_container.get_node_or_null("ShieldPool")
		if sp and sp.has_method("get_current_shield_points"):
			shield_points = sp.get_current_shield_points()
		var sidearms: Node = _systems_container.get_node_or_null("Sidearms")
		if sidearms:
			var pool: Node = sidearms.get_node_or_null("SidearmPool")
			if pool and pool.has_method("get_current_energy"):
				sidearm_energy = pool.get_current_energy()
	_center_panel_ui.set_charge(main_energy, 80000)
	if _center_panel_ui.has_method("set_shield"):
		_center_panel_ui.set_shield(shield_points)
	if _center_panel_ui.has_method("set_sidearm"):
		_center_panel_ui.set_sidearm(sidearm_energy / 100)
	if _center_panel_ui.has_method("set_next_bonus") and _milestone_tracker and _milestone_tracker.has_method("get_total_display") and _milestone_tracker.has_method("get_next_threshold"):
		_center_panel_ui.set_next_bonus(_milestone_tracker.get_total_display(), _milestone_tracker.get_next_threshold())
	# Update cannon shield visual on battlefield
	var battlefield: Node = get_parent().get_node_or_null("CombatContainer/BattlefieldView") if get_parent() else null
	if battlefield and battlefield.has_method("set_cannon_shield"):
		battlefield.set_cannon_shield(shield_points)
