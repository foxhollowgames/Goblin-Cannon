class_name PegTransformEffect
extends Node2D
## Burst VFX when a peg is converted to a special type during peg selection.
## Uses real time (Time.get_ticks_msec) so it animates even when Engine.time_scale = 0.

const DURATION_SEC: float = 0.55

var _peg_kind: String = ""
var _start_time_ms: int = 0
var _sparkle_angles: PackedFloat32Array = []
var _sparkle_speeds: PackedFloat32Array = []

func setup(kind: String) -> void:
	_peg_kind = kind

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_time_ms = Time.get_ticks_msec()
	z_index = 100
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	for i in range(10):
		_sparkle_angles.append(rng.randf() * TAU)
		_sparkle_speeds.append(45.0 + rng.randf() * 70.0)

func _process(_delta: float) -> void:
	queue_redraw()
	var elapsed: float = float(Time.get_ticks_msec() - _start_time_ms) / 1000.0
	if elapsed >= DURATION_SEC:
		queue_free()

func _draw() -> void:
	var elapsed: float = float(Time.get_ticks_msec() - _start_time_ms) / 1000.0
	var t: float = clampf(elapsed / DURATION_SEC, 0.0, 1.0)
	var color: Color = _get_kind_color()

	# Bright center flash
	var flash_alpha: float = maxf(0.0, 1.0 - t * 2.5)
	if flash_alpha > 0.0:
		draw_circle(Vector2.ZERO, lerpf(18.0, 6.0, t), Color(1.0, 1.0, 1.0, flash_alpha * 0.9))
		draw_circle(Vector2.ZERO, lerpf(12.0, 3.0, t), Color(color.r, color.g, color.b, flash_alpha))

	# Primary expanding ring
	var ring_r: float = lerpf(8.0, 55.0, t)
	var ring_alpha: float = (1.0 - t) * 0.85
	draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 32, Color(color.r, color.g, color.b, ring_alpha), 3.5)

	# Secondary ring (delayed, thinner)
	if t > 0.12:
		var t2: float = clampf((t - 0.12) / 0.88, 0.0, 1.0)
		var r2: float = lerpf(5.0, 42.0, t2)
		draw_arc(Vector2.ZERO, r2, 0.0, TAU, 32, Color(color.r, color.g, color.b, (1.0 - t2) * 0.5), 2.0)

	# Sparkle particles
	for i in range(_sparkle_angles.size()):
		var dist: float = _sparkle_speeds[i] * t
		var sp: Vector2 = Vector2(cos(_sparkle_angles[i]), sin(_sparkle_angles[i])) * dist
		var sa: float = (1.0 - t) * 0.75
		var ss: float = lerpf(3.0, 1.0, t)
		draw_circle(sp, ss, Color(color.r, color.g, color.b, sa))

func _get_kind_color() -> Color:
	match _peg_kind:
		"bomb":
			return Color(1.0, 0.35, 0.1)
		"trampoline":
			return Color(0.25, 0.88, 0.5)
		"goblin_reset":
			return Color(0.5, 0.75, 0.3)
		"eternal":
			return Color(0.7, 0.8, 1.0)
		"extreme_bouncer":
			return Color(1.0, 0.6, 0.15)
		"magnet":
			return Color(0.85, 0.25, 0.25)
		"splitter":
			return Color(0.75, 0.45, 0.85)
		"gold":
			return Color(1.0, 0.85, 0.3)
		"lucky_gold":
			return Color(0.35, 0.92, 0.5)
		"gravity_well":
			return Color(0.5, 0.3, 0.8)
		"phase":
			return Color(0.4, 0.85, 0.9)
		"wrench":
			return Color(0.8, 0.65, 0.25)
	return Color(1.0, 0.9, 0.4)
