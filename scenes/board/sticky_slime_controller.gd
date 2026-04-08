extends Node2D
## Human Kingdom only: preview highlights on chosen pegs, then they become sticky slime until freed or event ends.

enum _State { IDLE, PREVIEW, ACTIVE }

@export var preview_duration_sec: float = 3.4
@export var active_duration_sec: float = 75.0
@export var min_interval_sec: float = 50.0
@export var max_interval_sec: float = 78.0
@export var min_interval_near_boss_sec: float = 16.0
@export var max_interval_near_boss_sec: float = 28.0
@export var pegs_per_event: int = 3

var _rng: RandomNumberGenerator
## Lazily created on first _process while Human Kingdom — _ready runs before GameCoordinator applies current_city_id / TestScenario.
var _rng_ready: bool = false
var _state: int = _State.IDLE
var _time_until_spawn: float = 0.0
var _preview_remaining: float = 0.0
var _active_deadline_ms: int = 0
var _active_peg_ids: Array[int] = []
var _preview_drip_nodes: Array[Node2D] = []

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
	if TestScenario and TestScenario.enabled and TestScenario.sticky_slime_event_fast:
		_time_until_spawn = 1.0
		min_interval_sec = 8.0
		max_interval_sec = 14.0
		min_interval_near_boss_sec = 5.0
		max_interval_near_boss_sec = 9.0
	if TestScenario and TestScenario.enabled and TestScenario.sticky_slime_event_at_start:
		_time_until_spawn = 0.0
		if TestScenario.sticky_slime_event_fast:
			preview_duration_sec = 1.05

func _is_human_kingdom() -> bool:
	if not GameState:
		return false
	## Authoritative: progression index matches CITY_DEFINITION_PATHS (avoids relying on loaded Resource.city_id alone).
	return GameState.current_city_id == Constants.CITY_INDEX_HUMAN_KINGDOM

func arm_immediate_spawn_if_test() -> void:
	if not TestScenario or not TestScenario.enabled:
		return
	if not _is_human_kingdom():
		return
	_ensure_rng_ready()
	if TestScenario.sticky_slime_event_at_start:
		_time_until_spawn = 0.0
		if TestScenario.sticky_slime_event_fast:
			min_interval_sec = 8.0
			max_interval_sec = 14.0
			min_interval_near_boss_sec = 5.0
			max_interval_near_boss_sec = 9.0
			preview_duration_sec = 1.05

func _apply_rng_seed() -> void:
	var s: int = GameState.run_seed if GameState else 1
	_rng.seed = s ^ 0x51EE7A1E

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
	if not _is_human_kingdom():
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
			_tick_active(board)

func _tick_idle(delta: float, board: Node2D) -> void:
	_time_until_spawn -= delta
	if _time_until_spawn > 0.0:
		return
	_start_preview(board)

func _start_preview(board: Node2D) -> void:
	var n: int = maxi(1, pegs_per_event)
	if TestScenario and TestScenario.enabled and TestScenario.sticky_slime_event_pegs > 0:
		n = TestScenario.sticky_slime_event_pegs
	var ids: Array[int] = []
	if board.has_method("pick_random_normal_peg_ids_for_sticky_event"):
		ids = board.pick_random_normal_peg_ids_for_sticky_event(n)
	if ids.is_empty():
		_reset_to_idle(board)
		return
	_active_peg_ids = ids
	_preview_remaining = preview_duration_sec
	_state = _State.PREVIEW
	if board.has_method("set_sticky_slime_preview_highlights"):
		board.set_sticky_slime_preview_highlights(ids, true)
	_spawn_preview_drips(board, ids)

func _spawn_preview_drips(board: Node2D, peg_ids: Array[int]) -> void:
	_clear_preview_drips()
	var scr: GDScript = load("res://scenes/board/sticky_slime_preview.gd") as GDScript
	for pid in peg_ids:
		var peg: Node = board.get_peg_by_id(pid) if board.has_method("get_peg_by_id") else null
		if peg == null or not is_instance_valid(peg):
			continue
		var node: Node2D = Node2D.new()
		if scr:
			node.set_script(scr)
		board.add_child(node)
		node.global_position = peg.global_position
		node.z_index = 45
		_preview_drip_nodes.append(node)

func _clear_preview_drips() -> void:
	for n in _preview_drip_nodes:
		if n and is_instance_valid(n):
			n.queue_free()
	_preview_drip_nodes.clear()

func _tick_preview(delta: float, board: Node2D) -> void:
	_preview_remaining -= delta
	if _preview_remaining > 0.0:
		return
	if board.has_method("set_sticky_slime_preview_highlights"):
		board.set_sticky_slime_preview_highlights(_active_peg_ids, false)
	_clear_preview_drips()
	if board.has_method("apply_sticky_slime_to_peg_ids"):
		board.apply_sticky_slime_to_peg_ids(_active_peg_ids)
	_active_deadline_ms = Time.get_ticks_msec() + int(active_duration_sec * 1000.0)
	_state = _State.ACTIVE

func _tick_active(board: Node2D) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var remain_ms: int = _active_deadline_ms - now_ms
	var frac: float = clampf(float(remain_ms) / (active_duration_sec * 1000.0), 0.0, 1.0)
	for pid in _active_peg_ids:
		var peg: Node = board.get_peg_by_id(pid) if board.has_method("get_peg_by_id") else null
		if peg and is_instance_valid(peg) and str(peg.peg_extra_kind) == "sticky_slime":
			if peg.has_method("set_sticky_slime_urgency"):
				peg.set_sticky_slime_urgency(frac)
	if now_ms >= _active_deadline_ms:
		_timeout_revert_all(board)

func _timeout_revert_all(board: Node2D) -> void:
	for pid in _active_peg_ids:
		if board.has_method("revert_sticky_slime_peg_after_event_timeout"):
			board.revert_sticky_slime_peg_after_event_timeout(pid)
	_finish_active_to_idle(board)

func on_sticky_slime_peg_broken(_peg_id: int) -> void:
	## Pegs remove themselves from active coating when broken; optional early cleanup.
	pass

func _finish_active_to_idle(board: Node2D) -> void:
	_state = _State.IDLE
	_active_peg_ids.clear()
	var r: Vector2 = _pick_interval_range()
	_time_until_spawn = _rng.randf_range(r.x, r.y)
	if TestScenario and TestScenario.enabled and TestScenario.sticky_slime_event_fast:
		_time_until_spawn = _rng.randf_range(8.0, 14.0)

func _reset_to_idle(board: Node2D) -> void:
	_state = _State.IDLE
	_active_peg_ids.clear()
	_clear_preview_drips()
	if board.has_method("set_sticky_slime_preview_highlights"):
		board.set_sticky_slime_preview_highlights([], false)
	var r: Vector2 = _pick_interval_range()
	_time_until_spawn = _rng.randf_range(r.x, r.y)

func debug_arm_immediate_spawn() -> bool:
	if not GameState:
		return false
	if not _is_human_kingdom():
		return false
	if GameState.run_flow_state != GameState.RunFlowState.FIGHTING:
		return false
	if _state != _State.IDLE:
		return false
	_ensure_rng_ready()
	_time_until_spawn = 0.0
	return true
