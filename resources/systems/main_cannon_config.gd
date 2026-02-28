@tool
extends Resource
class_name MainCannonConfig
## §7: energy_per_shot, fire_threshold — both internal units (×100).

@export var energy_per_shot: int = 80000  # 800 display
@export var fire_threshold: int = 80000    # 800 display
## Status effects applied when cannon fires (e.g. muzzle blast on minions). Empty by default; upgrades can set (e.g. { "fire": 1 }).
@export var status_effects_on_fire: Dictionary = {}
