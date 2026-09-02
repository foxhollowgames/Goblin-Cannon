extends PolyominoMachineryComponent
class_name BallLock

signal ball_locked(lock_node: Node, locked_count: int)
signal multiball_released(lock_node: Node, released_balls: Array)

@export var max_capacity: int = 3
@export var eject_impulse_strength: float = 400.0

var locked_balls: Array = []

func _compute_impulse(_ball: Node) -> Vector2:
	var dir_norm: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	return dir_norm * eject_impulse_strength

func _ready() -> void:
	is_permeable = true
	component_radius = 22.0
	base_energy = 15
	_setup_collision()
	_setup_audio()
	set_process(true)

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

	locked_balls.append(ball)
	ball_locked.emit(self, locked_balls.size())

	if locked_balls.size() >= max_capacity:
		release_all_balls()

	return {
		"activated": true,
		"energy_granted": energy,
		"impulse_applied": Vector2.ZERO,
		"type": cell_type
	}

func release_all_balls() -> void:
	var released_balls: Array = []
	for ball in locked_balls:
		var impulse: Vector2 = _compute_impulse(ball)
		if impulse != Vector2.ZERO and "linear_velocity" in ball:
			ball.linear_velocity += impulse
		released_balls.append(ball)

	locked_balls.clear()
	multiball_released.emit(self, released_balls)
	queue_redraw()

func _draw_component_body() -> void:
	# Draw lock trough
	var r: float = component_radius * _spring_scale.x
	draw_circle(Vector2.ZERO, r, _accent_color.darkened(0.4))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, _accent_color, 2.0)

	var dir_norm: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	var trough_width: float = 4.0
	var trough_height: float = component_radius * 1.5
	var start_p: Vector2 = -dir_norm * (component_radius * 0.7)
	var end_p: Vector2 = start_p + dir_norm * trough_height
	draw_line(start_p, end_p, _accent_color.darkened(0.6), trough_width)
