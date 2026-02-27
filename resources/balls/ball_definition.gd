@tool
extends Resource
class_name BallDefinition
## §7: tier, base_energy (display), city_weights, optional scene.

@export var tier: int = 1
@export var base_energy: int = 20  # display units
@export var city_weights: Dictionary = {}  # city_id -> weight
@export var scene: PackedScene
