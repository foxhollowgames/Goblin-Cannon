extends Node
## MainCannon (§6.7). Accumulate main energy; try_fire at threshold.

signal main_energy_changed(current: int)
signal main_fired(damage: int)

var _current: int = 0
var _config: Resource

func add_energy(amount: int) -> void:
	_current += amount
	main_energy_changed.emit(_current)

func get_current_energy() -> int:
	return _current

## Status effects applied when cannon fires (e.g. to minions in muzzle blast). Empty by default; upgrades can set via MainCannonConfig.status_effects_on_fire.
func get_status_effects_on_fire() -> Dictionary:
	if _config is MainCannonConfig:
		return (_config as MainCannonConfig).status_effects_on_fire
	return {}

func try_fire() -> bool:
	var threshold: int = 80000  # internal
	if _current < threshold:
		return false
	var cost: int = _consume_energy_for_shot()
	if cost <= 0:
		return false
	_current -= cost
	main_energy_changed.emit(_current)
	var dmg: int = _get_damage_for_shot()
	main_fired.emit(dmg)
	return true

func sim_tick(_tick: int) -> void:
	try_fire()

func _consume_energy_for_shot() -> int:
	return 80000  # slice

func _get_damage_for_shot() -> int:
	return 10  # slice
