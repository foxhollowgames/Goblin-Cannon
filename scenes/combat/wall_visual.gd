extends Node2D
## Graphical wall at the top of the battlefield. Draws stone/brick style wall.

const WALL_HEIGHT: float = 72.0
const WALL_WIDTH: float = 320.0
const BRICK_ROWS: int = 4
const BRICK_COLS: int = 12

func _draw() -> void:
	# Dark stone base
	var base_rect := Rect2(0, 0, WALL_WIDTH, WALL_HEIGHT)
	draw_rect(base_rect, Color(0.25, 0.22, 0.2, 1))
	draw_rect(base_rect, Color(0.35, 0.32, 0.28, 1), false, 3.0)
	# Brick pattern
	var brick_w: float = WALL_WIDTH / float(BRICK_COLS)
	var brick_h: float = WALL_HEIGHT / float(BRICK_ROWS)
	for row in range(BRICK_ROWS):
		for col in range(BRICK_COLS):
			var offset_x: float = (row % 2) * (brick_w * 0.5)
			var x: float = col * brick_w + offset_x
			var y: float = row * brick_h
			var brick := Rect2(x + 2, y + 2, brick_w - 4, brick_h - 4)
			var shade: float = 0.28 + (row + col) % 3 * 0.025 if (row + col) % 2 == 0 else 0.32 + (row * 2 + col) % 3 * 0.02
			draw_rect(brick, Color(shade, shade * 0.95, shade * 0.9, 1))
	# Battlements (top edge)
	for i in range(0, int(WALL_WIDTH), 24):
		var cap := Rect2(i, 0, 20, 8)
		draw_rect(cap, Color(0.3, 0.27, 0.24, 1))
		draw_rect(cap, Color(0.4, 0.36, 0.32, 1), false, 1.0)
