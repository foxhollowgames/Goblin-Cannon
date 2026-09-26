extends RefCounted
class_name TemporaryRelicBallController
## Owns temporary relic reward reservations, emission timing, and ball lifetime.

const RelicBallReward = preload("res://resources/polyomino/relic_ball_reward.gd")
const BALL_RADIUS: float = 8.0
const CELL_WIDTH: float = 52.0
const CELL_HEIGHT: float = 56.0
const BLOCKED_TICKS: int = 60
const LIFE_TICKS: int = 720

signal reward_status(source_id: StringName, offered_count: int, emitted_count: int, canceled_count: int, blocked: bool)

var _board: Node = null
var _queue: Array = []
var _reserved: int = 0
var _activation_sequence: int = 0
var _consumed: Dictionary = {} ## String -> true; run/module/activation keys
var _balls: Array[Node] = []

func setup(board: Node) -> void:
	_board = board
	_balls = board._temporary_relic_balls

func queue_reward(module: Node, reward: RelicBallReward, triggering_ball: Node, sim_tick: int, activation_sequence: int) -> bool:
	if _board == null or reward == null:
		return false
	var tier: int = module.module_data.tier if module != null and module.module_data != null else 1
	if not reward.is_valid_for_tier(tier):
		return false
	var module_id: String = str(module.get_instance_id()) if is_instance_valid(module) else "missing"
	var run_id: String = str(GameState.run_seed) if GameState else "0"
	var sequence: int = activation_sequence if activation_sequence >= 0 else _activation_sequence
	var key: String = "%s/%s/%s" % [run_id, module_id, sequence]
	if _consumed.has(key):
		return false
	_consumed[key] = true
	_activation_sequence = maxi(_activation_sequence + 1, sequence + 1)
	var port: Dictionary = _port_for(module, triggering_ball) if reward.spawn_at_relic else {"valid": true, "position": Vector2.ZERO, "direction": Vector2.DOWN}
	_queue.append({"module": module, "reward": reward, "offered": reward.count,
		"remaining": 0, "emitted": 0, "canceled": 0, "allocated": false,
		"blocked_ticks": 0, "next_emit_tick": sim_tick + 1,
		"allocation_tick": sim_tick + 1, "sequence": sequence, "port": port})
	return true

func process(sim_tick: int) -> void:
	_prune_balls()
	var pending: Array = _queue.duplicate()
	pending.sort_custom(_entry_before)
	for entry: Dictionary in pending:
		if not _queue.has(entry):
			continue
		if not bool(entry.get("allocated", false)):
			if sim_tick < int(entry.get("allocation_tick", sim_tick)):
				continue
			_allocate_entry(entry)
			if not _queue.has(entry):
				continue
		if int(entry.get("remaining", 0)) <= 0:
			_queue.erase(entry)
			continue
		if sim_tick < int(entry.get("next_emit_tick", sim_tick)):
			continue
		var reward: RelicBallReward = entry.get("reward") as RelicBallReward
		var module: Node = entry.get("module") as Node
		var port: Dictionary = entry.get("port", {}) as Dictionary
		if not is_instance_valid(module) or module.is_queued_for_deletion():
			_cancel_entry(entry, reward, false)
			continue
		if not bool(port.get("valid", false)):
			_cancel_entry(entry, reward, true)
			continue
		var outlet: Vector2 = port.position
		if reward.spawn_at_relic and _outlet_blocked(outlet):
			entry.blocked_ticks = int(entry.get("blocked_ticks", 0)) + 1
			if int(entry.blocked_ticks) >= BLOCKED_TICKS:
				_cancel_entry(entry, reward, true)
			continue
		var new_ball: Node = _emit_ball(reward, port, sim_tick)
		if new_ball == null:
			_cancel_entry(entry, reward, true)
			continue
		entry.remaining = int(entry.remaining) - 1
		entry.emitted = int(entry.emitted) + 1
		_reserved -= 1
		entry.next_emit_tick = sim_tick + reward.spacing_ticks
		_emit_entry_status(entry, reward, false)
		if int(entry.remaining) <= 0:
			_queue.erase(entry)

func _emit_ball(reward: RelicBallReward, port: Dictionary, sim_tick: int) -> Node:
	if not reward.spawn_at_relic and (not is_instance_valid(_board._hopper) or not _board._hopper.has_method("accept_temporary_ball")):
		return null

	var ball: Node = _spawn(reward, port.position, port.direction, float(port.get("speed", 170.0)), sim_tick)

	if ball != null and not reward.spawn_at_relic:
		_board._active_balls.erase(ball)
		_board._hopper.accept_temporary_ball(ball)

	return ball


func _allocate_entry(entry: Dictionary) -> void:
	entry.allocated = true
	var reward: RelicBallReward = entry.get("reward") as RelicBallReward
	var free_slots: int = maxi(0, RelicBallReward.MAX_ACTIVE_OR_RESERVED - _balls.size() - _reserved)
	var count: int = mini(int(entry.get("offered", 0)), free_slots)
	entry.remaining = count
	entry.canceled = int(entry.offered) - count
	_reserved += count
	_emit_entry_status(entry, reward, false)
	if count <= 0:
		_queue.erase(entry)

static func _entry_before(left: Dictionary, right: Dictionary) -> bool:
	var left_module: Node = left.get("module") as Node
	var right_module: Node = right.get("module") as Node
	var left_id: int = left_module.get_instance_id() if is_instance_valid(left_module) else 2147483647
	var right_id: int = right_module.get_instance_id() if is_instance_valid(right_module) else 2147483647
	if left_id == right_id:
		return int(left.get("sequence", 0)) < int(right.get("sequence", 0))
	return left_id < right_id

func expire(sim_tick: int) -> void:
	for ball: Node in _balls.duplicate():
		if not is_instance_valid(ball) or not ball.has_method("is_temporary_relic_ball"):
			_balls.erase(ball)
			continue
		if ball.has_method("update_temporary_relic_age"):
			ball.update_temporary_relic_age(sim_tick)
		if sim_tick >= ball.get_temporary_relic_expiration_tick():
			_remove_ball(ball, false)

func discard() -> void:
	_queue.clear()
	_reserved = 0
	_consumed.clear()
	_activation_sequence = 0
	for ball: Node in _balls.duplicate():
		_remove_ball(ball, false)

func register_ball(ball: Node) -> void:
	if is_instance_valid(ball) and not _balls.has(ball):
		_balls.append(ball)

func unregister_ball(ball: Node) -> void:
	_balls.erase(ball)

func collect_ball(ball: Node) -> bool:
	if not is_instance_valid(ball) or not ball.has_method("mark_temporary_relic_collected"):
		return false
	if not ball.mark_temporary_relic_collected():
		return false
	_remove_ball(ball, true, true)
	return true

## Removes a temporary ball without awarding a bottom payout.
func discard_ball(ball: Node) -> void:
	if is_instance_valid(ball):
		_remove_ball(ball, false)

func slot_available() -> bool:
	_prune_balls()
	return _balls.size() + _reserved < RelicBallReward.MAX_ACTIVE_OR_RESERVED

func get_ball_count() -> int:
	return _balls.size()

func get_reserved_count() -> int:
	return _reserved

func _cancel_entry(entry: Dictionary, reward: RelicBallReward, blocked: bool) -> void:
	var remaining: int = int(entry.get("remaining", 0))
	_reserved -= remaining
	var un_emitted: int = maxi(0, int(entry.get("offered", 0)) - int(entry.get("emitted", 0)) - int(entry.get("canceled", 0)))
	entry.canceled = int(entry.get("canceled", 0)) + maxi(remaining, un_emitted)
	entry.remaining = 0
	_emit_entry_status(entry, reward, blocked)
	_queue.erase(entry)

func _emit_entry_status(entry: Dictionary, reward: RelicBallReward, blocked: bool) -> void:
	if reward != null:
		reward_status.emit(reward.source_id, int(entry.get("offered", 0)),
			int(entry.get("emitted", 0)), int(entry.get("canceled", 0)), blocked)

func _prune_balls() -> void:
	for ball: Node in _balls.duplicate():
		if not is_instance_valid(ball) or ball.is_queued_for_deletion():
			_balls.erase(ball)

func _remove_ball(ball: Node, collected: bool, already_marked: bool = false) -> void:
	_balls.erase(ball)
	if is_instance_valid(_board) and is_instance_valid(_board._hopper):
		_board._hopper.forget_temporary_ball(ball)
	if _board != null and "_active_balls" in _board:
		_board._active_balls.erase(ball)
	_detach_capture(ball)
	if ball.has_meta("relic_flow_owner"):
		ball.remove_meta("relic_flow_owner")
	if collected and not already_marked and ball.has_method("mark_temporary_relic_collected"):
		ball.mark_temporary_relic_collected()
	elif ball.has_method("clear_temporary_relic_state"):
		ball.clear_temporary_relic_state()
	if is_instance_valid(ball):
		ball.queue_free()

func _detach_capture(ball: Node) -> void:
	if _board == null:
		return
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else ball.get_instance_id()
	if _board.has_method("_detach_ball_from_sticky_slime_if_stuck"):
		_board._detach_ball_from_sticky_slime_if_stuck(ball)
	if "_goblin_grab_in_progress" in _board:
		_board._goblin_grab_in_progress.erase(bid)
	if "_buffet_affected_balls" in _board:
		_board._buffet_affected_balls.erase(ball)
	for module: Node in _board._placed_module_nodes.values() if "_placed_module_nodes" in _board else []:
		if not is_instance_valid(module) or not module.has_method("get_all_components"):
			continue
		for component: Node in module.get_all_components():
			_detach_from_component(component, ball, bid)
	if "freeze" in ball:
		ball.freeze = false

func _detach_from_component(component: Node, ball: Node, bid: int) -> void:
	for property: StringName in [&"retained_balls", &"_balls_awaiting_exit", &"_captured_balls", &"locked_balls"]:
		if property in component:
			var balls: Array = component.get(property)
			balls.erase(ball)
	if "_travelers" in component:
		component._travelers.erase(ball.get_instance_id())
	if "_guided_balls" in component:
		component._guided_balls.erase(bid)
	if "_previous_freeze" in component:
		component._previous_freeze.erase(ball.get_instance_id())

func _outlet_blocked(outlet: Vector2) -> bool:
	for ball: Node in _board._active_balls:
		if is_instance_valid(ball) and ball.global_position.distance_squared_to(outlet) < 4.0 * BALL_RADIUS * BALL_RADIUS:
			return true
	if not _board.is_inside_tree():
		return false
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = BALL_RADIUS
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, outlet)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return not _board.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _port_for(module: Node, triggering_ball: Node) -> Dictionary:
	if not is_instance_valid(module):
		return {"valid": false}
	var data: Resource = module.module_data as Resource
	var rotation: int = int(module.rotation_step)
	if data == null or not data.has_method("get_flow_ports"):
		return _fallback_impact_port(module, triggering_ball)
	var ports: Array = data.get_flow_ports(rotation)
	var has_exit: bool = false
	for candidate: Dictionary in ports:
		if str(candidate.get("kind", "")) == "exit":
			has_exit = true
	var selected: Dictionary = {}
	var best_distance: float = INF
	for candidate: Dictionary in ports:
		if has_exit and str(candidate.get("kind", "")) != "exit":
			continue
		var center: Vector2 = _port_center(module, candidate)
		var distance: float = center.distance_squared_to(triggering_ball.global_position) if is_instance_valid(triggering_ball) else float(ports.find(candidate))
		if distance < best_distance:
			best_distance = distance
			selected = candidate
	if selected.is_empty():
		return _fallback_impact_port(module, triggering_ball)
	var direction: Vector2 = selected.get("normal", Vector2.DOWN).normalized()
	return {"valid": true, "position": _port_center(module, selected) + direction * (BALL_RADIUS + 4.0), "direction": direction, "speed": _release_speed(module)}

func _fallback_impact_port(module: Node, triggering_ball: Node) -> Dictionary:
	var data: Resource = module.module_data as Resource
	if data == null or data.cells.is_empty():
		return {"valid": false}
	var cells: Array[Vector2i] = data.get_anchored_rotated_cells(int(module.rotation_step))
	var bounds: Rect2i = _cell_bounds(cells)
	var candidates: Array[Dictionary] = []
	for x: int in range(bounds.position.x, bounds.end.x):
		_add_impact_candidate(candidates, module, cells, Vector2i(x, bounds.position.y), Vector2.UP)
		_add_impact_candidate(candidates, module, cells, Vector2i(x, bounds.end.y - 1), Vector2.DOWN)
	for y: int in range(bounds.position.y, bounds.end.y):
		_add_impact_candidate(candidates, module, cells, Vector2i(bounds.position.x, y), Vector2.LEFT)
		_add_impact_candidate(candidates, module, cells, Vector2i(bounds.end.x - 1, y), Vector2.RIGHT)
	if candidates.is_empty():
		return {"valid": false}
	var chosen: Dictionary = candidates[0]
	if is_instance_valid(triggering_ball):
		for candidate: Dictionary in candidates:
			if candidate.position.distance_squared_to(triggering_ball.global_position) < chosen.position.distance_squared_to(triggering_ball.global_position):
				chosen = candidate
	return {"valid": true, "position": chosen.position + chosen.direction * (BALL_RADIUS + 4.0), "direction": chosen.direction, "speed": _release_speed(module)}

func _add_impact_candidate(candidates: Array[Dictionary], module: Node, cells: Array[Vector2i], cell: Vector2i, normal: Vector2) -> void:
	var neighbor: Vector2i = cell + Vector2i(int(normal.x), int(normal.y))
	if not cells.has(cell) or cells.has(neighbor):
		return
	var point: Vector2 = module.global_position + Vector2(
		(float(cell.x) + normal.x * 0.5) * CELL_WIDTH,
		(float(cell.y) + normal.y * 0.5) * CELL_HEIGHT)
	candidates.append({"position": point, "direction": normal})

func _cell_bounds(cells: Array[Vector2i]) -> Rect2i:
	var bounds: Rect2i = Rect2i(cells[0], Vector2i.ONE)
	for cell: Vector2i in cells:
		bounds = bounds.expand(cell)
	return bounds

func _release_speed(module: Node) -> float:
	for component: Node in module.get_all_components() if module.has_method("get_all_components") else []:
		if component.get("release_impulse_strength") != null:
			return float(component.release_impulse_strength)
		if component.get("eject_impulse_strength") != null:
			return float(component.eject_impulse_strength)
		if component.get("impulse_strength") != null and float(component.impulse_strength) > 0.0:
			return float(component.impulse_strength)
		if component.get("speed_multiplier") != null:
			return 300.0 * float(component.speed_multiplier)
	return 170.0

func _port_center(module: Node, port: Dictionary) -> Vector2:
	var p1: Vector2 = port.get("p1", Vector2.ZERO)
	var p2: Vector2 = port.get("p2", p1)
	var center: Vector2 = (p1 + p2) * 0.5
	return module.global_position + Vector2(center.x * CELL_WIDTH, center.y * CELL_HEIGHT)

func _spawn(reward: RelicBallReward, outlet: Vector2, direction: Vector2, speed: float, sim_tick: int) -> Node:
	if _board._ball_scene == null or _board._balls_container == null:
		return null
	var definition: BallDefinition = _definition_for(reward.ball_type)
	if definition == null:
		return null
	var ball: Node = _board._ball_scene.instantiate()
	if ball == null:
		return null
	_board._next_split_ball_id += 1
	ball.set_ball_id(_board._next_split_ball_id)
	_board._balls_container.add_child(ball)
	ball.set_definition(definition.duplicate(true))
	ball.mark_temporary_relic_ball(sim_tick + LIFE_TICKS, reward.source_id, sim_tick)
	ball.global_position = outlet
	ball.linear_velocity = direction.normalized() * speed
	_board._active_balls.append(ball)
	_balls.append(ball)
	_board._ball_hit_count_this_visit[ball.get_ball_id()] = 0
	_board._splitter_triggered_this_visit[ball.get_ball_id()] = false
	return ball

func _definition_for(ball_type: String) -> BallDefinition:
	var root: Node = _board.get_parent()
	var handler: Node = root.get_node_or_null("RewardHandler") if root else null
	if handler and handler.has_method("get_catalog_ball_definitions"):
		for definition: Variant in handler.get_catalog_ball_definitions():
			if definition is BallDefinition and str((definition as BallDefinition).ability_name) == ball_type:
				return definition as BallDefinition
	var fallback: BallDefinition = BallDefinition.new()
	fallback.ability_name = "" if ball_type == "Plain" else ball_type
	fallback.base_energy = Constants.legacy_display_energy_to_current(20)
	fallback.alignment = Constants.ALIGNMENT_MAIN
	return fallback
