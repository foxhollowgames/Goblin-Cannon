extends PolyominoMachineryComponent
class_name PinballBumper
## Pinball Bumper sub-component. Applies outward impulse and generates bonus energy on impact.

const DEFAULT_BUMPER_FORCE: float = 380.0
const DEFAULT_BUMPER_ENERGY: int = 5

func _init() -> void:
	cell_type = PolyominoModuleData.CellType.BUMPER
	base_energy = DEFAULT_BUMPER_ENERGY
	impulse_strength = DEFAULT_BUMPER_FORCE
	component_radius = 18.0
	is_permeable = false
	_accent_color = Color(1.0, 0.45, 0.15) # Warm Orange/Red
	_audio_stream = load("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/New Platformer Pack/Sounds/sfx_bump.ogg") as AudioStream

func _compute_impulse(ball: Node) -> Vector2:
	var ball_pos: Vector2 = ball.global_position if "global_position" in ball else global_position
	var diff: Vector2 = ball_pos - global_position
	var dir: Vector2 = diff.normalized()
	if dir.length_squared() < 0.0001:
		dir = Vector2(0, -1) # Default upward if directly on center
	return dir * impulse_strength

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	# Outer steel ring
	draw_circle(Vector2.ZERO, r, _accent_color.darkened(0.6))
	draw_arc(Vector2.ZERO, r, 0, TAU, 28, _accent_color.lightened(0.2), 3.0)
	# Inner glowing core
	draw_circle(Vector2.ZERO, r * 0.65, _accent_color)
	draw_circle(Vector2.ZERO, r * 0.3, Color.WHITE)
