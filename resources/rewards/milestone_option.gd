extends Resource
class_name MilestoneOption
## One of milestone shop options: stat upgrade, ball upgrade (convert plain → ability), or peg. BASIC_BATCH is legacy / debug only (+5 plain come from the milestone board event, not the shop).
## Used by reward draft to show mixed cards; player picks one.

enum Type { BASIC_BATCH, STAT, BALL_UPGRADE, PEG_UPGRADE, RELIC }

@export var option_type: Type = Type.STAT
## Set when option_type == BALL_UPGRADE (city-weighted, same pool as former ball draft).
@export var ball_definition: BallDefinition
## When option_type == STAT: main_charge, door_interval, door_duration, cannon_damage, cannon_energy, hopper_width,
## Stat IDs exclude plain_surge / plain_horde / plain_momentum (those are wall-break major upgrades).
@export var stat_id: String = ""
## When option_type == STAT: 0=Common, 1=Uncommon, 2=Rare. Used for draft border and pick weighting.
## When option_type == PEG_UPGRADE: same numeric tiers as balls/shop (0/1/2/5 for top peg tier) for border and shop price.
## When option_type == RELIC: relic tier (1..3).
@export var rarity: int = 0
## When option_type == PEG_UPGRADE: peg kind string (e.g. "bomb", "magnet") — matches RewardHandler.apply_peg_shop_unlock.
@export var peg_kind: String = ""
## When option_type == RELIC: deliberate relic ID from DeliberateRelicCatalog / PolyominoRelicDatabase.
@export var relic_id: StringName = &""

