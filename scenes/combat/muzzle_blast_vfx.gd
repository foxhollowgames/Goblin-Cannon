extends Node2D
## Small explosion burst around the cannon (muzzle blast) using preloaded VFX spritesheet texture.

#region Constants
const PARTICLE_COUNT: int = 16
const BURST_RADIUS: float = 38.0
const DURATION: float = 0.22
const PARTICLE_SIZE: float = 10.0

const BLAST_VFX_TEXTURE: Texture2D = preload("res://assets/VFX/Essentials VFX Spritesheets/Star_Explosion_V2_A_spritesheet.png")
#endregion

#region Variables
var _particles: Array[Dictionary] = []  # { pos: Vector2, end_pos: Vector2, frame: int }
var _progress: float = 0.0
#endregion

#region Public Methods
## Configures muzzle blast effect center position and particle trajectories.
func setup(blast_pos: Vector2) -> void:
	position = blast_pos
	for i in PARTICLE_COUNT:
		var angle: float = (float(i) / float(PARTICLE_COUNT)) * TAU
		var end_dist: float = 12.0 + (i % 4) * 4.0 + BURST_RADIUS * 0.5
		_particles.append({
			"pos": Vector2.ZERO,
			"end_pos": Vector2.from_angle(angle) * end_dist,
			"frame": (i * 2) % 16
		})
#endregion

#region Engine Callbacks
func _ready() -> void:
	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(self, "_progress", 1.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for p in _particles:
		var end_pos: Vector2 = p.end_pos
		t.tween_method(func(v: float) -> void: _lerp_particle(p, end_pos, v), 0.0, 1.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(queue_free).set_delay(DURATION)

func _draw() -> void:
	var alpha: float = clampf(1.0 - _progress, 0.0, 1.0)
	for p in _particles:
		if BLAST_VFX_TEXTURE:
			var frame_idx: int = int(p.frame + _progress * 10) % 16
			var col: int = frame_idx % 4
			var row: int = frame_idx / 4
			var src_rect := Rect2(col * 1024, row * 1024, 1024, 1024)
			var dest_rect := Rect2(p.pos - Vector2(PARTICLE_SIZE, PARTICLE_SIZE) * 0.5, Vector2(PARTICLE_SIZE, PARTICLE_SIZE))
			draw_texture_rect_region(BLAST_VFX_TEXTURE, dest_rect, src_rect, Color(1.0, 0.7, 0.3, alpha * 0.9))
		else:
			draw_circle(p.pos, PARTICLE_SIZE, Color(0.95, 0.5, 0.2, alpha * 0.9))
			draw_arc(p.pos, PARTICLE_SIZE, 0, TAU, 8, Color(1.0, 0.7, 0.3, alpha * 0.7), 1.0)
#endregion

#region Private Methods
func _lerp_particle(p: Dictionary, end_pos: Vector2, t: float) -> void:
	p.pos = end_pos * t
	queue_redraw()
#endregion


