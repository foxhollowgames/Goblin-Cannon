extends Node2D
## Preview VFX before a buffet table peg spawns.

var _phase: float = 0.0

func _ready() -> void:
	z_index = 50
	set_process(true)

func _process(delta: float) -> void:
	_phase += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var pulse: float = 0.88 + 0.12 * sin(_phase * 2.2)
	var cloth := Color(0.82, 0.72, 0.55, 0.92 * pulse)
	var plate := Color(0.95, 0.93, 0.88, 0.95 * pulse)
	var steam := Color(0.85, 0.9, 0.95, 0.35 * pulse)
	# Steam curls
	for i in range(4):
		var ox: float = (float(i) - 1.5) * 14.0
		draw_arc(Vector2(ox, 8.0), 10.0 + float(i) * 2.0, PI * 1.1, PI * 1.9, 10, steam, 2.0)
	# Table top
	var tw: float = 52.0
	var th: float = 14.0
	draw_rect(Rect2(-tw * 0.5, -th * 0.5, tw, th), cloth)
	draw_rect(Rect2(-tw * 0.5, -th * 0.5, tw, 3.0), cloth.darkened(0.12))
	# Plates
	for px in [-14.0, 14.0]:
		draw_arc(Vector2(px, -2.0), 9.0, 0.0, TAU, 20, plate, 2.0)
		draw_circle(Vector2(px, -2.0), 6.5, plate.darkened(0.04))
	# Center dome (cloche hint)
	draw_arc(Vector2.ZERO, 11.0, PI, TAU, 16, Color(0.75, 0.78, 0.82, 0.55 * pulse), 2.0)
