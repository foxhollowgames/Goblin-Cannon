extends PolyominoMachineryComponent
class_name CaptiveBall
## Confined steel captive ball inside a retaining channel that transfers kinetic energy to target switches.

#region Signals
signal captive_ball_struck(captive_node: CaptiveBall, ball: Node)
#endregion

#region Constants
const DEFAULT_RADIUS: float = 18.0
const DEFAULT_ENERGY: int = 7
const DEFAULT_IMPULSE: float = 280.0
const RETURN_SPEED: float = 24.0
#endregion

#region Variables
var strike_count: int = 0
var displacement: float = 0.0
#endregion

#region Lifecycle Methods
func _init() -> void:
	is_permeable = false
	component_radius = DEFAULT_RADIUS
	base_energy = DEFAULT_ENERGY
	impulse_strength = DEFAULT_IMPULSE

func _ready() -> void:
	set_process(true)
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	if displacement > 0.0:
		displacement = maxf(0.0, displacement - RETURN_SPEED * delta)
		queue_redraw()
#endregion

#region Public Methods
## Triggers activation upon hitting the captive ball assembly, driving the trapped ball into the rear switch.
func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	var res: Dictionary = super.trigger_activation(ball, sim_tick)
	if res.get("activated", false):
		strike_count += 1
		displacement = 8.0
		captive_ball_struck.emit(self, ball)
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
	var r: float = component_radius
	var dir_norm: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.UP

	# Retaining channel housing
	draw_rect(Rect2(-r * 0.8, -r * 0.9, r * 1.6, r * 1.8), Color(0.25, 0.25, 0.3))
	draw_rect(Rect2(-r * 0.6, -r * 0.7, r * 1.2, r * 1.4), Color(0.15, 0.15, 0.18))

	# Rear target contact switch
	var rear_pos: Vector2 = dir_norm * (r * 0.6)
	draw_circle(rear_pos, 4.0, _accent_color)

	# Trapped captive ball position (offsets when hit)
	var ball_center: Vector2 = dir_norm * displacement
	draw_circle(ball_center, r * 0.45, Color(0.8, 0.8, 0.85))
	draw_circle(ball_center + Vector2(-2, -2), r * 0.15, Color(1.0, 1.0, 1.0))
#endregion
