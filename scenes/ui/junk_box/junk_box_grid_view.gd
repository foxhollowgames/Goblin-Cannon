extends Control
class_name JunkBoxGridView

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxDragController = preload("res://scenes/ui/junk_box/junk_box_drag_controller.gd")

signal cell_clicked(cell_pos: Vector2i)
signal item_clicked(item: JunkBoxItem)
signal item_hovered(item: JunkBoxItem)
signal item_unhovered()
signal grid_size_changed()

const CELL_SIZE: int = 46
const CELL_WIDTH: int = 46
const CELL_HEIGHT: int = 46
const CELL_PAD: int = 2
const DARK_INK_BORDER: Color = Color(0.08, 0.05, 0.12, 1.0)

var hovered_cell: Vector2i = Vector2i(-1, -1)
var hovered_item: JunkBoxItem = null
var drag_controller: Node = null
@export var junk_box_data: JunkBoxData = null

func get_cell_size() -> int:
	return CELL_SIZE

func get_peg_preview_parameters() -> Dictionary:
	var data: JunkBoxData = get_junk_box_data()
	return {
		"cell_width": float(CELL_WIDTH),
		"cell_height": float(CELL_HEIGHT),
		"cell_pad": CELL_PAD,
		"grid_columns": data.grid_columns if data != null else 6
	}

func get_junk_box_data() -> JunkBoxData:
	if junk_box_data != null:
		return junk_box_data
	if GameState != null and "junk_box" in GameState:
		return GameState.junk_box
	return null

func set_junk_box_data(value: JunkBoxData) -> void:
	var old_data: JunkBoxData = get_junk_box_data()
	if old_data != null and old_data.inventory_changed.is_connected(_on_inventory_changed):
		old_data.inventory_changed.disconnect(_on_inventory_changed)
	junk_box_data = value
	if junk_box_data != null and not junk_box_data.inventory_changed.is_connected(_on_inventory_changed):
		junk_box_data.inventory_changed.connect(_on_inventory_changed)
	update_grid_size()
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	var data: JunkBoxData = get_junk_box_data()
	if data != null and not data.inventory_changed.is_connected(_on_inventory_changed):
		data.inventory_changed.connect(_on_inventory_changed)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	update_grid_size()

func _on_mouse_exited() -> void:
	if hovered_cell != Vector2i(-1, -1) or hovered_item != null:
		hovered_cell = Vector2i(-1, -1)
		hovered_item = null
		item_unhovered.emit()
		queue_redraw()

func _on_inventory_changed() -> void:
	update_grid_size()
	queue_redraw()

func _update_size() -> void:
	update_grid_size()

func update_grid_size() -> void:
	var data: JunkBoxData = get_junk_box_data()
	if data == null:
		return
	var max_occ: int = data.get_max_occupied_row()
	var needed_rows: int = max_occ + 4 if max_occ >= 0 else 4

	var parent_scroll: ScrollContainer = get_parent() as ScrollContainer
	var container_height: float = 0.0
	if parent_scroll != null:
		container_height = parent_scroll.size.y if parent_scroll.size.y > 0.0 else parent_scroll.custom_minimum_size.y

	var visible_rows: int = 0
	if container_height > 0.0:
		visible_rows = int(floor(container_height / CELL_SIZE))

	var rows: int = needed_rows
	if visible_rows > 0 and needed_rows <= visible_rows:
		rows = max(needed_rows, visible_rows)

	var cols: int = data.grid_columns
	custom_minimum_size = Vector2(cols * CELL_SIZE, rows * CELL_SIZE)
	size = custom_minimum_size

	grid_size_changed.emit()

func get_cell_at_global_pos(global_pos: Vector2) -> Vector2i:
	var local_pos: Vector2 = global_pos - global_position
	return Vector2i(int(floor(local_pos.x / CELL_SIZE)), int(floor(local_pos.y / CELL_SIZE)))

func get_global_pos_for_cell(cell: Vector2i) -> Vector2:
	return global_position + Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)

func _gui_input(event: InputEvent) -> void:
	var is_dragging: bool = (drag_controller != null and drag_controller.dragging_item != null)
	if event is InputEventMouseMotion:
		var cell: Vector2i = _pos_to_cell(event.position)
		if cell != hovered_cell:
			hovered_cell = cell
			var data: JunkBoxData = get_junk_box_data()
			var item: JunkBoxItem = data.get_item_at(cell) if data != null else null
			if item != hovered_item:
				hovered_item = item
				if item != null and not is_dragging:
					item_hovered.emit(item)
				else:
					item_unhovered.emit()
			queue_redraw()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var cell: Vector2i = _pos_to_cell(event.position)
			var data: JunkBoxData = get_junk_box_data()
			var item: JunkBoxItem = data.get_item_at(cell) if data != null else null
			if item != null:
				item_clicked.emit(item)
				if drag_controller:
					var grab_offset: Vector2i = cell - item.grid_position
					drag_controller.start_drag(item, 0, item.grid_position, grab_offset) # DragSource.JUNK_BOX = 0
					queue_redraw()
			else:
				cell_clicked.emit(cell)

func _pos_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / CELL_SIZE)), int(floor(pos.y / CELL_SIZE)))

func _draw() -> void:
	var data: JunkBoxData = get_junk_box_data()
	if data == null:
		return
	var cols: int = data.grid_columns
	var rows: int = maxi(int(size.y / CELL_SIZE), 1)

	var bg_color: Color = Constants.ui_buckets_panel_bg()
	var border_color: Color = Constants.ui_buckets_panel_border()
	for y in range(rows):
		for x in range(cols):
			var rect: Rect2 = Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			draw_rect(rect, bg_color)
			draw_rect(rect, border_color, false, 1.0)
			draw_circle(rect.get_center(), 1.0, Color(border_color.r, border_color.g, border_color.b, 0.5))

	var is_dragging: bool = (drag_controller != null and drag_controller.dragging_item != null)
	for item in data.get_all_items():
		var being_dragged: bool = (drag_controller != null and drag_controller.dragging_item == item)
		_draw_item(item, being_dragged)

	if not is_dragging and hovered_cell.x >= 0 and hovered_cell.x < cols and hovered_cell.y >= 0 and hovered_cell.y < rows:
		var highlight_rect: Rect2 = Rect2(hovered_cell.x * CELL_SIZE, hovered_cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		if hovered_item != null:
			for c in hovered_item.get_occupied_cells():
				var r: Rect2 = Rect2(c.x * CELL_SIZE, c.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
				draw_rect(r, Color(1.0, 1.0, 1.0, 0.2))
		else:
			draw_rect(highlight_rect, Color(1.0, 1.0, 1.0, 0.1))

func _draw_item(item: JunkBoxItem, being_dragged: bool = false) -> void:
	if item == null:
		return
	var tier: int = item.module_data.tier if item.module_data != null else 0
	var color: Color = Constants.shop_rarity_accent_color(tier)
	var bg_color := Color(color.r, color.g, color.b, 0.25)
	var wall_highlight: Color = color.lightened(0.2)
	var ink_border: Color = DARK_INK_BORDER

	if being_dragged:
		var alpha_mult: float = 0.35
		bg_color.a *= alpha_mult
		color.a *= alpha_mult
		wall_highlight.a *= alpha_mult
		ink_border.a *= alpha_mult

	var occupied: Array[Vector2i] = item.get_occupied_cells()
	if occupied.is_empty():
		return

	for c in occupied:
		var rect: Rect2 = Rect2(c.x * CELL_SIZE + CELL_PAD, c.y * CELL_SIZE + CELL_PAD, CELL_SIZE - CELL_PAD * 2, CELL_SIZE - CELL_PAD * 2)
		draw_rect(rect, bg_color)

	for c in occupied:
		var cell_origin := Vector2(float(c.x) * float(CELL_SIZE), float(c.y) * float(CELL_SIZE))
		if occupied.has(Vector2i(c.x + 1, c.y)):
			var p1 := Vector2(cell_origin.x + float(CELL_SIZE), cell_origin.y)
			var p2 := Vector2(cell_origin.x + float(CELL_SIZE), cell_origin.y + float(CELL_SIZE))
			draw_line(p1, p2, ink_border, 3.0)
			draw_line(p1, p2, Color(color.r, color.g, color.b, 0.5 * (0.35 if being_dragged else 1.0)), 1.5)
		if occupied.has(Vector2i(c.x, c.y + 1)):
			var p1 := Vector2(cell_origin.x, cell_origin.y + float(CELL_SIZE))
			var p2 := Vector2(cell_origin.x + float(CELL_SIZE), cell_origin.y + float(CELL_SIZE))
			draw_line(p1, p2, ink_border, 3.0)
			draw_line(p1, p2, Color(color.r, color.g, color.b, 0.5 * (0.35 if being_dragged else 1.0)), 1.5)

	if item.module_data != null:
		var segments: Array[Dictionary] = item.module_data.get_solid_edge_segments(item.rotation_step)
		var offset: Vector2 = Vector2(item.grid_position) + Vector2(0.5, 0.5)
		for seg in segments:
			var p1_l: Vector2 = seg["p1"]
			var p2_l: Vector2 = seg["p2"]
			var p1: Vector2 = (p1_l + offset) * float(CELL_SIZE)
			var p2: Vector2 = (p2_l + offset) * float(CELL_SIZE)
			var is_internal: bool = seg.get("is_internal", false)
			if is_internal:
				draw_line(p1, p2, ink_border, 3.0)
				draw_line(p1, p2, Color(0.3, 0.8, 1.0, 0.8 * (0.35 if being_dragged else 1.0)), 1.5)
			else:
				draw_line(p1, p2, ink_border, 4.0)
				draw_line(p1, p2, wall_highlight, 2.0)

	if item.module_data != null:
		var local_cells: Array[Vector2i] = item.get_local_cells()
		for i in range(mini(occupied.size(), local_cells.size())):
			var occ_c: Vector2i = occupied[i]
			var orig_idx: int = item.module_data._find_orig_cell_index_for_anchored(local_cells[i], item.rotation_step)
			if orig_idx >= 0 and orig_idx < item.module_data.cells.size():
				var orig_c: Vector2i = item.module_data.cells[orig_idx]
				var c_type: int = item.module_data.get_cell_type_at(orig_c)
				if c_type != PolyominoModuleData.CellType.EMPTY:
					var orig_dir: Vector2 = item.module_data.get_cell_direction_at(orig_c)
					var rotated_dir: Vector2 = PolyominoModuleData.get_rotated_direction(orig_dir, item.rotation_step)
					var center := Vector2((float(occ_c.x) + 0.5) * float(CELL_SIZE), (float(occ_c.y) + 0.5) * float(CELL_SIZE))
					_draw_kinetic_glyph(center, c_type, rotated_dir, (float(CELL_SIZE) - float(CELL_PAD) * 2.0) * 0.5, color)

func _draw_kinetic_glyph(center: Vector2, type: int, dir: Vector2, radius: float, accent_color: Color) -> void:
	if type == PolyominoModuleData.CellType.EMPTY:
		return
	var s: float = radius
	match type:
		PolyominoModuleData.CellType.BUMPER, PolyominoModuleData.CellType.POP_BUMPER:
			draw_circle(center, s * 0.65, DARK_INK_BORDER)
			draw_circle(center, s * 0.5, Color.WHITE)
			draw_circle(center, s * 0.25, accent_color.darkened(0.5))
		PolyominoModuleData.CellType.ACCELERATOR:
			var dir_norm: Vector2 = dir.normalized() if dir.length_squared() > 0.001 else Vector2.DOWN
			var tip: Vector2 = center + dir_norm * (s * 0.7)
			var perp := Vector2(-dir_norm.y, dir_norm.x) * (s * 0.5)
			var base_p: Vector2 = center - dir_norm * (s * 0.4)
			var poly_ink := PackedVector2Array([tip + dir_norm * 1.5, base_p + perp * 1.25, base_p - perp * 1.25])
			var poly_white := PackedVector2Array([tip, base_p + perp, base_p - perp])
			draw_colored_polygon(poly_ink, DARK_INK_BORDER)
			draw_colored_polygon(poly_white, Color.WHITE)
		PolyominoModuleData.CellType.FUNNEL, PolyominoModuleData.CellType.SCOOP_SINKHOLE, PolyominoModuleData.CellType.BALL_LOCK:
			var dir_norm: Vector2 = dir.normalized() if dir.length_squared() > 0.001 else Vector2.DOWN
			var perp := Vector2(-dir_norm.y, dir_norm.x)
			var left_start: Vector2 = center - dir_norm * (s * 0.55) + perp * (s * 0.55)
			var left_end: Vector2 = center + dir_norm * (s * 0.45) + perp * (s * 0.15)
			var right_start: Vector2 = center - dir_norm * (s * 0.55) - perp * (s * 0.55)
			var right_end: Vector2 = center + dir_norm * (s * 0.45) - perp * (s * 0.15)
			draw_line(left_start, left_end, DARK_INK_BORDER, 3.5)
			draw_line(left_start, left_end, Color.WHITE, 2.0)
			draw_line(right_start, right_end, DARK_INK_BORDER, 3.5)
			draw_line(right_start, right_end, Color.WHITE, 2.0)
			draw_circle(center + dir_norm * (s * 0.45), s * 0.15, Color.WHITE)
		PolyominoModuleData.CellType.ROTARY_BOOSTER, PolyominoModuleData.CellType.SPINNER:
			draw_arc(center, s * 0.55, 0.2, TAU * 0.85, 16, DARK_INK_BORDER, 3.5)
			draw_arc(center, s * 0.55, 0.2, TAU * 0.85, 16, Color.WHITE, 2.0)
			for i in range(3):
				var ang: float = 0.2 + float(i) * (TAU * 0.28)
				var p1: Vector2 = center + Vector2.from_angle(ang) * (s * 0.35)
				var p2: Vector2 = center + Vector2.from_angle(ang) * (s * 0.7)
				draw_line(p1, p2, Color.WHITE, 1.5)
			draw_circle(center, s * 0.2, Color.WHITE)
		PolyominoModuleData.CellType.MANA_SIPHON:
			draw_arc(center, s * 0.6, 0.0, PI * 1.2, 12, accent_color.lightened(0.4), 2.0)
			draw_arc(center, s * 0.35, PI * 0.8, PI * 2.0, 10, Color.WHITE, 1.8)
			draw_circle(center, s * 0.18, Color.WHITE)
		PolyominoModuleData.CellType.DIRECTIONAL_DEFLECTOR, PolyominoModuleData.CellType.SLINGSHOT:
			var dir_norm: Vector2 = dir.normalized() if dir.length_squared() > 0.001 else Vector2(1, 1).normalized()
			var perp := Vector2(-dir_norm.y, dir_norm.x)
			var bar_p1: Vector2 = center - perp * (s * 0.5) - dir_norm * (s * 0.2)
			var bar_p2: Vector2 = center + perp * (s * 0.5) - dir_norm * (s * 0.2)
			draw_line(bar_p1, bar_p2, DARK_INK_BORDER, 4.0)
			draw_line(bar_p1, bar_p2, Color.WHITE, 2.2)
			draw_line(center, center + dir_norm * (s * 0.6), accent_color.lightened(0.4), 2.0)
		PolyominoModuleData.CellType.DROP_TARGET, PolyominoModuleData.CellType.STANDUP_TARGET:
			var target_rect: Rect2 = Rect2(center.x - s * 0.45, center.y - s * 0.45, s * 0.9, s * 0.9)
			draw_rect(target_rect, DARK_INK_BORDER)
			draw_rect(target_rect.grow(-2.0), Color.WHITE)
			draw_rect(target_rect.grow(-4.0), accent_color)
		PolyominoModuleData.CellType.GUIDE_RAIL, PolyominoModuleData.CellType.GUIDE_TRACK:
			draw_line(center + Vector2(-s * 0.5, -s * 0.25), center + Vector2(s * 0.5, -s * 0.25), Color.WHITE, 1.8)
			draw_line(center + Vector2(-s * 0.5, s * 0.25), center + Vector2(s * 0.5, s * 0.25), Color.WHITE, 1.8)
		_:
			draw_circle(center, s * 0.2, accent_color.darkened(0.2))
