extends Control
## Connector segment between conquest path bubbles. Narrow vertical rectangle with light border.

const SEGMENT_WIDTH: int = 10
const SEGMENT_HEIGHT: int = 24
const COLOR_FILL: Color = Color(0.36, 0.18, 0.18, 1)      # dark reddish-brown
const COLOR_BORDER: Color = Color(0.55, 0.28, 0.28, 1)   # lighter reddish-brown

func _ready() -> void:
	custom_minimum_size = Vector2(SEGMENT_WIDTH, SEGMENT_HEIGHT)
	size = Vector2(SEGMENT_WIDTH, SEGMENT_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, COLOR_FILL)
	# Left and right borders
	draw_line(Vector2(0, 0), Vector2(0, size.y), COLOR_BORDER)
	draw_line(Vector2(size.x - 1, 0), Vector2(size.x - 1, size.y), COLOR_BORDER)
