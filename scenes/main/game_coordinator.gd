extends Node
## GameCoordinator (§3, §6). Wiring only; no peg buffering (Board does that).
## Runs per-sim-tick order; fixed-step accumulator for slow-mo. Disconnects in _exit_tree.

var _sim_accumulator: float = 0.0
var _sim_tick: int = 0
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

func _ready() -> void:
	_acquire_children()
	_wire_signals()
	GameState.start_run()
	if _hopper and _hopper.has_method("add_balls"):
		_hopper.add_balls(10)

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

func _wire_signals() -> void:
	if _conduit and _conduit.has_signal("ball_entered_board"):
		_conduit.ball_entered_board.connect(_on_ball_entered_board)
	if _board:
		if _board.has_signal("ball_reached_bottom"):
			_board.ball_reached_bottom.connect(_on_ball_reached_bottom)
		if _board.has_signal("ball_exited_board"):
			_board.ball_exited_board.connect(_on_ball_exited_board)
	if _milestone_tracker and _milestone_tracker.has_signal("milestone_reached"):
		_milestone_tracker.milestone_reached.connect(_on_milestone_reached)

func _disconnect_signals() -> void:
	if _conduit and _conduit.has_signal("ball_entered_board"):
		_conduit.ball_entered_board.disconnect(_on_ball_entered_board)
	if _board:
		if _board.has_signal("ball_reached_bottom"):
			_board.ball_reached_bottom.disconnect(_on_ball_reached_bottom)
		if _board.has_signal("ball_exited_board"):
			_board.ball_exited_board.disconnect(_on_ball_exited_board)
	if _milestone_tracker and _milestone_tracker.has_signal("milestone_reached"):
		_milestone_tracker.milestone_reached.disconnect(_on_milestone_reached)

func _process(delta: float) -> void:
	if GameState.paused:
		return
	var step_sec: float = 1.0 / float(Constants.SIM_TICKS_PER_SECOND)
	_sim_accumulator += delta * GameState.sim_speed
	while _sim_accumulator >= step_sec:
		_sim_accumulator -= step_sec
		_run_one_sim_tick()
	# For smooth ball rendering: 1 = just stepped (show new pos), 0 = about to step (show prev pos)
	GameState.sim_step_alpha = 1.0 - clampf(_sim_accumulator / step_sec, 0.0, 1.0)

func _run_one_sim_tick() -> void:
	_sim_tick += 1
	# 1. Conduit: maybe release ball(s)
	if _conduit and _conduit.has_method("request_ball"):
		_conduit.request_ball()
	# 2. Balls step (Board calls step_one_sim_tick for each ball)
	if _board and _board.has_method("run_ball_steps"):
		_board.run_ball_steps(_sim_tick)
	# 3. Board: resolve bottom, emit ball_reached_bottom (Board flushes in flush_tick)
	if _board and _board.has_method("flush_tick"):
		_board.flush_tick(_sim_tick)
	# 4. EnergyManager: route energy, fill pools (driven by ball_reached_bottom signals)
	# 5. Systems: try_fire (called by systems themselves on tick or from manager)
	if _systems_container:
		for child in _systems_container.get_children():
			if child.has_method("sim_tick"):
				child.sim_tick(_sim_tick)
	# 6. CombatManager: apply damage, advance waves
	if _combat_manager and _combat_manager.has_method("sim_tick"):
		_combat_manager.sim_tick(_sim_tick)
	# 7. RunFlow / victory-defeat (handled in rewards_manager on milestone_reached)
	_update_center_ui()

func _on_ball_entered_board(ball: Node) -> void:
	if _board and _board.has_method("spawn_ball_at_start"):
		_board.spawn_ball_at_start(ball)

func _on_ball_reached_bottom(ball_id: int, total_energy_display: int, alignment: int) -> void:
	if _energy_manager and _energy_manager.has_method("on_ball_reached_bottom"):
		_energy_manager.on_ball_reached_bottom(ball_id, total_energy_display, alignment)
	if _milestone_tracker and _milestone_tracker.has_method("add_display_energy"):
		_milestone_tracker.add_display_energy(total_energy_display)

func _on_ball_exited_board(_ball: Node, reason: int) -> void:
	if reason == 1:  # stall_despawn — return ball to hopper (future)
		pass

func _on_milestone_reached(milestone_index: int, total_energy_display: int) -> void:
	if _rewards_manager and _rewards_manager.has_method("on_milestone_reached"):
		_rewards_manager.on_milestone_reached(milestone_index, total_energy_display)

func _update_center_ui() -> void:
	if not _center_panel_ui or not _center_panel_ui.has_method("set_fortification"):
		return
	var wall_hp: int = 100
	if _combat_manager and _combat_manager.has_method("get_wall_hp"):
		wall_hp = _combat_manager.get_wall_hp()
	_center_panel_ui.set_fortification(wall_hp, 100)
	_center_panel_ui.set_health(wall_hp, 100)
	var ball_count: int = _hopper.get_visible_count() if _hopper and _hopper.has_method("get_visible_count") else 0
	_center_panel_ui.set_balls(ball_count, 10)
	var main_energy: int = 0
	if _systems_container:
		var mc: Node = _systems_container.get_node_or_null("MainCannon")
		if mc and mc.has_method("get_current_energy"):
			main_energy = mc.get_current_energy()
	_center_panel_ui.set_charge(main_energy, 80000)
