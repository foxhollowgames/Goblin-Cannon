extends RefCounted
class_name PolyominoGoalRewardHandler
## Dispatches pinball goal achievement rewards across the board.

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const RelicBallReward = preload("res://resources/polyomino/relic_ball_reward.gd")
const RewardType = PolyominoModuleData.RewardType

static func handle_goal_reward(board: Node2D, module_node: Node, goal_type: int, reward_type: int, ball: Node, reward_data: Dictionary) -> void:
	if not is_instance_valid(board):
		return
	if board.has_signal("relic_goal_achieved"):
		board.relic_goal_achieved.emit(module_node, goal_type, reward_type, ball, reward_data)

	match reward_type:
		RewardType.TEMPORARY_BALLS:
			var source_id: StringName = module_node.module_data.module_id if module_node != null and module_node.module_data != null else &""
			if module_node != null and module_node.item != null and "custom_payload" in module_node.item:
				source_id = StringName(str(module_node.item.custom_payload.get("relic_id", source_id)))
			var tier: int = module_node.module_data.tier if module_node != null and module_node.module_data != null else 1
			var reward: RelicBallReward = RelicBallReward.for_relic(source_id, tier)
			if reward != null and board.has_method("queue_temporary_relic_reward"):
				board.queue_temporary_relic_reward(module_node, reward, ball, int(reward_data.get("activation_sequence", -1)))
		_: pass
