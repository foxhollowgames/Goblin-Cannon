@tool
extends Resource
class_name BallDefinition
## GDD §7: tier, base_energy (display), city_weights. §8: alignment drives energy split (Main/Sidearm/Defense).
## Display: ability_name + alignment_name for reward draft; rarity drives border color — one tier per ability (see Constants.ball_rarity_display_name).

@export var tier: int = 1  ## 1=City 1 primary, 2=City 2 primary, 3=City 3 primary
@export var base_energy: int = 3  # display units (scaled with 100 main cannon charge; legacy ~20 start + 10/hit)
@export var city_weights: Dictionary = {}  # city_id (int) -> weight; GDD city-weighted rarity distribution
@export var scene: PackedScene
@export var ability_name: String = ""
@export var alignment: int = 0  # Constants.ALIGNMENT_*: 0=Main, 1=Sidearm, 2=Defense (GDD §8)
@export var rarity: int = 0  # Common/Uncommon/Rare/Legendary (index 5 = Explosive & Chain Lightning); same colors as shop tiers
@export var shape_type: int = -1  # BallVisuals.ShapeType; -1 = use alignment-based shape for unique per-ability look
## GDD §8: Status effects this ball applies (e.g. on peg hit or ball_reached_bottom). Keys: "fire", "frozen", "lightning"; value = stacks per trigger.
@export var status_effects: Dictionary = {}
