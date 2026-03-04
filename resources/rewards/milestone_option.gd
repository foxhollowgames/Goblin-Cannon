extends Resource
class_name MilestoneOption
## GDD §12: One of 5 milestone options — either a ball reward or a stat upgrade.
## Used by reward draft to show mixed cards; player picks one.

enum Type { BALL, STAT }

@export var option_type: Type = Type.BALL
## Set when option_type == BALL (city-weighted pick, alignment randomized at generation).
@export var ball_definition: BallDefinition
## When option_type == STAT: main_charge, sidearm_cap, shield_cap, health_max, shield_max, door_interval, door_duration, cannon_damage, cannon_energy.
@export var stat_id: String = ""
## When option_type == STAT: 0=Common (HP/shield/pool), 1=Uncommon (energy per ball), 2=Rare (hopper). Used for draft border and pick weighting.
@export var rarity: int = 0
