extends Control
## Draws a single ball preview (shape + alignment color). Used in reward draft cards and anywhere we need a ball icon.
## Set shape_type for per-ability unique shapes; -1 uses alignment-based shape.

var alignment: int = 0
var shape_type: int = -1

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var sz: float = minf(size.x, size.y)
	if sz <= 0:
		return
	var center: Vector2 = size / 2.0
	var radius: float = sz / 2.0 - 2.0
	BallVisuals.draw_ball(self, center, radius, alignment, shape_type)

func set_alignment(a: int) -> void:
	if alignment != a:
		alignment = a
		queue_redraw()

func set_shape_type(s: int) -> void:
	if shape_type != s:
		shape_type = s
		queue_redraw()
