extends PolyominoMachineryComponent
class_name ScoopSinkhole

signal ball_captured(scoop_node: Node, ball: Node)
signal ball_ejected(scoop_node: Node, ball: Node)

@export var hold_duration_sec: float = 0.5
@export var eject_direction: Vector2 = Vector2.UP

var _captured_balls: Array[Node] = []
var _hold_timer: Timer = null

# Backwards compatibility accessor
var _captured_ball: Node:
	get: return _captured_balls[0] if not _captured_balls.is_empty() else null
	set(val):
		_captured_balls.clear()
		if val != null:
			_captured_balls.append(val)

func configure_footprint(cell_count: int) -> void:
	if cell_count >= 9:
		component_radius = 76.0
		base_energy = 30
		impulse_strength = 600.0
		hold_duration_sec = 0.9
	elif cell_count >= 4:
		component_radius = 48.0
		base_energy = 20
		impulse_strength = 500.0
		hold_duration_sec = 0.8
	else:
		component_radius = 20.0
		base_energy = 10
		impulse_strength = 350.0
		hold_duration_sec = 0.5
	if _hold_timer:
		_hold_timer.wait_time = hold_duration_sec
	queue_redraw()

func _ready() -> void:
	is_permeable = true
	component_radius = 20.0
	base_energy = 10
	impulse_strength = 350.0
	_update_direction()
	
	_hold_timer = Timer.new()
	_hold_timer.wait_time = hold_duration_sec
	_hold_timer.one_shot = true
	_hold_timer.timeout.connect(_on_hold_timeout)
	add_child(_hold_timer)
	
	_setup_collision()
	_setup_audio()
	set_process(true)

func _update_direction() -> void:
	if direction != Vector2.ZERO:
		eject_direction = direction.normalized()

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

	_stop_ball(ball)
	if not _captured_balls.has(ball):
		_captured_balls.append(ball)
	if _hold_timer != null and _hold_timer.is_inside_tree():
		_hold_timer.start()
	
	ball_captured.emit(self, ball)
	
	component_activated.emit(self, ball, energy, Vector2.ZERO)
	return {
		"activated": true,
		"energy_granted": energy,
		"impulse_applied": Vector2.ZERO,
		"type": cell_type
	}

func _stop_ball(ball: Node) -> void:
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO

func _on_hold_timeout() -> void:
	var balls_to_eject := _captured_balls.duplicate()
	_captured_balls.clear()
	var total: int = balls_to_eject.size()
	for i in range(total):
		var b: Node = balls_to_eject[i]
		if not is_instance_valid(b):
			continue
		var spread_angle: float = 0.0
		if total > 1:
			spread_angle = lerpf(-0.25, 0.25, float(i) / float(total - 1))
		var impulse: Vector2 = eject_direction.rotated(spread_angle) * impulse_strength
		_apply_ball_impulse(b, impulse)
		ball_ejected.emit(self, b)

func _process(delta: float) -> void:
	var my_p: Vector2 = global_position if is_inside_tree() else position
	for b in _captured_balls:
		if is_instance_valid(b) and "position" in b:
			b.position = my_p
	
	var needs_redraw: bool = false
	if _spring_scale != Vector2.ONE:
		_spring_scale = _spring_scale.move_toward(Vector2.ONE, delta * 5.0)
		needs_redraw = true
	if _spark_progress < 1.0:
		_spark_progress = minf(1.0, _spark_progress + delta * 3.5)
		needs_redraw = true
	if needs_redraw:
		queue_redraw()

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	draw_circle(Vector2.ZERO, r, _accent_color.darkened(0.4))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, _accent_color, 2.0)
	
	# Draw dark sinkhole cutout
	var cutout_r: float = component_radius * 0.8
	var cutout_col := Color(0.0, 0.0, 0.0, 0.5)
	draw_circle(Vector2.ZERO, cutout_r, cutout_col)

func _draw_sparks() -> void:
	var t: float = _spark_progress
	var spark_r: float = lerpf(component_radius, component_radius * 2.2, t)
	var alpha: float = (1.0 - t) * 0.8
	var spark_col := Color(_accent_color.r, _accent_color.g, _accent_color.b, alpha)
	draw_arc(Vector2.ZERO, spark_r, 0, TAU, 16, spark_col, 2.0)
	for i in range(6):
		var angle: float = float(i) * (TAU / 6.0) + (t * 0.5)
		var p1: Vector2 = Vector2.from_angle(angle) * (spark_r * 0.7)
		var p2: Vector2 = Vector2.from_angle(angle) * spark_r
		draw_line(p1, p2, spark_col, 2.0)
