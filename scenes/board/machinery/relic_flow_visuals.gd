@tool
extends RefCounted
## Draws shared entrances, exits, and physical wall shapes.

const SIZE: Vector2 = Vector2(52.0, 56.0)

## Creates engine collision walls from the same segments used by the preview.
static func build_walls(data: Resource, steps: int) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.name = "FlowWalls"
	body.collision_layer = 1
	body.collision_mask = 1
	for edge: Dictionary in data.get_solid_edge_segments(steps):
		var shape: SegmentShape2D = SegmentShape2D.new()
		shape.a = edge.p1 * SIZE
		shape.b = edge.p2 * SIZE
		var collision: CollisionShape2D = CollisionShape2D.new()
		collision.shape = shape
		body.add_child(collision)
	return body

## Draws arrows at open edges without drawing a false closed chassis.
static func draw_ports(canvas: CanvasItem, data: Resource, steps: int, size: Vector2, offset: Vector2 = Vector2.ZERO) -> void:
	for port: Dictionary in data.get_flow_ports(steps):
		var center: Vector2 = (port.p1 + port.p2) * 0.5 * size + offset
		var direction: Vector2 = port.normal if port.kind == "exit" else -port.normal
		var color: Color = Color(0.25, 0.95, 0.65) if port.kind == "entry" else Color(1.0, 0.75, 0.25)
		var tip: Vector2 = center + direction * 8.0
		var side: Vector2 = Vector2(-direction.y, direction.x) * 4.0
		canvas.draw_line(center - direction * 8.0, tip, color, 2.0)
		canvas.draw_line(tip, center + side, color, 2.0)
		canvas.draw_line(tip, center - side, color, 2.0)

## Supports isolated collision tests outside the scene tree.
static func bounce_wall(module_data: Resource, rotation_step: int, ball: Node, module_base_pos: Vector2) -> Dictionary:
	if module_data == null:
		return { "activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO }
	var segments: Array[Dictionary] = module_data.get_solid_edge_segments(rotation_step)
	if segments.is_empty():
		return { "activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO }

	var ball_pos: Vector2 = (ball.global_position if ball.is_inside_tree() else ball.position) if "position" in ball else Vector2.ZERO
	var ball_vel: Vector2 = ball.linear_velocity if "linear_velocity" in ball else Vector2.ZERO
	var ball_radius: float = Constants.BALL_RADIUS

	for seg in segments:
		var p1_l: Vector2 = seg["p1"]
		var p2_l: Vector2 = seg["p2"]
		var w1: Vector2 = module_base_pos + Vector2(p1_l.x * SIZE.x, p1_l.y * SIZE.y)
		var w2: Vector2 = module_base_pos + Vector2(p2_l.x * SIZE.x, p2_l.y * SIZE.y)
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(ball_pos, w1, w2)
		if ball_pos.distance_to(closest) <= ball_radius + 2.0:
			var hit_normal: Vector2 = (ball_pos - closest).normalized()
			if hit_normal.length_squared() < 0.01:
				hit_normal = seg["normal"]
			var eff_vel: Vector2 = ball_vel if ball_vel.length_squared() > 0.01 else -hit_normal * 100.0
			if eff_vel.dot(hit_normal) <= 0.0:
				var reflected: Vector2 = eff_vel.bounce(hit_normal) * 0.85
				if "linear_velocity" in ball:
					ball.linear_velocity = reflected
				return { "activated": true, "energy_granted": 0, "impulse_applied": reflected - eff_vel, "wall_hit": true }
	return { "activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO }


## Draws the ordered route used by the live track.
static func draw_route(canvas: CanvasItem, data: Resource, steps: int, size: Vector2, offset: Vector2) -> void:
	if data.unified_component_type != 17 or data.goal_target_sequence.size() < 2:
		return
	var cells: Array = data.get_anchored_rotated_cells(steps)
	var route: PackedVector2Array = []
	for cell: Vector2i in data.goal_target_sequence:
		var index: int = data.cells.find(cell)
		if index >= 0:
			route.append(Vector2(cells[index]) * size + offset)
	if route.size() < 2:
		return
	var entry: Vector2 = data.get_rotated_direction(Vector2.DOWN, steps)
	route.insert(0, route[0] - entry * size * 0.5)
	route.append(route[-1] + (route[-1] - route[-2]).normalized() * size * 0.5)
	canvas.draw_polyline(route, Color(0.1, 0.15, 0.18), size.x * 0.48, true)
	canvas.draw_polyline(route, Color(0.45, 0.8, 0.95), size.x * 0.34, true)
	canvas.draw_polyline(route, Color(0.1, 0.15, 0.18), size.x * 0.24, true)
