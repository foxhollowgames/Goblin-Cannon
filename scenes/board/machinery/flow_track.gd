extends "res://scenes/board/machinery/polyomino_machinery_component.gd"
## A continuous guided rail. Only entry-to-exit traversal earns a route reward.

signal route_completed(ball: Node)

const Geometry = preload("res://resources/polyomino/relic_flow_geometry.gd")
const CELL_SIZE: Vector2 = Vector2(52.0, 56.0)
const SPEED: float = 280.0
const ENTRY_RADIUS: float = 16.0
const MAX_TRAVEL_TICKS: int = 600
var points: PackedVector2Array = []
var _travelers: Dictionary = {} ## int instance ID -> ball, next waypoint, gravity, ticks
var _exit_direction: Vector2 = Vector2.DOWN

func _init() -> void:
	is_permeable = true
	base_energy = 0
	component_radius = ENTRY_RADIUS
	exit_cooldown_ticks = 60

## Builds an ordered rail with external entry and exit points.
func configure_route(data: Resource, steps: int) -> void:
	points.clear()
	var cells: Array = data.get_anchored_rotated_cells(steps)
	for original: Vector2i in data.goal_target_sequence:
		var index: int = data.cells.find(original)
		if index >= 0:
			points.append(Vector2(cells[index]) * CELL_SIZE - position)
	if points.size() < 2:
		return
	var entry_dir: Vector2 = Geometry.rotate_point(Vector2.DOWN, steps)
	_exit_direction = (points[-1] - points[-2]).normalized()
	points.insert(0, points[0] - entry_dir * 28.0)
	points.append(points[-1] + _exit_direction * 30.0)
	queue_redraw()

## Only the entry mouth can capture a new ball.
func check_ball_contact(ball_pos: Vector2, ball_radius: float, base_world_pos: Vector2 = Vector2.ZERO) -> bool:
	if points.size() < 2:
		return false
	var origin: Vector2 = global_position if is_inside_tree() else base_world_pos + position
	return ball_pos.distance_to(origin + points[0]) <= ENTRY_RADIUS + ball_radius

## Starts traversal without granting a completion reward.
func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	var id: int = ball.get_instance_id()
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else id
	if points.size() < 2 or _travelers.has(id) or not can_activate_for_ball(bid, sim_tick):
		return {"activated": false}
	record_activation(bid, sim_tick)
	var gravity: float = ball.gravity_scale if ball is RigidBody2D else 0.0
	_travelers[id] = {"ball": ball, "next": 1, "gravity": gravity, "ticks": 0}
	if ball is RigidBody2D:
		ball.gravity_scale = 0.0
	component_activated.emit(self, ball, 0, Vector2.ZERO)
	return {"activated": true, "energy_granted": 0, "impulse_applied": Vector2.ZERO}

func _physics_process(delta: float) -> void:
	if GameState.paused: return
	for id: int in _travelers.keys():
		var state: Dictionary = _travelers[id]
		var ball: Node2D = state.ball
		if not is_instance_valid(ball):
			_travelers.erase(id)
			continue
		state.ticks += 1
		if state.ticks > MAX_TRAVEL_TICKS:
			_release(id, false)
			continue
		var target: Vector2 = global_position + points[state.next]
		var distance: float = ball.global_position.distance_to(target)
		if distance <= maxf(6.0, SPEED * delta * 1.5):
			state.next += 1
			if state.next >= points.size():
				_release(id, true)
				continue
			target = global_position + points[state.next]
		ball.linear_velocity = (target - ball.global_position).normalized() * SPEED

func _release(id: int, completed: bool) -> void:
	var state: Dictionary = _travelers[id]
	var ball: Node = state.ball
	_travelers.erase(id)
	if not is_instance_valid(ball):
		return
	if ball is RigidBody2D:
		ball.gravity_scale = state.gravity
	ball.linear_velocity = _exit_direction * SPEED
	if completed:
		route_completed.emit(ball)

func _exit_tree() -> void:
	for id: int in _travelers.keys():
		_release(id, false)

func _draw_component_body() -> void:
	if points.size() < 2:
		return
	draw_polyline(points, Color(0.08, 0.1, 0.13), 30.0, true)
	draw_polyline(points, _accent_color.lightened(0.3), 25.0, true)
	draw_polyline(points, Color(0.08, 0.1, 0.13), 21.0, true)
	for index: int in [0, points.size() - 1]:
		var dir: Vector2 = (points[1] - points[0]).normalized() if index == 0 else _exit_direction
		var tip: Vector2 = points[index] + dir * 6.0
		var side: Vector2 = Vector2(-dir.y, dir.x) * 5.0
		draw_line(tip, points[index] - dir * 5.0 + side, Color.GREEN if index == 0 else Color.ORANGE, 2.0)
		draw_line(tip, points[index] - dir * 5.0 - side, Color.GREEN if index == 0 else Color.ORANGE, 2.0)
