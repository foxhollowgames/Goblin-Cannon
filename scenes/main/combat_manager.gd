extends Node
## CombatManager. Owns wall HP, wall timer, and wall advancement.
## Timer counts down in sim ticks; when it hits 0, emits time_expired.

signal wall_destroyed
signal time_expired

const TICKS_PER_SECOND: int = 60
const WALL_TIME_SECONDS: Array[int] = [300, 180, 120]  # 5 min, 3 min, 2 min

var _wall_hp: int = 50
var _wall_hp_max: int = 50
var _wall_destroyed_emitted: bool = false
var _wall_names: Array = []
var _city_display_name: String = ""
var _current_wall_index: int = 0
var _timer_ticks_remaining: int = 0
var _time_expired_emitted: bool = false

func init_from_city(city: CityDefinition) -> void:
	if city == null:
		return
	_wall_hp_max = city.get_wall_hp_max_for_index(0)
	_wall_names = city.get_effective_wall_names()
	_city_display_name = city.display_name if not city.display_name.is_empty() else ""
	_current_wall_index = 0
	_wall_hp = _wall_hp_max
	_wall_destroyed_emitted = false
	_time_expired_emitted = false
	_timer_ticks_remaining = _get_wall_time_ticks(0)

func _ready() -> void:
	var main: Node = get_parent()
	var sys: Node = main.get_node_or_null("SystemsContainer")
	if sys:
		var mc: Node = sys.get_node_or_null("MainCannon")
		if mc and mc.has_signal("main_fired"):
			mc.main_fired.connect(_on_main_fired)

func _exit_tree() -> void:
	var main: Node = get_parent()
	var sys: Node = main.get_node_or_null("SystemsContainer")
	if sys:
		var mc: Node = sys.get_node_or_null("MainCannon")
		if mc and mc.has_signal("main_fired") and mc.main_fired.is_connected(_on_main_fired):
			mc.main_fired.disconnect(_on_main_fired)

func sim_tick(_tick: int) -> void:
	if _time_expired_emitted:
		return
	if _timer_ticks_remaining > 0:
		_timer_ticks_remaining -= 1
		if _timer_ticks_remaining <= 0 and not _time_expired_emitted:
			_time_expired_emitted = true
			time_expired.emit()

func _on_main_fired(damage: int) -> void:
	if _time_expired_emitted:
		return
	_wall_hp -= damage
	if _wall_hp < 0:
		_wall_hp = 0
	_emit_wall_destroyed_once()

func _emit_wall_destroyed_once() -> void:
	if _wall_hp == 0 and not _wall_destroyed_emitted:
		_wall_destroyed_emitted = true
		wall_destroyed.emit()

func get_wall_hp() -> int:
	return _wall_hp

func get_wall_hp_max() -> int:
	return _wall_hp_max

func get_timer_seconds_remaining() -> float:
	return float(_timer_ticks_remaining) / float(TICKS_PER_SECOND)

func is_time_expired() -> bool:
	return _time_expired_emitted

func _get_wall_time_ticks(wall_index: int) -> int:
	if TestScenario and TestScenario.enabled:
		if TestScenario.timer_override_seconds == 0:
			return 999999 * TICKS_PER_SECOND
		elif TestScenario.timer_override_seconds > 0:
			return TestScenario.timer_override_seconds * TICKS_PER_SECOND
	var idx: int = clampi(wall_index, 0, WALL_TIME_SECONDS.size() - 1)
	return WALL_TIME_SECONDS[idx] * TICKS_PER_SECOND

func _advance_to_next_wall() -> void:
	_current_wall_index += 1
	if _current_wall_index < _wall_names.size():
		var city: CityDefinition = GameState.get_current_city_definition() if GameState else null
		var base_max: int = city.get_wall_hp_max_for_index(_current_wall_index) if city else 50
		_wall_hp_max = base_max
		_wall_hp = _wall_hp_max
		_wall_destroyed_emitted = false
		_timer_ticks_remaining = _get_wall_time_ticks(_current_wall_index)
		_time_expired_emitted = false

func advance_to_next_wall() -> void:
	_advance_to_next_wall()

func get_city_display_name() -> String:
	return _city_display_name

func get_wall_names() -> Array:
	return _wall_names.duplicate()

func get_current_wall_index() -> int:
	return _current_wall_index

func get_current_gate_name() -> String:
	if _current_wall_index >= 0 and _current_wall_index < _wall_names.size():
		return str(_wall_names[_current_wall_index])
	return ""

func is_all_walls_destroyed() -> bool:
	return _current_wall_index >= _wall_names.size()
