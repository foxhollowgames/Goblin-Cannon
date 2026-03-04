extends "res://scenes/systems/sidearms/sidearm_base.gd"
## Sniper: high single-target damage sidearm. Shared pool; consumes more energy per shot, longer cooldown.

var _pool: Node
var _config: SidearmConfig

func _ready() -> void:
	var sidearms: Node = get_parent()
	_pool = sidearms.get_node_or_null("SidearmPool")
	_config = _load_config()
	if _config == null:
		_config = _default_config()

func _load_config() -> SidearmConfig:
	var r: Resource = load("res://resources/systems/sniper_config.tres") as Resource
	if r is SidearmConfig:
		return r as SidearmConfig
	return null

func _default_config() -> SidearmConfig:
	var c: SidearmConfig = SidearmConfig.new()
	c.energy_per_shot = 10000   # 100 display
	c.cooldown_sim_ticks = 180  # 3 seconds at 60 sim ticks/s
	c.archetype_id = &"sniper"
	c.damage_per_shot = 25
	return c

func get_status_effects_on_fire() -> Dictionary:
	if _config != null and _config.status_effects_on_fire != null:
		return _config.status_effects_on_fire
	return {}

func sim_tick(tick: int) -> void:
	super.sim_tick(tick)
	try_fire()

func try_fire() -> bool:
	if _cooldown_ticks_remaining > 0:
		return false
	if _pool == null or not _pool.has_method("consume"):
		return false
	var cost: int = _config.energy_per_shot
	if not _pool.consume(cost):
		return false
	_cooldown_ticks_remaining = _config.cooldown_sim_ticks
	var energy_display: int = _config.energy_per_shot / 100
	sidearm_fired.emit(_config.damage_per_shot, energy_display, get_status_effects_on_fire(), false, 0.0)
	return true
