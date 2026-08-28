class_name SidearmBase
extends Node
## Base for sidearms (§6.8). try_fire, cooldown in sim_ticks.

signal sidearm_fired(damage: int, energy_cost_display: int, status_effects: Dictionary, is_aoe: bool, aoe_radius: float)

var _cooldown_ticks_remaining: int = 0
var _pool: Node
var _config: SidearmConfig

func _ready() -> void:
	var sidearms: Node = get_parent()
	if sidearms:
		_pool = sidearms.get_node_or_null("SidearmPool")
	_config = _load_config()
	if _config == null:
		_config = _default_config()

func _load_config() -> SidearmConfig:
	var path: String = _get_config_resource_path()
	if not path.is_empty():
		var r: Resource = load(path) as Resource
		if r is SidearmConfig:
			return r as SidearmConfig
	return null

func _get_config_resource_path() -> String:
	return ""

func _default_config() -> SidearmConfig:
	return null

func is_on_cooldown() -> bool:
	return _cooldown_ticks_remaining > 0

func get_status_effects_on_fire() -> Dictionary:
	if _config != null and _config.status_effects_on_fire != null:
		return _config.status_effects_on_fire
	return {}

func sim_tick(_tick: int) -> void:
	if _cooldown_ticks_remaining > 0:
		_cooldown_ticks_remaining -= 1
	try_fire()

func try_fire() -> bool:
	if _cooldown_ticks_remaining > 0:
		return false
	if _pool == null or not _pool.has_method("consume"):
		return false
	if _config == null:
		return false
	var cost: int = _config.energy_per_shot
	if not _pool.consume(cost):
		return false
	_cooldown_ticks_remaining = _config.cooldown_sim_ticks
	var energy_display: int = _config.energy_per_shot / 100
	var is_aoe: bool = _config.is_aoe
	var aoe_radius: float = _config.aoe_radius
	sidearm_fired.emit(_config.damage_per_shot, energy_display, get_status_effects_on_fire(), is_aoe, aoe_radius)
	return true
