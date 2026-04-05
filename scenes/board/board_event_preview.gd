extends Node2D
## Money bag + vortex preview before a milestone event peg spawns.

var _phase: float = 0.0

func _ready() -> void:
	z_index = 50
	set_process(true)

func _process(delta: float) -> void:
	_phase += delta * 5.0
	queue_redraw()

func _draw() -> void:
	var t: float = float(Time.get_ticks_msec()) * 0.003
	# Vortex arcs
	var r0: float = 28.0
	for i in range(5):
		var a0: float = t + float(i) * TAU / 5.0
		var a1: float = a0 + TAU * 0.35
		var col := Color(0.55, 0.35, 0.95, 0.45 - float(i) * 0.06)
		draw_arc(Vector2.ZERO, r0 + float(i) * 5.0, a0, a1, 16, col, 3.0 - float(i) * 0.35)
	# Simple money bag (rounded body + tie)
	var bag_w: float = 22.0
	var bag_h: float = 26.0
	var pulse: float = 0.85 + 0.15 * sin(_phase * 2.0)
	var gold := Color(0.92, 0.78, 0.28, pulse)
	var shadow := Color(0.45, 0.35, 0.12, pulse)
	draw_rect(Rect2(-bag_w * 0.5, -bag_h * 0.5 + 4.0, bag_w, bag_h * 0.75), gold)
	draw_arc(Vector2(0, -bag_h * 0.5 + 8.0), bag_w * 0.45, PI, TAU, 12, gold, 2.0, true)
	draw_line(Vector2(0, -bag_h * 0.5 + 4.0), Vector2(0, -bag_h * 0.5 - 2.0), shadow, 3.0)
	draw_circle(Vector2(0, -bag_h * 0.5 - 4.0), 4.0, gold.lightened(0.1))
