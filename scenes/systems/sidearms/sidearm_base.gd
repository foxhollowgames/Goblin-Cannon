extends Node
class_name SidearmBase
## Base for sidearms (§6.8). try_fire, cooldown in sim_ticks. RapidFire extends this.

signal sidearm_fired(damage: int, energy_cost_display: int, status_effects: Dictionary, is_aoe: bool, aoe_radius: float)

var _cooldown_ticks_remaining: int = 0

func is_on_cooldown() -> bool:
	return _cooldown_ticks_remaining > 0

func try_fire() -> bool:
	return false  # override

func sim_tick(_tick: int) -> void:
	if _cooldown_ticks_remaining > 0:
		_cooldown_ticks_remaining -= 1
