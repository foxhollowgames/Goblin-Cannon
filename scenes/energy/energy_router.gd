extends Node
## EnergyRouter (§6.6). Pure logic; internal = display×100. route_energy -> emit energy_allocated.

signal energy_allocated(main: int, sidearm: int, shield: int)

func route_energy(internal_energy: int, alignment: int) -> void:
	var v: Vector3i
	match alignment:
		0: v = EnergyRouting.split_main_aligned(internal_energy)
		1: v = EnergyRouting.split_sidearm_aligned(internal_energy)
		2: v = EnergyRouting.split_defense_aligned(internal_energy)
		_: v = EnergyRouting.split_main_aligned(internal_energy)
	energy_allocated.emit(v.x, v.y, v.z)
