extends PolyominoMachineryComponent
class_name VerticalUpKicker

signal vuk_captured(vuk_node: Node, ball: Node)
signal vuk_launched(vuk_node: Node, ball: Node)

@export var launch_direction: Vector2 = Vector2.UP

func _ready() -> void:
	is_permeable = true
	component_radius = 20.0
	base_energy = 12
	impulse_strength = 480.0
	_update_direction()
	_setup_collision()
	_setup_audio()
	set_process(true)

func _update_direction() -> void:
	if direction != Vector2.ZERO:
		launch_direction = direction.normalized()

func _compute_impulse(_ball: Node) -> Vector2:
	return launch_direction * impulse_strength

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

	vuk_captured.emit(self, ball)
	var impulse: Vector2 = _compute_impulse(ball)
	if impulse != Vector2.ZERO and "linear_velocity" in ball:
		_apply_ball_impulse(ball, impulse)
		vuk_launched.emit(self, ball)

	component_activated.emit(self, ball, energy, impulse)
	return {
		"activated": true,
		"energy_granted": energy,
		"impulse_applied": impulse,
		"type": cell_type
	}

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	draw_circle(Vector2.ZERO, r, _accent_color.darkened(0.4))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, _accent_color, 2.0)

	# Draw kicker pot
	var pot_r: float = component_radius * 0.8
	var pot_col := Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.7)
	draw_circle(Vector2.ZERO, pot_r, pot_col)
	draw_arc(Vector2.ZERO, pot_r, 0, TAU, 16, pot_col, 1.5)

	var kicker_line_start: Vector2 = Vector2.ZERO
	var kicker_line_end: Vector2 = launch_direction * (component_radius * 1.2)
	draw_line(kicker_line_start, kicker_line_end, _accent_color, 3.0)
