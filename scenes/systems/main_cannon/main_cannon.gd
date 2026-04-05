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

## For UI: effective fire threshold (internal). cannon_charge_reduction subtracts internal units (see RewardHandler cannon_energy).
func get_charge_threshold() -> int:
	var base: int = Constants.main_cannon_charge_internal()
	var reduction: int = GameState.cannon_charge_reduction if GameState else 0
	var primer: int = GameState.main_cannon_volt_primer_discount if GameState else 0
	return maxi(1, base - reduction - primer)

## Status effects applied when cannon fires (e.g. to minions in muzzle blast). Empty by default; upgrades can set via MainCannonConfig.status_effects_on_fire.
func get_status_effects_on_fire() -> Dictionary:
	if _config is MainCannonConfig:
		return (_config as MainCannonConfig).status_effects_on_fire
	return {}

func try_fire() -> bool:
	var threshold: int = get_charge_threshold()
	if _current < threshold:
		return false
	var cost: int = _consume_energy_for_shot()
	if cost <= 0:
		return false
	_current -= cost
	if GameState:
		GameState.main_cannon_volt_primer_discount = 0
	main_energy_changed.emit(_current)
	var dmg: int = _get_damage_for_shot()
	main_fired.emit(dmg)
	return true

func sim_tick(_tick: int) -> void:
	try_fire()

func _consume_energy_for_shot() -> int:
	return get_charge_threshold()

func _get_damage_for_shot() -> int:
	var base: int = 10
	var bonus: int = GameState.cannon_base_damage_bonus if GameState else 0
	return base + bonus
