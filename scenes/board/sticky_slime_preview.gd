extends Node2D
## Warning VFX above pegs before slime coating.

var _phase: float = 0.0

func _ready() -> void:
	z_index = 45
	set_process(true)

func _process(delta: float) -> void:
	_phase += delta * 5.0
	queue_redraw()

func _draw() -> void:
	var pulse: float = 0.82 + 0.18 * sin(_phase * 2.0)
	var drop := Color(0.4, 0.95, 0.55, 0.55 * pulse)
	var glow := Color(0.25, 0.85, 0.45, 0.25 * pulse)
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, glow, 3.0)
	for i in range(3):
		var dy: float = -8.0 - float(i) * 9.0 + fposmod(_phase * 22.0 + float(i) * 4.0, 10.0)
		draw_circle(Vector2(sin(_phase + float(i)) * 6.0, dy), 3.0 + float(i) * 0.4, drop)
