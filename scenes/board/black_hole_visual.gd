extends Node2D
## Active black hole: dark core + swirling accretion ring (board-local position).

var _t: float = 0.0

func _ready() -> void:
	z_index = 41
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var pulse: float = 0.92 + 0.08 * sin(_t * 3.0)
	var core_r: float = 44.0 * pulse
	draw_circle(Vector2.ZERO, core_r * 1.35, Color(0.04, 0.02, 0.12, 0.5))
	draw_circle(Vector2.ZERO, core_r, Color(0.0, 0.0, 0.0, 0.96))
	draw_arc(Vector2.ZERO, core_r * 1.02, 0.0, TAU, 64, Color(0.25, 0.1, 0.5, 0.65), 2.5)
	var rings: int = 6
	for i in range(rings):
		var r0: float = core_r + 12.0 + float(i) * 14.0
		var a0: float = _t * (1.1 + float(i) * 0.08) + float(i) * 0.9
		var a1: float = a0 + TAU * 0.4
		var alpha: float = (0.45 - float(i) * 0.055) * pulse
		draw_arc(Vector2.ZERO, r0, a0, a1, 32, Color(0.55, 0.35, 0.95, alpha), 3.0 - float(i) * 0.25)
