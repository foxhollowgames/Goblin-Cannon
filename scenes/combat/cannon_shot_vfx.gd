extends Node2D
## VFX: ball leaves cannon and travels to wall, then triggers wall impact callback.

const BALL_RADIUS: float = 10.0
const DURATION: float = 0.28

var _start_pos: Vector2
var _end_pos: Vector2
var _wall_impact_callback: Callable

func setup(start_pos: Vector2, end_pos: Vector2, wall_impact_callback: Callable) -> void:
	_start_pos = start_pos
	_end_pos = end_pos
	_wall_impact_callback = wall_impact_callback
	position = start_pos

func _ready() -> void:
	var t: Tween = create_tween()
	t.tween_property(self, "position", _end_pos, DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_callback(_on_reached_wall)

func _on_reached_wall() -> void:
	if _wall_impact_callback.is_valid():
		_wall_impact_callback.call(_end_pos)
	queue_free()

func _draw() -> void:
	var core: Color = Constants.gameplay_cannon_shot_core()
	var ring: Color = Constants.gameplay_cannon_shot_ring()
	draw_circle(Vector2.ZERO, BALL_RADIUS, Color(core.r, core.g, core.b, 1))
	draw_arc(Vector2.ZERO, BALL_RADIUS, 0, TAU, 16, Color(ring.r, ring.g, ring.b, 1), 2.0)
