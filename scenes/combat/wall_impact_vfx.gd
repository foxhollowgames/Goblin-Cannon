extends Node2D
## Burst explosion at wall impact. Short-lived expanding particles.

const PARTICLE_COUNT: int = 24
const BURST_RADIUS: float = 45.0
const DURATION: float = 0.35
const PARTICLE_SIZE: float = 8.0

var _particles: Array[Dictionary] = []  # { pos: Vector2, end_pos: Vector2 }
var _tween: Tween

func setup(impact_pos: Vector2) -> void:
	position = impact_pos
	for i in PARTICLE_COUNT:
		var angle: float = (float(i) / float(PARTICLE_COUNT)) * TAU + 0.1
		var dist: float = 15.0 + (i % 5) * 6.0
		var end_dist: float = dist + BURST_RADIUS
		_particles.append({
			"pos": Vector2.from_angle(angle) * dist,
			"end_pos": Vector2.from_angle(angle) * end_dist
		})

func _ready() -> void:
	_tween = create_tween()
	_tween.set_parallel(true)
	for p in _particles:
		var start_pos: Vector2 = p.pos
		var end_pos: Vector2 = p.end_pos
		_tween.tween_method(func(v): _tween_particle(p, start_pos, end_pos, v), 0.0, 1.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(queue_free).set_delay(DURATION)

func _tween_particle(p: Dictionary, start_pos: Vector2, end_pos: Vector2, t: float) -> void:
	p.pos = start_pos.lerp(end_pos, t)
	queue_redraw()

func _draw() -> void:
	for p in _particles:
		var c0: Color = Constants.gameplay_wall_impact_core()
		var c1: Color = Constants.gameplay_wall_impact_ring()
		draw_circle(p.pos, PARTICLE_SIZE, Color(c0.r, c0.g, c0.b, 0.95))
		draw_arc(p.pos, PARTICLE_SIZE, 0, TAU, 10, Color(c1.r, c1.g, c1.b, 0.8), 1.5)
