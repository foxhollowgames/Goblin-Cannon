extends Node2D
## Visual-only "twin" that flies opposite the real ball when Split triggers, so the split looks like two balls bouncing apart.

const DURATION_SEC: float = 0.45
const MIN_SPEED: float = 120.0  # so twin is always visible even if ball was slow

var _velocity: Vector2 = Vector2.ZERO
var _alignment: int = 0
var _shape_type: int = -1
var _elapsed: float = 0.0

func _ready() -> void:
	pass

func setup(start_global_pos: Vector2, velocity_opposite: Vector2, alignment: int, shape_type: int) -> void:
	global_position = start_global_pos
	_velocity = velocity_opposite
	if _velocity.length_squared() < 1.0:
		_velocity = Vector2(1, 0)
	else:
		_velocity = _velocity.normalized() * maxf(MIN_SPEED, _velocity.length())
	_alignment = alignment
	_shape_type = shape_type
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	global_position += _velocity * delta
	queue_redraw()
	var t: float = _elapsed / DURATION_SEC
	modulate.a = 1.0 - t
	if _elapsed >= DURATION_SEC:
		queue_free()

func _draw() -> void:
	BallVisuals.draw_ball(self, Vector2.ZERO, Constants.BALL_RADIUS, _alignment, _shape_type)
