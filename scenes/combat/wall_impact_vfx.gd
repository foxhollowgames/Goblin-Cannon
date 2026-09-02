extends Node2D
## Burst explosion at wall impact using preloaded VFX spritesheet texture.

const PARTICLE_COUNT: int = 24
const BURST_RADIUS: float = 45.0
const DURATION: float = 0.35
const PARTICLE_SIZE: float = 12.0

const IMPACT_VFX_TEXTURE: Texture2D = preload("res://assets/VFX/Essentials VFX Spritesheets/Star_Explosion_V1_A_spritesheet.png")

var _particles: Array[Dictionary] = []  # { pos: Vector2, end_pos: Vector2 }
var _progress: float = 0.0
var _tween: Tween

func setup(impact_pos: Vector2) -> void:
	position = impact_pos
	for i in PARTICLE_COUNT:
		var angle: float = (float(i) / float(PARTICLE_COUNT)) * TAU + 0.1
		var dist: float = 15.0 + (i % 5) * 6.0
		var end_dist: float = dist + BURST_RADIUS
		_particles.append({
			"pos": Vector2.from_angle(angle) * dist,
			"end_pos": Vector2.from_angle(angle) * end_dist,
			"frame": i % 16
		})

func _ready() -> void:
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "_progress", 1.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for p in _particles:
		var start_pos: Vector2 = p.pos
		var end_pos: Vector2 = p.end_pos
		_tween.tween_method(func(v): _tween_particle(p, start_pos, end_pos, v), 0.0, 1.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(queue_free).set_delay(DURATION)

func _tween_particle(p: Dictionary, start_pos: Vector2, end_pos: Vector2, t: float) -> void:
	p.pos = start_pos.lerp(end_pos, t)
	queue_redraw()

func _draw() -> void:
	var alpha: float = clampf(1.0 - _progress, 0.0, 1.0)
	for p in _particles:
		if IMPACT_VFX_TEXTURE:
			var frame_idx: int = int(p.frame + _progress * 8) % 16
			var col: int = frame_idx % 4
			var row: int = frame_idx / 4
			var src_rect := Rect2(col * 1024, row * 1024, 1024, 1024)
			var dest_rect := Rect2(p.pos - Vector2(PARTICLE_SIZE, PARTICLE_SIZE) * 0.5, Vector2(PARTICLE_SIZE, PARTICLE_SIZE))
			draw_texture_rect_region(IMPACT_VFX_TEXTURE, dest_rect, src_rect, Color(1.0, 0.8, 0.4, alpha * 0.9))
		else:
			var c0: Color = Constants.gameplay_wall_impact_core()
			var c1: Color = Constants.gameplay_wall_impact_ring()
			draw_circle(p.pos, PARTICLE_SIZE, Color(c0.r, c0.g, c0.b, alpha * 0.95))
			draw_arc(p.pos, PARTICLE_SIZE, 0, TAU, 10, Color(c1.r, c1.g, c1.b, alpha * 0.8), 1.5)

