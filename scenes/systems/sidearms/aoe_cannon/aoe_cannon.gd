extends "res://scenes/systems/sidearms/sidearm_base.gd"
## AOE Cannon: area damage sidearm. Damages all minions within radius of the frontmost minion. Shared pool.

var _pool: Node
var _config: SidearmConfig

func _ready() -> void:
	var sidearms: Node = get_parent()
	_pool = sidearms.get_node_or_null("SidearmPool")
	_config = _load_config()
	if _config == null:
		_config = _default_config()

func _load_config() -> SidearmConfig:
	var r: Resource = load("res://resources/systems/aoe_cannon_config.tres") as Resource
	if r is SidearmConfig:
		return r as SidearmConfig
	return null

func _default_config() -> SidearmConfig:
	var c: SidearmConfig = SidearmConfig.new()
	c.energy_per_shot = 8000   # 80 display
	c.cooldown_sim_ticks = 200  # ~3.3 seconds at 60 sim ticks/s
	c.archetype_id = &"aoe_cannon"
	c.damage_per_shot = 8
	c.is_aoe = true
	c.aoe_radius = 120.0
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
	var is_aoe: bool = _config.is_aoe if _config != null else true
	var aoe_radius: float = _config.aoe_radius if _config != null else 120.0
	sidearm_fired.emit(_config.damage_per_shot, energy_display, get_status_effects_on_fire(), is_aoe, aoe_radius)
	return true
