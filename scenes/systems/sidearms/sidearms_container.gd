extends Node
## Sidearms container (§6.8). Forwards sim_tick to each sidearm (e.g. RapidFire) so they can decrement cooldown and try_fire.
## Pool (SidearmPool) does not receive sim_tick; only sidearm weapons do.

func sim_tick(tick: int) -> void:
	for child in get_children():
		if child.has_method("sim_tick"):
			child.sim_tick(tick)
