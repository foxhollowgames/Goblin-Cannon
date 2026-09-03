extends PolyominoMachineryComponent
class_name OrbitLoop
## Curved high-speed turnaround rail lane that redirects balls along the orbit path.

#region Signals
signal orbit_traversed(orbit_node: OrbitLoop, ball: Node)
#endregion

#region Constants
const DEFAULT_RADIUS: float = 22.0
const DEFAULT_ENERGY: int = 8
const DEFAULT_IMPULSE: float = 220.0
#endregion

#region Variables
var traversal_count: int = 0
#endregion

#region Lifecycle Methods
func _init() -> void:
	is_permeable = true
	component_radius = DEFAULT_RADIUS
	base_energy = DEFAULT_ENERGY
	impulse_strength = DEFAULT_IMPULSE

func _ready() -> void:
	super._ready()
#endregion

#region Public Methods
## Triggers activation upon ball traversing the orbit, applying directional guidance impulse.
func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	var res: Dictionary = super.trigger_activation(ball, sim_tick)
	if res.get("activated", false):
		traversal_count += 1
		orbit_traversed.emit(self, ball)
		queue_redraw()
	return res
#endregion

#region Private Methods
func _compute_impulse(_ball: Node) -> Vector2:
	var dir_norm: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	return dir_norm * impulse_strength

func _draw_component_body() -> void:
	var r: float = component_radius
	var dir_norm: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	var angle: float = dir_norm.angle()

	# Draw outer and inner curved metal guide rails
	draw_arc(Vector2.ZERO, r, angle - PI * 0.4, angle + PI * 0.4, 16, Color(0.7, 0.7, 0.75), 2.0)
	draw_arc(Vector2.ZERO, r * 0.65, angle - PI * 0.4, angle + PI * 0.4, 16, Color(0.5, 0.5, 0.55), 1.5)

	# Accent flow arrow along direction
	var arrow_tip: Vector2 = dir_norm * (r * 0.8)
	var arrow_base: Vector2 = dir_norm * (r * 0.3)
	draw_line(arrow_base, arrow_tip, _accent_color, 2.0)
#endregion
