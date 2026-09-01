class_name PegKindDrawing
extends RefCounted
## Static drawing helpers for special peg kinds. All methods accept a CanvasItem for draw calls.
## Keeps peg.gd under 500 lines by extracting per-kind draw routines.

#region Helpers
## Computes peg luminance from durability ratio and vibrancy scale.
static func compute_luminance(recovery: int, max_dur: int, dur: int, vibrancy: float, dim: float = 0.25) -> float:
	if recovery > 0:
		return 0.15
	var ratio: float = 1.0 if max_dur <= 0 else (float(dur) / float(max_dur))
	return lerpf(dim, 1.0, ratio * vibrancy)

## Applies luminance to a base color (multiplies RGB channels).
static func color_with_lum(c: Color, lum: float) -> Color:
	return Color(c.r * lum, c.g * lum, c.b * lum, c.a)
#endregion

#region Eternal Peg
## Draws the eternal peg (silver body, infinity loops, blue rim).
static func draw_eternal(ci: CanvasItem, r: float, lum: float) -> void:
	var base_color := color_with_lum(Color(0.85, 0.85, 0.95, 1.0), lum)
	ci.draw_circle(Vector2.ZERO, r, base_color)
	ci.draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, Color(0.6, 0.7, 1.0, lum), 2.5)
	var inf_color := Color(0.4, 0.5, 1.0, 0.9 * lum)
	var inf_r: float = r * 0.35
	ci.draw_arc(Vector2(-inf_r * 0.5, 0), inf_r, 0.0, TAU, 12, inf_color, 2.0)
	ci.draw_arc(Vector2(inf_r * 0.5, 0), inf_r, 0.0, TAU, 12, inf_color, 2.0)
#endregion

#region Extreme Bouncer
## Draws the extreme bouncer peg (orange body, 4 outward arrows).
static func draw_extreme_bouncer(ci: CanvasItem, r: float, lum: float) -> void:
	var body := color_with_lum(Color(1.0, 0.55, 0.1, 1.0), lum)
	ci.draw_circle(Vector2.ZERO, r, body)
	ci.draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 24, Color(1.0, 0.8, 0.3, lum), 3.0)
	var arrow_c := Color(1.0, 1.0, 0.7, 0.9 * lum)
	for i in range(4):
		var angle: float = float(i) * TAU / 4.0 + TAU / 8.0
		var dir := Vector2(cos(angle), sin(angle))
		var base_pt := dir * (r * 0.2)
		var tip := dir * (r * 0.75)
		ci.draw_line(base_pt, tip, arrow_c, 2.0)
		var wing_l := tip - dir * 4.0 + Vector2(-dir.y, dir.x) * 3.0
		var wing_r := tip - dir * 4.0 - Vector2(-dir.y, dir.x) * 3.0
		ci.draw_colored_polygon(PackedVector2Array([tip, wing_l, wing_r]), arrow_c)
#endregion

#region Magnet
## Draws the magnet peg (red body, horseshoe U-shape, silver caps).
static func draw_magnet(ci: CanvasItem, r: float, lum: float) -> void:
	var body := color_with_lum(Color(0.55, 0.15, 0.15, 1.0), lum)
	ci.draw_circle(Vector2.ZERO, r, body)
	ci.draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, Color(0.7, 0.3, 0.3, lum), 2.0)
	var u_c := Color(0.9, 0.2, 0.2, 0.9 * lum)
	ci.draw_arc(Vector2.ZERO, r * 0.55, PI, TAU, 12, u_c, 2.5)
	ci.draw_line(Vector2(-r * 0.55, 0), Vector2(-r * 0.55, -r * 0.4), u_c, 2.5)
	ci.draw_line(Vector2(r * 0.55, 0), Vector2(r * 0.55, -r * 0.4), u_c, 2.5)
	var cap := Color(0.8, 0.8, 0.85, lum)
	ci.draw_circle(Vector2(-r * 0.55, -r * 0.4), 2.5, cap)
	ci.draw_circle(Vector2(r * 0.55, -r * 0.4), 2.5, cap)
#endregion

#region Splitter
## Draws the splitter peg (purple body, forking Y-shape).
static func draw_splitter(ci: CanvasItem, r: float, lum: float) -> void:
	var body := color_with_lum(Color(0.6, 0.25, 0.65, 1.0), lum)
	ci.draw_circle(Vector2.ZERO, r, body)
	ci.draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, Color(0.75, 0.45, 0.8, lum), 2.0)
	var sc := Color(1.0, 0.85, 1.0, 0.9 * lum)
	ci.draw_line(Vector2(0, -r * 0.6), Vector2(0, 0), sc, 2.0)
	ci.draw_line(Vector2(0, 0), Vector2(-r * 0.5, r * 0.5), sc, 2.0)
	ci.draw_line(Vector2(0, 0), Vector2(r * 0.5, r * 0.5), sc, 2.0)
	ci.draw_circle(Vector2(-r * 0.5, r * 0.5), 2.5, sc)
	ci.draw_circle(Vector2(r * 0.5, r * 0.5), 2.5, sc)
#endregion

#region Gold
## Draws the gold peg (amber body, rim, inner circle, sparkle).
static func draw_gold(ci: CanvasItem, r: float, lum: float) -> void:
	var body := color_with_lum(Color(0.78, 0.48, 0.14, 1.0), lum)
	ci.draw_circle(Vector2.ZERO, r, body)
	ci.draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 24, Color(0.86, 0.56, 0.18, lum), 3.0)
	ci.draw_circle(Vector2.ZERO, r * 0.5, Color(0.82, 0.58, 0.22, 0.75 * lum))
	ci.draw_circle(Vector2(-r * 0.25, -r * 0.25), 1.5, Color(0.95, 0.76, 0.40, 0.85 * lum))

## Draws the lucky gold peg (gold peg + green luck ring).
static func draw_lucky_gold(ci: CanvasItem, r: float, lum: float) -> void:
	draw_gold(ci, r, lum)
	ci.draw_arc(Vector2.ZERO, r + 5.0, 0.0, TAU, 28, Color(0.2, 0.85, 0.55, 0.9 * lum), 2.0)
#endregion

#region Gravity Well
## Draws the gravity well vortex field around the peg.
static func draw_gravity_well_vortex(ci: CanvasItem, lum: float, vortex_phase: float) -> void:
	var gw_r: float = Constants.GRAVITY_WELL_RADIUS_PX
	var pulse: float = (0.82 + 0.18 * sin(vortex_phase * 1.15)) * lum
	ci.draw_circle(Vector2.ZERO, gw_r, Color(0.42, 0.08, 0.72, 0.14 * pulse))
	ci.draw_arc(Vector2.ZERO, gw_r - 1.5, 0.0, TAU, 64, Color(0.55, 0.2, 0.92, 0.42 * pulse), 2.5)
	ci.draw_arc(Vector2.ZERO, gw_r * 0.65, 0.0, TAU, 48, Color(0.65, 0.3, 1.0, 0.12 * pulse), 1.5)
	var arms: int = 6
	var inner_r: float = Constants.PEG_RADIUS + 10.0
	var outer_r: float = gw_r - 5.0
	for i in arms:
		var base_cw: float = vortex_phase * 1.25 + float(i) * TAU / float(arms)
		var pts: PackedVector2Array = PackedVector2Array()
		var steps: int = 28
		for s in steps + 1:
			var u: float = float(s) / float(steps)
			var rad: float = lerpf(inner_r, outer_r, u)
			var ang: float = base_cw + u * TAU * 2.2
			pts.append(Vector2(cos(ang) * rad, sin(ang) * rad))
		ci.draw_polyline(pts, Color(0.72, 0.38, 1.0, 0.55 * pulse), 3.0)
	for j in arms:
		var base_ccw: float = -vortex_phase * 0.95 + float(j) * TAU / float(arms) + TAU / 12.0
		var pts2: PackedVector2Array = PackedVector2Array()
		for s2 in 18 + 1:
			var u2: float = float(s2) / 18.0
			var rad2: float = lerpf(inner_r + 8.0, outer_r - 4.0, u2)
			var ang2: float = base_ccw - u2 * TAU * 1.6
			pts2.append(Vector2(cos(ang2) * rad2, sin(ang2) * rad2))
		ci.draw_polyline(pts2, Color(0.5, 0.2, 0.85, 0.28 * pulse), 2.0)

## Draws the gravity well peg body (dark core with inner rings).
static func draw_gravity_well(ci: CanvasItem, r: float, lum: float, vortex_phase: float) -> void:
	draw_gravity_well_vortex(ci, lum, vortex_phase)
	var body := color_with_lum(Color(0.15, 0.1, 0.35, 1.0), lum)
	ci.draw_circle(Vector2.ZERO, r, body)
	ci.draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, Color(0.4, 0.25, 0.7, lum), 2.0)
	var ring_a: float = 0.5 * lum
	ci.draw_arc(Vector2.ZERO, r * 0.7, 0.0, TAU, 16, Color(0.5, 0.3, 0.8, ring_a), 1.5)
	ci.draw_arc(Vector2.ZERO, r * 0.4, 0.0, TAU, 12, Color(0.6, 0.4, 0.9, ring_a * 0.8), 1.5)
	ci.draw_circle(Vector2.ZERO, 2.5, Color(0.8, 0.6, 1.0, lum))
#endregion

#region Phase
## Draws the phase peg (teal body, dashed ring when intangible).
static func draw_phase(ci: CanvasItem, r: float, lum: float, solid: bool) -> void:
	var alpha: float = 1.0 if solid else 0.3
	var body := color_with_lum(Color(0.3, 0.8, 0.85, alpha), lum)
	ci.draw_circle(Vector2.ZERO, r, body)
	ci.draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, Color(0.5, 0.9, 0.95, alpha * lum), 2.0)
	if not solid:
		var dash_c := Color(0.5, 0.9, 0.95, 0.4 * lum)
		for i in range(8):
			var a1: float = float(i) * TAU / 8.0
			var a2: float = a1 + TAU / 16.0
			ci.draw_arc(Vector2.ZERO, r * 0.6, a1, a2, 4, dash_c, 1.5)
#endregion

#region Wrench
## Draws the wrench peg (gray body, wrench symbol).
static func draw_wrench(ci: CanvasItem, r: float, lum: float) -> void:
	var body := color_with_lum(Color(0.45, 0.42, 0.38, 1.0), lum)
	ci.draw_circle(Vector2.ZERO, r, body)
	ci.draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, Color(0.6, 0.55, 0.45, lum), 2.0)
	var wc := Color(0.85, 0.7, 0.3, 0.95 * lum)
	ci.draw_line(Vector2(0, -r * 0.6), Vector2(0, r * 0.5), wc, 2.5)
	ci.draw_line(Vector2(-r * 0.35, -r * 0.6), Vector2(r * 0.35, -r * 0.6), wc, 2.5)
	ci.draw_line(Vector2(-r * 0.35, -r * 0.6), Vector2(-r * 0.35, -r * 0.3), wc, 2.0)
	ci.draw_line(Vector2(r * 0.35, -r * 0.6), Vector2(r * 0.35, -r * 0.3), wc, 2.0)
	ci.draw_circle(Vector2(0, r * 0.5), 3.0, wc)
#endregion

#region Event Pegs
## Draws the treasure chest peg.
static func draw_treasure_chest(ci: CanvasItem, r: float, max_dur: int, dur: int, urgency: float) -> void:
	var ratio: float = 1.0 if max_dur <= 0 else (float(dur) / float(max_dur))
	var t: float = float(Time.get_ticks_msec()) * 0.006
	var pulse: float = 0.78 + 0.22 * sin(t * 2.0)
	var alpha: float = clampf(0.45 + 0.55 * urgency, 0.35, 1.0) * pulse
	var wood := Color(0.38, 0.24, 0.12, alpha)
	var trim := Color(0.9, 0.72, 0.2, alpha)
	var glow := Color(0.95, 0.55, 0.15, 0.28 * alpha * ratio)
	ci.draw_circle(Vector2.ZERO, r + 5.0, glow)
	var bw: float = r * 1.35
	var bh: float = r * 1.25
	ci.draw_rect(Rect2(-bw * 0.5, -bh * 0.5, bw, bh * 0.52), wood)
	ci.draw_rect(Rect2(-bw * 0.5, bh * 0.02, bw, bh * 0.48), wood.darkened(0.1))
	ci.draw_line(Vector2(-bw * 0.5, bh * 0.02), Vector2(bw * 0.5, bh * 0.02), trim, 2.5)
	ci.draw_arc(Vector2(0, -bh * 0.5), bw * 0.48, PI, TAU, 18, trim, 2.5, true)
	ci.draw_circle(Vector2(0, 0), 4.5, trim.lightened(0.05))
	ci.draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 28, Color(trim.r, trim.g, trim.b, alpha * 0.85), 2.0)

## Draws the buffet table peg.
static func draw_buffet_table(ci: CanvasItem, r: float, urgency: float) -> void:
	var t: float = float(Time.get_ticks_msec()) * 0.0065
	var pulse: float = 0.78 + 0.22 * sin(t * 2.0)
	var alpha: float = clampf(0.4 + 0.6 * urgency, 0.35, 1.0) * pulse
	var cloth := Color(0.78, 0.62, 0.42, alpha)
	var trim := Color(0.55, 0.38, 0.22, alpha)
	var plate := Color(0.96, 0.94, 0.9, alpha)
	var steam := Color(0.88, 0.92, 0.95, 0.22 * alpha)
	ci.draw_circle(Vector2.ZERO, r + 4.0, steam)
	var tw: float = r * 2.45
	var th: float = r * 0.95
	ci.draw_rect(Rect2(-tw * 0.5, -th * 0.5, tw, th * 0.55), cloth)
	ci.draw_rect(Rect2(-tw * 0.5, th * 0.02, tw, th * 0.48), cloth.darkened(0.08))
	ci.draw_line(Vector2(-tw * 0.5, th * 0.02), Vector2(tw * 0.5, th * 0.02), trim, 2.0)
	for px in [-r * 0.65, r * 0.65]:
		ci.draw_circle(Vector2(px, -r * 0.15), r * 0.42, plate)
		ci.draw_arc(Vector2(px, -r * 0.15), r * 0.42, 0.0, TAU, 20, trim.darkened(0.1), 1.5)
	ci.draw_arc(Vector2(0, -r * 0.35), r * 0.5, PI * 1.05, TAU * 0.95, 14, Color(0.7, 0.75, 0.78, 0.55 * alpha), 2.0)
	ci.draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 28, Color(trim.r, trim.g, trim.b, alpha * 0.85), 2.0)

## Draws the sticky slime overlay peg.
static func draw_sticky_slime(ci: CanvasItem, r: float, urgency: float, phase: float) -> void:
	var pulse: float = 0.72 + 0.28 * sin(phase)
	var alpha: float = clampf(0.42 + 0.58 * urgency, 0.35, 1.0) * pulse
	var slime := Color(0.25, 0.72, 0.38, alpha)
	var slime_dark := Color(0.12, 0.45, 0.22, alpha * 0.92)
	var drip := Color(0.35, 0.85, 0.5, 0.55 * alpha)
	ci.draw_circle(Vector2.ZERO, r + 3.5, slime_dark)
	ci.draw_circle(Vector2.ZERO, r + 1.0, slime)
	for i in range(5):
		var ang: float = phase * 0.8 + float(i) * TAU / 5.0
		var drip_len: float = 4.0 + 3.0 * sin(phase + float(i))
		var outer: Vector2 = Vector2(cos(ang), sin(ang)) * (r + 1.5)
		ci.draw_line(outer, outer + Vector2(0, drip_len), drip, 2.2)
	ci.draw_arc(Vector2.ZERO, r + 2.5, 0.0, TAU, 28, Color(0.5, 1.0, 0.65, alpha * 0.35), 2.0)

## Draws the milestone event peg (gold bag).
static func draw_milestone_event(ci: CanvasItem, r: float, urgency: float) -> void:
	var t: float = float(Time.get_ticks_msec()) * 0.008
	var pulse: float = 0.75 + 0.25 * sin(t * 3.0)
	var alpha: float = clampf(0.35 + 0.65 * urgency, 0.15, 1.0) * pulse
	var gold := Color(0.95, 0.82, 0.25, alpha)
	var rim := Color(0.55, 0.4, 0.1, alpha)
	ci.draw_circle(Vector2.ZERO, r + 3.0, Color(0.45, 0.25, 0.95, 0.35 * alpha))
	ci.draw_circle(Vector2.ZERO, r, gold)
	ci.draw_arc(Vector2.ZERO, r + 1.0, 0.0, TAU, 32, rim, 2.5)
	var bw: float = r * 1.1
	var bh: float = r * 1.15
	ci.draw_rect(Rect2(-bw * 0.45, -bh * 0.35, bw * 0.9, bh * 0.7), Color(0.35, 0.28, 0.08, alpha * 0.9))
	ci.draw_arc(Vector2(0, -bh * 0.35), bw * 0.45, PI, TAU, 14, gold.darkened(0.15), 2.0, true)
#endregion

#region Leech and Energize
## Draws leech siphon cone on top of the peg.
static func draw_leech_cone(ci: CanvasItem, r: float) -> void:
	var phase: float = float(Time.get_ticks_msec()) * 0.001 * 4.0
	var tip_y: float = -r - 12.0
	var base_half: float = 6.0 + 2.0 * sin(phase)
	var base_y: float = -r + 2.0
	var pulse: float = 0.75 + 0.25 * sin(phase * 2.0)
	var cone_c := Color(0.72, 0.45, 0.95, 0.85 * pulse)
	var cone_d := Color(0.5, 0.28, 0.75, 0.6 * pulse)
	var tip := Vector2(0, tip_y)
	var bl := Vector2(-base_half, base_y)
	var br := Vector2(base_half, base_y)
	ci.draw_colored_polygon(PackedVector2Array([tip, bl, br]), cone_c)
	ci.draw_polyline(PackedVector2Array([tip, bl, br, tip]), cone_d, 1.5)
#endregion
