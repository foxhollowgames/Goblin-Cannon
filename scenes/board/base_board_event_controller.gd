class_name BaseBoardEventController
extends Node2D
## BaseBoardEventController: Shared base class for board events.
## Manages state transitions (IDLE -> PREVIEW -> ACTIVE), timers, preview visuals, and RNG.

enum State { IDLE, PREVIEW, ACTIVE }

@export var preview_duration_sec: float = 3.6
@export var active_duration_sec: float = 30.0
@export var min_interval_sec: float = 22.0
@export var max_interval_sec: float = 42.0
@export var event_row_y: float = 368.0
@export var event_x_min: float = 100.0
@export var event_x_max: float = 860.0

var _rng: RandomNumberGenerator
var _rng_ready: bool = false
var _state: int = State.IDLE
var _time_until_spawn: float = 0.0
var _preview_remaining: float = 0.0
var _preview_pos: Vector2 = Vector2.ZERO
var _active_deadline_ms: int = 0
var _active_peg_id: int = -1
var _preview_node: Node2D = null

func _ready() -> void:
	z_index = 40
	set_process(true)
	_setup_test_and_intervals()

func _ensure_rng_ready() -> void:
	if _rng_ready:
		return
	_rng_ready = true
	_rng = RandomNumberGenerator.new()
	_apply_rng_seed()
	_time_until_spawn = _get_next_spawn_interval()

func _apply_rng_seed() -> void:
	var s: int = GameState.run_seed if GameState else 1
	_rng.seed = s ^ _get_rng_salt()

func _get_rng_salt() -> int:
	return 0xB00BE471

func _setup_test_and_intervals() -> void:
	pass

func _is_event_enabled() -> bool:
	return true

func arm_immediate_spawn_if_test() -> void:
	pass

func _process(delta: float) -> void:
	if not _is_event_enabled():
		return
	if not GameState or GameState.paused:
		return
	if GameState.run_flow_state != GameState.RunFlowState.FIGHTING:
		return
	_ensure_rng_ready()
	var board: Node2D = get_parent() as Node2D
	if board == null:
		return
	match _state:
		State.IDLE:
			_tick_idle(delta, board)
		State.PREVIEW:
			_tick_preview(delta, board)
		State.ACTIVE:
			_tick_active(board)

func _tick_idle(delta: float, board: Node2D) -> void:
	_time_until_spawn -= delta
	if _time_until_spawn > 0.0:
		return
	_start_preview(board)

func _pick_preview_x() -> float:
	return _rng.randf_range(event_x_min, event_x_max)

func _get_preview_script() -> GDScript:
	return null

func _start_preview(board: Node2D) -> void:
	var preferred := Vector2(_pick_preview_x(), event_row_y)
	if board.has_method("resolve_milestone_event_position"):
		_preview_pos = board.resolve_milestone_event_position(preferred, event_x_min, event_x_max)
	else:
		_preview_pos = preferred
	_preview_remaining = preview_duration_sec
	_state = State.PREVIEW
	var scr: GDScript = _get_preview_script()
	if scr != null and _preview_node == null:
		_preview_node = Node2D.new()
		_preview_node.set_script(scr)
		add_child(_preview_node)
	if _preview_node:
		_preview_node.position = _preview_pos
		_preview_node.visible = true

func _tick_preview(delta: float, board: Node2D) -> void:
	_preview_remaining -= delta
	if _preview_remaining > 0.0:
		return
	if _preview_node:
		_preview_node.visible = false
	_active_peg_id = _spawn_event_peg(board, _preview_pos)
	if _active_peg_id < 0:
		_reset_to_idle()
		return
	_active_deadline_ms = Time.get_ticks_msec() + int(active_duration_sec * 1000.0)
	_state = State.ACTIVE

func _spawn_event_peg(_board: Node2D, _pos: Vector2) -> int:
	return -1

func _tick_active(board: Node2D) -> void:
	if _active_peg_id < 0:
		return
	var peg: Node = board.get_peg_by_id(_active_peg_id) if board.has_method("get_peg_by_id") else null
	if peg == null or not is_instance_valid(peg):
		if _state == State.ACTIVE:
			_on_event_ended(false)
		return
	var now_ms: int = Time.get_ticks_msec()
	var remain_ms: int = _active_deadline_ms - now_ms
	var frac: float = clampf(float(remain_ms) / (active_duration_sec * 1000.0), 0.0, 1.0)
	_on_event_active_tick(board, peg, frac)
	if now_ms >= _active_deadline_ms:
		_on_event_timeout(board, _active_peg_id)
		_on_event_ended(false)

func _on_event_active_tick(_board: Node2D, _peg: Node, _frac: float) -> void:
	pass

func _on_event_timeout(_board: Node2D, _peg_id: int) -> void:
	pass

func _on_event_ended(_claimed: bool) -> void:
	_state = State.IDLE
	_active_peg_id = -1
	if _preview_node:
		_preview_node.visible = false
	_time_until_spawn = _get_next_spawn_interval()

func _reset_to_idle() -> void:
	_state = State.IDLE
	_active_peg_id = -1
	if _preview_node:
		_preview_node.visible = false
	_time_until_spawn = _get_next_spawn_interval()

func _get_next_spawn_interval() -> float:
	if _rng:
		return _rng.randf_range(min_interval_sec, max_interval_sec)
	return min_interval_sec

func debug_arm_immediate_spawn() -> bool:
	if not GameState:
		return false
	if not _is_event_enabled():
		return false
	if GameState.run_flow_state != GameState.RunFlowState.FIGHTING:
		return false
	if _state != State.IDLE:
		return false
	_ensure_rng_ready()
	_time_until_spawn = 0.0
	return true
