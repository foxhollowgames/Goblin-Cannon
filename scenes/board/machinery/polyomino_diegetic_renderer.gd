@tool
extends RefCounted
class_name PolyominoDiegeticRenderer
## Renders diegetic physical pinball visual indicators and widget states directly on the board.

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const DropTargetScript = preload("res://scenes/board/machinery/drop_target.gd")
const RolloverSwitchScript = preload("res://scenes/board/machinery/rollover_switch.gd")

const GoalArchetype = PolyominoModuleData.GoalArchetype

static func draw_module(canvas: CanvasItem, module_node: Node2D, module_data: PolyominoModuleData, anchored_cells: Array[Vector2i], components: Array, components_by_cell: Dictionary, cell_w: float, cell_h: float, accent_col: Color, rotation: int, is_ghost: bool, flash_timer: float, hurry_active: bool, banner_text: String, banner_timer: float) -> void:
	if anchored_cells.is_empty():
		return

	var half_w: float = cell_w * 0.5
	var half_h: float = cell_h * 0.5

	# 1. Base cell backgrounds
	var bg_col := Color(accent_col.r, accent_col.g, accent_col.b, 0.15)
	if flash_timer > 0.0:
		var flash_alpha: float = (flash_timer / 0.6) * 0.45
		bg_col = Color(1.0, 0.85, 0.2, flash_alpha)
	elif hurry_active:
		var pulse: float = 0.15 + 0.15 * sin(Time.get_ticks_msec() * 0.012)
		bg_col = Color(1.0, 0.3, 0.2, pulse)

	for c in anchored_cells:
		var center := Vector2(float(c.x) * cell_w, float(c.y) * cell_h)
		canvas.draw_rect(Rect2(center.x - half_w, center.y - half_h, cell_w, cell_h), bg_col)

	# 2. Solid wall enclosure lines
	if module_data != null:
		var wall_ink_col := Color(0.08, 0.05, 0.12, 0.95)
		var wall_highlight_col := accent_col.lightened(0.2)
		if flash_timer > 0.0:
			wall_highlight_col = Color(1.0, 0.95, 0.5, 1.0)

		var segments: Array[Dictionary] = module_data.get_solid_edge_segments(rotation)
		for seg in segments:
			var p1_l: Vector2 = seg["p1"]
			var p2_l: Vector2 = seg["p2"]
			var p1_px := Vector2(p1_l.x * cell_w, p1_l.y * cell_h)
			var p2_px := Vector2(p2_l.x * cell_w, p2_l.y * cell_h)
			var is_internal: bool = seg.get("is_internal", false)

			if is_internal:
				canvas.draw_line(p1_px, p2_px, wall_ink_col, 3.0)
				canvas.draw_line(p1_px, p2_px, Color(0.3, 0.8, 1.0, 0.8), 1.5)
			else:
				canvas.draw_line(p1_px, p2_px, wall_ink_col, 4.0)
				canvas.draw_line(p1_px, p2_px, wall_highlight_col, 2.0)

	# 3. Diegetic component-level visual overlays
	if module_data != null and not is_ghost:
		var th: int = module_node.get_activation_threshold()
		var cur_count: int = module_node.get_current_hit_count()
		if th > 0:
			var ratio: float = module_node.get_charge_progress()
			for comp_item in components:
				if module_data.required_widget_type == PolyominoModuleData.CellType.EMPTY or comp_item.cell_type == module_data.required_widget_type:
					canvas.draw_arc(comp_item.position, comp_item.component_radius + 4.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 24, Color(0.2, 0.9, 0.5, 0.9), 2.5)

		for comp_item in components:
			var c_pos: Vector2 = comp_item.position
			var c_rad: float = comp_item.component_radius
			match comp_item.cell_type:
				PolyominoModuleData.CellType.DROP_TARGET:
					var is_down: bool = module_node._dropped_targets.has(comp_item.local_cell) or (comp_item is DropTargetScript and comp_item.is_dropped)
					if is_down:
						canvas.draw_rect(Rect2(c_pos.x - 14.0, c_pos.y - 5.0, 28.0, 10.0), Color(0.12, 0.12, 0.16, 0.85))
						canvas.draw_rect(Rect2(c_pos.x - 14.0, c_pos.y - 5.0, 28.0, 10.0), Color(0.3, 0.35, 0.4, 0.7), false, 1.5)
					else:
						canvas.draw_rect(Rect2(c_pos.x - 12.0, c_pos.y - 12.0, 24.0, 24.0), Color(1.0, 1.0, 0.95, 0.9))
						canvas.draw_rect(Rect2(c_pos.x - 14.0, c_pos.y - 14.0, 28.0, 28.0), accent_col, false, 2.0)

				PolyominoModuleData.CellType.ROLLOVER_SWITCH:
					var is_lit: bool = module_node._lit_rollovers.has(comp_item.local_cell) or (comp_item is RolloverSwitchScript and comp_item.is_lit)
					if is_lit:
						canvas.draw_circle(c_pos, c_rad + 6.0, Color(1.0, 0.85, 0.2, 0.3))
						canvas.draw_arc(c_pos, c_rad + 2.0, 0, TAU, 20, Color(1.0, 0.95, 0.5, 0.95), 2.5)
						canvas.draw_circle(c_pos, 3.5, Color(1.0, 1.0, 0.9, 0.95))
					else:
						canvas.draw_circle(c_pos, 3.0, Color(0.3, 0.35, 0.4, 0.6))

				PolyominoModuleData.CellType.ORBIT_LOOP, PolyominoModuleData.CellType.GUIDE_TRACK:
					var dir_norm: Vector2 = comp_item.direction.normalized() if comp_item.direction != Vector2.ZERO else Vector2.UP
					var chevron_count: int = maxi(2, th)
					for i in range(chevron_count):
						var offset_dist: float = (float(i) - float(chevron_count - 1) * 0.5) * 10.0
						var ch_pos: Vector2 = c_pos + dir_norm * offset_dist
						var ch_lit: bool = (i < cur_count)
						var ch_col: Color = Color(0.2, 0.95, 1.0, 0.95) if ch_lit else Color(0.2, 0.3, 0.35, 0.5)
						canvas.draw_circle(ch_pos, 2.5, ch_col)

				PolyominoModuleData.CellType.SPINNER:
					var spin_ratio: float = module_node.get_charge_progress()
					canvas.draw_arc(c_pos, c_rad + 4.0, -PI * 0.8, PI * 0.8, 20, Color(0.2, 0.25, 0.3, 0.5), 2.0)
					if spin_ratio > 0.0:
						canvas.draw_arc(c_pos, c_rad + 4.0, -PI * 0.8, -PI * 0.8 + (1.6 * PI) * spin_ratio, 20, Color(0.25, 0.95, 0.55, 0.95), 2.5)

				PolyominoModuleData.CellType.BASH_TOY, PolyominoModuleData.CellType.CAPTIVE_BALL:
					var max_pips: int = maxi(3, th)
					var cur_hits: int = mini(max_pips, cur_count)
					for p_idx in range(max_pips):
						var angle: float = -PI * 0.5 + TAU * (float(p_idx) / float(max_pips))
						var pip_pos: Vector2 = c_pos + Vector2(cos(angle), sin(angle)) * (c_rad + 5.0)
						if p_idx < cur_hits:
							canvas.draw_circle(pip_pos, 3.5, Color(1.0, 0.35, 0.2, 0.95))
						else:
							canvas.draw_circle(pip_pos, 2.5, Color(0.7, 0.7, 0.4, 0.7))

				PolyominoModuleData.CellType.BALL_LOCK, PolyominoModuleData.CellType.SCOOP_SINKHOLE:
					if module_node._lock_count > 0:
						canvas.draw_circle(c_pos, 7.0, Color(0.85, 0.95, 1.0, 0.95))
						canvas.draw_arc(c_pos, 9.0, 0, TAU, 16, Color(0.3, 0.8, 1.0, 0.9), 2.0)

		# Sequential route specific pulsing guidance
		if module_data.goal_type == GoalArchetype.SEQUENCE_ROUTE:
			var target_seq: Array[Vector2i] = module_data.goal_target_sequence
			if target_seq.is_empty():
				for comp_item in components:
					target_seq.append(comp_item.local_cell)
			if not target_seq.is_empty():
				var cur_step: Vector2i = target_seq[mini(module_node._sequence_index, target_seq.size() - 1)]
				var cur_comp = components_by_cell.get(cur_step, null)
				if cur_comp != null:
					var pulse: float = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.01)
					canvas.draw_arc(cur_comp.position, cur_comp.component_radius + 6.0, 0, TAU, 16, Color(0.2, 0.9, 1.0, pulse), 3.0)

	# 4. Floating comic banner text on goal achievement
	if banner_timer > 0.0 and not banner_text.is_empty():
		var font: Font = ThemeDB.fallback_font
		var font_size: int = 14
		var alpha: float = clampf(banner_timer / 0.4, 0.0, 1.0)
		var text_pos: Vector2 = Vector2(-20, -18.0 - (1.2 - banner_timer) * 20.0)
		canvas.draw_string(font, text_pos + Vector2(1, 1), banner_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.0, 0.0, 0.0, alpha))
		canvas.draw_string(font, text_pos, banner_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1.0, 0.9, 0.2, alpha))
