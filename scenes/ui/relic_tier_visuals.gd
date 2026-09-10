class_name RelicTierVisuals
extends RefCounted
## Visual styling rules and rendering routines for polyomino relic tiers.
## Replaces text-based tier numbers with distinct graphic styling across the game.

const DARK_INK_BORDER: Color = Color(0.08, 0.05, 0.12, 1.0)

## Map tier (1..5+) to distinct theme accent colors.
static func get_tier_color(tier: int) -> Color:
	match tier:
		1:
			# Tier 1: Iron Slate (Common / Starter)
			return Color(0.70, 0.74, 0.80, 1.0)
		2:
			# Tier 2: Emerald Teal (Wall Break / Cross-Links)
			return Color(0.28, 0.78, 0.62, 1.0)
		3:
			# Tier 3: Royal Amethyst Purple (Boss Amplifiers)
			return Color(0.76, 0.45, 0.96, 1.0)
		_:
			# Tier 4+: Radiant Solar Gold (Overdrive / Legendary)
			return Color(1.0, 0.84, 0.28, 1.0)

## Returns the full styling dictionary for the requested relic tier.
static func get_tier_style(tier: int) -> Dictionary:
	var col: Color = get_tier_color(tier)
	match tier:
		1:
			return {
				"tier": 1,
				"name": "Standard",
				"accent_color": col,
				"highlight_color": col.lightened(0.2),
				"border_width": 1.5,
				"ink_border_width": 3.5,
				"corner_accent_type": &"none",
				"corner_accent_size": 0.0,
				"has_outer_glow": false,
				"glow_color": Color(0, 0, 0, 0),
				"bg_alpha": 0.15,
				"badge_shape": 0 # Square
			}
		2:
			return {
				"tier": 2,
				"name": "Reinforced",
				"accent_color": col,
				"highlight_color": col.lightened(0.25),
				"border_width": 2.0,
				"ink_border_width": 4.0,
				"corner_accent_type": &"bracket",
				"corner_accent_size": 5.0,
				"has_outer_glow": false,
				"glow_color": Color(col.r, col.g, col.b, 0.25),
				"bg_alpha": 0.20,
				"badge_shape": 1 # Diamond
			}
		3:
			return {
				"tier": 3,
				"name": "Masterwork",
				"accent_color": col,
				"highlight_color": col.lightened(0.3),
				"border_width": 2.5,
				"ink_border_width": 4.5,
				"corner_accent_type": &"diamond",
				"corner_accent_size": 4.0,
				"has_outer_glow": true,
				"glow_color": Color(col.r, col.g, col.b, 0.35),
				"bg_alpha": 0.24,
				"badge_shape": 2 # Triangle
			}
		_:
			return {
				"tier": tier,
				"name": "Exalted",
				"accent_color": col,
				"highlight_color": Color(1.0, 0.95, 0.6, 1.0),
				"border_width": 3.0,
				"ink_border_width": 5.0,
				"corner_accent_type": &"star",
				"corner_accent_size": 5.0,
				"has_outer_glow": true,
				"glow_color": Color(1.0, 0.85, 0.3, 0.45),
				"bg_alpha": 0.28,
				"badge_shape": 3 # Circle / Star
			}

## Renders background fill rects for polyomino cells with tier-aligned alpha.
static func draw_cell_backgrounds(
	canvas: CanvasItem,
	cells: Array[Vector2i],
	cell_size: Vector2,
	origin: Vector2,
	tier: int,
	being_dragged: bool = false,
	bg_override: Color = Color(0, 0, 0, 0)
) -> void:
	var style: Dictionary = get_tier_style(tier)
	var col: Color = style["accent_color"]
	var alpha: float = float(style["bg_alpha"]) * (0.35 if being_dragged else 1.0)
	var fill_color: Color = bg_override if bg_override.a > 0.0 else Color(col.r, col.g, col.b, alpha)

	for c in cells:
		var top_left := Vector2(origin.x + float(c.x) * cell_size.x, origin.y + float(c.y) * cell_size.y)
		canvas.draw_rect(Rect2(top_left, cell_size), fill_color)

## Renders perimeter wall edges and internal dividers with tier styling.
static func draw_tier_frame(
	canvas: CanvasItem,
	segments: Array,
	cell_size: Vector2,
	origin: Vector2,
	tier: int,
	being_dragged: bool = false,
	highlight_override: Color = Color(0, 0, 0, 0)
) -> void:
	var style: Dictionary = get_tier_style(tier)
	var ink_col: Color = DARK_INK_BORDER
	var highlight_col: Color = highlight_override if highlight_override.a > 0.0 else style["highlight_color"]
	var glow_col: Color = style["glow_color"]
	var has_glow: bool = bool(style["has_outer_glow"]) and not being_dragged

	var ink_w: float = float(style["ink_border_width"])
	var hi_w: float = float(style["border_width"])

	if being_dragged:
		var alpha_m: float = 0.35
		ink_col.a *= alpha_m
		highlight_col.a *= alpha_m
		glow_col.a *= alpha_m

	for seg in segments:
		var p1_local: Vector2 = seg["p1"]
		var p2_local: Vector2 = seg["p2"]
		var is_internal: bool = seg.get("is_internal", false)

		var p1: Vector2 = origin + Vector2(p1_local.x * cell_size.x, p1_local.y * cell_size.y)
		var p2: Vector2 = origin + Vector2(p2_local.x * cell_size.x, p2_local.y * cell_size.y)

		if is_internal:
			canvas.draw_line(p1, p2, ink_col, 3.0)
			canvas.draw_line(p1, p2, Color(0.3, 0.8, 1.0, 0.8 * (0.35 if being_dragged else 1.0)), 1.5)
		else:
			if has_glow:
				canvas.draw_line(p1, p2, glow_col, ink_w + 3.0)
			canvas.draw_line(p1, p2, ink_col, ink_w)
			canvas.draw_line(p1, p2, highlight_col, hi_w)

## Renders decorative corner accents at exterior corners of the module.
static func draw_tier_corner_accents(
	canvas: CanvasItem,
	cells: Array[Vector2i],
	cell_size: Vector2,
	origin: Vector2,
	tier: int,
	being_dragged: bool = false
) -> void:
	if cells.is_empty() or tier <= 1:
		return

	var style: Dictionary = get_tier_style(tier)
	var accent_type: StringName = style["corner_accent_type"]
	if accent_type == &"none":
		return

	var accent_col: Color = style["highlight_color"]
	if being_dragged:
		accent_col.a *= 0.35

	var sz: float = float(style["corner_accent_size"])
	var cell_set: Dictionary = {}
	for c in cells:
		cell_set[c] = true

	# Detect exterior convex corners
	for c in cells:
		var px: float = origin.x + float(c.x) * cell_size.x
		var py: float = origin.y + float(c.y) * cell_size.y

		# Top-Left corner: no neighbor on North or West
		if not cell_set.has(Vector2i(c.x, c.y - 1)) and not cell_set.has(Vector2i(c.x - 1, c.y)):
			_draw_corner_pip(canvas, Vector2(px, py), accent_type, sz, accent_col, 0)

		# Top-Right corner: no neighbor on North or East
		if not cell_set.has(Vector2i(c.x, c.y - 1)) and not cell_set.has(Vector2i(c.x + 1, c.y)):
			_draw_corner_pip(canvas, Vector2(px + cell_size.x, py), accent_type, sz, accent_col, 1)

		# Bottom-Left corner: no neighbor on South or West
		if not cell_set.has(Vector2i(c.x, c.y + 1)) and not cell_set.has(Vector2i(c.x - 1, c.y)):
			_draw_corner_pip(canvas, Vector2(px, py + cell_size.y), accent_type, sz, accent_col, 2)

		# Bottom-Right corner: no neighbor on South or East
		if not cell_set.has(Vector2i(c.x, c.y + 1)) and not cell_set.has(Vector2i(c.x + 1, c.y)):
			_draw_corner_pip(canvas, Vector2(px + cell_size.x, py + cell_size.y), accent_type, sz, accent_col, 3)

static func _draw_corner_pip(canvas: CanvasItem, pos: Vector2, kind: StringName, sz: float, col: Color, corner_idx: int) -> void:
	match kind:
		&"bracket":
			# L-shaped corner bracket
			var dir_x: float = 1.0 if (corner_idx == 0 or corner_idx == 2) else -1.0
			var dir_y: float = 1.0 if (corner_idx == 0 or corner_idx == 1) else -1.0
			canvas.draw_line(pos, pos + Vector2(dir_x * sz, 0), col, 2.0)
			canvas.draw_line(pos, pos + Vector2(0, dir_y * sz), col, 2.0)
		&"diamond":
			# Diamond pip
			var pts := PackedVector2Array([
				pos + Vector2(0, -sz),
				pos + Vector2(sz, 0),
				pos + Vector2(0, sz),
				pos + Vector2(-sz, 0)
			])
			canvas.draw_colored_polygon(pts, col)
		&"star":
			# 4-point radiant star pip
			var pts := PackedVector2Array([
				pos + Vector2(0, -sz * 1.3),
				pos + Vector2(sz * 0.4, -sz * 0.4),
				pos + Vector2(sz * 1.3, 0),
				pos + Vector2(sz * 0.4, sz * 0.4),
				pos + Vector2(0, sz * 1.3),
				pos + Vector2(-sz * 0.4, sz * 0.4),
				pos + Vector2(-sz * 1.3, 0),
				pos + Vector2(-sz * 0.4, -sz * 0.4)
			])
			canvas.draw_colored_polygon(pts, col)
