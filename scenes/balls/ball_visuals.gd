class_name BallVisuals
extends RefCounted
## Shared ball representation: color by alignment, shape per ability (or by alignment if shape_type not set). Used on board and in reward draft.

## Main = Yellow, Sidearm = Red, Defense = Blue (alignment index 0, 1, 2)
const ALIGNMENT_COLORS: Array[Color] = [
	Color(0.95, 0.85, 0.2, 1),   # 0 Main cannon - Yellow
	Color(0.9, 0.25, 0.2, 1),    # 1 Sidearm - Red
	Color(0.25, 0.5, 0.95, 1),  # 2 Defense - Blue
]

enum ShapeType {
	CIRCLE,
	TRIANGLE,
	DIAMOND,
	SQUARE,
	PENTAGON,
	HEXAGON,
	STAR,
	PLUS
}

static func get_alignment_color(alignment: int) -> Color:
	if alignment >= 0 and alignment < ALIGNMENT_COLORS.size():
		return ALIGNMENT_COLORS[alignment]
	return ALIGNMENT_COLORS[0]

static func get_shape_for_alignment(alignment: int) -> int:
	match alignment:
		1: return ShapeType.TRIANGLE   # Sidearm
		2: return ShapeType.DIAMOND   # Defense
		_: return ShapeType.CIRCLE  # Main

## Draw the ball visual (shape + alignment color) at center with given radius.
## shape_override: -1 = use alignment-based shape; 0+ = use this ShapeType so each ability can be unique.
static func draw_ball(canvas: CanvasItem, center: Vector2, radius: float, alignment: int, shape_override: int = -1) -> void:
	var color: Color = get_alignment_color(alignment)
	var shape: int = shape_override if shape_override >= 0 and shape_override <= ShapeType.PLUS else get_shape_for_alignment(alignment)
	var r: float = radius
	match shape:
		ShapeType.CIRCLE:
			canvas.draw_circle(center, radius, color)
		ShapeType.TRIANGLE:
			var pts: PackedVector2Array = PackedVector2Array([
				center + Vector2(0, -r),
				center + Vector2(r * 0.866, r * 0.5),
				center + Vector2(-r * 0.866, r * 0.5),
			])
			canvas.draw_colored_polygon(pts, color)
		ShapeType.DIAMOND:
			var pts: PackedVector2Array = PackedVector2Array([
				center + Vector2(0, -r),
				center + Vector2(r, 0),
				center + Vector2(0, r),
				center + Vector2(-r, 0),
			])
			canvas.draw_colored_polygon(pts, color)
		ShapeType.SQUARE:
			var h: float = r * 0.707  # half side for inscribed square
			var pts: PackedVector2Array = PackedVector2Array([
				center + Vector2(-h, -h),
				center + Vector2(h, -h),
				center + Vector2(h, h),
				center + Vector2(-h, h),
			])
			canvas.draw_colored_polygon(pts, color)
		ShapeType.PENTAGON:
			var pts: PackedVector2Array = PackedVector2Array()
			for i in 5:
				var a: float = -TAU / 4.0 + (float(i) * TAU / 5.0)
				pts.append(center + Vector2(cos(a) * r, sin(a) * r))
			canvas.draw_colored_polygon(pts, color)
		ShapeType.HEXAGON:
			var pts: PackedVector2Array = PackedVector2Array()
			for i in 6:
				var a: float = float(i) * TAU / 6.0
				pts.append(center + Vector2(cos(a) * r, sin(a) * r))
			canvas.draw_colored_polygon(pts, color)
		ShapeType.STAR:
			var outer: float = r
			var inner: float = r * 0.45
			var pts: PackedVector2Array = PackedVector2Array()
			for i in 10:
				var a: float = -TAU / 4.0 + (float(i) * TAU / 10.0)
				var rad: float = outer if i % 2 == 0 else inner
				pts.append(center + Vector2(cos(a) * rad, sin(a) * rad))
			canvas.draw_colored_polygon(pts, color)
		ShapeType.PLUS:
			var thick: float = r * 0.4
			var vert: PackedVector2Array = PackedVector2Array([
				center + Vector2(-thick, -r),
				center + Vector2(thick, -r),
				center + Vector2(thick, r),
				center + Vector2(-thick, r),
			])
			canvas.draw_colored_polygon(vert, color)
			var horz: PackedVector2Array = PackedVector2Array([
				center + Vector2(-r, -thick),
				center + Vector2(r, -thick),
				center + Vector2(r, thick),
				center + Vector2(-r, thick),
			])
			canvas.draw_colored_polygon(horz, color)
		_:
			canvas.draw_circle(center, radius, color)
