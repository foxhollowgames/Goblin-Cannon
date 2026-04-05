extends Node2D
## Preview VFX before a treasure chest peg spawns (gold sparks + chest silhouette).

var _phase: float = 0.0

func _ready() -> void:
	z_index = 50
	set_process(true)

func _process(delta: float) -> void:
	_phase += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var t: float = float(Time.get_ticks_msec()) * 0.004
	var pulse: float = 0.82 + 0.18 * sin(_phase * 2.0)
	# Spark arcs
	for i in range(4):
		var a0: float = t + float(i) * TAU / 4.0
		var a1: float = a0 + TAU * 0.28
		var col := Color(0.95, 0.72, 0.2, 0.4 - float(i) * 0.07)
		draw_arc(Vector2.ZERO, 26.0 + float(i) * 6.0, a0, a1, 14, col, 2.5)
	# Chest body
	var w: float = 26.0
	var h: float = 20.0
	var wood := Color(0.42, 0.28, 0.14, pulse)
	var trim := Color(0.92, 0.75, 0.22, pulse)
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h * 0.55), wood)
	draw_rect(Rect2(-w * 0.5, -h * 0.5 + h * 0.45, w, h * 0.55), wood.darkened(0.12))
	draw_line(Vector2(-w * 0.5, -h * 0.5 + h * 0.45), Vector2(w * 0.5, -h * 0.5 + h * 0.45), trim, 2.5)
	draw_arc(Vector2(0, -h * 0.5), w * 0.48, PI, TAU, 14, trim, 2.0, true)
	draw_circle(Vector2(0, 0), 4.5 * pulse, trim.lightened(0.05))
