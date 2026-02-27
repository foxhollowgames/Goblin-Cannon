extends Control
## DebugOverlay (§6). set_energy, set_stats_cached; update once per second from cached values.

var _energy_label: Label

func _ready() -> void:
	_energy_label = get_node_or_null("EnergyLabel") as Label
	if _energy_label:
		_update_energy_display(0, 0, 0)

func set_energy(main: int, sidearm: int, shield: int) -> void:
	_update_energy_display(main, sidearm, shield)

func _update_energy_display(main: int, sidearm: int, _shield: int) -> void:
	if _energy_label:
		_energy_label.text = "Energy: %d | Sidearm: %d" % [main / 100, sidearm / 100]

func set_stats_cached(_stats: Dictionary) -> void:
	pass
