extends "res://scenes/board/base_board_event_controller.gd"
## Schedules milestone board events: preview VFX → timed peg → reward or despawn.

func _get_rng_salt() -> int:
	return 0xB00BE471

func _setup_test_and_intervals() -> void:
	_time_until_spawn = min_interval_sec
	if TestScenario and TestScenario.enabled and TestScenario.board_event_fast:
		_time_until_spawn = 1.0
		min_interval_sec = 3.0
		max_interval_sec = 5.0
	if TestScenario and TestScenario.enabled and TestScenario.board_event_at_start:
		_time_until_spawn = 0.0
		if TestScenario.board_event_fast:
			preview_duration_sec = 1.05

func arm_immediate_spawn_if_test() -> void:
	if not TestScenario or not TestScenario.enabled:
		return
	if TestScenario.board_event_at_start:
		_time_until_spawn = 0.0
		if TestScenario.board_event_fast:
			min_interval_sec = 3.0
			max_interval_sec = 5.0
			preview_duration_sec = 1.05

func _pick_preview_x() -> float:
	if TestScenario and TestScenario.enabled and TestScenario.board_event_force_x >= 0.0:
		return TestScenario.board_event_force_x
	return super._pick_preview_x()

func _get_preview_script() -> GDScript:
	return load("res://scenes/board/board_event_preview.gd") as GDScript

func _spawn_event_peg(board: Node2D, pos: Vector2) -> int:
	return board.spawn_milestone_event_peg_at(pos, event_x_min, event_x_max)

func _on_event_active_tick(_board: Node2D, peg: Node, frac: float) -> void:
	if peg.has_method("set_milestone_event_urgency"):
		peg.set_milestone_event_urgency(frac)

func _on_event_timeout(board: Node2D, peg_id: int) -> void:
	board.remove_milestone_event_peg(peg_id)

func on_milestone_event_ended(claimed: bool) -> void:
	_on_event_ended(claimed)

func _get_next_spawn_interval() -> float:
	if TestScenario and TestScenario.enabled and TestScenario.board_event_fast:
		return _rng.randf_range(3.0, 5.0)
	return super._get_next_spawn_interval()
