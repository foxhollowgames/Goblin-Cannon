extends Node
## EnergyRouter. All energy goes to main cannon.

signal energy_allocated(main: int, sidearm: int, shield: int)

func route_energy(internal_energy: int, _alignment: int) -> void:
	energy_allocated.emit(internal_energy, 0, 0)
