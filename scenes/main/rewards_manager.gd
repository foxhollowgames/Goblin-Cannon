extends Node
## RewardsManager (§6). Receives milestone_reached, calls RewardHandler + Hopper. Owns RunFlow (optional).

func _ready() -> void:
	pass

func on_milestone_reached(milestone_index: int, total_energy_display: int) -> void:
	var rh: Node = get_parent().get_node_or_null("RewardHandler")
	if rh and rh.has_method("grant_ball_rewards"):
		rh.grant_ball_rewards(3)  # slice: 3 picks
	if rh and rh.has_method("grant_stat_upgrades"):
		rh.grant_stat_upgrades(2)  # slice: 2 stats
	# RunFlow: transition to REWARD_SLOWMO then REWARD_PAUSED (optional timer)
	GameState.set_run_flow_state(GameState.RunFlowState.REWARD_SLOWMO)
