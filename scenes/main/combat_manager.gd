extends Node
## CombatManager. Owns wall HP, wall timer, and wall advancement.
## Timer counts down in sim ticks; when it hits 0, emits time_expired.

signal wall_destroyed
signal time_expired
signal pushback_occurred(from_wall_index: int, to_wall_index: int)
signal cannon_fired_at_wall(damage: int, remaining_hp: int, max_hp: int)

const TICKS_PER_SECOND: int = 60
## Endless mode: ramp difficulty (testing). HP rises; timer tightens toward a floor.
const ENDLESS_HP_GROWTH: float = 1.12
const ENDLESS_TIMER_SHRINK: float = 0.94
const ENDLESS_MIN_TIMER_SEC: int = 25

var _wall_hp: int = 200
var _wall_hp_max: int = 200
var _wall_destroyed_emitted: bool = false
var _wall_names: Array = []
var _city_display_name: String = ""
var _current_wall_index: int = 0
var _timer_ticks_remaining: int = 0
var _time_expired_emitted: bool = false
var _endless_active: bool = false
var _endless_wave: int = 0

func init_from_city(city: CityDefinition) -> void:
	if city == null:
		return
	_endless_active = false
	_endless_wave = 0
	_wall_hp_max = city.get_wall_hp_max_for_index(0)
	_wall_names = city.get_effective_wall_names()
	_city_display_name = city.display_name if not city.display_name.is_empty() else ""
	_current_wall_index = 0
	_wall_hp = _wall_hp_max
	_wall_destroyed_emitted = false
	_time_expired_emitted = false
	_timer_ticks_remaining = _get_wall_time_ticks(0)

## Debug / TestScenario: start combat at a specific wall (0 = first "world" in the city).
func init_from_city_at_wall(city: CityDefinition, wall_index: int) -> void:
	if city == null:
		return
	_endless_active = false
	_endless_wave = 0
	_wall_names = city.get_effective_wall_names()
	_city_display_name = city.display_name if not city.display_name.is_empty() else ""
	if _wall_names.is_empty():
		_wall_names = [city.gate_name] if not city.gate_name.is_empty() else ["Wall"]
	var max_idx: int = maxi(0, _wall_names.size() - 1)
	_current_wall_index = clampi(wall_index, 0, max_idx)
	_wall_hp_max = city.get_wall_hp_max_for_index(_current_wall_index)
	_wall_hp = _wall_hp_max
	_wall_destroyed_emitted = false
	_time_expired_emitted = false
	_timer_ticks_remaining = _get_wall_time_ticks(_current_wall_index)

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
	cannon_fired_at_wall.emit(damage, _wall_hp, _wall_hp_max)
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

func _get_wall_time_ticks(_wall_index: int) -> int:
	if TestScenario and TestScenario.enabled:
		if TestScenario.timer_override_seconds == 0:
			return 999999 * TICKS_PER_SECOND
		elif TestScenario.timer_override_seconds > 0:
			return TestScenario.timer_override_seconds * TICKS_PER_SECOND
	if _endless_active and _endless_wave > 0:
		var base_sec: int = Constants.WALL_PHASE_TIME_SECONDS
		var sec: int = int(roundf(float(base_sec) * pow(ENDLESS_TIMER_SHRINK, float(_endless_wave - 1))))
		sec = maxi(ENDLESS_MIN_TIMER_SEC, sec)
		return sec * TICKS_PER_SECOND
	return Constants.WALL_PHASE_TIME_SECONDS * TICKS_PER_SECOND

func _advance_to_next_wall() -> void:
	_current_wall_index += 1
	if _current_wall_index < _wall_names.size():
		var city: CityDefinition = GameState.get_current_city_definition() if GameState else null
		var base_max: int = city.get_wall_hp_max_for_index(_current_wall_index) if city else 200
		_wall_hp_max = base_max
		_wall_hp = _wall_hp_max
		_wall_destroyed_emitted = false
		_timer_ticks_remaining = _get_wall_time_ticks(_current_wall_index)
		_time_expired_emitted = false

func start_endless_wave(wave: int) -> void:
	var city: CityDefinition = GameState.get_current_city_definition() if GameState else null
	if city == null or _wall_names.is_empty():
		return
	_endless_active = true
	_endless_wave = maxi(1, wave)
	_current_wall_index = _wall_names.size() - 1
	_apply_endless_wall_hp_from_city(city)

func _apply_endless_wall_hp_from_city(city: CityDefinition) -> void:
	var last_idx: int = _wall_names.size() - 1
	var base_max: int = city.get_wall_hp_max_for_index(last_idx)
	_wall_hp_max = int(roundf(float(base_max) * pow(ENDLESS_HP_GROWTH, float(_endless_wave - 1))))
	_wall_hp_max = maxi(1, _wall_hp_max)
	_wall_hp = _wall_hp_max
	_wall_destroyed_emitted = false
	_time_expired_emitted = false
	_timer_ticks_remaining = _get_wall_time_ticks(_current_wall_index)

func advance_to_next_wall() -> void:
	if _endless_active:
		_endless_wave += 1
		var city: CityDefinition = GameState.get_current_city_definition() if GameState else null
		if city:
			_apply_endless_wall_hp_from_city(city)
		return
	_advance_to_next_wall()

func get_city_display_name() -> String:
	return _city_display_name

func get_wall_names() -> Array:
	return _wall_names.duplicate()

func get_current_wall_index() -> int:
	return _current_wall_index

func get_current_gate_name() -> String:
	if _endless_active and _endless_wave > 0:
		return "Endless %d" % _endless_wave
	if _current_wall_index >= 0 and _current_wall_index < _wall_names.size():
		return str(_wall_names[_current_wall_index])
	return ""

func is_all_walls_destroyed() -> bool:
	return _current_wall_index >= _wall_names.size()

func apply_defender_pushback() -> void:
	var from_idx: int = _current_wall_index
	if _current_wall_index > 0:
		_current_wall_index -= 1
	var city: CityDefinition = GameState.get_current_city_definition() if GameState else null
	_wall_hp_max = city.get_wall_hp_max_for_index(_current_wall_index) if city else 200
	_wall_hp = _wall_hp_max
	_wall_destroyed_emitted = false
	_time_expired_emitted = false
	_timer_ticks_remaining = _get_wall_time_ticks(_current_wall_index)
	pushback_occurred.emit(from_idx, _current_wall_index)

