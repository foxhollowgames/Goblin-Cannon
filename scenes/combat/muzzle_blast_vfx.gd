extends Node2D
## Small explosion burst around the cannon (muzzle blast). Visual only; damage is applied by battlefield.

const PARTICLE_COUNT: int = 16
const BURST_RADIUS: float = 38.0
const DURATION: float = 0.22
const PARTICLE_SIZE: float = 6.0

var _particles: Array[Dictionary] = []

func setup(blast_pos: Vector2) -> void:
	position = blast_pos
	for i in PARTICLE_COUNT:
		var angle: float = (float(i) / float(PARTICLE_COUNT)) * TAU
		var end_dist: float = 12.0 + (i % 4) * 4.0 + BURST_RADIUS * 0.5
		_particles.append({
			"pos": Vector2.ZERO,
			"end_pos": Vector2.from_angle(angle) * end_dist
		})

func _ready() -> void:
	var t: Tween = create_tween()
	t.set_parallel(true)
	for p in _particles:
		var end_pos: Vector2 = p.end_pos
		t.tween_method(func(v): _lerp_particle(p, end_pos, v), 0.0, 1.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(queue_free).set_delay(DURATION)

func _lerp_particle(p: Dictionary, end_pos: Vector2, t: float) -> void:
	p.pos = end_pos * t
	queue_redraw()

func _draw() -> void:
	for p in _particles:
		draw_circle(p.pos, PARTICLE_SIZE, Color(0.95, 0.5, 0.2, 0.9))
		draw_arc(p.pos, PARTICLE_SIZE, 0, TAU, 8, Color(1.0, 0.7, 0.3, 0.7), 1.0)
