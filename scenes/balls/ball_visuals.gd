class_name BallVisuals
extends RefCounted
## Shared ball representation: alignment color, per-ability icon from res://icons inside a glass bubble shell.
## Used on board and in reward draft.

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
	PLUS,
	HALF_CIRCLE
}

## White SVGs from the icon library; tinted by alignment in _draw_icon_glow.
const _ICON_PLAIN: Texture2D = preload("res://icons/ffffff/transparent/1x1/delapouite/glass-ball.svg")
const _ICON_SPLIT: Texture2D = preload("res://icons/ffffff/transparent/1x1/lorc/split-body.svg")
const _ICON_ENERGIZE: Texture2D = preload("res://icons/ffffff/transparent/1x1/lorc/energy-arrow.svg")
const _ICON_EXPLOSIVE: Texture2D = preload("res://icons/ffffff/transparent/1x1/lorc/fire-bomb.svg")
const _ICON_CHAIN: Texture2D = preload("res://icons/ffffff/transparent/1x1/willdabeast/chain-lightning.svg")
const _ICON_LEECH: Texture2D = preload("res://icons/ffffff/transparent/1x1/lorc/chemical-drop.svg")
const _ICON_RUBBERY: Texture2D = preload("res://icons/ffffff/transparent/1x1/lorc/shield-bounces.svg")
const _ICON_PHANTOM: Texture2D = preload("res://icons/ffffff/transparent/1x1/lorc/ghost.svg")
const _ICON_VOLATILE: Texture2D = preload("res://icons/ffffff/transparent/1x1/sbed/poison-cloud.svg")

static func get_alignment_color(alignment: int) -> Color:
	if alignment >= 0 and alignment < ALIGNMENT_COLORS.size():
		return ALIGNMENT_COLORS[alignment]
	return ALIGNMENT_COLORS[0]

static func get_shape_for_alignment(alignment: int) -> int:
	match alignment:
		1: return ShapeType.TRIANGLE   # Sidearm
		2: return ShapeType.DIAMOND   # Defense
		_: return ShapeType.CIRCLE  # Main

static func get_icon_texture_for_ability(ability_key: String) -> Texture2D:
	var k: String = ability_key.strip_edges()
	match k:
		"Split":
			return _ICON_SPLIT
		"Energize":
			return _ICON_ENERGIZE
		"Explosive":
			return _ICON_EXPLOSIVE
		"Chain Lightning":
			return _ICON_CHAIN
		"Leech":
			return _ICON_LEECH
		"Rubbery":
			return _ICON_RUBBERY
		"Phantom":
			return _ICON_PHANTOM
		"Volatile":
			return _ICON_VOLATILE
		_:
			return _ICON_PLAIN

static func _resolve_ability_for_drawing(ability_name: String, shape: int) -> String:
	var ab: String = ability_name.strip_edges()
	if not ab.is_empty():
		return ab
	if shape == ShapeType.HALF_CIRCLE:
		return "Split"
	return ""

## Draw the ball: transparent sphere shell + color-coded, slightly glowing icon inside.
## shape_override: -1 = alignment-based shape; HALF_CIRCLE = split-twin / half-disk silhouette.
## ability_name: empty with plain circle = generic glass orb; empty with HALF_CIRCLE resolves to Split icon.
static func draw_ball(canvas: CanvasItem, center: Vector2, radius: float, alignment: int, shape_override: int = -1, ability_name: String = "") -> void:
	var shape: int = shape_override if shape_override >= 0 and shape_override <= ShapeType.HALF_CIRCLE else get_shape_for_alignment(alignment)
	var ab: String = _resolve_ability_for_drawing(ability_name, shape)
	var tex: Texture2D = get_icon_texture_for_ability(ab)
	var base_color: Color = get_alignment_color(alignment)
	if shape == ShapeType.HALF_CIRCLE:
		_draw_half_bubble(canvas, center, radius, base_color, tex)
	else:
		_draw_full_bubble(canvas, center, radius, base_color, tex)

static func _draw_full_bubble(canvas: CanvasItem, center: Vector2, r: float, base_color: Color, icon: Texture2D) -> void:
	canvas.draw_circle(center, r * 1.08, Color(base_color.r, base_color.g, base_color.b, 0.13))
	canvas.draw_circle(center, r * 0.99, Color(0.82, 0.9, 0.98, 0.26))
	canvas.draw_circle(center + Vector2(0, r * 0.36), r * 0.55, Color(0.32, 0.4, 0.52, 0.1))
	canvas.draw_arc(center, r * 0.99, 0.0, TAU, 56, Color(1, 1, 1, 0.3), 1.15, true)
	canvas.draw_arc(center, r * 0.96, 0.85, 2.35, 20, Color(base_color.r, base_color.g, base_color.b, 0.2), 0.85, true)
	canvas.draw_circle(center + Vector2(-r * 0.36, -r * 0.34), r * 0.17, Color(1, 1, 1, 0.42))
	_draw_icon_glow(canvas, center, r * 1.05, icon, base_color)

## Same arc topology as legacy HALF_CIRCLE fill: right half-disk, flat chord on the left.
static func _draw_half_bubble(canvas: CanvasItem, center: Vector2, r: float, base_color: Color, icon: Texture2D) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var segments: int = 22
	for i in segments + 1:
		var a: float = -PI / 2.0 + (float(i) / float(segments)) * PI
		pts.append(center + Vector2(cos(a) * r, sin(a) * r))
	canvas.draw_colored_polygon(pts, Color(0.76, 0.87, 0.98, 0.3))
	canvas.draw_line(center + Vector2(0, r), center + Vector2(0, -r), Color(1, 1, 1, 0.36), 1.15)
	canvas.draw_arc(center, r * 0.99, -PI / 2.0, PI / 2.0, 30, Color(1, 1, 1, 0.34), 1.15, true)
	canvas.draw_arc(center, r * 0.99, -PI / 2.0, PI / 2.0, 30, Color(base_color.r, base_color.g, base_color.b, 0.22), 0.85, true)
	canvas.draw_circle(center + Vector2(r * 0.45, -r * 0.28), r * 0.14, Color(1, 1, 1, 0.38))
	var icon_center: Vector2 = center + Vector2(r * 0.36, 0)
	_draw_icon_glow(canvas, icon_center, r * 0.94, icon, base_color)

static func _draw_icon_glow(canvas: CanvasItem, center: Vector2, icon_size: float, tex: Texture2D, base_color: Color) -> void:
	if tex == null:
		return
	var glow: Color = Color(
		minf(base_color.r * 1.28, 1.0),
		minf(base_color.g * 1.28, 1.0),
		minf(base_color.b * 1.28, 1.0),
		1.0
	)
	for layer in range(7, 0, -1):
		var s: float = icon_size * (1.0 + float(layer) * 0.042)
		var c: Color = Color(glow.r, glow.g, glow.b, 0.028 * float(layer))
		var rect := Rect2(center - Vector2(s * 0.5, s * 0.5), Vector2(s, s))
		canvas.draw_texture_rect(tex, rect, false, c)
	var main_rect := Rect2(center - Vector2(icon_size * 0.5, icon_size * 0.5), Vector2(icon_size, icon_size))
	canvas.draw_texture_rect(tex, main_rect, false, Color(glow.r, glow.g, glow.b, 0.94))
