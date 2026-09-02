extends PolyominoMachineryComponent
class_name GuideTrack

signal track_entered(track_node: Node, ball: Node)
signal track_exited(track_node: Node, ball: Node)

@export var exit_offset: Vector2 = Vector2(0, -80)
@export var speed_multiplier: float = 1.25

var _guided_balls: Dictionary = {}  # ball_id (int) -> Node (ball)

func _ready() -> void:
	is_permeable = true
	component_radius = 24.0
	base_energy = 8
	_update_direction()
	_setup_collision()
	_setup_audio()
	set_process(true)

func _update_direction() -> void:
	if direction != Vector2.ZERO:
		exit_offset = direction.normalized() * 80.0

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

	_guided_balls[bid] = ball

	track_entered.emit(self, ball)
	component_activated.emit(self, ball, energy, Vector2.ZERO)
	return {
		"activated": true,
		"energy_granted": energy,
		"impulse_applied": Vector2.ZERO,
		"type": cell_type
	}

func _process(delta: float) -> void:
	for bid in _guided_balls.keys():
		var ball: Node = _guided_balls[bid]
		if not is_instance_valid(ball):
			_guided_balls.erase(bid)
			continue

		var my_pos: Vector2 = global_position if is_inside_tree() else position
		var target_pos: Vector2 = my_pos + exit_offset
		var ball_pos: Vector2 = ball.global_position if "global_position" in ball else ball.position
		var dist: float = ball_pos.distance_to(target_pos)
		if dist < 10.0:
			if "linear_velocity" in ball:
				ball.linear_velocity = exit_offset.normalized() * (300.0 * speed_multiplier)
			track_exited.emit(self, ball)
			_guided_balls.erase(bid)
		else:
			var dir: Vector2 = (target_pos - ball_pos).normalized()
			if "linear_velocity" in ball:
				ball.linear_velocity = dir * (250.0 * speed_multiplier)

	super._process(delta)

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	draw_circle(Vector2.ZERO, r, _accent_color.darkened(0.4))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, _accent_color, 2.0)

	# Draw wireform habitrail track line
	draw_line(Vector2.ZERO, exit_offset, _accent_color, 2.0)
	draw_circle(exit_offset, 4.0, _accent_color)
