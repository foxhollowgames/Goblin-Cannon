@tool
extends Resource
class_name SidearmConfig
## §7: energy_per_shot, cooldown_sim_ticks, archetype_id; internal units.

@export var energy_per_shot: int = 20000  # 200 display
@export var cooldown_sim_ticks: int = 30
@export var archetype_id: StringName = &"rapid_fire"
