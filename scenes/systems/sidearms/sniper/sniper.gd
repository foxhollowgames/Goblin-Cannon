extends SidearmBase
## Sniper: high single-target damage sidearm. Shared pool; consumes more energy per shot, longer cooldown.

func _get_config_resource_path() -> String:
	return "res://resources/systems/sniper_config.tres"

func _default_config() -> SidearmConfig:
	var c: SidearmConfig = SidearmConfig.new()
	c.energy_per_shot = Constants.legacy_internal_energy_to_current(10000)  # 12.5 display @ 100 main charge
	c.cooldown_sim_ticks = 180  # 3 seconds at 60 sim ticks/s
	c.archetype_id = &"sniper"
	c.damage_per_shot = 25
	return c
