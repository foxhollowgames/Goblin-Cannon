extends Node
## EnergyPool (§6.8). Shared sidearm energy; add_energy, consume. GDD §12.1 Sidearm Energy: cap scales with upgrades.

signal sidearm_energy_changed(current: int)

const BASE_CAP_INTERNAL: int = 10000  # 100 display; cap scales with GameState.sidearm_pool_cap_scale and sidearm_cap_bonus

var _current: int = 0

func get_max_internal() -> int:
	var scale: float = GameState.sidearm_pool_cap_scale if GameState else 1.0
	var bonus: float = GameState.sidearm_cap_bonus if GameState else 0.0
	return int(BASE_CAP_INTERNAL * scale * (1.0 + bonus))

func add_energy(amount: int) -> void:
	var cap: int = get_max_internal()
	_current = mini(_current + amount, cap)
	sidearm_energy_changed.emit(_current)

func get_current_energy() -> int:
	return _current

func consume(amount: int) -> bool:
	if _current < amount:
		return false
	_current -= amount
	sidearm_energy_changed.emit(_current)
	return true
