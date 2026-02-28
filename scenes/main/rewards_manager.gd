extends Node
## RewardsManager (§6). Milestone = balls + stats (GDD §12). Wall break = major upgrades (GDD conquest/boss).

signal wall_break_reward_completed  ## Emitted when the player has finished the wall-break draft; coordinator advances to next wall.

## GDD §1.10: brief slow-mo so player sees the milestone, then show modal; slow-mo continues for this long, then strict pause for picks.
const REWARD_SLOWMO_DURATION: float = 1.0
const REWARD_SLOWMO_WITH_MODAL_DURATION: float = 5.0  ## Slow-mo degrades to full pause over this many real seconds while modal is open.
const SLOWMO_TIME_SCALE: float = 0.03  ## Match GameState; start of ramp to pause.

enum RewardType { MILESTONE, WALL_BREAK }

var _reward_handler: Node
var _draft_panel: Control
var _major_draft_panel: Control
var _modal_layer: CanvasLayer  ## Dedicated layer so modals always draw on top (layer=10)
var _pending_picks: Array = []
var _reward_flow_id: int = 0
## GDD §6.9: drain one at a time. Queue reward type so milestone (balls+stats) ≠ wall_break (major upgrades).
var _pending_rewards: Array = []  # [RewardType.MILESTONE, RewardType.WALL_BREAK, ...]
var _in_reward_flow: bool = false
var _current_reward_type: RewardType = RewardType.MILESTONE
## Real-time end of slow-mo (ms); Engine.time_scale is 0.03 during slow-mo so we must not use create_timer.
var _slowmo_end_utime_ms: int = 0
var _slowmo_flow_id_for_timer: int = -1
## After modal is shown, strict pause at this time (ms). 0 = not set.
var _strict_pause_at_utime_ms: int = 0
## When the "modal open + ramp to pause" phase started (ms); used to lerp time_scale.
var _slowmo_modal_start_utime_ms: int = 0

func _ready() -> void:
	var main: Node = get_parent()
	_reward_handler = main.get_node_or_null("RewardHandler")
	# Create modal layer and panels; add them deferred so we don't add_child during parent's _ready()
	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = 10
	_modal_layer.name = "ModalLayer"
	var draft_scene: PackedScene = load("res://scenes/rewards/reward_draft_panel.tscn") as PackedScene
	if draft_scene:
		_draft_panel = draft_scene.instantiate() as Control
		if _draft_panel and _draft_panel.has_signal("pick_selected"):
			_draft_panel.pick_selected.connect(_on_milestone_pick_selected)
	var major_scene: PackedScene = load("res://scenes/rewards/major_upgrade_draft_panel.tscn") as PackedScene
	if major_scene:
		_major_draft_panel = major_scene.instantiate() as Control
		if _major_draft_panel and _major_draft_panel.has_signal("pick_selected"):
			_major_draft_panel.pick_selected.connect(_on_wall_break_pick_selected)
	call_deferred("_add_modal_layer_and_panels")

func _add_modal_layer_and_panels() -> void:
	var main: Node = get_parent()
	if not is_node_ready() or not main:
		return
	main.add_child(_modal_layer)
	if _draft_panel:
		_modal_layer.add_child(_draft_panel)
	if _major_draft_panel:
		_modal_layer.add_child(_major_draft_panel)

func _start_reward_flow() -> void:
	if _in_reward_flow:
		return
	if _pending_rewards.is_empty():
		return
	_current_reward_type = _pending_rewards.pop_front()
	if not _reward_handler:
		_finish_reward_flow()
		return
	_in_reward_flow = true
	_reward_flow_id += 1
	var flow_id: int = _reward_flow_id
	if _current_reward_type == RewardType.MILESTONE:
		if not _reward_handler.has_method("get_ball_reward_picks"):
			_finish_reward_flow()
			return
		_pending_picks = _reward_handler.get_ball_reward_picks(3)
	else:
		if not _reward_handler.has_method("get_major_upgrade_picks"):
			_finish_reward_flow()
			return
		_pending_picks = _reward_handler.get_major_upgrade_picks(3)
	GameState.set_run_flow_state(GameState.RunFlowState.REWARD_SLOWMO)
	_slowmo_end_utime_ms = Time.get_ticks_msec() + int(REWARD_SLOWMO_DURATION * 1000.0)
	_slowmo_flow_id_for_timer = flow_id

func _process(_delta: float) -> void:
	if not _in_reward_flow or GameState.run_flow_state != GameState.RunFlowState.REWARD_SLOWMO:
		return
	var now_ms: int = Time.get_ticks_msec()
	if _strict_pause_at_utime_ms > 0:
		var duration_ms: int = _strict_pause_at_utime_ms - _slowmo_modal_start_utime_ms
		var elapsed_ms: int = now_ms - _slowmo_modal_start_utime_ms
		var progress: float = 1.0 if duration_ms <= 0 else clampf(float(elapsed_ms) / float(duration_ms), 0.0, 1.0)
		Engine.time_scale = lerpf(SLOWMO_TIME_SCALE, 0.0, progress)
		if now_ms >= _strict_pause_at_utime_ms:
			GameState.set_run_flow_state(GameState.RunFlowState.REWARD_PAUSED)
			_strict_pause_at_utime_ms = 0
			_slowmo_modal_start_utime_ms = 0
	elif now_ms >= _slowmo_end_utime_ms:
		_on_slowmo_finished(_slowmo_flow_id_for_timer)

func _on_slowmo_finished(flow_id: int) -> void:
	if flow_id != _reward_flow_id:
		return
	if _pending_picks.is_empty() and _reward_handler:
		if _current_reward_type == RewardType.MILESTONE and _reward_handler.has_method("get_ball_reward_picks"):
			_pending_picks = _reward_handler.get_ball_reward_picks(3)
		elif _current_reward_type == RewardType.WALL_BREAK and _reward_handler.has_method("get_major_upgrade_picks"):
			_pending_picks = _reward_handler.get_major_upgrade_picks(3)
	# Show modal but stay in REWARD_SLOWMO for REWARD_SLOWMO_WITH_MODAL_DURATION, then strict pause
	if _current_reward_type == RewardType.MILESTONE:
		if _draft_panel and _draft_panel.has_method("show_draft") and not _pending_picks.is_empty():
			call_deferred("_show_milestone_draft")
			_slowmo_modal_start_utime_ms = Time.get_ticks_msec()
			_strict_pause_at_utime_ms = _slowmo_modal_start_utime_ms + int(REWARD_SLOWMO_WITH_MODAL_DURATION * 1000.0)
		else:
			if _pending_picks.size() > 0 and _reward_handler.has_method("apply_ball_pick"):
				_reward_handler.apply_ball_pick(_pending_picks[0])
			_finish_reward_flow()
	else:
		if _major_draft_panel and _major_draft_panel.has_method("show_draft") and not _pending_picks.is_empty():
			call_deferred("_show_wall_break_draft")
			_slowmo_modal_start_utime_ms = Time.get_ticks_msec()
			_strict_pause_at_utime_ms = _slowmo_modal_start_utime_ms + int(REWARD_SLOWMO_WITH_MODAL_DURATION * 1000.0)
		else:
			if _pending_picks.size() > 0 and _reward_handler.has_method("apply_major_upgrade"):
				_reward_handler.apply_major_upgrade(_pending_picks[0])
			_finish_reward_flow()

func _show_milestone_draft() -> void:
	if _major_draft_panel:
		_major_draft_panel.hide()
	if _draft_panel and not _pending_picks.is_empty():
		if _modal_layer:
			_modal_layer.move_child(_draft_panel, _modal_layer.get_child_count() - 1)
		_draft_panel.z_index = 100
		_draft_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		var shown: bool = _draft_panel.show_draft(_pending_picks)
		_draft_panel.visible = true
		if not shown and _reward_handler and _reward_handler.has_method("apply_ball_pick"):
			_reward_handler.apply_ball_pick(_pending_picks[0])
			_finish_reward_flow()
	else:
		if _pending_picks.size() > 0 and _reward_handler and _reward_handler.has_method("apply_ball_pick"):
			_reward_handler.apply_ball_pick(_pending_picks[0])
			_finish_reward_flow()

func _show_wall_break_draft() -> void:
	if _draft_panel:
		_draft_panel.hide()
	if _major_draft_panel and not _pending_picks.is_empty():
		if _modal_layer:
			_modal_layer.move_child(_major_draft_panel, _modal_layer.get_child_count() - 1)
		_major_draft_panel.z_index = 100
		_major_draft_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		var shown: bool = _major_draft_panel.show_draft(_pending_picks)
		_major_draft_panel.visible = true
		if not shown and _reward_handler and _reward_handler.has_method("apply_major_upgrade"):
			_reward_handler.apply_major_upgrade(_pending_picks[0])
			_finish_reward_flow()
	else:
		if _pending_picks.size() > 0 and _reward_handler and _reward_handler.has_method("apply_major_upgrade"):
			_reward_handler.apply_major_upgrade(_pending_picks[0])
			_finish_reward_flow()

func _on_milestone_pick_selected(pick: Resource) -> void:
	if _reward_handler and _reward_handler.has_method("apply_ball_pick"):
		_reward_handler.apply_ball_pick(pick)
	if _reward_handler and _reward_handler.has_method("grant_stat_upgrades"):
		_reward_handler.grant_stat_upgrades(2)  # GDD §12: 2 stat upgrades per milestone
	_finish_reward_flow()

func _on_wall_break_pick_selected(pick: Resource) -> void:
	if _reward_handler and _reward_handler.has_method("apply_major_upgrade"):
		_reward_handler.apply_major_upgrade(pick)
	_finish_reward_flow()

func _finish_reward_flow() -> void:
	var was_wall_break: bool = (_current_reward_type == RewardType.WALL_BREAK)
	_pending_picks.clear()
	_in_reward_flow = false
	_strict_pause_at_utime_ms = 0
	_slowmo_modal_start_utime_ms = 0
	GameState.set_run_flow_state(GameState.RunFlowState.FIGHTING)
	if was_wall_break:
		wall_break_reward_completed.emit()
	if not _pending_rewards.is_empty():
		call_deferred("_start_reward_flow")

func on_milestone_reached(_milestone_index: int, _total_energy_display: int) -> void:
	_pending_rewards.append(RewardType.MILESTONE)
	if not _in_reward_flow:
		call_deferred("_start_reward_flow")

func on_wall_break() -> void:
	_pending_rewards.append(RewardType.WALL_BREAK)
	if not _in_reward_flow:
		call_deferred("_start_reward_flow")
