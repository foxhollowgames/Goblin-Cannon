extends Node2D
## One-shot VFX when the buffet table is cleared: warm crumbs, steam puff, confetti flecks.

const DURATION_SEC: float = 0.72
const BURST_COUNT: int = 28
const CRUMB_MAX: float = 78.0

var _elapsed: float = 0.0
var _angles: Array[float] = []

func _ready() -> void:
	z_index = 106
	for i in BURST_COUNT:
		_angles.append((float(i) / float(BURST_COUNT)) * TAU + float(i) * 0.513)

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= DURATION_SEC:
		queue_free()

func _draw() -> void:
	var t: float = clampf(_elapsed / DURATION_SEC, 0.0, 1.0)
	var ease: float = 1.0 - pow(1.0 - t, 2.4)
	var fade: float = (1.0 - t) * (1.0 - t * 0.25)

	# Steam cloud
	var steam_a: float = (1.0 - clampf(_elapsed / 0.35, 0.0, 1.0)) * 0.55
	if steam_a > 0.02:
		for s in range(5):
			var sr: float = lerpf(16.0, 42.0, float(s) / 4.0) * (0.85 + 0.15 * sin(_elapsed * 12.0 + float(s)))
			draw_circle(Vector2(sin(_elapsed * 8.0 + s) * 6.0, -12.0 - float(s) * 5.0), sr * 0.45, Color(0.92, 0.95, 0.98, steam_a * (0.35 - float(s) * 0.05)))

	# Soft pop
	var flash_t: float = clampf(_elapsed / 0.14, 0.0, 1.0)
	var flash_alpha: float = (1.0 - flash_t) * 0.55
	if flash_alpha > 0.02:
		draw_circle(Vector2.ZERO, lerpf(10.0, 36.0, 1.0 - flash_t), Color(1.0, 0.96, 0.88, flash_alpha))

	# Radial crumbs / sparkles (greens, golds, cream)
	for i in BURST_COUNT:
		var a: float = _angles[i]
		var dir := Vector2.from_angle(a)
		var dist: float = ease * CRUMB_MAX * (0.45 + 0.55 * abs(sin(float(i) * 1.37)))
		var p: Vector2 = dir * dist + Vector2(0, -ease * 12.0)
		var hue: float = fmod(float(i) * 0.17, 1.0)
		var col: Color
		if hue < 0.33:
			col = Color(0.45, 0.72, 0.38, fade * 0.9)
		elif hue < 0.66:
			col = Color(0.95, 0.82, 0.35, fade * 0.92)
		else:
			col = Color(0.96, 0.9, 0.78, fade * 0.88)
		var sz: float = 1.8 + 1.6 * (1.0 - t)
		draw_circle(p, sz, col)
		draw_circle(p + dir * 2.2, sz * 0.4, Color(1.0, 1.0, 1.0, fade * 0.35))

	# Ring wave
	var rw: float = lerpf(14.0, 62.0, ease)
	draw_arc(Vector2.ZERO, rw, 0.0, TAU, 64, Color(0.55, 0.75, 0.4, fade * 0.45), 2.2)
