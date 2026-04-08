extends Node2D
## Elf Palace only: preview → large black hole that pulls in balls; consumed balls return to hopper after a delay.

enum _State { IDLE, PREVIEW, ACTIVE }

@export var preview_duration_sec: float = 3.5
@export var active_duration_sec: float = 28.0
@export var min_interval_sec: float = 52.0
@export var max_interval_sec: float = 82.0
@export var event_row_y: float = 368.0
@export var event_x_min: float = 100.0
@export var event_x_max: float = 860.0

var _rng: RandomNumberGenerator
## Lazily created on first _process while Elf Palace — _ready runs before GameCoordinator applies current_city_id / TestScenario.
var _rng_ready: bool = false
var _state: int = _State.IDLE
var _time_until_spawn: float = 0.0
var _preview_remaining: float = 0.0
var _preview_node: Node2D
var _preview_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	z_index = 40
	## Do not set_process(false) from a wrong city: _ready runs before GameCoordinator sets current_city_id / TestScenario.
	set_process(true)

func _ensure_rng_ready() -> void:
	if _rng_ready:
		return
	_rng_ready = true
	_rng = RandomNumberGenerator.new()
	_apply_rng_seed()
	_time_until_spawn = _rng.randf_range(min_interval_sec, max_interval_sec)
	if TestScenario and TestScenario.enabled and TestScenario.black_hole_event_fast:
		_time_until_spawn = 1.0
		min_interval_sec = 10.0
		max_interval_sec = 16.0
	if TestScenario and TestScenario.enabled and TestScenario.black_hole_event_at_start:
		_time_until_spawn = 0.0
		if TestScenario.black_hole_event_fast:
			preview_duration_sec = 1.05

func _is_elf_palace() -> bool:
	if not GameState:
		return false
	## Authoritative: progression index matches CITY_DEFINITION_PATHS (avoids relying on loaded Resource.city_id alone).
	return GameState.current_city_id == Constants.CITY_INDEX_ELF_PALACE

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

func _apply_rng_seed() -> void:
	var s: int = GameState.run_seed if GameState else 1
	_rng.seed = s ^ 0xB1AC0E

func _process(_delta: float) -> void:
	if not _is_elf_palace():
		return
	if not GameState:
		return
	if GameState.paused:
		return
	if GameState.run_flow_state != GameState.RunFlowState.FIGHTING:
		return
	_ensure_rng_ready()
	var board: Node2D = get_parent() as Node2D
	if board == null:
		return
	match _state:
		_State.IDLE:
			_tick_idle(_delta, board)
		_State.PREVIEW:
			_tick_preview(_delta, board)
		_State.ACTIVE:
			pass

func _tick_idle(delta: float, board: Node2D) -> void:
	_time_until_spawn -= delta
	if _time_until_spawn > 0.0:
		return
	_start_preview(board)

func _pick_preview_x() -> float:
	if TestScenario and TestScenario.enabled and TestScenario.black_hole_event_force_x >= 0.0:
		return TestScenario.black_hole_event_force_x
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
		var scr: GDScript = load("res://scenes/board/black_hole_preview.gd") as GDScript
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
	if board.has_method("begin_black_hole_event"):
		board.begin_black_hole_event(_preview_pos, active_duration_sec)
	_state = _State.ACTIVE

func on_black_hole_event_ended() -> void:
	_state = _State.IDLE
	if _preview_node:
		_preview_node.visible = false
	_time_until_spawn = _rng.randf_range(min_interval_sec, max_interval_sec)
	if TestScenario and TestScenario.enabled and TestScenario.black_hole_event_fast:
		_time_until_spawn = _rng.randf_range(10.0, 16.0)

func debug_arm_immediate_spawn() -> bool:
	if not GameState:
		return false
	if not _is_elf_palace():
		return false
	if GameState.run_flow_state != GameState.RunFlowState.FIGHTING:
		return false
	if _state != _State.IDLE:
		return false
	_ensure_rng_ready()
	_time_until_spawn = 0.0
	return true
