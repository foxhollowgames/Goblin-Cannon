extends Node2D
## Burst explosion at wall impact using preloaded VFX spritesheet texture.

#region Constants
const PARTICLE_COUNT: int = 16
const DEBRIS_COUNT: int = 10
const BURST_RADIUS: float = 40.0
const DURATION: float = 0.35
const PARTICLE_SIZE: float = 28.0

const IMPACT_VFX_TEXTURE: Texture2D = preload("res://assets/VFX/Essentials VFX Spritesheets/Impact_Cartoon Hit_V1_spritesheet.png")
const DEBRIS_TEXTURE: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Platformer Pack Medieval/PNG/medievalTile_015.png")
#endregion

#region Variables
var _particles: Array[Dictionary] = []  # { pos: Vector2, end_pos: Vector2, frame: int }
var _debris: Array[Dictionary] = []     # { pos: Vector2, vel: Vector2, size: float, rot: float, rot_speed: float }
var _progress: float = 0.0
var _tween: Tween
#endregion

#region Public Methods
## Configures impact effect starting position and initializes particle and debris trajectory data.
func setup(impact_pos: Vector2) -> void:
	position = impact_pos
	for i in PARTICLE_COUNT:
		var angle: float = (float(i) / float(PARTICLE_COUNT)) * TAU + 0.1
		var dist: float = 10.0 + (i % 4) * 6.0
		var end_dist: float = dist + BURST_RADIUS
		_particles.append({
			"pos": Vector2.from_angle(angle) * dist,
			"end_pos": Vector2.from_angle(angle) * end_dist,
			"frame": i % 16
		})
	for i in DEBRIS_COUNT:
		var angle: float = randf_range(PI * 0.6, PI * 1.4)
		var speed: float = randf_range(60.0, 180.0)
		_debris.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.from_angle(angle) * speed,
			"size": randf_range(4.0, 8.0),
			"rot": randf_range(0.0, TAU),
			"rot_speed": randf_range(-8.0, 8.0)
		})
#endregion

#region Engine Callbacks
func _ready() -> void:
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "_progress", 1.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for p in _particles:
		var start_pos: Vector2 = p.pos
		var end_pos: Vector2 = p.end_pos
		_tween.tween_method(func(v: float) -> void: _tween_particle(p, start_pos, end_pos, v), 0.0, 1.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(queue_free).set_delay(DURATION)

func _process(delta: float) -> void:
	for d in _debris:
		d.pos += d.vel * delta
		d.vel.y += 350.0 * delta
		d.rot += d.rot_speed * delta
	queue_redraw()

func _draw() -> void:
	var alpha: float = clampf(1.0 - _progress, 0.0, 1.0)
	for d in _debris:
		var d_rect := Rect2(d.pos - Vector2(d.size, d.size) * 0.5, Vector2(d.size, d.size))
		if DEBRIS_TEXTURE:
			draw_texture_rect(DEBRIS_TEXTURE, d_rect, false, Color(1, 1, 1, alpha))
		else:
			draw_rect(d_rect, Color(0.4, 0.36, 0.32, alpha))
	for p in _particles:
		if IMPACT_VFX_TEXTURE:
			var frame_idx: int = int(p.frame + _progress * 8) % 16
			var col: int = frame_idx % 4
			var row: int = frame_idx / 4
			var src_rect := Rect2(col * 512, row * 512, 512, 512)
			var dest_rect := Rect2(p.pos - Vector2(PARTICLE_SIZE, PARTICLE_SIZE) * 0.5, Vector2(PARTICLE_SIZE, PARTICLE_SIZE))
			draw_texture_rect_region(IMPACT_VFX_TEXTURE, dest_rect, src_rect, Color(1.0, 0.85, 0.45, alpha * 0.95))
		else:
			var c0: Color = Constants.gameplay_wall_impact_core()
			var c1: Color = Constants.gameplay_wall_impact_ring()
			draw_circle(p.pos, PARTICLE_SIZE * 0.5, Color(c0.r, c0.g, c0.b, alpha * 0.95))
			draw_arc(p.pos, PARTICLE_SIZE * 0.5, 0, TAU, 10, Color(c1.r, c1.g, c1.b, alpha * 0.8), 1.5)
#endregion

#region Private Methods
func _tween_particle(p: Dictionary, start_pos: Vector2, end_pos: Vector2, t: float) -> void:
	p.pos = start_pos.lerp(end_pos, t)
	queue_redraw()
#endregion


