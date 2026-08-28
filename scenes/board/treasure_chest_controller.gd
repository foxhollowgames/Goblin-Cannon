extends "res://scenes/board/base_board_event_controller.gd"
## Spawns durable treasure chest pegs; breaking one opens the onboard passive upgrade draft.

func _init() -> void:
	active_duration_sec = 120.0
	min_interval_sec = 90.0
	max_interval_sec = 150.0
	event_row_y = 312.0

func _get_rng_salt() -> int:
	return 0x7E5A8E11

func _setup_test_and_intervals() -> void:
	if TestScenario and TestScenario.enabled and TestScenario.treasure_chest_event_fast:
		_time_until_spawn = 1.0
		min_interval_sec = 8.0
		max_interval_sec = 14.0
	if TestScenario and TestScenario.enabled and TestScenario.treasure_chest_event_at_start:
		_time_until_spawn = 0.0
		if TestScenario.treasure_chest_event_fast:
			preview_duration_sec = 1.05

func arm_immediate_spawn_if_test() -> void:
	if not TestScenario or not TestScenario.enabled:
		return
	if TestScenario.treasure_chest_event_at_start:
		_time_until_spawn = 0.0
		if TestScenario.treasure_chest_event_fast:
			min_interval_sec = 8.0
			max_interval_sec = 14.0
			preview_duration_sec = 1.05

func _pick_preview_x() -> float:
	if TestScenario and TestScenario.enabled and TestScenario.treasure_chest_event_force_x >= 0.0:
		return TestScenario.treasure_chest_event_force_x
	return super._pick_preview_x()

func _get_preview_script() -> GDScript:
	return load("res://scenes/board/treasure_chest_preview.gd") as GDScript

func _spawn_event_peg(board: Node2D, pos: Vector2) -> int:
	if board.has_method("spawn_treasure_chest_peg_at"):
		return board.spawn_treasure_chest_peg_at(pos, event_x_min, event_x_max)
	return -1

func _on_event_active_tick(_board: Node2D, peg: Node, frac: float) -> void:
	if peg.has_method("set_treasure_chest_urgency"):
		peg.set_treasure_chest_urgency(frac)

func _on_event_timeout(board: Node2D, peg_id: int) -> void:
	if board.has_method("remove_treasure_chest_peg"):
		board.remove_treasure_chest_peg(peg_id)

func on_treasure_event_ended(claimed: bool) -> void:
	_on_event_ended(claimed)

func _get_next_spawn_interval() -> float:
	if TestScenario and TestScenario.enabled and TestScenario.treasure_chest_event_fast:
		return _rng.randf_range(8.0, 14.0)
	return super._get_next_spawn_interval()
