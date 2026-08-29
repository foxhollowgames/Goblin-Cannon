class_name BallVisuals
extends RefCounted
## Shared ball representation: alignment color, per-ability icon from res://icons inside a glass bubble shell.
## Used on board and in reward draft.

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

const _ICON_PATHS: Dictionary = {
	"Plain": "res://icons/ffffff/transparent/1x1/lorc/energy-arrow.svg",
	"Split": "res://icons/ffffff/transparent/1x1/lorc/split-body.svg",
	"Energize": "res://icons/ffffff/transparent/1x1/lorc/shield-bounces.svg",
	"Explosive": "res://icons/ffffff/transparent/1x1/lorc/fire-bomb.svg",
	"Chain Lightning": "res://icons/ffffff/transparent/1x1/willdabeast/chain-lightning.svg",
	"Leech": "res://icons/ffffff/transparent/1x1/lorc/chemical-drop.svg",
	"Rubbery": "res://icons/ffffff/transparent/1x1/delapouite/glass-ball.svg",
	"Phantom": "res://icons/ffffff/transparent/1x1/lorc/ghost.svg",
	"Volatile": "res://icons/ffffff/transparent/1x1/sbed/poison-cloud.svg",
	"Constellation": "res://icons/ffffff/transparent/1x1/delapouite/star-formation.svg",
	"Binary": "res://icons/ffffff/transparent/1x1/delapouite/stars-stack.svg",
	"Bloom": "res://icons/ffffff/transparent/1x1/delapouite/flower-star.svg",
}

static var _cached_textures: Dictionary = {}

static func get_alignment_color(alignment: int) -> Color:
	return Constants.ball_alignment_color(alignment)

static func get_shape_for_alignment(alignment: int) -> int:
	match alignment:
		1: return ShapeType.TRIANGLE   # Sidearm
		2: return ShapeType.DIAMOND   # Defense
		_: return ShapeType.CIRCLE  # Main

static func get_icon_texture_for_ability(ability_key: String) -> Texture2D:
	var k: String = ability_key.strip_edges()
	var path: String = _ICON_PATHS.get(k, _ICON_PATHS["Plain"])
	if _cached_textures.has(path):
		return _cached_textures[path]
	if ResourceLoader.exists(path):
		var tex = ResourceLoader.load(path)
		if tex is Texture2D:
			_cached_textures[path] = tex
			return tex
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null:
			var tex := ImageTexture.create_from_image(img)
			_cached_textures[path] = tex
			return tex
	return null

## Per-ability tint — one Lospec index per ability (`Constants.ball_ability_theme_color`).
static func get_ability_theme_color(ability_key: String) -> Color:
	return Constants.ball_ability_theme_color(ability_key)

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
## Volatile reagent glow is drawn on the ball node (Sprite2D + gas_cloud.gdshader), not here.
static func draw_ball(canvas: CanvasItem, center: Vector2, radius: float, alignment: int, shape_override: int = -1, ability_name: String = "") -> void:
	var shape: int = shape_override if shape_override >= 0 and shape_override <= ShapeType.HALF_CIRCLE else get_shape_for_alignment(alignment)
	var ab: String = _resolve_ability_for_drawing(ability_name, shape)
	var tex: Texture2D = get_icon_texture_for_ability(ab)
	var align_c: Color = get_alignment_color(alignment)
	var theme_c: Color = get_ability_theme_color(ab)
	var base_color: Color = align_c.lerp(theme_c, 0.48)
	if shape == ShapeType.HALF_CIRCLE:
		_draw_half_bubble(canvas, center, radius, base_color, tex)
	else:
		_draw_full_bubble(canvas, center, radius, base_color, tex)

static func _draw_full_bubble(canvas: CanvasItem, center: Vector2, r: float, base_color: Color, icon: Texture2D) -> void:
	canvas.draw_circle(center, r * 1.08, Color(base_color.r, base_color.g, base_color.b, 0.13))
	var slate: Color = Constants.monsters_also_die_color(Constants.MAD_IDX_SLATE)
	var cream: Color = Constants.monsters_also_die_color(Constants.MAD_IDX_CREAM)
	var glass: Color = slate.lerp(cream, 0.22)
	canvas.draw_circle(center, r * 0.99, Color(glass.r, glass.g, glass.b, 0.26))
	var indigo: Color = Constants.monsters_also_die_color(Constants.MAD_IDX_INDIGO)
	canvas.draw_circle(center + Vector2(0, r * 0.36), r * 0.55, Color(indigo.r, indigo.g, indigo.b, 0.1))
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
	var half_fill: Color = Constants.monsters_also_die_color(Constants.MAD_IDX_SLATE).lerp(
		Constants.monsters_also_die_color(Constants.MAD_IDX_CREAM), 0.35
	)
	canvas.draw_colored_polygon(pts, Color(half_fill.r, half_fill.g, half_fill.b, 0.3))
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
