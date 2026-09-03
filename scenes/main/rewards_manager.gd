extends Node
## RewardsManager. Milestone rewards (balls + stats), wall-break synergies, and onboard treasure chest.

signal wall_break_reward_completed
signal boss_reward_completed
signal onboard_effect_reward_completed

const REWARD_SLOWMO_DURATION: float = 1.0
const REWARD_SLOWMO_WITH_MODAL_DURATION: float = 5.0
const SLOWMO_TIME_SCALE: float = 0.03

enum RewardType { MILESTONE, WALL_BREAK, BOSS_REWARD, ONBOARD_EFFECT }

var _reward_handler: Node
var _draft_panel: Control
var _major_draft_panel: Control
var _modal_layer: CanvasLayer
var _pending_picks: Array = []
var _reward_flow_id: int = 0
var _pending_rewards: Array = []
var _in_reward_flow: bool = false
var _current_reward_type: RewardType = RewardType.MILESTONE
var _slowmo_end_utime_ms: int = 0
var _slowmo_flow_id_for_timer: int = -1
var _strict_pause_at_utime_ms: int = 0
var _slowmo_modal_start_utime_ms: int = 0
var _peg_selection_overlay: Node2D = null

func _ready() -> void:
	var main: Node = get_parent()
	_reward_handler = main.get_node_or_null("RewardHandler")
	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = 20
	_modal_layer.name = "ModalLayer"
	var draft_scene: PackedScene = load("res://scenes/rewards/reward_draft_panel.tscn") as PackedScene
	if draft_scene:
		_draft_panel = draft_scene.instantiate() as Control
		if _draft_panel and _draft_panel.has_signal("pick_selected"):
			_draft_panel.pick_selected.connect(_on_milestone_pick_selected)
		if _draft_panel and _draft_panel.has_signal("refresh_requested"):
			_draft_panel.refresh_requested.connect(_on_milestone_shop_refresh)
		if _draft_panel and _draft_panel.has_signal("shop_done"):
			_draft_panel.shop_done.connect(_on_milestone_shop_done)
	var major_scene: PackedScene = load("res://scenes/rewards/major_upgrade_draft_panel.tscn") as PackedScene
	if major_scene:
		_major_draft_panel = major_scene.instantiate() as Control
		if _major_draft_panel and _major_draft_panel.has_signal("pick_selected"):
			_major_draft_panel.pick_selected.connect(_on_wall_break_pick_selected)
		if _major_draft_panel and _major_draft_panel.has_signal("draft_skipped"):
			_major_draft_panel.draft_skipped.connect(_on_major_draft_skipped)
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
	if _current_reward_type == RewardType.MILESTONE:
		if not _reward_handler.has_method("get_milestone_reward_picks"):
			_finish_reward_flow()
			return
		_pending_picks = _reward_handler.get_milestone_reward_picks(5)
	elif _current_reward_type == RewardType.BOSS_REWARD:
		if not _reward_handler.has_method("get_boss_upgrade_picks"):
			_finish_reward_flow()
			return
		_pending_picks = _reward_handler.get_boss_upgrade_picks(3)
	elif _current_reward_type == RewardType.ONBOARD_EFFECT:
		if not _reward_handler.has_method("get_onboard_effect_picks"):
			_finish_reward_flow()
			return
		_pending_picks = _reward_handler.get_onboard_effect_picks(3)
	else:
		if not _reward_handler.has_method("get_major_upgrade_picks"):
			_finish_reward_flow()
			return
		_pending_picks = _reward_handler.get_major_upgrade_picks(3)
	GameState.set_run_flow_state(GameState.RunFlowState.REWARD_SLOWMO)
	_slowmo_end_utime_ms = Time.get_ticks_msec() + int(REWARD_SLOWMO_DURATION * 1000.0)
	_slowmo_flow_id_for_timer = _reward_flow_id

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
		if _current_reward_type == RewardType.MILESTONE and _reward_handler.has_method("get_milestone_reward_picks"):
			_pending_picks = _reward_handler.get_milestone_reward_picks(5)
		elif _current_reward_type == RewardType.WALL_BREAK and _reward_handler.has_method("get_major_upgrade_picks"):
			_pending_picks = _reward_handler.get_major_upgrade_picks(3)
		elif _current_reward_type == RewardType.BOSS_REWARD and _reward_handler.has_method("get_boss_upgrade_picks"):
			_pending_picks = _reward_handler.get_boss_upgrade_picks(3)
		elif _current_reward_type == RewardType.ONBOARD_EFFECT and _reward_handler.has_method("get_onboard_effect_picks"):
			_pending_picks = _reward_handler.get_onboard_effect_picks(3)
	if _current_reward_type == RewardType.MILESTONE:
		if _draft_panel and _draft_panel.has_method("show_draft") and not _pending_picks.is_empty():
			call_deferred("_show_milestone_draft")
			_slowmo_modal_start_utime_ms = Time.get_ticks_msec()
			_strict_pause_at_utime_ms = _slowmo_modal_start_utime_ms + int(REWARD_SLOWMO_WITH_MODAL_DURATION * 1000.0)
		else:
			if _pending_picks.size() > 0 and _reward_handler.has_method("apply_milestone_pick"):
				_reward_handler.apply_milestone_pick(_pending_picks[0])
			_finish_reward_flow()
	elif _current_reward_type == RewardType.BOSS_REWARD:
		if _major_draft_panel and _major_draft_panel.has_method("show_draft") and not _pending_picks.is_empty():
			call_deferred("_show_boss_draft")
			_slowmo_modal_start_utime_ms = Time.get_ticks_msec()
			_strict_pause_at_utime_ms = _slowmo_modal_start_utime_ms + int(REWARD_SLOWMO_WITH_MODAL_DURATION * 1000.0)
		else:
			if _pending_picks.size() > 0 and _reward_handler.has_method("apply_boss_upgrade"):
				_reward_handler.apply_boss_upgrade(_pending_picks[0])
			_finish_reward_flow()
	elif _current_reward_type == RewardType.ONBOARD_EFFECT:
		if _major_draft_panel and _major_draft_panel.has_method("show_draft") and not _pending_picks.is_empty():
			call_deferred("_show_onboard_effect_draft")
			_slowmo_modal_start_utime_ms = Time.get_ticks_msec()
			_strict_pause_at_utime_ms = _slowmo_modal_start_utime_ms + int(REWARD_SLOWMO_WITH_MODAL_DURATION * 1000.0)
		else:
			if _pending_picks.size() > 0 and _reward_handler.has_method("apply_major_upgrade"):
				_reward_handler.apply_major_upgrade(_pending_picks[0])
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
		if not shown and _reward_handler and _reward_handler.has_method("apply_milestone_pick"):
			_reward_handler.apply_milestone_pick(_pending_picks[0])
			_finish_reward_flow()
	else:
		if _pending_picks.size() > 0 and _reward_handler and _reward_handler.has_method("apply_milestone_pick"):
			_reward_handler.apply_milestone_pick(_pending_picks[0])
			_finish_reward_flow()

func _show_onboard_effect_draft() -> void:
	if _draft_panel:
		_draft_panel.hide()
	if _major_draft_panel and not _pending_picks.is_empty():
		if _major_draft_panel.has_method("set_show_skip_visible"):
			_major_draft_panel.set_show_skip_visible(true)
		if _major_draft_panel.has_method("set_title"):
			_major_draft_panel.set_title("Treasure found \u2013 Choose an onboard upgrade")
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

func _show_wall_break_draft() -> void:
	if _draft_panel:
		_draft_panel.hide()
	if _major_draft_panel and not _pending_picks.is_empty():
		if _major_draft_panel.has_method("set_show_skip_visible"):
			_major_draft_panel.set_show_skip_visible(false)
		if _major_draft_panel.has_method("set_title"):
			_major_draft_panel.set_title("Conquest reward \u2013 Choose a major upgrade")
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

func _show_boss_draft() -> void:
	if _draft_panel:
		_draft_panel.hide()
	if _major_draft_panel and not _pending_picks.is_empty():
		if _major_draft_panel.has_method("set_show_skip_visible"):
			_major_draft_panel.set_show_skip_visible(false)
		if _major_draft_panel.has_method("set_title"):
			_major_draft_panel.set_title("City conquered! Choose a boss amplifier")
		if _modal_layer:
			_modal_layer.move_child(_major_draft_panel, _modal_layer.get_child_count() - 1)
		_major_draft_panel.z_index = 100
		_major_draft_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		var shown: bool = _major_draft_panel.show_draft(_pending_picks)
		_major_draft_panel.visible = true
		if not shown and _reward_handler and _reward_handler.has_method("apply_boss_upgrade"):
			_reward_handler.apply_boss_upgrade(_pending_picks[0])
			_finish_reward_flow()
	else:
		if _pending_picks.size() > 0 and _reward_handler and _reward_handler.has_method("apply_boss_upgrade"):
			_reward_handler.apply_boss_upgrade(_pending_picks[0])
			_finish_reward_flow()

func _on_milestone_shop_refresh() -> void:
	if not _in_reward_flow or _current_reward_type != RewardType.MILESTONE:
		return
	if not GameState or GameState.run_gold < Constants.SHOP_REFRESH_COST:
		return
	GameState.add_run_gold(-Constants.SHOP_REFRESH_COST)
	if _reward_handler and _reward_handler.has_method("get_milestone_reward_picks"):
		_pending_picks = _reward_handler.get_milestone_reward_picks(5)
	if _draft_panel and _draft_panel.has_method("show_draft") and not _pending_picks.is_empty():
		_draft_panel.show_draft(_pending_picks)

func _on_milestone_pick_selected(pick: Resource) -> void:
	if _reward_handler and _reward_handler.has_method("apply_milestone_pick"):
		_reward_handler.apply_milestone_pick(pick)
	if _current_reward_type == RewardType.MILESTONE and _reward_handler and _reward_handler.has_method("has_pending_peg_selection") and _reward_handler.has_pending_peg_selection():
		var kind: String = _reward_handler.get_pending_peg_kind()
		_reward_handler.clear_pending_peg_selection()
		if _start_peg_selection(kind) and _draft_panel and _draft_panel.has_method("hide_overlay_for_board_interaction"):
			_draft_panel.hide_overlay_for_board_interaction()

func _on_milestone_shop_done() -> void:
	if _draft_panel and _draft_panel.visible:
		_draft_panel.hide()
	_finish_reward_flow()

func _on_major_draft_skipped() -> void:
	if _current_reward_type != RewardType.ONBOARD_EFFECT:
		return
	_finish_reward_flow()

func _on_wall_break_pick_selected(pick: Resource) -> void:
	if _current_reward_type == RewardType.BOSS_REWARD:
		if _reward_handler and _reward_handler.has_method("apply_boss_upgrade"):
			_reward_handler.apply_boss_upgrade(pick)
		_finish_reward_flow()
		return
	if _current_reward_type == RewardType.ONBOARD_EFFECT:
		if _reward_handler and _reward_handler.has_method("apply_major_upgrade"):
			_reward_handler.apply_major_upgrade(pick)
		_finish_reward_flow()
		return
	if _reward_handler and _reward_handler.has_method("apply_major_upgrade"):
		_reward_handler.apply_major_upgrade(pick)
	if _reward_handler and _reward_handler.has_method("has_pending_peg_selection") and _reward_handler.has_pending_peg_selection():
		var kind: String = _reward_handler.get_pending_peg_kind()
		_reward_handler.clear_pending_peg_selection()
		_start_peg_selection(kind)
		return
	_finish_reward_flow()

func _finish_reward_flow() -> void:
	var was_wall_break: bool = (_current_reward_type == RewardType.WALL_BREAK)
	var was_boss: bool = (_current_reward_type == RewardType.BOSS_REWARD)
	var was_onboard: bool = (_current_reward_type == RewardType.ONBOARD_EFFECT)
	_pending_picks.clear()
	_in_reward_flow = false
	_strict_pause_at_utime_ms = 0
	_slowmo_modal_start_utime_ms = 0
	GameState.set_run_flow_state(GameState.RunFlowState.FIGHTING)
	if was_boss:
		boss_reward_completed.emit()
	elif was_wall_break:
		wall_break_reward_completed.emit()
	elif was_onboard:
		onboard_effect_reward_completed.emit()
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

func on_boss_reward() -> void:
	_pending_rewards.append(RewardType.BOSS_REWARD)
	if not _in_reward_flow:
		call_deferred("_start_reward_flow")

func on_onboard_effect() -> void:
	_pending_rewards.append(RewardType.ONBOARD_EFFECT)
	if not _in_reward_flow:
		call_deferred("_start_reward_flow")

## Debug: close draft UI and clear queues without emitting completion signals (no wall/city advancement).
func debug_discard_open_reward_ui() -> void:
	_pending_rewards.clear()
	_pending_picks.clear()
	_in_reward_flow = false
	_strict_pause_at_utime_ms = 0
	_slowmo_modal_start_utime_ms = 0
	_slowmo_flow_id_for_timer = -1
	Engine.time_scale = 1.0
	if GameState:
		GameState.set_run_flow_state(GameState.RunFlowState.FIGHTING)
	if _draft_panel:
		if _draft_panel.has_method("hide"):
			_draft_panel.hide()
		else:
			_draft_panel.visible = false
	if _major_draft_panel:
		if _major_draft_panel.has_method("hide"):
			_major_draft_panel.hide()
		else:
			_major_draft_panel.visible = false
	if is_instance_valid(_peg_selection_overlay):
		_peg_selection_overlay.queue_free()
		_peg_selection_overlay = null

func _start_peg_selection(kind: String) -> bool:
	var main: Node = get_parent()
	var board: Node = main.get_node_or_null("Board") if main else null
	if not board:
		_finish_reward_flow()
		return false
	# Fallback: if no normal pegs are available, auto-place randomly
	if board.has_method("get_nearest_normal_peg_id") and board.get_nearest_normal_peg_id(Vector2(480, 400), 9999.0) < 0:
		if board.has_method("add_extra_pegs_if_needed"):
			board.add_extra_pegs_if_needed()
		_finish_reward_flow()
		return false
	var overlay_script: GDScript = load("res://scenes/board/peg_selection_overlay.gd") as GDScript
	if not overlay_script:
		_finish_reward_flow()
		return false
	_peg_selection_overlay = Node2D.new()
	_peg_selection_overlay.set_script(overlay_script)
	_peg_selection_overlay.setup(board, kind)
	_peg_selection_overlay.peg_selected.connect(_on_peg_selection_completed)
	main.add_child(_peg_selection_overlay)
	return true

func _on_peg_selection_completed(_peg_id: int) -> void:
	_peg_selection_overlay = null
	if _current_reward_type == RewardType.MILESTONE:
		if _draft_panel and _draft_panel.has_method("restore_overlay_after_board_interaction"):
			_draft_panel.restore_overlay_after_board_interaction()
		return
	_finish_reward_flow()
