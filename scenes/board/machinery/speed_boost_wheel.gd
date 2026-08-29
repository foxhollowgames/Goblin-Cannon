extends PolyominoMachineryComponent
class_name SpeedBoostWheel
## Speed Boost Wheel / Accelerator sub-component. Accelerates colliding balls along a set vector.

const DEFAULT_BOOST_SPEED: float = 420.0
const DEFAULT_BOOST_ENERGY: int = 3

var _wheel_spin_angle: float = 0.0

func _init() -> void:
	cell_type = PolyominoModuleData.CellType.ACCELERATOR
	base_energy = DEFAULT_BOOST_ENERGY
	impulse_strength = DEFAULT_BOOST_SPEED
	component_radius = 18.0
	is_permeable = false
	direction = Vector2.DOWN
	_accent_color = Color(0.2, 0.85, 1.0) # Bright Cyan/Electric Blue
	_audio_stream = load("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Desert Shooter Pack/Sounds/shoot-a.ogg") as AudioStream

func _compute_impulse(ball: Node) -> Vector2:
	var boost_dir: Vector2 = direction.normalized()
	if boost_dir.length_squared() < 0.0001:
		boost_dir = Vector2.DOWN

	if "linear_velocity" in ball:
		var cur_vel: Vector2 = ball.linear_velocity
		var current_speed_in_dir: float = cur_vel.dot(boost_dir)
		if current_speed_in_dir < impulse_strength:
			# Boost ball up to at least impulse_strength along boost_dir
			var needed_boost: float = impulse_strength - maxf(0.0, current_speed_in_dir)
			return boost_dir * (needed_boost + 120.0)
	return boost_dir * impulse_strength

func _process(delta: float) -> void:
	super._process(delta)
	_wheel_spin_angle = fmod(_wheel_spin_angle + delta * 6.0, TAU)
	queue_redraw()

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	# Outer rim
	draw_circle(Vector2.ZERO, r, _accent_color.darkened(0.7))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, _accent_color, 2.0)

	# Rotating inner roller cogs
	for i in range(4):
		var ang: float = _wheel_spin_angle + float(i) * (TAU / 4.0)
		var p: Vector2 = Vector2.from_angle(ang) * (r * 0.55)
		draw_circle(p, r * 0.2, _accent_color.lightened(0.3))

	# Directional Chevron
	var dir_norm: Vector2 = direction.normalized()
	if dir_norm.length_squared() > 0.001:
		var head: Vector2 = dir_norm * (r * 0.75)
		var perp: Vector2 = Vector2(-dir_norm.y, dir_norm.x) * (r * 0.45)
		var base_p: Vector2 = -dir_norm * (r * 0.3)
		var poly: PackedVector2Array = [head, base_p + perp, base_p - perp]
		draw_colored_polygon(poly, Color.WHITE)
