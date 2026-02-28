extends Node
## EnergyPool (§6.8). Shared sidearm energy; add_energy, consume.

signal sidearm_energy_changed(current: int)

var _current: int = 0

func add_energy(amount: int) -> void:
	_current += amount
	sidearm_energy_changed.emit(_current)

func get_current_energy() -> int:
	return _current

func consume(amount: int) -> bool:
	if _current < amount:
		return false
	_current -= amount
	sidearm_energy_changed.emit(_current)
	return true
