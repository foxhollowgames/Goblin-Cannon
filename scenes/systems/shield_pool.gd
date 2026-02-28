extends Node
## Shield pool: receives shield energy from EnergyRouter; converts to shield points (50 energy per point).
## Starts at full. Capped at max (GDD default). UI and cannon visual read points, not raw energy.

## GDD: max shield points (e.g. 100). Integer only.
const MAX_SHIELD_POINTS: int = 100
## 50 display energy = 1 shield point → 5000 internal per point.
const ENERGY_PER_POINT_INTERNAL: int = 5000

var _current_internal: int = 0

func _ready() -> void:
	_current_internal = MAX_SHIELD_POINTS * ENERGY_PER_POINT_INTERNAL

func add_energy(amount: int) -> void:
	var cap: int = MAX_SHIELD_POINTS * ENERGY_PER_POINT_INTERNAL
	_current_internal = mini(_current_internal + amount, cap)

## Returns current shield points (0..MAX_SHIELD_POINTS) for UI and cannon visual.
func get_current_shield_points() -> int:
	return mini(MAX_SHIELD_POINTS, _current_internal / ENERGY_PER_POINT_INTERNAL)

## For debug overlay / compatibility: returns internal energy (points × 5000).
func get_current_energy() -> int:
	return _current_internal

## Consume up to `amount` shield points (e.g. from damage). 1 damage = 1 shield point.
func consume_shield_points(amount: int) -> void:
	var points: int = get_current_shield_points()
	var consume: int = mini(amount, points)
	_current_internal = maxi(0, _current_internal - consume * ENERGY_PER_POINT_INTERNAL)
