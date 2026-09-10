@tool
extends RefCounted
class_name PolyominoMachineryVisuals
## Renders authentic pinball kinetic machinery components on CanvasItem nodes.
## Matches the physical artwork styling used on the live board.

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const CellType = PolyominoModuleData.CellType
const DARK_INK_BORDER: Color = Color(0.08, 0.05, 0.12, 1.0)

static func draw_component(canvas: CanvasItem, type: int, center: Vector2, dir: Vector2, radius: float, accent_color: Color, footprint_count: int = 1, alpha_mult: float = 1.0) -> void:
	if type == CellType.EMPTY or canvas == null:
		return

	var r: float = radius
	var col := Color(accent_color.r, accent_color.g, accent_color.b, accent_color.a * alpha_mult)
	var ink := Color(DARK_INK_BORDER.r, DARK_INK_BORDER.g, DARK_INK_BORDER.b, alpha_mult)

	match type:
		CellType.POP_BUMPER:
			_draw_pop_bumper(canvas, center, r, col, ink, alpha_mult)
		CellType.BUMPER:
			_draw_pinball_bumper(canvas, center, r, col, ink, alpha_mult)
		CellType.ACCELERATOR, CellType.ROTARY_BOOSTER:
			_draw_speed_boost_wheel(canvas, center, dir, r, col, ink, alpha_mult)
		CellType.DROP_TARGET:
			_draw_drop_target(canvas, center, r, col, ink, alpha_mult)
		CellType.SPINNER:
			_draw_spinner(canvas, center, r, col, ink, alpha_mult)
		CellType.ROLLOVER_SWITCH:
			_draw_rollover_switch(canvas, center, r, col, alpha_mult)
		CellType.DIRECTIONAL_DEFLECTOR, CellType.FUNNEL:
			_draw_directional_deflector(canvas, center, dir, r, col, ink, alpha_mult)
		CellType.SLINGSHOT:
			_draw_slingshot(canvas, center, dir, r, col, ink, alpha_mult)
		CellType.BASH_TOY:
			_draw_bash_toy(canvas, center, r, col, ink, footprint_count, alpha_mult)
		CellType.SCOOP_SINKHOLE:
			_draw_scoop_sinkhole(canvas, center, r, col, ink, alpha_mult)
		CellType.BALL_LOCK:
			_draw_ball_lock(canvas, center, dir, r, col, ink, alpha_mult)
		CellType.GUIDE_TRACK, CellType.GUIDE_RAIL:
			_draw_guide_track(canvas, center, dir, r, col, ink, alpha_mult)
		CellType.ORBIT_LOOP:
			_draw_orbit_loop(canvas, center, dir, r, col, ink, alpha_mult)
		CellType.CAPTIVE_BALL:
			_draw_captive_ball(canvas, center, dir, r, col, ink, alpha_mult)
		CellType.MECHANICAL_DIVERTER:
			_draw_diverter(canvas, center, dir, r, col, ink, alpha_mult)
		CellType.VERTICAL_UP_KICKER:
			_draw_vuk(canvas, center, dir, r, col, ink, alpha_mult)
		_:
			canvas.draw_circle(center, r * 0.5, ink)
			canvas.draw_circle(center, r * 0.35, col)

static func _draw_pop_bumper(canvas: CanvasItem, center: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	# Skirt ring
	canvas.draw_circle(center, r, ink)
	canvas.draw_circle(center, r - 1.5, col.darkened(0.5))
	canvas.draw_arc(center, r, 0, TAU, 28, col, 2.0)
	# Wafer ring
	canvas.draw_circle(center, r * 0.7, Color(0.9, 0.9, 0.95, a))
	canvas.draw_arc(center, r * 0.7, 0, TAU, 24, col.lightened(0.3), 1.5)
	# Central dome cap
	canvas.draw_circle(center, r * 0.45, col)
	canvas.draw_circle(center, r * 0.2, Color(1.0, 1.0, 1.0, a))

static func _draw_pinball_bumper(canvas: CanvasItem, center: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	canvas.draw_circle(center, r, ink)
	canvas.draw_circle(center, r - 1.5, col.darkened(0.6))
	canvas.draw_arc(center, r, 0, TAU, 24, col.lightened(0.2), 2.5)
	canvas.draw_circle(center, r * 0.65, col)
	canvas.draw_circle(center, r * 0.3, Color(1.0, 1.0, 1.0, a))

static func _draw_speed_boost_wheel(canvas: CanvasItem, center: Vector2, dir: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	canvas.draw_circle(center, r, ink)
	canvas.draw_circle(center, r - 1.5, col.darkened(0.7))
	canvas.draw_arc(center, r, 0, TAU, 24, col, 2.0)
	for i in range(4):
		var ang: float = float(i) * (TAU * 0.25)
		var p: Vector2 = center + Vector2.from_angle(ang) * (r * 0.55)
		canvas.draw_circle(p, r * 0.18, col.lightened(0.3))
	var dir_norm: Vector2 = dir.normalized() if dir != Vector2.ZERO else Vector2.DOWN
	var tip: Vector2 = center + dir_norm * (r * 0.6)
	var perp := Vector2(-dir_norm.y, dir_norm.x) * (r * 0.35)
	canvas.draw_line(center - dir_norm * (r * 0.2) + perp, tip, Color(1.0, 1.0, 1.0, a), 2.2)
	canvas.draw_line(center - dir_norm * (r * 0.2) - perp, tip, Color(1.0, 1.0, 1.0, a), 2.2)

static func _draw_drop_target(canvas: CanvasItem, center: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	var rect := Rect2(center.x - r * 0.75, center.y - r * 0.75, r * 1.5, r * 1.5)
	canvas.draw_rect(rect, ink)
	canvas.draw_rect(rect.grow(-1.5), col)
	canvas.draw_rect(rect.grow(-3.5), Color(0.92, 0.92, 0.92, a))
	canvas.draw_rect(Rect2(center.x - r * 0.25, center.y - r * 0.25, r * 0.5, r * 0.5), col.darkened(0.2))

static func _draw_spinner(canvas: CanvasItem, center: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	canvas.draw_line(center + Vector2(-r, -r * 0.45), center + Vector2(-r, r * 0.45), ink, 3.5)
	canvas.draw_line(center + Vector2(r, -r * 0.45), center + Vector2(r, r * 0.45), ink, 3.5)
	canvas.draw_line(center + Vector2(-r, -r * 0.45), center + Vector2(-r, r * 0.45), Color(0.65, 0.65, 0.65, a), 2.0)
	canvas.draw_line(center + Vector2(r, -r * 0.45), center + Vector2(r, r * 0.45), Color(0.65, 0.65, 0.65, a), 2.0)
	canvas.draw_line(center + Vector2(-r, 0), center + Vector2(r, 0), Color(0.4, 0.4, 0.4, a), 1.8)
	var blade_rect := Rect2(center.x - r * 0.65, center.y - r * 0.35, r * 1.3, r * 0.7)
	canvas.draw_rect(blade_rect, ink)
	canvas.draw_rect(blade_rect.grow(-1.5), col)
	canvas.draw_rect(blade_rect.grow(-1.5), Color(1.0, 1.0, 1.0, 0.7 * a), false, 1.0)

static func _draw_rollover_switch(canvas: CanvasItem, center: Vector2, r: float, col: Color, a: float) -> void:
	canvas.draw_circle(center, r, Color(0.22, 0.22, 0.3, a))
	canvas.draw_arc(center, r, 0, TAU, 24, col, 2.0)
	canvas.draw_circle(center, r * 0.6, Color(1.0, 0.85, 0.2, a))
	canvas.draw_circle(center, r * 0.22, Color(1.0, 1.0, 1.0, a))

static func _draw_directional_deflector(canvas: CanvasItem, center: Vector2, dir: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	canvas.draw_circle(center, r, ink)
	canvas.draw_circle(center, r - 1.5, col.darkened(0.6))
	canvas.draw_arc(center, r, 0, TAU, 24, col, 2.0)
	var dir_norm: Vector2 = dir.normalized() if dir != Vector2.ZERO else Vector2(1, 1).normalized()
	var perp := Vector2(-dir_norm.y, dir_norm.x)
	var p1_l: Vector2 = center - dir_norm * (r * 0.7) + perp * (r * 0.6)
	var p2_l: Vector2 = center + dir_norm * (r * 0.5) + perp * (r * 0.2)
	var p1_r: Vector2 = center - dir_norm * (r * 0.7) - perp * (r * 0.6)
	var p2_r: Vector2 = center + dir_norm * (r * 0.5) - perp * (r * 0.2)
	canvas.draw_line(p1_l, p2_l, ink, 4.0)
	canvas.draw_line(p1_l, p2_l, Color(1.0, 1.0, 1.0, a), 2.5)
	canvas.draw_line(p1_r, p2_r, ink, 4.0)
	canvas.draw_line(p1_r, p2_r, Color(1.0, 1.0, 1.0, a), 2.5)
	canvas.draw_line(center, center + dir_norm * (r * 0.75), col.lightened(0.4), 2.5)

static func _draw_slingshot(canvas: CanvasItem, center: Vector2, dir: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	var dir_norm: Vector2 = dir.normalized() if dir != Vector2.ZERO else Vector2(1, 1).normalized()
	var perp := Vector2(-dir_norm.y, dir_norm.x)
	var p1: Vector2 = center - perp * (r * 0.55) - dir_norm * (r * 0.2)
	var p2: Vector2 = center + perp * (r * 0.55) - dir_norm * (r * 0.2)
	canvas.draw_circle(p1, 4.5, ink)
	canvas.draw_circle(p1, 3.5, Color(0.85, 0.85, 0.9, a))
	canvas.draw_circle(p2, 4.5, ink)
	canvas.draw_circle(p2, 3.5, Color(0.85, 0.85, 0.9, a))
	canvas.draw_line(p1, p2, ink, 4.5)
	canvas.draw_line(p1, p2, Color(1.0, 1.0, 1.0, a), 2.5)
	canvas.draw_line(center, center + dir_norm * (r * 0.6), col.lightened(0.3), 2.2)

static func _draw_bash_toy(canvas: CanvasItem, center: Vector2, r: float, col: Color, ink: Color, footprint_count: int, a: float) -> void:
	canvas.draw_circle(center, r, ink)
	canvas.draw_circle(center, r - 1.5, col.darkened(0.5))
	canvas.draw_arc(center, r, 0, TAU, 32, col, 2.5)
	var pips: int = 8 if footprint_count >= 4 else 5
	for i in range(pips):
		var ang: float = (float(i) / float(pips)) * TAU - PI * 0.5
		var pip_pos: Vector2 = center + Vector2(cos(ang), sin(ang)) * (r * 0.75)
		canvas.draw_circle(pip_pos, maxf(2.5, r * 0.08), Color(0.2, 0.85, 0.35, a))
	canvas.draw_circle(center, r * 0.35, col)
	canvas.draw_circle(center, r * 0.18, Color(1.0, 1.0, 1.0, a))

static func _draw_scoop_sinkhole(canvas: CanvasItem, center: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	canvas.draw_circle(center, r, ink)
	canvas.draw_circle(center, r - 1.5, col.darkened(0.4))
	canvas.draw_arc(center, r, 0, TAU, 24, col, 2.0)
	canvas.draw_circle(center, r * 0.75, Color(0.0, 0.0, 0.0, 0.8 * a))
	canvas.draw_arc(center, r * 0.75, 0, TAU, 20, col.lightened(0.2), 1.5)

static func _draw_ball_lock(canvas: CanvasItem, center: Vector2, dir: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	canvas.draw_circle(center, r, ink)
	canvas.draw_circle(center, r - 1.5, col.darkened(0.4))
	canvas.draw_arc(center, r, 0, TAU, 24, col, 2.0)
	var dir_norm: Vector2 = dir.normalized() if dir != Vector2.ZERO else Vector2.UP
	var start_p: Vector2 = center - dir_norm * (r * 0.7)
	var end_p: Vector2 = start_p + dir_norm * (r * 1.4)
	canvas.draw_line(start_p, end_p, ink, maxf(5.0, r * 0.35))
	canvas.draw_line(start_p, end_p, col.darkened(0.6), maxf(3.0, r * 0.22))
	canvas.draw_circle(center, r * 0.3, Color(0.85, 0.85, 0.9, a))

static func _draw_guide_track(canvas: CanvasItem, center: Vector2, dir: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	canvas.draw_circle(center, r, ink)
	canvas.draw_circle(center, r - 1.5, col.darkened(0.4))
	canvas.draw_arc(center, r, 0, TAU, 24, col, 2.0)
	var dir_norm: Vector2 = dir.normalized() if dir != Vector2.ZERO else Vector2.UP
	var perp := Vector2(-dir_norm.y, dir_norm.x)
	var r1_start: Vector2 = center + perp * (r * 0.35) - dir_norm * (r * 0.7)
	var r1_end: Vector2 = center + perp * (r * 0.35) + dir_norm * (r * 0.7)
	var r2_start: Vector2 = center - perp * (r * 0.35) - dir_norm * (r * 0.7)
	var r2_end: Vector2 = center - perp * (r * 0.35) + dir_norm * (r * 0.7)
	canvas.draw_line(r1_start, r1_end, ink, 3.5)
	canvas.draw_line(r1_start, r1_end, Color(0.8, 0.8, 0.85, a), 2.0)
	canvas.draw_line(r2_start, r2_end, ink, 3.5)
	canvas.draw_line(r2_start, r2_end, Color(0.8, 0.8, 0.85, a), 2.0)

static func _draw_orbit_loop(canvas: CanvasItem, center: Vector2, dir: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	var dir_norm: Vector2 = dir.normalized() if dir != Vector2.ZERO else Vector2.UP
	var angle: float = dir_norm.angle()
	canvas.draw_arc(center, r, angle - PI * 0.4, angle + PI * 0.4, 16, ink, 3.5)
	canvas.draw_arc(center, r, angle - PI * 0.4, angle + PI * 0.4, 16, Color(0.7, 0.7, 0.75, a), 2.0)
	canvas.draw_arc(center, r * 0.65, angle - PI * 0.4, angle + PI * 0.4, 16, ink, 3.0)
	canvas.draw_arc(center, r * 0.65, angle - PI * 0.4, angle + PI * 0.4, 16, Color(0.5, 0.5, 0.55, a), 1.5)
	canvas.draw_line(center + dir_norm * (r * 0.3), center + dir_norm * (r * 0.8), col, 2.2)

static func _draw_captive_ball(canvas: CanvasItem, center: Vector2, dir: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	var rect := Rect2(center.x - r * 0.8, center.y - r * 0.9, r * 1.6, r * 1.8)
	canvas.draw_rect(rect, ink)
	canvas.draw_rect(rect.grow(-1.5), Color(0.25, 0.25, 0.3, a))
	canvas.draw_rect(rect.grow(-3.0), Color(0.15, 0.15, 0.18, a))
	var dir_norm: Vector2 = dir.normalized() if dir != Vector2.ZERO else Vector2.UP
	canvas.draw_circle(center + dir_norm * (r * 0.55), 3.5, col)
	canvas.draw_circle(center, r * 0.45, Color(0.8, 0.8, 0.85, a))
	canvas.draw_circle(center + Vector2(-2, -2), r * 0.15, Color(1.0, 1.0, 1.0, a))

static func _draw_diverter(canvas: CanvasItem, center: Vector2, dir: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	canvas.draw_circle(center, 5.0, ink)
	canvas.draw_circle(center, 3.5, Color(0.7, 0.7, 0.75, a))
	var dir_norm: Vector2 = dir.normalized() if dir != Vector2.ZERO else Vector2.DOWN
	var arm_pos: Vector2 = center + dir_norm.rotated(TAU * 0.25) * (r * 1.5)
	canvas.draw_line(center, arm_pos, ink, 4.5)
	canvas.draw_line(center, arm_pos, col, 2.5)

static func _draw_vuk(canvas: CanvasItem, center: Vector2, dir: Vector2, r: float, col: Color, ink: Color, a: float) -> void:
	canvas.draw_circle(center, r, ink)
	canvas.draw_circle(center, r - 1.5, col.darkened(0.4))
	canvas.draw_arc(center, r, 0, TAU, 24, col, 2.0)
	var pot_col := Color(col.r, col.g, col.b, 0.7 * a)
	canvas.draw_circle(center, r * 0.75, pot_col)
	canvas.draw_arc(center, r * 0.75, 0, TAU, 16, pot_col, 1.5)
	var dir_norm: Vector2 = dir.normalized() if dir != Vector2.ZERO else Vector2.UP
	canvas.draw_line(center, center + dir_norm * (r * 1.2), ink, 4.5)
	canvas.draw_line(center, center + dir_norm * (r * 1.2), col.lightened(0.3), 2.5)

