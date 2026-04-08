extends Node2D
## Halfling Shire only: preview → buffet peg; first ball hit triggers feast sequence on Board.

enum _State { IDLE, PREVIEW, ACTIVE }

@export var preview_duration_sec: float = 3.2
@export var active_duration_sec: float = 10.0
@export var min_interval_sec: float = 55.0
@export var max_interval_sec: float = 85.0
## Shortest / longest interval when closest to the boss wall (faster spawns).
@export var min_interval_near_boss_sec: float = 18.0
@export var max_interval_near_boss_sec: float = 32.0
@export var event_row_y: float = 330.0
@export var event_x_min: float = 100.0
@export var event_x_max: float = 860.0

var _rng: RandomNumberGenerator
var _state: int = _State.IDLE
var _time_until_spawn: float = 0.0
var _preview_remaining: float = 0.0
var _preview_pos: Vector2 = Vector2.ZERO
var _active_deadline_ms: int = 0
var _active_peg_id: int = -1
var _preview_node: Node2D

func _ready() -> void:
	z_index = 40
	if not _is_halfling_city():
		set_process(false)
		return
	_rng = RandomNumberGenerator.new()
	_apply_rng_seed()
	_time_until_spawn = _rng.randf_range(min_interval_sec, max_interval_sec)
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
	set_process(true)

func _is_halfling_city() -> bool:
	if not GameState:
		return false
	return GameState.current_city_id == Constants.CITY_INDEX_HALFLING_SHIRE

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

func _apply_rng_seed() -> void:
	var s: int = GameState.run_seed if GameState else 1
	_rng.seed = s ^ 0xBFFE7ABE

## 0 = start of run, 1 = at last wall before boss (all walls cleared → boss).
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

func _process(_delta: float) -> void:
	if not _is_halfling_city():
		return
	if not GameState:
		return
	if GameState.paused:
		return
	if GameState.run_flow_state != GameState.RunFlowState.FIGHTING:
		return
	var board: Node2D = get_parent() as Node2D
	if board == null:
		return
	match _state:
		_State.IDLE:
			_tick_idle(_delta, board)
		_State.PREVIEW:
			_tick_preview(_delta, board)
		_State.ACTIVE:
			_tick_active(board)

func _tick_idle(delta: float, board: Node2D) -> void:
	_time_until_spawn -= delta
	if _time_until_spawn > 0.0:
		return
	_start_preview(board)

func _pick_preview_x() -> float:
	if TestScenario and TestScenario.enabled and TestScenario.buffet_table_event_force_x >= 0.0:
		return TestScenario.buffet_table_event_force_x
	return _rng.randf_range(event_x_min, event_x_max)

func _start_preview(board: Node2D) -> void:
	var preferred := Vector2(_pick_preview_x(), event_row_y)
	if board.has_method("resolve_milestone_event_position"):
		_preview_pos = board.resolve_milestone_event_position(preferred, event_x_min, event_x_max)
	else:
		_preview_pos = preferred
	_preview_remaining = preview_duration_sec
	_state = _State.PREVIEW
	if _preview_node == null:
		var scr: GDScript = load("res://scenes/board/buffet_table_preview.gd") as GDScript
		_preview_node = Node2D.new()
		if scr:
			_preview_node.set_script(scr)
		add_child(_preview_node)
	_preview_node.position = _preview_pos
	_preview_node.visible = true

func _tick_preview(delta: float, board: Node2D) -> void:
	_preview_remaining -= delta
	if _preview_remaining > 0.0:
		return
	if _preview_node:
		_preview_node.visible = false
	if board.has_method("spawn_buffet_table_peg_at"):
		_active_peg_id = board.spawn_buffet_table_peg_at(_preview_pos, event_x_min, event_x_max)
	else:
		_active_peg_id = -1
	if _active_peg_id < 0:
		_reset_to_idle()
		return
	_active_deadline_ms = Time.get_ticks_msec() + int(active_duration_sec * 1000.0)
	_state = _State.ACTIVE

func _tick_active(board: Node2D) -> void:
	if _active_peg_id < 0:
		return
	var peg: Node = board.get_peg_by_id(_active_peg_id) if board.has_method("get_peg_by_id") else null
	if peg == null or not is_instance_valid(peg):
		if _state == _State.ACTIVE:
			on_buffet_event_ended(false)
		return
	if board.has_method("is_buffet_sequence_active") and board.is_buffet_sequence_active():
		return
	var now_ms: int = Time.get_ticks_msec()
	var remain_ms: int = _active_deadline_ms - now_ms
	var frac: float = clampf(float(remain_ms) / (active_duration_sec * 1000.0), 0.0, 1.0)
	if peg.has_method("set_buffet_table_urgency"):
		peg.set_buffet_table_urgency(frac)
	if now_ms >= _active_deadline_ms:
		if board.has_method("remove_buffet_table_peg"):
			board.remove_buffet_table_peg(_active_peg_id)
		on_buffet_event_ended(false)

func on_buffet_event_ended(_claimed: bool) -> void:
	_state = _State.IDLE
	_active_peg_id = -1
	if _preview_node:
		_preview_node.visible = false
	var r: Vector2 = _pick_interval_range()
	_time_until_spawn = _rng.randf_range(r.x, r.y)
	if TestScenario and TestScenario.enabled and TestScenario.buffet_table_event_fast:
		_time_until_spawn = _rng.randf_range(6.0, 12.0)

func _reset_to_idle() -> void:
	_state = _State.IDLE
	_active_peg_id = -1
	if _preview_node:
		_preview_node.visible = false
	var r: Vector2 = _pick_interval_range()
	_time_until_spawn = _rng.randf_range(r.x, r.y)

func debug_arm_immediate_spawn() -> bool:
	if not GameState:
		return false
	if not _is_halfling_city():
		return false
	if GameState.run_flow_state != GameState.RunFlowState.FIGHTING:
		return false
	if _state != _State.IDLE:
		return false
	_time_until_spawn = 0.0
	return true
