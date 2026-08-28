extends SidearmBase
## AOE Cannon: area damage sidearm. Damages all minions within radius of the frontmost minion. Shared pool.

func _get_config_resource_path() -> String:
	return "res://resources/systems/aoe_cannon_config.tres"

func _default_config() -> SidearmConfig:
	var c: SidearmConfig = SidearmConfig.new()
	c.energy_per_shot = Constants.legacy_internal_energy_to_current(8000)  # 10 display @ 100 main charge
	c.cooldown_sim_ticks = 200  # ~3.3 seconds at 60 sim ticks/s
	c.archetype_id = &"aoe_cannon"
	c.damage_per_shot = 8
	c.is_aoe = true
	c.aoe_radius = 120.0
	return c
