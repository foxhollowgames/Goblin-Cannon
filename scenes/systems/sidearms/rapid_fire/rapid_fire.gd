extends SidearmBase
## RapidFire (§6.8). Cooldown-based sidearm; consumes from shared pool; emits sidearm_fired.

func _get_config_resource_path() -> String:
	return "res://resources/systems/rapid_fire_config.tres"

func _default_config() -> SidearmConfig:
	var c: SidearmConfig = SidearmConfig.new()
	c.energy_per_shot = Constants.legacy_internal_energy_to_current(5000)  # 6.25 display @ 100 main charge
	c.cooldown_sim_ticks = 120  # 2 seconds at 60 sim ticks/s
	c.archetype_id = &"rapid_fire"
	c.damage_per_shot = 5
	return c
