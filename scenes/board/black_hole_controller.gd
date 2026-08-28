extends "res://scenes/board/base_board_event_controller.gd"
## Elf Palace only: preview → large black hole that pulls in balls; consumed balls return to hopper after a delay.

func _init() -> void:
	preview_duration_sec = 3.5
	active_duration_sec = 28.0
	min_interval_sec = 52.0
	max_interval_sec = 82.0
	event_row_y = 368.0

func _is_elf_palace() -> bool:
	if not GameState:
		return false
	return GameState.current_city_id == Constants.CITY_INDEX_ELF_PALACE

func _is_event_enabled() -> bool:
	return _is_elf_palace()

func _get_rng_salt() -> int:
	return 0xB1AC0E

func _setup_test_and_intervals() -> void:
	if TestScenario and TestScenario.enabled and TestScenario.black_hole_event_fast:
		_time_until_spawn = 1.0
		min_interval_sec = 10.0
		max_interval_sec = 16.0
	if TestScenario and TestScenario.enabled and TestScenario.black_hole_event_at_start:
		_time_until_spawn = 0.0
		if TestScenario.black_hole_event_fast:
			preview_duration_sec = 1.05

func arm_immediate_spawn_if_test() -> void:
	if not TestScenario or not TestScenario.enabled:
		return
	if not _is_elf_palace():
		return
	_ensure_rng_ready()
	if TestScenario.black_hole_event_at_start:
		_time_until_spawn = 0.0
		if TestScenario.black_hole_event_fast:
			min_interval_sec = 10.0
			max_interval_sec = 16.0
			preview_duration_sec = 1.05

func _pick_preview_x() -> float:
	if TestScenario and TestScenario.enabled and TestScenario.black_hole_event_force_x >= 0.0:
		return TestScenario.black_hole_event_force_x
	return super._pick_preview_x()

func _get_preview_script() -> GDScript:
	return load("res://scenes/board/black_hole_preview.gd") as GDScript

func _tick_preview(delta: float, board: Node2D) -> void:
	_preview_remaining -= delta
	if _preview_remaining > 0.0:
		return
	if _preview_node:
		_preview_node.visible = false
	if board.has_method("begin_black_hole_event"):
		board.begin_black_hole_event(_preview_pos, active_duration_sec)
	_state = State.ACTIVE

func _tick_active(_board: Node2D) -> void:
	pass

func on_black_hole_event_ended() -> void:
	_on_event_ended(false)

func _get_next_spawn_interval() -> float:
	if TestScenario and TestScenario.enabled and TestScenario.black_hole_event_fast:
		return _rng.randf_range(10.0, 16.0)
	return super._get_next_spawn_interval()
