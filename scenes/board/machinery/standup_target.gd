extends PolyominoMachineryComponent
class_name StandupTarget
## Rigid upright leaf switch target that repels pinballs and registers direct hits.

#region Signals
signal target_hit(target_node: StandupTarget, ball: Node)
#endregion

#region Constants
const DEFAULT_RADIUS: float = 16.0
const DEFAULT_ENERGY: int = 6
const DEFAULT_IMPULSE: float = 320.0
#endregion

#region Variables
var hit_count: int = 0
#endregion

#region Lifecycle Methods
func _init() -> void:
	is_permeable = false
	component_radius = DEFAULT_RADIUS
	base_energy = DEFAULT_ENERGY
	impulse_strength = DEFAULT_IMPULSE

func _ready() -> void:
	super._ready()
#endregion

#region Public Methods
## Triggers target activation, applying rebound impulse and registering direct impact.
func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	var res: Dictionary = super.trigger_activation(ball, sim_tick)
	if res.get("activated", false):
		hit_count += 1
		target_hit.emit(self, ball)
		queue_redraw()
	return res
#endregion

#region Private Methods
func _compute_impulse(ball: Node) -> Vector2:
	var ball_pos: Vector2 = (ball.global_position if ball.is_inside_tree() else ball.position) if "position" in ball else Vector2.ZERO
	var my_pos: Vector2 = global_position if is_inside_tree() else position
	var dir: Vector2 = (ball_pos - my_pos).normalized()
	if dir == Vector2.ZERO:
		dir = -direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	return dir * impulse_strength

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	var plate_w: float = r * 1.6
	var plate_h: float = r * 0.8
	draw_rect(Rect2(-plate_w * 0.5, -plate_h * 0.5, plate_w, plate_h), _accent_color)
	draw_rect(Rect2(-plate_w * 0.4, -plate_h * 0.3, plate_w * 0.8, plate_h * 0.6), Color(0.95, 0.95, 0.95))
	draw_circle(Vector2.ZERO, r * 0.25, _accent_color.darkened(0.3))
#endregion
