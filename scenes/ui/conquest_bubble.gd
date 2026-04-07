extends Control
## Single wall section bubble for the conquest path. Draws a circle; current wall = rust highlight, others = warm brown.

var is_current: bool = false:
	set(v):
		is_current = v
		queue_redraw()

const BUBBLE_SIZE: int = 42  # 25% smaller than original 56
const COLOR_CURRENT: Color = ColorPalette.CONQUEST_CURRENT
const COLOR_CURRENT_HIGHLIGHT: Color = ColorPalette.CONQUEST_CURRENT_HIGHLIGHT
const COLOR_DEFAULT: Color = ColorPalette.CONQUEST_INACTIVE
const COLOR_DEFAULT_HIGHLIGHT: Color = ColorPalette.CONQUEST_INACTIVE_HIGHLIGHT

func _ready() -> void:
	custom_minimum_size = Vector2(BUBBLE_SIZE, BUBBLE_SIZE)
	size = Vector2(BUBBLE_SIZE, BUBBLE_SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 2.0
	var fill_color: Color = COLOR_CURRENT if is_current else COLOR_DEFAULT
	var highlight_color: Color = COLOR_CURRENT_HIGHLIGHT if is_current else COLOR_DEFAULT_HIGHLIGHT
	# Fill
	draw_circle(center, radius, fill_color)
	# Subtle highlight along bottom-right edge (arc from ~7 o'clock to ~2 o'clock)
	draw_arc(center, radius + 1.0, deg_to_rad(200.0), deg_to_rad(20.0), 24, highlight_color, 1.5)
