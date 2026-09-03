extends PolyominoMachineryComponent
class_name Spinner
## Hinged axle spinner that spins rapidly as pinballs pass through, awarding recurring energy.

#region Signals
signal spinner_spun(spinner_node: Spinner, spin_count: int)
#endregion

#region Constants
const DEFAULT_RADIUS: float = 18.0
const DEFAULT_ENERGY: int = 3
const INITIAL_SPIN_VELOCITY: float = 24.0
const SPIN_FRICTION: float = 6.0
#endregion

#region Variables
var total_spins: int = 0
var spin_angle: float = 0.0
var spin_velocity: float = 0.0
#endregion

#region Lifecycle Methods
func _init() -> void:
	is_permeable = true
	component_radius = DEFAULT_RADIUS
	base_energy = DEFAULT_ENERGY
	impulse_strength = 0.0

func _ready() -> void:
	set_process(true)
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	if spin_velocity > 0.0:
		spin_angle += spin_velocity * delta
		spin_velocity = maxf(0.0, spin_velocity - SPIN_FRICTION * delta)
		queue_redraw()
#endregion

#region Public Methods
## Triggers activation upon ball pass-through, increasing spin speed and emitting spin event.
func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	var res: Dictionary = super.trigger_activation(ball, sim_tick)
	if res.get("activated", false):
		total_spins += 1
		spin_velocity += INITIAL_SPIN_VELOCITY
		spinner_spun.emit(self, total_spins)
		queue_redraw()
	return res
#endregion

#region Private Methods
func _draw_component_body() -> void:
	var r: float = component_radius
	# Axle brackets on the sides
	draw_line(Vector2(-r, -r * 0.4), Vector2(-r, r * 0.4), Color(0.6, 0.6, 0.6), 2.5)
	draw_line(Vector2(r, -r * 0.4), Vector2(r, r * 0.4), Color(0.6, 0.6, 0.6), 2.5)
	# Central axle rod
	draw_line(Vector2(-r, 0), Vector2(r, 0), Color(0.4, 0.4, 0.4), 1.5)

	# Spinning blade with perspective scale based on angle
	var blade_scale: float = cos(spin_angle)
	var blade_h: float = r * 0.8 * absf(blade_scale)
	var blade_color: Color = _accent_color if blade_scale >= 0.0 else _accent_color.darkened(0.3)
	draw_rect(Rect2(-r * 0.7, -blade_h * 0.5, r * 1.4, maxf(2.0, blade_h)), blade_color)
#endregion
