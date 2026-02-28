@tool
extends Resource
class_name BallDefinition
## GDD §7: tier, base_energy (display), city_weights. §8: alignment drives energy split (Main/Sidearm/Defense).
## Display: ability_name + alignment_name for reward draft; rarity 0-5 for border color (White→Red).

@export var tier: int = 1  ## 1=City 1 primary, 2=City 2 primary, 3=City 3 primary
@export var base_energy: int = 20  # display units (GDD: 20 at bottom + 10 per peg hit)
@export var city_weights: Dictionary = {}  # city_id (int) -> weight; GDD city-weighted rarity distribution
@export var scene: PackedScene
@export var ability_name: String = ""
@export var alignment: int = 0  # Constants.ALIGNMENT_*: 0=Main, 1=Sidearm, 2=Defense (GDD §8)
@export var rarity: int = 0  # 0=Common .. 5=Epic: White, Green, Blue, Purple, Orange, Red
@export var shape_type: int = -1  # BallVisuals.ShapeType; -1 = use alignment-based shape for unique per-ability look
## GDD §8: Status effects this ball applies (e.g. on peg hit or ball_reached_bottom). Keys: "fire", "frozen", "lightning"; value = stacks per trigger.
@export var status_effects: Dictionary = {}
