class_name PegDrawing
extends RefCounted
## Static drawing helpers for Peg visuals. Called from peg._draw() to keep peg.gd under 500 lines.
## All methods accept the peg CanvasItem as the first argument for draw calls.

#region Trampoline
## Draws the trampoline peg (mat, net lines, rim, highlight).
static func draw_trampoline(peg: CanvasItem, r: float, luminance: float, vibrancy_scale: float, max_dur: int, dur: int, recovery: int, squash: float) -> void:
	var lum: float = luminance
	if recovery <= 0:
		var ratio: float = 1.0 if max_dur <= 0 else (float(dur) / float(max_dur))
		lum = lerpf(0.25, 1.0, ratio * vibrancy_scale)
	var rim_base: Color = Constants.monsters_also_die_color(Constants.MAD_IDX_SLATE).lerp(
		Constants.monsters_also_die_color(Constants.MAD_IDX_INDIGO), 0.45
	)
	var rim_color: Color = Constants.color_with_luminance(rim_base, lum)
	peg.draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 32, rim_color, 4.0)
	var mat_base: Color = Constants.monsters_also_die_color(Constants.MAD_IDX_TEAL).lerp(
		Constants.monsters_also_die_color(Constants.MAD_IDX_OLIVE), 0.5
	)
	var mat_color: Color = Constants.color_with_luminance(mat_base, lum)
	var mat_hi_base: Color = Constants.monsters_also_die_color(Constants.MAD_IDX_CREAM).lerp(
		Constants.monsters_also_die_color(Constants.MAD_IDX_TEAL), 0.55
	)
	var mat_highlight: Color = Color(mat_hi_base.r, mat_hi_base.g, mat_hi_base.b, 0.9 * lum)
	var pts: PackedVector2Array = []
	var segs: int = 24
	for i in range(segs + 1):
		var angle: float = (float(i) / float(segs)) * PI
		var px: float = cos(angle) * r
		var py: float = sin(angle) * r * squash
		pts.append(Vector2(px, py))
	peg.draw_colored_polygon(pts, mat_color)
	var line_color := Color(1.0, 1.0, 1.0, 0.5 * lum)
	for ly in [3.0, 6.0, 9.0]:
		var half_w: float = sqrt(maxf(0, r * r - (ly / squash) * (ly / squash))) if squash > 0 else 0.0
		peg.draw_line(Vector2(-half_w, ly), Vector2(half_w, ly), line_color)
	peg.draw_arc(Vector2.ZERO, r, 0.0, PI, 16, mat_highlight, 2.0)
#endregion

#region Bomb
## Draws the bomb peg (dark body, metallic rim, fuse).
static func draw_bomb(peg: CanvasItem, r: float, luminance: float) -> void:
	var body_color := Color(0.35, 0.12, 0.1, 1.0)
	body_color = Color(body_color.r * luminance, body_color.g * luminance, body_color.b * luminance, body_color.a)
	peg.draw_circle(Vector2.ZERO, r, body_color)
	var rim_color := Color(0.45, 0.4, 0.38, luminance)
	peg.draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, rim_color, 2.0)
	var fuse_y: float = -r - 2.0
	peg.draw_circle(Vector2(0, fuse_y), 3.0, Color(0.9, 0.5, 0.15, luminance))
	peg.draw_line(Vector2(0, fuse_y - 3.0), Vector2(0, fuse_y - 8.0), Color(0.6, 0.35, 0.1, luminance))
#endregion

#region Goblin Reset
## Draws the goblin reset peg (green body, arrow symbol).
static func draw_goblin_reset(peg: CanvasItem, r: float, luminance: float) -> void:
	var base_color := Color(0.35, 0.55, 0.25, 1.0)
	base_color = Color(base_color.r * luminance, base_color.g * luminance, base_color.b * luminance, base_color.a)
	peg.draw_circle(Vector2.ZERO, r, base_color)
	var rim_color := Color(0.2, 0.4, 0.15, luminance)
	peg.draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, rim_color, 2.0)
	var arrow_r: float = r * 0.55
	var arrow_color := Color(0.95, 0.85, 0.5, 0.95 * luminance)
	peg.draw_arc(Vector2.ZERO, arrow_r, -PI * 0.15, PI * 1.4, 16, arrow_color, 2.0)
	var tip_angle: float = PI * 1.4
	var tip: Vector2 = Vector2(cos(tip_angle), sin(tip_angle)) * arrow_r
	var perp: Vector2 = Vector2(-sin(tip_angle), cos(tip_angle)).normalized()
	peg.draw_line(tip, tip + perp * 4.0 + Vector2(cos(tip_angle), sin(tip_angle)) * -4.0, arrow_color, 2.0)
	peg.draw_line(tip, tip - perp * 4.0 + Vector2(cos(tip_angle), sin(tip_angle)) * -4.0, arrow_color, 2.0)
#endregion

#region Stash Gold Overlay
## Draws gold stash overlay (dispatches to one or five coin).
static func draw_stash_gold_overlay(peg: CanvasItem, amount: int) -> void:
	if amount >= 5:
		draw_stash_gold_overlay_five(peg)
	else:
		draw_stash_gold_overlay_one(peg)

## Draws single gold coin overlay.
static func draw_stash_gold_overlay_one(peg: CanvasItem) -> void:
	var p := Vector2(7.0, 7.0)
	var coin_r: float = 5.5
	peg.draw_circle(p, coin_r, Color(0.80, 0.50, 0.14, 1.0))
	peg.draw_arc(p, coin_r - 1.0, 0.0, TAU, 24, Color(0.48, 0.26, 0.06, 1.0), 1.2)
	peg.draw_line(p + Vector2(-2.0, -1.0), p + Vector2(1.0, 2.0), Color(0.92, 0.68, 0.32, 0.9), 1.0)

## Draws stacked 5-gold coin overlay with warm ring.
static func draw_stash_gold_overlay_five(peg: CanvasItem) -> void:
	var back := Vector2(4.5, 5.0)
	var front := Vector2(9.0, 8.5)
	var r_back: float = 5.0
	var r_front: float = 5.8
	var gold_deep := Color(0.72, 0.44, 0.12, 1.0)
	var gold_mid := Color(0.82, 0.54, 0.18, 1.0)
	var rim := Color(0.44, 0.22, 0.05, 1.0)
	var highlight := Color(0.92, 0.70, 0.35, 0.95)
	peg.draw_circle(back, r_back + 2.0, Color(0.80, 0.35, 0.08, 0.35))
	peg.draw_circle(front, r_front + 2.5, Color(0.82, 0.38, 0.08, 0.45))
	peg.draw_circle(back, r_back, gold_deep.darkened(0.08))
	peg.draw_arc(back, r_back - 0.5, 0.0, TAU, 20, rim, 1.5, true)
	peg.draw_circle(front, r_front, gold_mid)
	peg.draw_arc(front, r_front - 1.0, 0.0, TAU, 24, rim, 1.8, true)
	peg.draw_line(front + Vector2(-2.2, -1.0), front + Vector2(1.2, 2.2), highlight, 1.2)
	var bag_center: Vector2 = (back + front) * 0.5
	peg.draw_arc(bag_center, 12.0, 0.0, TAU, 40, Color(0.82, 0.35, 0.06, 0.55), 2.0, true)
#endregion

#region Ghost Trail and Hover
## Draws phantom ghost trail glow around the peg.
static func draw_ghost_trail_glow(peg: CanvasItem, r: float, phase: float) -> void:
	var pulse: float = 0.65 + 0.35 * sin(phase)
	peg.draw_circle(Vector2.ZERO, r, Color(0.3, 0.75, 0.9, 0.35 * pulse))
	peg.draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 32, Color(0.35, 0.85, 0.95, 0.7 * pulse), 3.5)
	peg.draw_arc(Vector2.ZERO, r + 8.0, 0.0, TAU, 32, Color(0.45, 0.9, 1.0, 0.35 * pulse), 2.5)
	var wisp_count: int = 4
	for i in wisp_count:
		var a: float = phase * 0.8 + float(i) * TAU / float(wisp_count)
		var wisp_r: float = r + 6.0 + 3.0 * sin(phase * 1.5 + float(i))
		var wisp_pos: Vector2 = Vector2(cos(a) * wisp_r, sin(a) * wisp_r)
		peg.draw_circle(wisp_pos, 2.5, Color(0.6, 0.95, 1.0, 0.5 * pulse))

## Draws hover highlight ring around the peg.
static func draw_hover_highlight(peg: CanvasItem, r: float, hover_kind: String) -> void:
	var time_sec: float = float(Time.get_ticks_msec()) / 1000.0
	var pulse: float = 0.6 + 0.4 * sin(time_sec * 5.0)
	var color: Color = _get_hover_color(hover_kind, pulse)
	peg.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, color, 3.0)
	peg.draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 32, Color(color.r, color.g, color.b, color.a * 0.35), 2.0)
	peg.draw_circle(Vector2.ZERO, Constants.PEG_RADIUS, Color(color.r, color.g, color.b, 0.12))

## Returns the hover color for a specified peg kind.
static func _get_hover_color(kind: String, pulse: float) -> Color:
	match kind:
		"bomb":
			return Color(1.0, 0.3, 0.1, pulse * 0.85)
		"trampoline":
			return Color(0.2, 0.9, 0.5, pulse * 0.85)
		"goblin_reset":
			return Color(0.5, 0.8, 0.3, pulse * 0.85)
		"eternal":
			return Color(0.7, 0.8, 1.0, pulse * 0.85)
		"extreme_bouncer":
			return Color(1.0, 0.6, 0.15, pulse * 0.85)
		"magnet":
			return Color(0.9, 0.25, 0.25, pulse * 0.85)
		"splitter":
			return Color(0.75, 0.4, 0.85, pulse * 0.85)
		"gold":
			return Color(1.0, 0.9, 0.3, pulse * 0.85)
		"lucky_gold":
			return Color(0.45, 0.95, 0.55, pulse * 0.85)
		"gravity_well":
			return Color(0.5, 0.3, 0.8, pulse * 0.85)
		"phase":
			return Color(0.4, 0.85, 0.9, pulse * 0.85)
		"wrench":
			return Color(0.85, 0.7, 0.3, pulse * 0.85)
		"sticky_preview":
			return Color(0.35, 0.95, 0.55, pulse * 0.88)
		_:
			return Color(1.0, 0.9, 0.4, pulse * 0.85)
#endregion
