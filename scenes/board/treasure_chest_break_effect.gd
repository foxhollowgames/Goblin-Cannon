extends Node2D
## One-shot VFX when a treasure chest peg breaks: gold/orange pop, shockwave, and flying sparks.

const DURATION_SEC: float = 0.58
const OUTER_RING_PX: float = 56.0
const SPARK_COUNT: int = 22
const SPARK_MAX_DIST: float = 72.0

var _elapsed: float = 0.0
var _spark_angles: Array[float] = []

func _ready() -> void:
	z_index = 105
	for i in SPARK_COUNT:
		_spark_angles.append((float(i) / float(SPARK_COUNT)) * TAU + float(i) * 0.417)

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= DURATION_SEC:
		queue_free()

func _draw() -> void:
	var t: float = clampf(_elapsed / DURATION_SEC, 0.0, 1.0)
	var ease: float = 1.0 - pow(1.0 - t, 2.85)
	var fade: float = (1.0 - t) * (1.0 - t * 0.32)

	# Bright core flash (first ~120ms)
	var flash_t: float = clampf(_elapsed / 0.12, 0.0, 1.0)
	var flash_alpha: float = (1.0 - flash_t) * 0.92
	if flash_alpha > 0.02:
		draw_circle(Vector2.ZERO, lerpf(8.0, 28.0, 1.0 - flash_t), Color(1.0, 0.97, 0.88, flash_alpha))
		draw_circle(Vector2.ZERO, lerpf(4.0, 14.0, 1.0 - flash_t), Color(1.0, 1.0, 1.0, flash_alpha * 0.75))

	# Expanding rings — warm gold through orange (matches chest trim / loot feel)
	var r_wave: float = lerpf(12.0, OUTER_RING_PX, ease)
	var r_inner: float = lerpf(6.0, OUTER_RING_PX * 0.78, ease * 0.94)
	draw_circle(Vector2.ZERO, r_wave, Color(0.52, 0.22, 0.04, fade * 0.52))
	draw_circle(Vector2.ZERO, r_inner * 0.9, Color(0.92, 0.42, 0.08, fade * 0.62))
	draw_circle(Vector2.ZERO, r_inner * 0.55, Color(1.0, 0.72, 0.18, fade * 0.74))
	draw_circle(Vector2.ZERO, r_inner * 0.24, Color(1.0, 0.92, 0.45, fade * 0.88))
	draw_arc(Vector2.ZERO, r_wave, 0.0, TAU, 72, Color(1.0, 0.78, 0.22, fade * 0.88), 2.8)

	# Slightly delayed inner shockwave for a second “pop”
	var t2: float = clampf((_elapsed - 0.04) / (DURATION_SEC - 0.04), 0.0, 1.0)
	if t2 > 0.0:
		var e2: float = 1.0 - pow(1.0 - t2, 2.2)
		var r2: float = lerpf(6.0, OUTER_RING_PX * 0.92, e2)
		var f2: float = (1.0 - t2) * fade
		draw_arc(Vector2.ZERO, r2, 0.0, TAU, 64, Color(1.0, 0.55, 0.12, f2 * 0.75), 2.0)

	# Radial sparks / splinters
	for i in SPARK_COUNT:
		var a: float = _spark_angles[i]
		var dir := Vector2.from_angle(a)
		var dist_var: float = 0.52 + 0.48 * abs(sin(float(i) * 1.97))
		var dist: float = ease * SPARK_MAX_DIST * dist_var
		var p: Vector2 = dir * dist
		var spark_fade: float = fade * (0.55 + 0.45 * abs(cos(float(i) * 1.3)))
		var sz: float = 1.6 + 1.4 * (1.0 - t)
		draw_circle(p, sz, Color(1.0, 0.82, 0.28, spark_fade * 0.92))
		draw_circle(p + dir * 3.5 * (1.0 - ease), sz * 0.45, Color(1.0, 0.35, 0.08, spark_fade * 0.55))

	# A few longer streaks (motion lines)
	for k in 8:
		var sa: float = (float(k) / 8.0) * TAU + 0.31
		var sd := Vector2.from_angle(sa)
		var len: float = lerpf(18.0, 4.0, t) * ease
		var w: float = 2.2 * fade
		draw_line(Vector2.ZERO, sd * len, Color(1.0, 0.65, 0.15, fade * 0.65), w)
