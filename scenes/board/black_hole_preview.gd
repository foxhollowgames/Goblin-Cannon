extends Node2D
## Warning rings before the black hole event activates.

var _phase: float = 0.0

func _ready() -> void:
	z_index = 50
	set_process(true)

func _process(delta: float) -> void:
	_phase += delta * 4.5
	queue_redraw()

func _draw() -> void:
	var t: float = float(Time.get_ticks_msec()) * 0.0025
	var pulse: float = 0.75 + 0.25 * sin(_phase * 2.0)
	for i in range(4):
		var r: float = 36.0 + float(i) * 22.0
		var a0: float = t + float(i) * TAU / 4.0
		var a1: float = a0 + TAU * 0.42
		var col := Color(0.25, 0.12, 0.45, (0.5 - float(i) * 0.08) * pulse)
		draw_arc(Vector2.ZERO, r, a0, a1, 24, col, 4.0 - float(i) * 0.5)
		draw_arc(Vector2.ZERO, r + 6.0, a1 + 0.2, a0 + TAU * 0.38, 24, Color(0.5, 0.35, 0.85, 0.22 * pulse), 2.0)
	draw_circle(Vector2.ZERO, 14.0, Color(0.02, 0.02, 0.06, 0.92 * pulse))
	draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 48, Color(0.4, 0.2, 0.7, 0.55 * pulse), 2.0)
