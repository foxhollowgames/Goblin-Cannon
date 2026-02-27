extends Node
## RewardHandler (§6.10). grant_ball_rewards, grant_stat_upgrades; calls simulation/reward_generation only.

var _reward_gen: RewardGeneration
var _hopper: Node

func _ready() -> void:
	_reward_gen = RewardGeneration.new(GameState.run_seed)
	var main: Node = get_parent()
	_hopper = main.get_node_or_null("Hopper")

func grant_ball_rewards(count: int) -> void:
	var candidates: Array = []  # TODO: build from tier weights
	var picks: Array = _reward_gen.pick_ball_rewards(candidates, count)
	for p in picks:
		_apply_ball_to_hopper(p)

func grant_stat_upgrades(count: int) -> void:
	pass  # TODO: present 2 stat upgrades

func _apply_ball_to_hopper(_pick: Variant) -> void:
	if _hopper and _hopper.has_method("add_balls"):
		_hopper.add_balls(1)
