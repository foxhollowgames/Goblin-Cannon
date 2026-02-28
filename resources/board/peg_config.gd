@tool
extends Resource
class_name PegConfig
## §7: durability, recovery_sim_ticks, vibrancy_scale.

@export var durability: int = 3
@export var recovery_sim_ticks: int = 300  # 5 seconds at 60 sim ticks/sec
@export var vibrancy_scale: float = 1.0
