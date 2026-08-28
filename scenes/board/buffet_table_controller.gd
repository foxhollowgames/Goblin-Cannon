extends "res://scenes/board/base_board_event_controller.gd"
## Halfling Shire only: preview → buffet peg; first ball hit triggers feast sequence on Board.

@export var min_interval_near_boss_sec: float = 18.0
@export var max_interval_near_boss_sec: float = 32.0

func _init() -> void:
	preview_duration_sec = 3.2
	active_duration_sec = 10.0
	min_interval_sec = 55.0
	max_interval_sec = 85.0
	event_row_y = 330.0

func _is_halfling_city() -> bool:
	if not GameState:
		return false
	return GameState.current_city_id == Constants.CITY_INDEX_HALFLING_SHIRE

func _is_event_enabled() -> bool:
	return _is_halfling_city()

func _get_rng_salt() -> int:
	return 0xBFFE7ABE

func _setup_test_and_intervals() -> void:
	if not _is_halfling_city():
		set_process(false)
		return
	if TestScenario and TestScenario.enabled and TestScenario.buffet_table_event_fast:
		_time_until_spawn = 1.0
		min_interval_sec = 6.0
		max_interval_sec = 12.0
		min_interval_near_boss_sec = 4.0
		max_interval_near_boss_sec = 8.0
	if TestScenario and TestScenario.enabled and TestScenario.buffet_table_event_at_start:
		_time_until_spawn = 0.0
		if TestScenario.buffet_table_event_fast:
			preview_duration_sec = 1.05

func arm_immediate_spawn_if_test() -> void:
	if not TestScenario or not TestScenario.enabled:
		return
	if not _is_halfling_city():
		return
	if TestScenario.buffet_table_event_at_start:
		_time_until_spawn = 0.0
		if TestScenario.buffet_table_event_fast:
			min_interval_sec = 6.0
			max_interval_sec = 12.0
			min_interval_near_boss_sec = 4.0
			max_interval_near_boss_sec = 8.0
			preview_duration_sec = 1.05

func _boss_proximity01() -> float:
	var board: Node = get_parent()
	if board == null:
		return 0.0
	var main: Node = board.get_parent()
	if main == null:
		return 0.0
	var cm: Node = main.get_node_or_null("CombatManager")
	if cm == null or not cm.has_method("get_wall_names"):
		return 0.0
	var names: Array = cm.get_wall_names()
	var n: int = names.size()
	if n <= 1:
		return 1.0
	var wi: int = cm.get_current_wall_index() if cm.has_method("get_current_wall_index") else 0
	var wall_t: float = clampf(float(wi) / float(n - 1), 0.0, 1.0)
	var timer_t: float = 0.0
	if cm.has_method("get_timer_seconds_remaining") and cm.has_method("get_wall_hp_max") and cm.has_method("get_wall_hp"):
		var max_hp: int = cm.get_wall_hp_max()
		if max_hp > 0:
			var hp_frac: float = clampf(float(cm.get_wall_hp()) / float(max_hp), 0.0, 1.0)
			timer_t = 1.0 - hp_frac
	return clampf(wall_t * 0.72 + timer_t * 0.28, 0.0, 1.0)

func _pick_interval_range() -> Vector2:
	var u: float = _boss_proximity01()
	var lo: float = lerpf(min_interval_sec, min_interval_near_boss_sec, u)
	var hi: float = lerpf(max_interval_sec, max_interval_near_boss_sec, u)
	return Vector2(lo, hi)

func _pick_preview_x() -> float:
	if TestScenario and TestScenario.enabled and TestScenario.buffet_table_event_force_x >= 0.0:
		return TestScenario.buffet_table_event_force_x
	return super._pick_preview_x()

func _get_preview_script() -> GDScript:
	return load("res://scenes/board/buffet_table_preview.gd") as GDScript

func _spawn_event_peg(board: Node2D, pos: Vector2) -> int:
	if board.has_method("spawn_buffet_table_peg_at"):
		return board.spawn_buffet_table_peg_at(pos, event_x_min, event_x_max)
	return -1

func _on_event_active_tick(board: Node2D, peg: Node, frac: float) -> void:
	if board.has_method("is_buffet_sequence_active") and board.is_buffet_sequence_active():
		return
	if peg.has_method("set_buffet_table_urgency"):
		peg.set_buffet_table_urgency(frac)

func _on_event_timeout(board: Node2D, peg_id: int) -> void:
	if board.has_method("remove_buffet_table_peg"):
		board.remove_buffet_table_peg(peg_id)

func on_buffet_event_ended(claimed: bool) -> void:
	_on_event_ended(claimed)

func _get_next_spawn_interval() -> float:
	if TestScenario and TestScenario.enabled and TestScenario.buffet_table_event_fast:
		return _rng.randf_range(6.0, 12.0)
	var r: Vector2 = _pick_interval_range()
	return _rng.randf_range(r.x, r.y)
