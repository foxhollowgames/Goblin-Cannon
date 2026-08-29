extends PolyominoMachineryComponent
class_name ManaSiphon
## Mana Siphon sub-component. Generates bonus energy without deflecting ball trajectories.

const DEFAULT_SIPHON_ENERGY: int = 8

var _vortex_phase: float = 0.0

func _init() -> void:
	cell_type = PolyominoModuleData.CellType.MANA_SIPHON
	base_energy = DEFAULT_SIPHON_ENERGY
	impulse_strength = 0.0
	component_radius = 18.0
	is_permeable = true
	_accent_color = Color(0.2, 0.95, 0.45) # Emerald / Siphon Green
	_audio_stream = load("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/New Platformer Pack/Sounds/sfx_gem.ogg") as AudioStream

func _compute_impulse(_ball: Node) -> Vector2:
	# Mana Siphons do NOT deflect ball trajectories
	return Vector2.ZERO

func _process(delta: float) -> void:
	super._process(delta)
	_vortex_phase = fmod(_vortex_phase + delta * 4.0, TAU)
	queue_redraw()

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	# Outer soft energy halo
	draw_circle(Vector2.ZERO, r, Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.25))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, _accent_color, 1.5)

	# Swirling siphon vortex rings
	for i in range(3):
		var ring_r: float = r * (0.3 + 0.25 * float(i))
		var start_ang: float = _vortex_phase + float(i) * 1.2
		draw_arc(Vector2.ZERO, ring_r, start_ang, start_ang + PI * 0.8, 12, _accent_color.lightened(0.3), 2.0)

	# Glowing core
	draw_circle(Vector2.ZERO, r * 0.25, Color.WHITE)
