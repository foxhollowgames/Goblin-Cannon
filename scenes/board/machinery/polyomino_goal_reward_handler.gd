extends RefCounted
class_name PolyominoGoalRewardHandler
## Dispatches pinball goal achievement rewards across the board.

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const RewardType = PolyominoModuleData.RewardType

static func handle_goal_reward(board: Node2D, module_node: Node, goal_type: int, reward_type: int, ball: Node, reward_data: Dictionary) -> void:
	if not is_instance_valid(board):
		return
	if board.has_signal("relic_goal_achieved"):
		board.relic_goal_achieved.emit(module_node, goal_type, reward_type, ball, reward_data)

	var origin_pos: Vector2 = module_node.global_position if is_instance_valid(module_node) else Vector2(480, 360)

	match reward_type:
		RewardType.ENERGY_SURGE:
			var energy: int = int(reward_data.get("energy", 100))
			if is_instance_valid(ball):
				if ball.has_method("add_peg_energy"):
					ball.add_peg_energy(energy)
				if "linear_velocity" in ball:
					ball.linear_velocity = Vector2(randf_range(-120.0, 120.0), -420.0)
			if board.has_method("_spawn_energy_popup_at_pos"):
				board._spawn_energy_popup_at_pos(origin_pos, energy)

		RewardType.BOARD_SUPERCHARGE:
			apply_board_supercharge(board, 3)
			if board.has_method("_spawn_energy_popup_at_pos"):
				board._spawn_energy_popup_at_pos(origin_pos, 50)

		RewardType.MULTIBALL_CASCADE:
			var b_count: int = int(reward_data.get("ball_count", 3))
			apply_multiball_cascade(board, origin_pos, b_count)

		RewardType.GLOBAL_BOARD_KNOCK:
			apply_global_board_knock(board)

		RewardType.CONCUSSIVE_OVERDRIVE:
			var blast_energy: int = int(reward_data.get("energy", 120))
			apply_concussive_overdrive(board, origin_pos, blast_energy, ball)

static func apply_board_supercharge(board: Node2D, stacks: int = 3) -> void:
	var pegs_dict: Dictionary = board.get("_pegs") if "_pegs" in board else {}
	for pid in pegs_dict:
		var peg: Node = pegs_dict[pid]
		if is_instance_valid(peg) and peg.is_inside_tree():
			if peg.has_method("is_destroyed") and peg.is_destroyed():
				continue
			var ek: String = peg.peg_extra_kind if "peg_extra_kind" in peg else ""
			if not Constants.peg_extra_kind_blocks_energize(ek):
				if peg.has_method("apply_hit"):
					for _s in range(stacks):
						peg.apply_hit(false, 0, true)

static func apply_multiball_cascade(board: Node2D, origin_pos: Vector2, count: int = 3) -> void:
	var ball_scene: PackedScene = board.get("_ball_scene") if "_ball_scene" in board else null
	var balls_container: Node = board.get("_balls_container") if "_balls_container" in board else null
	if ball_scene == null or balls_container == null:
		return
	var ball_count: int = mini(8, maxi(1, count))
	for i in range(ball_count):
		board._next_split_ball_id += 1
		var new_ball: Node = ball_scene.instantiate()
		if new_ball.has_method("set_ball_id"):
			new_ball.set_ball_id(board._next_split_ball_id)
		balls_container.add_child(new_ball)
		if "freeze" in new_ball:
			new_ball.freeze = false
		new_ball.global_position = origin_pos + Vector2(randf_range(-16.0, 16.0), 10.0)
		if "linear_velocity" in new_ball:
			new_ball.linear_velocity = Vector2(randf_range(-140.0, 140.0), randf_range(150.0, 320.0))
		if "_active_balls" in board:
			board._active_balls.append(new_ball)
		if "_ball_hit_count_this_visit" in board:
			board._ball_hit_count_this_visit[new_ball.get_ball_id() if new_ball.has_method("get_ball_id") else 0] = 0

static func apply_global_board_knock(board: Node2D) -> void:
	var total_hit_energy: int = 0
	var pegs_dict: Dictionary = board.get("_pegs") if "_pegs" in board else {}
	for pid in pegs_dict:
		var peg: Node = pegs_dict[pid]
		if is_instance_valid(peg) and peg.is_inside_tree():
			if peg.has_method("is_destroyed") and peg.is_destroyed():
				continue
			if peg.has_method("apply_hit"):
				peg.apply_hit(true, 1, false)
			total_hit_energy += Constants.legacy_display_energy_to_current(1)
	if total_hit_energy > 0:
		GameState.add_energy(total_hit_energy)
		if board.has_method("_spawn_energy_popup_at_pos"):
			board._spawn_energy_popup_at_pos(Vector2(480, 360), total_hit_energy)

static func apply_concussive_overdrive(board: Node2D, origin_pos: Vector2, energy_amount: int, triggering_ball: Node) -> void:
	var blast_radius: float = 180.0
	var pegs_dict: Dictionary = board.get("_pegs") if "_pegs" in board else {}
	for pid in pegs_dict:
		var peg: Node = pegs_dict[pid]
		if is_instance_valid(peg) and peg.is_inside_tree():
			var p_pos: Vector2 = peg.global_position if "global_position" in peg else peg.position
			if p_pos.distance_to(origin_pos) <= blast_radius:
				if peg.has_method("apply_hit"):
					peg.apply_hit(true, 1, false)
	var active_balls: Array = board.get("_active_balls") if "_active_balls" in board else []
	for b in active_balls:
		if is_instance_valid(b) and "linear_velocity" in b:
			var b_pos: Vector2 = b.global_position if "global_position" in b else b.position
			var diff: Vector2 = b_pos - origin_pos
			var dir: Vector2 = diff.normalized() if diff.length_squared() > 1.0 else Vector2.UP
			b.linear_velocity += dir * 350.0
	if is_instance_valid(triggering_ball) and triggering_ball.has_method("add_peg_energy"):
		triggering_ball.add_peg_energy(energy_amount)
	if board.has_method("_spawn_energy_popup_at_pos"):
		board._spawn_energy_popup_at_pos(origin_pos, energy_amount)
