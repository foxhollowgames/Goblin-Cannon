extends Node
## Minimal stub for RewardHandler milestone tests.

var basic_added: int = 0
var last_conversion: BallDefinition = null
var plain_count: int = 5

func add_basic_balls(n: int) -> void:
	basic_added += n

func apply_ball_upgrade_conversion(def: BallDefinition) -> bool:
	last_conversion = def
	return def != null

func count_plain_balls_in_play() -> int:
	return plain_count
