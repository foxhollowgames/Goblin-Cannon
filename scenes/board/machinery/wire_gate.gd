extends PolyominoMachineryComponent
class_name WireGate

signal ball_retained(gate_node: Node, count: int)
signal gate_opened(gate_node: Node)
signal gate_closed(gate_node: Node)
signal cascade_released(gate_node: Node, released_balls: Array)

@export var max_capacity: int = 3
@export var is_open: bool = false
@export var release_impulse_strength: float = 320.0
@export var auto_close_delay_sec: float = 0.6

const GATE_COOLDOWN_TICKS: int = 20

var retained_balls: Array[Node] = []
var _close_timer: Timer = null

func _init() -> void:
	is_permeable = true
	component_radius = 16.0
	base_energy = 4
	direction = Vector2.DOWN
	exit_cooldown_ticks = GATE_COOLDOWN_TICKS
	hit_cooldown_ticks = GATE_COOLDOWN_TICKS
	cell_type = PolyominoModuleData.CellType.WIRE_GATE

func _ready() -> void:
	is_permeable = true
	component_radius = 16.0
	base_energy = 4
	exit_cooldown_ticks = GATE_COOLDOWN_TICKS
	hit_cooldown_ticks = GATE_COOLDOWN_TICKS
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN

	_close_timer = Timer.new()
	_close_timer.wait_time = auto_close_delay_sec
	_close_timer.one_shot = true
	_close_timer.timeout.connect(close_gate)
	add_child(_close_timer)

	super._ready()

func can_activate_for_ball(ball_id: int, sim_tick: int) -> bool:
	for b in retained_balls:
		if is_instance_valid(b):
			var bid: int = b.get_ball_id() if b.has_method("get_ball_id") else b.get_instance_id()
			if bid == ball_id:
				return false
	return super.can_activate_for_ball(ball_id, sim_tick)

func record_ball_exit(ball_id: int, sim_tick: int) -> void:
	super.record_ball_exit(ball_id, sim_tick)
	for i in range(retained_balls.size() - 1, -1, -1):
		var b: Node = retained_balls[i]
		if is_instance_valid(b):
			var bid: int = b.get_ball_id() if b.has_method("get_ball_id") else b.get_instance_id()
			if bid == ball_id:
				retained_balls.remove_at(i)

func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
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
		_retain_ball(ball)
		if ball.has_method("add_peg_energy") and energy > 0:
			ball.add_peg_energy(energy)

		if retained_balls.size() >= max_capacity:
			release_retained_balls()
			return {
				"activated": true,
				"energy_granted": energy + 10,
				"impulse_applied": gate_dir * release_impulse_strength,
				"type": cell_type
			}

		component_activated.emit(self, ball, energy, Vector2.ZERO)
		return {"activated": true, "energy_granted": energy, "impulse_applied": Vector2.ZERO, "type": cell_type}

	var bounce_impulse: Vector2 = -gate_dir * 100.0
	if "linear_velocity" in ball:
		ball.linear_velocity = vel.bounce(-gate_dir) * 0.8
	component_activated.emit(self, ball, 0, bounce_impulse)
	return {"activated": true, "energy_granted": 0, "impulse_applied": bounce_impulse, "type": cell_type}

func _retain_ball(ball: Node) -> void:
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
	is_open = false
	gate_closed.emit(self)
	queue_redraw()

func release_retained_balls() -> Array:
	open_gate()
	var released: Array = retained_balls.duplicate()
	retained_balls.clear()

	var gate_dir: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	var total: int = released.size()

	for i in range(total):
		var b: Node = released[i]
		if is_instance_valid(b):
			var bid: int = b.get_ball_id() if b.has_method("get_ball_id") else b.get_instance_id()
			record_ball_exit(bid, _current_sim_tick)
			var spread: float = 0.0
			if total > 1:
				spread = lerpf(-0.2, 0.2, float(i) / float(total - 1))
			var impulse: Vector2 = gate_dir.rotated(spread) * release_impulse_strength
			_apply_ball_impulse(b, impulse)

	cascade_released.emit(self, released)

	if _close_timer != null and _close_timer.is_inside_tree():
		_close_timer.start()

	queue_redraw()
	return released

func reset_gate() -> void:
	retained_balls.clear()
	is_open = false
	if _close_timer != null and not _close_timer.is_stopped():
		_close_timer.stop()
	queue_redraw()

func _process(delta: float) -> void:
	var my_p: Vector2 = global_position if is_inside_tree() else position
	for b in retained_balls:
		if is_instance_valid(b) and "position" in b:
			b.position = my_p
	super._process(delta)

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	var gate_dir: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	var perp: Vector2 = Vector2(-gate_dir.y, gate_dir.x)

	var cup_col: Color = _accent_color.darkened(0.5)
	draw_circle(Vector2.ZERO, r, cup_col)
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, _accent_color, 2.0)

	var post_a: Vector2 = perp * (r * 0.8)
	var post_b: Vector2 = -perp * (r * 0.8)
	draw_circle(post_a, 3.0, Color(0.1, 0.1, 0.15))
	draw_circle(post_b, 3.0, Color(0.1, 0.1, 0.15))

	if is_open:
		var bar_end: Vector2 = post_a + (gate_dir * (r * 1.1))
		draw_line(post_a, bar_end, Color(0.3, 0.95, 0.4), 3.0)
	else:
		draw_line(post_a, post_b, Color(1.0, 0.85, 0.2), 3.5)

	var pips: int = max_capacity
	for i in range(pips):
		var pip_offset: Vector2 = -gate_dir * (r * 0.4) + perp * ((float(i) - float(pips - 1) * 0.5) * 6.0)
		if i < retained_balls.size():
			draw_circle(pip_offset, 2.5, Color(1.0, 0.95, 0.3))
		else:
			draw_circle(pip_offset, 2.0, Color(0.2, 0.25, 0.3, 0.7))
