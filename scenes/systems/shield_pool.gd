extends Node
## Shield pool: receives shield energy from EnergyRouter; converts to shield points (50 energy per point).
## Starts at full. Capped at max (GDD default). UI and cannon visual read points, not raw energy.

## GDD: base max shield points (e.g. 100). Scaled by GameState.shield_cap_bonus (milestone stat upgrades).
const MAX_SHIELD_POINTS: int = 100
## 50 display energy = 1 shield point → 5000 internal per point.
const ENERGY_PER_POINT_INTERNAL: int = 5000

var _current_internal: int = 0

func _ready() -> void:
	_current_internal = _get_max_internal()

func _get_max_internal() -> int:
	var bonus: float = GameState.shield_cap_bonus if GameState else 0.0
	return int(MAX_SHIELD_POINTS * ENERGY_PER_POINT_INTERNAL * (1.0 + bonus))

func add_energy(amount: int) -> void:
	var cap: int = _get_max_internal()
	_current_internal = mini(_current_internal + amount, cap)

## Returns current shield points (0..get_max_shield_points()) for UI and cannon visual.
func get_current_shield_points() -> int:
	var max_pts: int = _get_max_internal() / ENERGY_PER_POINT_INTERNAL
	return mini(max_pts, _current_internal / ENERGY_PER_POINT_INTERNAL)

## For debug overlay / compatibility: returns internal energy (points × 5000).
func get_current_energy() -> int:
	return _current_internal

## Consume up to `amount` shield points (e.g. from damage). 1 damage = 1 shield point.
func consume_shield_points(amount: int) -> void:
	var points: int = get_current_shield_points()
	var consume: int = mini(amount, points)
	_current_internal = maxi(0, _current_internal - consume * ENERGY_PER_POINT_INTERNAL)
