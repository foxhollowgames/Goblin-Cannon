@tool
extends Resource
class_name SidearmConfig
## §7: energy_per_shot, cooldown_sim_ticks, archetype_id; internal units. damage_per_shot for CombatManager.

@export var energy_per_shot: int = 10000  # 100 display (internal)
@export var cooldown_sim_ticks: int = 30
@export var archetype_id: StringName = &"rapid_fire"
@export var damage_per_shot: int = 5  # Slice: Rapid Fire damage per shot
## Status effects applied when this sidearm hits. Empty by default; upgrades can set (e.g. { "fire": 1, "lightning": 1 }).
@export var status_effects_on_fire: Dictionary = {}
