class_name RarityShapeMarker
extends Control
## Rarity shape marker component drawn at top of shop cards.

#region Config
@export var rarity: int = 0
@export var shape_color: Color = Color.WHITE
#endregion

#region Signals
signal shape_changed(new_rarity: int)
#endregion

#region Public API
func _ready() -> void:
	update_shape()

func set_rarity(new_rarity: int) -> void:
	rarity = clampi(new_rarity, 0, 10)
	update_shape()
	shape_changed.emit(rarity)

func update_shape() -> void:
	queue_redraw()
#endregion

#region Drawing
func _draw() -> void:
	var kind: int = 3
	if rarity <= 0:
		kind = 0
	elif rarity == 1:
		kind = 1
	elif rarity == 2:
		kind = 2
	var s: float = minf(size.x, size.y)
	var cx: float = size.x * 0.5
	var cy: float = size.y * 0.5
	match kind:
		0:
			var half: float = s * 0.38
			draw_rect(Rect2(cx - half, cy - half, half * 2.0, half * 2.0), shape_color)
		1:
			var pts: PackedVector2Array = PackedVector2Array([
				Vector2(cx, cy - s * 0.45),
				Vector2(cx + s * 0.45, cy),
				Vector2(cx, cy + s * 0.45),
				Vector2(cx - s * 0.45, cy),
			])
			draw_colored_polygon(pts, shape_color)
		2:
			var pts2: PackedVector2Array = PackedVector2Array([
				Vector2(cx, cy - s * 0.42),
				Vector2(cx + s * 0.45, cy + s * 0.45),
				Vector2(cx - s * 0.45, cy + s * 0.45),
			])
			draw_colored_polygon(pts2, shape_color)
		3:
			draw_circle(Vector2(cx, cy), s * 0.44, shape_color)
#endregion

