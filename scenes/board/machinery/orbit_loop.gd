extends PolyominoMachineryComponent
class_name OrbitLoop
## Curved high-speed turnaround rail lane that redirects balls along multi-peg V and U shapes.

#region Signals
signal orbit_traversed(orbit_node: OrbitLoop, ball: Node)
signal orbit_entered(orbit_node: OrbitLoop, ball: Node, port_id: int)
#endregion

#region Enums
enum LoopShape {
	SINGLE = 0,
	V_SHAPE_3 = 1,
	U_SHAPE_5 = 2,
	U_SHAPE_7 = 3,
	CUSTOM = 4
}
#endregion

#region Constants
const CELL_WIDTH: float = 52.0
const CELL_HEIGHT: float = 56.0
const DEFAULT_RADIUS: float = 22.0
const DEFAULT_ENERGY: int = 8
const DEFAULT_IMPULSE: float = 400.0
const ORBIT_REENTRY_COOLDOWN_TICKS: int = 45
#endregion

#region Exports & Variables
@export var speed_multiplier: float = 1.35
@export var guide_speed: float = 450.0
@export var port_radius: float = 24.0

var loop_shape: int = LoopShape.SINGLE
var traversal_count: int = 0
var waypoints: Array[Vector2] = []
var port_a: Vector2 = Vector2.ZERO
var port_b: Vector2 = Vector2.ZERO
var port_a_dir: Vector2 = Vector2.UP
var port_b_dir: Vector2 = Vector2.UP
var apex_point: Vector2 = Vector2.ZERO

var _guided_balls: Dictionary = {}  # bid -> { "ball": Node, "target_idx": int, "dir": int, "exit_dir": Vector2 }
var _pulse_t: float = 1.0
#endregion

#region Lifecycle Methods
func _init() -> void:
	is_permeable = true
	component_radius = DEFAULT_RADIUS
	base_energy = DEFAULT_ENERGY
	impulse_strength = DEFAULT_IMPULSE
	exit_cooldown_ticks = ORBIT_REENTRY_COOLDOWN_TICKS
	hit_cooldown_ticks = ORBIT_REENTRY_COOLDOWN_TICKS
	cell_type = PolyominoModuleData.CellType.ORBIT_LOOP

func _ready() -> void:
	is_permeable = true
	exit_cooldown_ticks = ORBIT_REENTRY_COOLDOWN_TICKS
	hit_cooldown_ticks = ORBIT_REENTRY_COOLDOWN_TICKS
	cell_type = PolyominoModuleData.CellType.ORBIT_LOOP
	if footprint_cells.size() > 0:
		configure_from_cells(footprint_cells)
	super._ready()
	set_process(true)
#endregion

#region Configuration Methods
func configure_footprint(cell_count: int) -> void:
	if footprint_cells.size() > 0:
		configure_from_cells(footprint_cells)
		return
	if cell_count >= 7:
		configure_u_shape_7()
	elif cell_count >= 5:
		configure_u_shape_5()
	elif cell_count >= 3:
		configure_v_shape_3()
	else:
		loop_shape = LoopShape.SINGLE
		component_radius = DEFAULT_RADIUS
		base_energy = DEFAULT_ENERGY
		impulse_strength = DEFAULT_IMPULSE
		waypoints.clear()
	queue_redraw()

func configure_v_shape_3(open_dir: Vector2 = Vector2.DOWN) -> void:
	loop_shape = LoopShape.V_SHAPE_3
	base_energy = 15
	impulse_strength = 500.0
	component_radius = 52.0
	var h_dir: Vector2 = open_dir.normalized() if open_dir != Vector2.ZERO else Vector2.DOWN
	var perp := Vector2(h_dir.y, -h_dir.x)
	port_a = perp * (-CELL_WIDTH * 0.5) + h_dir * (CELL_HEIGHT * 0.35)
	apex_point = -h_dir * (CELL_HEIGHT * 0.35)
	port_b = perp * (CELL_WIDTH * 0.5) + h_dir * (CELL_HEIGHT * 0.35)
	port_a_dir = h_dir
	port_b_dir = h_dir
	waypoints = [port_a, apex_point, port_b]
	queue_redraw()

func configure_u_shape_5(open_dir: Vector2 = Vector2.DOWN) -> void:
	loop_shape = LoopShape.U_SHAPE_5
	base_energy = 25
	impulse_strength = 600.0
	component_radius = 65.0
	var h_dir: Vector2 = open_dir.normalized() if open_dir != Vector2.ZERO else Vector2.DOWN
	var perp := Vector2(h_dir.y, -h_dir.x)
	port_a = perp * (-CELL_WIDTH) - h_dir * (CELL_HEIGHT * 0.5)
	var corner_a: Vector2 = perp * (-CELL_WIDTH) + h_dir * (CELL_HEIGHT * 0.5)
	apex_point = h_dir * (CELL_HEIGHT * 0.5)
	var corner_b: Vector2 = perp * CELL_WIDTH + h_dir * (CELL_HEIGHT * 0.5)
	port_b = perp * CELL_WIDTH - h_dir * (CELL_HEIGHT * 0.5)
	port_a_dir = -h_dir
	port_b_dir = -h_dir
	waypoints = [port_a, corner_a, apex_point, corner_b, port_b]
	queue_redraw()

func configure_u_shape_7(open_dir: Vector2 = Vector2.DOWN) -> void:
	loop_shape = LoopShape.U_SHAPE_7
	base_energy = 35
	impulse_strength = 700.0
	component_radius = 85.0
	var h_dir: Vector2 = open_dir.normalized() if open_dir != Vector2.ZERO else Vector2.DOWN
	var perp := Vector2(h_dir.y, -h_dir.x)
	port_a = perp * (-CELL_WIDTH) - h_dir * CELL_HEIGHT
	var mid_a: Vector2 = perp * (-CELL_WIDTH)
	var corner_a: Vector2 = perp * (-CELL_WIDTH) + h_dir * CELL_HEIGHT
	apex_point = h_dir * CELL_HEIGHT
	var corner_b: Vector2 = perp * CELL_WIDTH + h_dir * CELL_HEIGHT
	var mid_b: Vector2 = perp * CELL_WIDTH
	port_b = perp * CELL_WIDTH - h_dir * CELL_HEIGHT
	port_a_dir = -h_dir
	port_b_dir = -h_dir
	waypoints = [port_a, mid_a, corner_a, apex_point, corner_b, mid_b, port_b]
	queue_redraw()

func configure_from_cells(cells: Array[Vector2i]) -> void:
	if cells.is_empty():
		return
	footprint_cells = cells
	var count: int = cells.size()
	if count >= 7:
		loop_shape = LoopShape.U_SHAPE_7
		base_energy = 35
		impulse_strength = 700.0
		component_radius = 85.0
	elif count >= 5:
		loop_shape = LoopShape.U_SHAPE_5
		base_energy = 25
		impulse_strength = 600.0
		component_radius = 65.0
	elif count >= 3:
		loop_shape = LoopShape.V_SHAPE_3
		base_energy = 15
		impulse_strength = 500.0
		component_radius = 52.0
	else:
		loop_shape = LoopShape.SINGLE
		component_radius = DEFAULT_RADIUS
		waypoints.clear()
		queue_redraw()
		return

	# Calculate center offset
	var sum := Vector2.ZERO
	for c in cells:
		sum += Vector2(float(c.x) * CELL_WIDTH, float(c.y) * CELL_HEIGHT)
	var center_offset: Vector2 = sum / float(count)

	# Build adjacency and find endpoints
	var local_pts: Array[Vector2] = []
	for c in cells:
		local_pts.append(Vector2(float(c.x) * CELL_WIDTH, float(c.y) * CELL_HEIGHT) - center_offset)

	var ordered_idx: Array[int] = _order_cells_by_adjacency(cells)
	waypoints.clear()
	for idx in ordered_idx:
		waypoints.append(local_pts[idx])

	if waypoints.size() >= 2:
		port_a = waypoints[0]
		port_b = waypoints[waypoints.size() - 1]
		var mid_idx: int = waypoints.size() / 2
		apex_point = waypoints[mid_idx]
		port_a_dir = (waypoints[0] - waypoints[1]).normalized()
		port_b_dir = (waypoints[waypoints.size() - 1] - waypoints[waypoints.size() - 2]).normalized()
	queue_redraw()

func _order_cells_by_adjacency(cells: Array[Vector2i]) -> Array[int]:
	var n: int = cells.size()
	var adj: Array[Array] = []
	for i in range(n):
		adj.append([])

	for i in range(n):
		for j in range(i + 1, n):
			var d: Vector2i = cells[i] - cells[j]
			if absi(d.x) <= 1 and absi(d.y) <= 1:
				adj[i].append(j)
				adj[j].append(i)

	# Find degree-1 endpoint or first cell
	var start_node: int = 0
	for i in range(n):
		if adj[i].size() == 1:
			start_node = i
			break

	var visited: Dictionary = {}
	var path: Array[int] = []
	var curr: int = start_node
	while curr != -1 and not visited.has(curr):
		visited[curr] = true
		path.append(curr)
		var next_node: int = -1
		for neighbor in adj[curr]:
			if not visited.has(neighbor):
				next_node = neighbor
				break
		curr = next_node

	# Append any remaining unvisited cells
	for i in range(n):
		if not visited.has(i):
			path.append(i)
	return path
#endregion

#region Getters
func get_port_a() -> Vector2: return port_a
func get_port_b() -> Vector2: return port_b
func get_apex_point() -> Vector2: return apex_point
func get_waypoints() -> Array[Vector2]: return waypoints
func get_loop_shape() -> int: return loop_shape
func is_ball_traversing(ball_id: int) -> bool: return _guided_balls.has(ball_id)
#endregion

#region Collision and Physics
func can_activate_for_ball(ball_id: int, sim_tick: int) -> bool:
	if _guided_balls.has(ball_id):
		return false
	return super.can_activate_for_ball(ball_id, sim_tick)

func record_ball_exit(ball_id: int, sim_tick: int) -> void:
	super.record_ball_exit(ball_id, sim_tick)
	_guided_balls.erase(ball_id)

func check_ball_contact(ball_pos: Vector2, ball_radius: float, module_base_pos: Vector2 = Vector2.ZERO) -> bool:
	var my_global: Vector2 = global_position if is_inside_tree() else (module_base_pos + position)
	var local_ball: Vector2 = ball_pos - my_global

	if waypoints.size() >= 2:
		var contact_sq: float = (port_radius + ball_radius) * (port_radius + ball_radius)
		if local_ball.distance_squared_to(port_a) <= contact_sq:
			return true
		if local_ball.distance_squared_to(port_b) <= contact_sq:
			return true
		for i in range(waypoints.size() - 1):
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(local_ball, waypoints[i], waypoints[i + 1])
			if local_ball.distance_squared_to(closest) <= contact_sq:
				return true
	var hr: float = component_radius + ball_radius + 4.0
	return local_ball.length_squared() <= (hr * hr)

func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else ball.get_instance_id()
	if not can_activate_for_ball(bid, sim_tick):
		return { "activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO, "type": cell_type }

	record_activation(bid, sim_tick)
	_play_visual_feedback()
	_play_audio_feedback()

	var energy: int = base_energy
	if ball.has_method("add_peg_energy") and energy > 0:
		ball.add_peg_energy(energy)

	traversal_count += 1
	orbit_traversed.emit(self, ball)
	_pulse_t = 0.0

	var exit_dir: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	var travel_dir: int = 1
	var start_idx: int = 0
	var port_id: int = 0

	if waypoints.size() >= 2:
		var my_global: Vector2 = global_position if is_inside_tree() else position
		var b_pos: Vector2 = ball.global_position if "global_position" in ball else (ball.position if "position" in ball else Vector2.ZERO)
		var local_b: Vector2 = b_pos - my_global
		var dist_a: float = local_b.distance_to(port_a)
		var dist_b: float = local_b.distance_to(port_b)

		if dist_b < dist_a:
			# Entered at Port B, traveling toward Port A
			travel_dir = -1
			start_idx = waypoints.size() - 1
			exit_dir = port_b_dir if port_b_dir != Vector2.ZERO else port_a_dir
			port_id = 1
		else:
			# Entered at Port A, traveling toward Port B
			travel_dir = 1
			start_idx = 0
			exit_dir = port_a_dir if port_a_dir != Vector2.ZERO else port_b_dir
			port_id = 0

	orbit_entered.emit(self, ball, port_id)
	var impulse: Vector2 = exit_dir * impulse_strength

	if is_inside_tree() and waypoints.size() >= 2 and is_instance_valid(ball) and ("linear_velocity" in ball or "position" in ball):
		_guided_balls[bid] = {
			"ball": ball,
			"target_idx": start_idx + travel_dir,
			"dir": travel_dir,
			"exit_dir": exit_dir
		}
	else:
		_apply_ball_impulse(ball, impulse)

	component_activated.emit(self, ball, energy, impulse)
	queue_redraw()
	return {
		"activated": true,
		"energy_granted": energy,
		"impulse_applied": impulse,
		"type": cell_type
	}

func _compute_impulse(_ball: Node) -> Vector2:
	if waypoints.size() >= 2:
		return port_b_dir * impulse_strength
	var dir_norm: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	return dir_norm * impulse_strength

func _process(delta: float) -> void:
	if _pulse_t < 1.0:
		_pulse_t = minf(1.0, _pulse_t + delta * 2.5)
		queue_redraw()

	if not _guided_balls.is_empty():
		var my_pos: Vector2 = global_position if is_inside_tree() else position
		for bid in _guided_balls.keys():
			var entry: Dictionary = _guided_balls[bid]
			var ball: Node = entry.get("ball")
			if not is_instance_valid(ball):
				_guided_balls.erase(bid)
				continue

			var target_idx: int = entry.get("target_idx", 0)
			var travel_dir: int = entry.get("dir", 1)
			var exit_dir: Vector2 = entry.get("exit_dir", Vector2.UP)

			if target_idx < 0 or target_idx >= waypoints.size():
				_apply_ball_impulse(ball, exit_dir * impulse_strength)
				record_ball_exit(bid, _current_sim_tick)
				_guided_balls.erase(bid)
				continue

			var target_local: Vector2 = waypoints[target_idx]
			var target_global: Vector2 = my_pos + target_local
			var ball_pos: Vector2 = ball.global_position if "global_position" in ball else (ball.position if "position" in ball else Vector2.ZERO)
			var dist: float = ball_pos.distance_to(target_global)

			if dist < 16.0:
				entry["target_idx"] = target_idx + travel_dir
			else:
				var move_dir: Vector2 = (target_global - ball_pos).normalized()
				if "linear_velocity" in ball:
					ball.linear_velocity = move_dir * (guide_speed * speed_multiplier)
				if "position" in ball:
					ball.position += move_dir * (guide_speed * speed_multiplier * delta)

	super._process(delta)
#endregion

#region Visual Rendering
func _draw_component_body() -> void:
	if waypoints.size() >= 2:
		var rail_gap: float = 12.0
		var outer_points: PackedVector2Array = []
		var inner_points: PackedVector2Array = []

		for i in range(waypoints.size()):
			var p: Vector2 = waypoints[i]
			var tangent: Vector2 = Vector2.UP
			if i == 0:
				tangent = (waypoints[1] - waypoints[0]).normalized()
			elif i == waypoints.size() - 1:
				tangent = (waypoints[i] - waypoints[i - 1]).normalized()
			else:
				tangent = (waypoints[i + 1] - waypoints[i - 1]).normalized()
			var normal: Vector2 = Vector2(-tangent.y, tangent.x)
			outer_points.append(p + normal * rail_gap)
			inner_points.append(p - normal * rail_gap)

		# Dark under-track outline
		var ink_color := Color(0.08, 0.08, 0.12, 0.75)
		draw_polyline(outer_points, ink_color, 4.0)
		draw_polyline(inner_points, ink_color, 4.0)

		# Chrome rails
		var rail_col := Color(0.78, 0.8, 0.88, 0.95)
		draw_polyline(outer_points, rail_col, 2.0)
		draw_polyline(inner_points, rail_col, 2.0)

		# Entry and exit port brackets
		draw_circle(port_a, 7.0, Color(0.2, 0.22, 0.28, 0.9))
		draw_arc(port_a, 7.0, 0, TAU, 16, _accent_color, 2.0)
		draw_circle(port_b, 7.0, Color(0.2, 0.22, 0.28, 0.9))
		draw_arc(port_b, 7.0, 0, TAU, 16, _accent_color, 2.0)

		# Directional neon indicators along track
		for i in range(waypoints.size() - 1):
			var mid: Vector2 = (waypoints[i] + waypoints[i + 1]) * 0.5
			var t_dir: Vector2 = (waypoints[i + 1] - waypoints[i]).normalized()
			draw_line(mid - t_dir * 6.0, mid + t_dir * 6.0, _accent_color, 2.0)
			var norm: Vector2 = Vector2(-t_dir.y, t_dir.x)
			draw_line(mid, mid - t_dir * 4.0 + norm * 4.0, _accent_color, 1.5)
			draw_line(mid, mid - t_dir * 4.0 - norm * 4.0, _accent_color, 1.5)

		# Animated pulse
		if _pulse_t < 1.0:
			var total_segments: int = waypoints.size() - 1
			var seg_float: float = _pulse_t * float(total_segments)
			var seg_idx: int = clampi(int(seg_float), 0, total_segments - 1)
			var seg_sub_t: float = seg_float - float(seg_idx)
			var pulse_p: Vector2 = waypoints[seg_idx].lerp(waypoints[seg_idx + 1], seg_sub_t)
			draw_circle(pulse_p, 8.0, Color(1.0, 1.0, 1.0, (1.0 - _pulse_t) * 0.9))
			draw_arc(pulse_p, 12.0, 0, TAU, 16, _accent_color, 2.5)
	else:
		var r: float = component_radius
		var dir_norm: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.UP
		var angle: float = dir_norm.angle()
		draw_arc(Vector2.ZERO, r, angle - PI * 0.4, angle + PI * 0.4, 16, Color(0.7, 0.7, 0.75), 2.0)
		draw_arc(Vector2.ZERO, r * 0.65, angle - PI * 0.4, angle + PI * 0.4, 16, Color(0.5, 0.5, 0.55), 1.5)
		var arrow_tip: Vector2 = dir_norm * (r * 0.8)
		var arrow_base: Vector2 = dir_norm * (r * 0.3)
		draw_line(arrow_base, arrow_tip, _accent_color, 2.0)
#endregion
