extends PolyominoMachineryComponent
class_name DirectionalDeflector
## Directional Deflector / Funnel sub-component. Funnels balls into specific board directions or columns.

const DEFAULT_DEFLECTOR_ENERGY: int = 2
const MIN_REDIRECT_SPEED: float = 280.0

func _init() -> void:
	cell_type = PolyominoModuleData.CellType.DIRECTIONAL_DEFLECTOR
	base_energy = DEFAULT_DEFLECTOR_ENERGY
	impulse_strength = 200.0
	component_radius = 18.0
	is_permeable = false
	direction = Vector2(1, 1).normalized()
	_accent_color = Color(0.95, 0.8, 0.2) # Golden Amber / Mechanical Yellow
	_audio_stream = load("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Desert Shooter Pack/Sounds/select-a.ogg") as AudioStream

func _compute_impulse(ball: Node) -> Vector2:
	var target_dir: Vector2 = direction.normalized()
	if target_dir.length_squared() < 0.0001:
		target_dir = Vector2.DOWN

	if "linear_velocity" in ball:
		var cur_vel: Vector2 = ball.linear_velocity
		var spd: float = maxf(cur_vel.length(), MIN_REDIRECT_SPEED)
		var desired_vel: Vector2 = target_dir * spd
		# Compute corrective impulse to steer ball into desired velocity
		return desired_vel - cur_vel
	return target_dir * MIN_REDIRECT_SPEED

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	# Base container
	draw_circle(Vector2.ZERO, r, _accent_color.darkened(0.6))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, _accent_color, 2.0)

	# Angled guide rails
	var dir_norm: Vector2 = direction.normalized()
	var perp: Vector2 = Vector2(-dir_norm.y, dir_norm.x)
	var p_left1: Vector2 = -dir_norm * (r * 0.7) + perp * (r * 0.6)
	var p_left2: Vector2 = dir_norm * (r * 0.5) + perp * (r * 0.2)
	var p_right1: Vector2 = -dir_norm * (r * 0.7) - perp * (r * 0.6)
	var p_right2: Vector2 = dir_norm * (r * 0.5) - perp * (r * 0.2)

	draw_line(p_left1, p_left2, Color.WHITE, 3.0)
	draw_line(p_right1, p_right2, Color.WHITE, 3.0)

	# Direction arrow
	var head: Vector2 = dir_norm * (r * 0.8)
	draw_line(Vector2.ZERO, head, _accent_color.lightened(0.4), 2.5)
