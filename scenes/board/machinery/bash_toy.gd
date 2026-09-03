extends PolyominoMachineryComponent
class_name BashToy
## Durable multi-hit interactive bash toy that shakes on impact and breaks at max hits.

#region Signals
signal bash_hit(bash_node: BashToy, hit_count: int)
signal bash_toy_broken(bash_node: BashToy)
#endregion

#region Constants
const DEFAULT_RADIUS: float = 24.0
const DEFAULT_ENERGY: int = 12
const BROKEN_BONUS_ENERGY: int = 25
const DEFAULT_IMPULSE: float = 420.0
const WOBBLE_DECAY: float = 12.0
#endregion

#region Variables
@export var max_hits: int = 5
var current_hits: int = 0
var is_broken: bool = false
var _wobble_offset: Vector2 = Vector2.ZERO
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
	if _wobble_offset != Vector2.ZERO:
		_wobble_offset = _wobble_offset.move_toward(Vector2.ZERO, WOBBLE_DECAY * delta * 10.0)
		queue_redraw()
#endregion

#region Public Methods
## Triggers activation upon hitting the bash toy, tracking damage progression and emitting signals.
func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	var will_break: bool = (current_hits + 1 >= max_hits) and not is_broken
	var orig_base_energy: int = base_energy
	if will_break:
		base_energy += BROKEN_BONUS_ENERGY

	var res: Dictionary = super.trigger_activation(ball, sim_tick)
	base_energy = orig_base_energy

	if res.get("activated", false):
		current_hits += 1
		_wobble_offset = Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
		bash_hit.emit(self, current_hits)
		if will_break:
			is_broken = true
			bash_toy_broken.emit(self)
		queue_redraw()
	return res
#endregion

#region Private Methods
func _compute_impulse(ball: Node) -> Vector2:
	var ball_pos: Vector2 = (ball.global_position if ball.is_inside_tree() else ball.position) if "position" in ball else Vector2.ZERO
	var my_pos: Vector2 = global_position if is_inside_tree() else position
	var dir: Vector2 = (ball_pos - my_pos).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	return dir * impulse_strength

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	var center: Vector2 = _wobble_offset

	# Heavy sculpture base
	var base_col: Color = _accent_color.darkened(0.5) if not is_broken else Color(0.3, 0.3, 0.35)
	draw_circle(center, r, base_col)
	draw_arc(center, r, 0, TAU, 32, _accent_color, 2.5)

	# Health indicator pips around perimeter
	var pips: int = max_hits
	for i in range(pips):
		var ang: float = (float(i) / float(pips)) * TAU - PI * 0.5
		var pip_pos: Vector2 = center + Vector2(cos(ang), sin(ang)) * (r * 0.75)
		var pip_col: Color = Color.ORANGE_RED if i < current_hits else Color.FOREST_GREEN
		draw_circle(pip_pos, 3.0, pip_col)

	# Central crest
	draw_circle(center, r * 0.35, _accent_color)
#endregion
