extends PolyominoMachineryComponent
class_name WireGate
const BallFlow = preload("res://scenes/board/machinery/relic_ball_flow.gd")

signal ball_retained(gate_node: Node, count: int)
signal gate_opened(gate_node: Node)
signal gate_closed(gate_node: Node)
signal cascade_released(gate_node: Node, released_balls: Array)

@export var max_capacity: int = 3
@export var is_open: bool = false
@export var release_impulse_strength: float = 320.0
@export var auto_close_delay_sec: float = 0.6
@export var requires_external_activation: bool = false
@export var is_requirement_satisfied: bool = false
@export var cup_rect: Rect2 = Rect2()

const GATE_COOLDOWN_TICKS: int = 20
const PARTIAL_RELEASE_TICKS: int = 360
var _held_ticks: int = 0
var _previous_freeze: Dictionary = {} ## instance ID -> original freeze state

var retained_balls: Array[Node] = []
var _balls_awaiting_exit: Array[Node] = []
var _close_timer: Timer = null

func _init() -> void:
	is_permeable = true
	component_radius = 20.0
	base_energy = 4
	direction = Vector2.DOWN
	exit_cooldown_ticks = GATE_COOLDOWN_TICKS
	hit_cooldown_ticks = GATE_COOLDOWN_TICKS
	cell_type = PolyominoModuleData.CellType.WIRE_GATE
	cup_rect = Rect2(-component_radius, -component_radius, component_radius * 2.0, component_radius * 2.0)

func _ready() -> void:
	is_permeable = true
	exit_cooldown_ticks = GATE_COOLDOWN_TICKS
	hit_cooldown_ticks = GATE_COOLDOWN_TICKS
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN

	if cup_rect.size == Vector2.ZERO:
		cup_rect = Rect2(-component_radius, -component_radius, component_radius * 2.0, component_radius * 2.0)

	_close_timer = Timer.new()
	_close_timer.wait_time = auto_close_delay_sec
	_close_timer.one_shot = true
	_close_timer.timeout.connect(close_gate)
	add_child(_close_timer)

	super._ready()

func configure_footprint(cell_count: int, cells: Array[Vector2i] = []) -> void:
	if cells.is_empty() and not footprint_cells.is_empty():
		cells = footprint_cells
	if cell_count >= 9:
		component_radius = 76.0
		max_capacity = 6
		release_impulse_strength = 500.0
	elif cell_count >= 4:
		component_radius = 54.0
		max_capacity = 5
		release_impulse_strength = 440.0
	elif cell_count >= 2:
		component_radius = 38.0
		max_capacity = 4
		release_impulse_strength = 380.0
	else:
		component_radius = 20.0
		max_capacity = 3
		release_impulse_strength = 320.0

	cup_rect = Rect2(-component_radius, -component_radius, component_radius * 2.0, component_radius * 2.0)
	queue_redraw()

func can_activate_for_ball(ball_id: int, sim_tick: int) -> bool:
	for b in retained_balls:
		if is_instance_valid(b):
			var bid: int = b.get_ball_id() if b.has_method("get_ball_id") else b.get_instance_id()
			if bid == ball_id:
				return false
	return super.can_activate_for_ball(ball_id, sim_tick)

func record_ball_exit(ball_id: int, sim_tick: int) -> void:
	super.record_ball_exit(ball_id, sim_tick)
	# Leaving the entry sensor does not remove a ball held inside the cup.

func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	if not BallFlow.available(ball, self): return {"activated": false}
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else ball.get_instance_id()
	if not can_activate_for_ball(bid, sim_tick):
		return {"activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO, "type": cell_type}

	record_activation(bid, sim_tick)
	_play_visual_feedback()
	_play_audio_feedback()

	var energy: int = base_energy

	if is_open:
		if ball.has_method("add_peg_energy") and energy > 0:
			ball.add_peg_energy(energy)
		var pass_impulse: Vector2 = direction.normalized() * 120.0
		_apply_ball_impulse(ball, pass_impulse)
		component_activated.emit(self, ball, energy, pass_impulse)
		return {"activated": true, "energy_granted": energy, "impulse_applied": pass_impulse, "type": cell_type}

	var vel: Vector2 = ball.linear_velocity if "linear_velocity" in ball else Vector2.ZERO
	var gate_dir: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	var forward_dot: float = vel.dot(gate_dir)

	if forward_dot > -0.1 or vel == Vector2.ZERO:
		if retained_balls.size() < max_capacity:
			_retain_ball(ball)
			if ball.has_method("add_peg_energy") and energy > 0:
				ball.add_peg_energy(energy)

			if not requires_external_activation and retained_balls.size() >= max_capacity:
				release_retained_balls()
				return {
					"activated": true,
					"energy_granted": energy + 10,
					"impulse_applied": gate_dir * release_impulse_strength,
					"type": cell_type
				}

			component_activated.emit(self, ball, energy, Vector2.ZERO)
			return {"activated": true, "energy_granted": energy, "impulse_applied": Vector2.ZERO, "type": cell_type}
		else:
			var bounce_vel: Vector2 = -gate_dir * 120.0
			if "linear_velocity" in ball:
				ball.linear_velocity = vel.bounce(-gate_dir) * 0.8
			component_activated.emit(self, ball, 0, bounce_vel)
			return {"activated": true, "energy_granted": 0, "impulse_applied": bounce_vel, "type": cell_type}

	var bounce_impulse: Vector2 = -gate_dir * 100.0
	if "linear_velocity" in ball:
		ball.linear_velocity = vel.bounce(-gate_dir) * 0.8
	component_activated.emit(self, ball, 0, bounce_impulse)
	return {"activated": true, "energy_granted": 0, "impulse_applied": bounce_impulse, "type": cell_type}

func _retain_ball(ball: Node) -> void:
	BallFlow.claim(ball, self)
	if ball is RigidBody2D:
		_previous_freeze[ball.get_instance_id()] = ball.freeze
		ball.set_deferred("freeze", true)
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO
	if not retained_balls.has(ball):
		retained_balls.append(ball)
	ball_retained.emit(self, retained_balls.size())
	queue_redraw()

func open_gate() -> void:
	is_open = true
	gate_opened.emit(self)
	queue_redraw()

func close_gate() -> void:
	if not _balls_awaiting_exit.is_empty():
		return
	is_open = false
	_balls_awaiting_exit.clear()
	if _close_timer != null and not _close_timer.is_stopped():
		_close_timer.stop()
	gate_closed.emit(self)
	queue_redraw()

func satisfy_activation_requirement() -> Array:
	is_requirement_satisfied = true
	if not retained_balls.is_empty():
		return release_retained_balls()
	open_gate()
	return []

func release_retained_balls(award_bonus: bool = true) -> Array:
	open_gate()
	_held_ticks = 0
	var released: Array = retained_balls.duplicate()
	retained_balls.clear()
	_balls_awaiting_exit = released.duplicate()

	var gate_dir: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	var total: int = released.size()

	for i in range(total):
		var b: Node = released[i]
		if is_instance_valid(b):
			BallFlow.release(b, self)
			if b is RigidBody2D:
				b.set_deferred("freeze", _previous_freeze.get(b.get_instance_id(), false))
			_previous_freeze.erase(b.get_instance_id())
			var bid: int = b.get_ball_id() if b.has_method("get_ball_id") else b.get_instance_id()
			record_ball_exit(bid, _current_sim_tick)
			var spread: float = 0.0
			if total > 1:
				spread = lerpf(-0.25, 0.25, float(i) / float(total - 1))
			var impulse: Vector2 = gate_dir.rotated(spread) * release_impulse_strength
			_apply_ball_impulse(b, impulse)

	if award_bonus and not released.is_empty() and _all_balls_are_permanent(released):
		cascade_released.emit(self, released)

	if _close_timer != null and _close_timer.is_inside_tree():
		_close_timer.start()

	queue_redraw()
	return released

func _all_balls_are_permanent(balls: Array) -> bool:
	for ball: Node in balls:
		if is_instance_valid(ball) and ball.has_method("is_temporary_relic_ball") and ball.is_temporary_relic_ball():
			return false
	return true

func reset_gate() -> void:
	if not retained_balls.is_empty(): release_retained_balls(false)
	_held_ticks = 0
	retained_balls.clear()
	_balls_awaiting_exit.clear()
	is_open = false
	is_requirement_satisfied = false
	if _close_timer != null and not _close_timer.is_stopped():
		_close_timer.stop()
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if GameState.paused: return
	retained_balls = retained_balls.filter(func(ball: Node) -> bool: return is_instance_valid(ball))
	if not is_open and not retained_balls.is_empty():
		_held_ticks += 1
		if _held_ticks >= PARTIAL_RELEASE_TICKS: release_retained_balls(false)
	else:
		_held_ticks = 0
	_update_held_positions()
	_update_departures()

func _update_held_positions() -> void:
	if is_open: return
	var my_p: Vector2 = global_position if is_inside_tree() else position
	var gate_dir: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	var side: Vector2 = Vector2(-gate_dir.y, gate_dir.x)
	for index: int in range(retained_balls.size()):
		var ball: Node2D = retained_balls[index]
		var columns: int = mini(3, max_capacity)
		var x: float = (float(index % columns) - float(columns - 1) * 0.5) * 20.0
		var y: float = component_radius * 0.35 - float(index / columns) * 20.0
		if ball.is_inside_tree(): ball.global_position = my_p + side * x + gate_dir * y
		else: ball.position = my_p + side * x + gate_dir * y
		ball.linear_velocity = Vector2.ZERO

func _update_departures() -> void:
	if not is_open: return
	var origin: Vector2 = global_position if is_inside_tree() else position
	for index: int in range(_balls_awaiting_exit.size() - 1, -1, -1):
		var ball: Node2D = _balls_awaiting_exit[index]
		if not is_instance_valid(ball):
			_balls_awaiting_exit.remove_at(index)
		elif ball.global_position.distance_to(origin) > component_radius + Constants.BALL_RADIUS + 8.0:
			_balls_awaiting_exit.remove_at(index)
	if _balls_awaiting_exit.is_empty(): close_gate()

func _exit_tree() -> void:
	if not retained_balls.is_empty(): release_retained_balls(false)

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	var gate_dir: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	var perp: Vector2 = Vector2(-gate_dir.y, gate_dir.x)

	var cup_col: Color = _accent_color.darkened(0.55)
	draw_circle(Vector2.ZERO, r, cup_col)

	var fill_ratio: float = clampf(float(retained_balls.size()) / float(maxi(1, max_capacity)), 0.0, 1.0)
	if fill_ratio > 0.0:
		var fill_col: Color = Color(0.2, 0.75, 1.0, 0.25 * fill_ratio)
		if is_requirement_satisfied or is_open:
			fill_col = Color(0.3, 0.95, 0.4, 0.35)
		draw_circle(Vector2.ZERO, r * fill_ratio, fill_col)

	var gate_ang: float = gate_dir.angle()
	draw_arc(Vector2.ZERO, r, gate_ang + PI * 0.25, gate_ang + PI * 0.75, 16, _accent_color, 2.5)
	draw_arc(Vector2.ZERO, r, gate_ang + PI * 1.25, gate_ang + PI * 1.75, 16, _accent_color, 2.5)

	var post_a: Vector2 = gate_dir * (r * 0.7) + perp * (r * 0.75)
	var post_b: Vector2 = gate_dir * (r * 0.7) - perp * (r * 0.75)
	draw_circle(post_a, 4.0, Color(0.12, 0.12, 0.18))
	draw_circle(post_b, 4.0, Color(0.12, 0.12, 0.18))
	draw_circle(post_a, 2.5, _accent_color.lightened(0.4))
	draw_circle(post_b, 2.5, _accent_color.lightened(0.4))

	if is_open:
		var swing_arm: Vector2 = post_a + gate_dir * (r * 0.9)
		draw_line(post_a, swing_arm, Color(0.25, 0.98, 0.45), 3.5)
		draw_line(post_b, post_b + gate_dir * (r * 0.4), Color(0.25, 0.98, 0.45, 0.7), 2.0)
		var exit_tip: Vector2 = gate_dir * (r * 0.95)
		draw_line(exit_tip - perp * 6.0 - gate_dir * 5.0, exit_tip, Color(0.3, 0.95, 0.45), 2.0)
		draw_line(exit_tip + perp * 6.0 - gate_dir * 5.0, exit_tip, Color(0.3, 0.95, 0.45), 2.0)
	else:
		draw_line(post_a, post_b, Color(0.15, 0.15, 0.2), 4.5)
		var barrier_col: Color = Color(1.0, 0.85, 0.2) if not is_requirement_satisfied else Color(0.4, 0.9, 1.0)
		draw_line(post_a, post_b, barrier_col, 3.0)

	var pips: int = max_capacity
	var pip_spread: float = minf(r * 0.9, float(pips - 1) * 9.0)
	for i in range(pips):
		var t: float = (float(i) / float(pips - 1) - 0.5) if pips > 1 else 0.0
		var pip_offset: Vector2 = -gate_dir * (r * 0.45) + perp * (t * pip_spread)
		if i < retained_balls.size():
			draw_circle(pip_offset, 3.2, Color(1.0, 0.95, 0.25))
			draw_circle(pip_offset, 1.8, Color(1.0, 1.0, 1.0))
		else:
			draw_circle(pip_offset, 2.2, Color(0.25, 0.3, 0.38, 0.7))
