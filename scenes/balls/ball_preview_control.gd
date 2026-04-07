extends Control
## Draws a single ball preview (bubble + ability icon + alignment color). Used in reward draft cards and anywhere we need a ball icon.
## Set shape_type for per-ability unique shapes; -1 uses alignment-based shape.

var alignment: int = 0
var shape_type: int = -1
var ability_name: String = ""

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var sz: float = minf(size.x, size.y)
	if sz <= 0:
		return
	var center: Vector2 = size / 2.0
	var radius: float = sz / 2.0 - 2.0
	BallVisuals.draw_ball(self, center, radius, alignment, shape_type, ability_name)

func set_alignment(a: int) -> void:
	if alignment != a:
		alignment = a
		queue_redraw()

func set_shape_type(s: int) -> void:
	if shape_type != s:
		shape_type = s
		queue_redraw()

func set_ability_name(name: String) -> void:
	if ability_name != name:
		ability_name = name
		queue_redraw()
