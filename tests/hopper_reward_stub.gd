extends Node
## Minimal hopper stub for RewardHandler ball-grant tests.

var balls_added: int = 0

func add_balls_with_definition(_count: int, _def: Resource) -> void:
	balls_added += 1

func get_stored_ball_count() -> int:
	return balls_added
