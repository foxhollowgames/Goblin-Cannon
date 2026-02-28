@tool
extends Resource
class_name MilestoneDefinition
## §7: threshold (display), ball_reward_count, stat_upgrade_count. Slice: 3 and 2.

@export var threshold: int = 200  # display units; GDD §12 ~3 per wall
@export var ball_reward_count: int = 3
@export var stat_upgrade_count: int = 2
