extends Control
class_name JunkBoxDragController
## Manages dragging, 90-degree in-flight rotation, grid snapping,
## and valid/invalid visual feedback overlays for polyomino relic modules.

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")

enum DragSource { JUNK_BOX = 0, BOARD = 1, DRAFT = 2 }

var dragging_item: JunkBoxItem = null
var drag_source: int = DragSource.JUNK_BOX
var current_rotation_step: int = 0
var drag_origin_cell: Vector2i = Vector2i.ZERO
var grab_offset_cell: Vector2i = Vector2i.ZERO
var grabbed_cell_index: int = 0

var junk_box_data: JunkBoxData
var junk_box_grid_view: Control
var junk_box_panel: Control
var scroll_container: ScrollContainer
var board: Node

var ghost_preview: Control
var _ghost_visual: _GhostPreviewVisual

const SCROLL_MARGIN: float = 50.0
const SCROLL_SPEED: float = 300.0

func _init() -> void:
	_ensure_ghost_created()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 200
	_ensure_ghost_created()
	set_process_input(false)
	set_process(false)

func _ensure_ghost_created() -> void:
	if ghost_preview == null:
		ghost_preview = Control.new()
		ghost_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost_preview.z_index = 200
		add_child(ghost_preview)

		_ghost_visual = _GhostPreviewVisual.new()
		_ghost_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost_preview.add_child(_ghost_visual)

func start_drag(item: JunkBoxItem, source: int, origin_cell: Vector2i, offset_cell: Vector2i) -> void:
	if item == null:
		return
	_ensure_ghost_created()
	dragging_item = item
	drag_source = source
	current_rotation_step = item.rotation_step
	drag_origin_cell = origin_cell
	grab_offset_cell = offset_cell

	grabbed_cell_index = 0
	if item.module_data != null and not item.module_data.cells.is_empty():
		var initial_cells: Array[Vector2i] = item.module_data.get_anchored_rotated_cells(current_rotation_step)
		for i in range(initial_cells.size()):
			if initial_cells[i] == offset_cell:
				grabbed_cell_index = i
				break

	if junk_box_data == null and GameState and GameState.junk_box != null:
		junk_box_data = GameState.junk_box

	set_process_input(true)
	set_process(true)
	if ghost_preview:
		ghost_preview.visible = true
	_update_ghost()

func _input(event: InputEvent) -> void:
	if dragging_item == null:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_rotate_item()
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_cancel_drag()
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_rotate_item()
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_drop()
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		_update_ghost()

func _process(delta: float) -> void:
	if dragging_item == null:
		return

	if scroll_container and scroll_container.visible:
		var mouse_pos: Vector2 = scroll_container.get_local_mouse_position()
		var container_size: Vector2 = scroll_container.size
		if mouse_pos.x >= 0 and mouse_pos.x <= container_size.x:
			if mouse_pos.y >= 0 and mouse_pos.y < SCROLL_MARGIN:
				scroll_container.scroll_vertical -= int(SCROLL_SPEED * delta)
			elif mouse_pos.y > container_size.y - SCROLL_MARGIN and mouse_pos.y <= container_size.y:
				scroll_container.scroll_vertical += int(SCROLL_SPEED * delta)

func _rotate_item() -> void:
	current_rotation_step = (current_rotation_step + 1) % 4
	_update_ghost()

func get_current_grab_offset() -> Vector2i:
	if dragging_item and dragging_item.module_data != null and not dragging_item.module_data.cells.is_empty():
		var rot_cells: Array[Vector2i] = dragging_item.module_data.get_anchored_rotated_cells(current_rotation_step)
		if grabbed_cell_index >= 0 and grabbed_cell_index < rot_cells.size():
			return rot_cells[grabbed_cell_index]
	return grab_offset_cell

func _get_safe_mouse_position() -> Vector2:
	if is_inside_tree() and get_viewport():
		return get_global_mouse_position()
	return Vector2.ZERO

func _update_ghost() -> void:
	if not dragging_item or not ghost_preview or not _ghost_visual:
		return

	var mouse_pos: Vector2 = _get_safe_mouse_position()
	var cells: Array[Vector2i] = []
	if dragging_item.module_data != null and not dragging_item.module_data.cells.is_empty():
		cells = dragging_item.module_data.get_anchored_rotated_cells(current_rotation_step)
	else:
		cells = [Vector2i.ZERO]

	var tier: int = dragging_item.module_data.tier if dragging_item.module_data != null else 1
	var cell_types: Dictionary = dragging_item.module_data.cell_types if dragging_item.module_data != null else {}

	if junk_box_grid_view and junk_box_grid_view.is_visible_in_tree() and _is_mouse_over(junk_box_grid_view):
		var cell_size := Vector2(48.0, 48.0)
		var target_cell: Vector2i = Vector2i.ZERO
		if junk_box_grid_view.has_method("get_cell_at_global_pos"):
			target_cell = junk_box_grid_view.get_cell_at_global_pos(mouse_pos)
		else:
			var local_pos: Vector2 = junk_box_grid_view.get_local_mouse_position()
			target_cell = Vector2i(int(floor(local_pos.x / 48.0)), int(floor(local_pos.y / 48.0)))

		var final_cell: Vector2i = target_cell - get_current_grab_offset()
		var valid: bool = false
		if junk_box_data:
			var ignore_id: StringName = dragging_item.instance_id if drag_source == DragSource.JUNK_BOX else &""
			valid = junk_box_data.can_place_item(dragging_item, final_cell, current_rotation_step, ignore_id)

		if junk_box_grid_view.has_method("get_global_pos_for_cell"):
			ghost_preview.global_position = junk_box_grid_view.get_global_pos_for_cell(final_cell)
		else:
			ghost_preview.global_position = junk_box_grid_view.global_position + Vector2(final_cell.x * 48.0, final_cell.y * 48.0)

		var mod_data: PolyominoModuleData = dragging_item.module_data if dragging_item != null else null
		_ghost_visual.update_data(cells, mod_data, cell_size, valid, tier, current_rotation_step)
	elif board and _is_mouse_over_board():
		var col_spacing: float = board.BOARD_GRID_COL_SPACING if "BOARD_GRID_COL_SPACING" in board else 52.0
		var row_spacing: float = board.BOARD_GRID_ROW_SPACING if "BOARD_GRID_ROW_SPACING" in board else 56.0
		var cell_size := Vector2(col_spacing, row_spacing)

		var target_cell: Vector2i = Vector2i.ZERO
		if board.has_method("world_to_board_cell"):
			target_cell = board.world_to_board_cell(mouse_pos)
		var final_cell: Vector2i = target_cell - get_current_grab_offset()

		var valid: bool = false
		if board.has_method("can_place_module"):
			var ignore_id: StringName = dragging_item.instance_id if drag_source == DragSource.BOARD else &""
			valid = board.can_place_module(dragging_item, final_cell, current_rotation_step, ignore_id)

		if board.has_method("board_cell_to_world"):
			var world_origin: Vector2 = board.board_cell_to_world(final_cell)
			ghost_preview.global_position = world_origin - Vector2(cell_size.x * 0.5, cell_size.y * 0.5)
		else:
			ghost_preview.global_position = mouse_pos

		var mod_data: PolyominoModuleData = dragging_item.module_data if dragging_item != null else null
		_ghost_visual.update_data(cells, mod_data, cell_size, valid, tier, current_rotation_step)
	elif drag_source == DragSource.BOARD and junk_box_panel and junk_box_panel.is_visible_in_tree() and _is_mouse_over(junk_box_panel):
		var cell_size := Vector2(48.0, 48.0)
		ghost_preview.global_position = mouse_pos - Vector2(24.0, 24.0)
		var can_fit: bool = junk_box_data != null and junk_box_data.find_first_available_slot(dragging_item).x >= 0
		var mod_data: PolyominoModuleData = dragging_item.module_data if dragging_item != null else null
		_ghost_visual.update_data(cells, mod_data, cell_size, can_fit, tier, current_rotation_step)
	else:
		# Floating in empty/invalid area
		var cell_size := Vector2(48.0, 48.0)
		ghost_preview.global_position = mouse_pos - Vector2(24.0, 24.0)
		var mod_data: PolyominoModuleData = dragging_item.module_data if dragging_item != null else null
		_ghost_visual.update_data(cells, mod_data, cell_size, false, tier, current_rotation_step)

func _handle_drop() -> void:
	var mouse_pos: Vector2 = _get_safe_mouse_position()

	if junk_box_grid_view and junk_box_grid_view.is_visible_in_tree() and _is_mouse_over(junk_box_grid_view):
		var target_cell: Vector2i = Vector2i.ZERO
		if junk_box_grid_view.has_method("get_cell_at_global_pos"):
			target_cell = junk_box_grid_view.get_cell_at_global_pos(mouse_pos)
		else:
			var local_pos: Vector2 = junk_box_grid_view.get_local_mouse_position()
			target_cell = Vector2i(int(floor(local_pos.x / 48.0)), int(floor(local_pos.y / 48.0)))

		var final_cell: Vector2i = target_cell - get_current_grab_offset()
		var ignore_id: StringName = dragging_item.instance_id if drag_source == DragSource.JUNK_BOX else &""
		var valid: bool = junk_box_data.can_place_item(dragging_item, final_cell, current_rotation_step, ignore_id) if junk_box_data else false

		if valid:
			if drag_source == DragSource.BOARD:
				if board and board.has_method("unslot_module"):
					board.unslot_module(dragging_item.instance_id)
				junk_box_data.place_item(dragging_item, final_cell, current_rotation_step)
			else:
				junk_box_data.move_item(dragging_item.instance_id, final_cell, current_rotation_step)
		elif drag_source == DragSource.BOARD and junk_box_data:
			if junk_box_data.add_item_auto(dragging_item):
				pass
			else:
				_cancel_drag()
		else:
			_cancel_drag()
	elif drag_source == DragSource.BOARD and junk_box_panel and junk_box_panel.is_visible_in_tree() and _is_mouse_over(junk_box_panel):
		if junk_box_data and junk_box_data.add_item_auto(dragging_item):
			pass
		else:
			_cancel_drag()
	elif board and _is_mouse_over_board():
		var target_cell: Vector2i = Vector2i.ZERO
		if board.has_method("world_to_board_cell"):
			target_cell = board.world_to_board_cell(mouse_pos)
		var final_cell: Vector2i = target_cell - get_current_grab_offset()
		var ignore_id: StringName = dragging_item.instance_id if drag_source == DragSource.BOARD else &""
		var valid: bool = board.can_place_module(dragging_item, final_cell, current_rotation_step, ignore_id)

		if valid:
			board.place_module(dragging_item, final_cell, current_rotation_step)
			if drag_source == DragSource.JUNK_BOX and junk_box_data:
				junk_box_data.remove_item(dragging_item.instance_id)
		else:
			_cancel_drag()
	else:
		_cancel_drag()

	_end_drag()

func _cancel_drag() -> void:
	if dragging_item == null:
		return
	if drag_source == DragSource.JUNK_BOX and junk_box_data:
		junk_box_data.move_item(dragging_item.instance_id, drag_origin_cell, dragging_item.rotation_step)
	elif drag_source == DragSource.BOARD and board:
		board.place_module(dragging_item, drag_origin_cell, dragging_item.rotation_step)
	_end_drag()

func _end_drag() -> void:
	dragging_item = null
	set_process_input(false)
	set_process(false)
	if ghost_preview:
		ghost_preview.visible = false

func _is_mouse_over(control: Node) -> bool:
	if not control is Control or not (is_inside_tree() and get_viewport()):
		return false
	var rect := Rect2(control.global_position, control.size)
	return rect.has_point(_get_safe_mouse_position())

func _is_mouse_over_board() -> bool:
	if not board or not (is_inside_tree() and get_viewport()):
		return false
	if junk_box_panel and junk_box_panel.is_visible_in_tree() and _is_mouse_over(junk_box_panel):
		return false
	var mouse_pos: Vector2 = _get_safe_mouse_position()
	# Board field occupies X: [0, 960], Y: [80, 720]
	return mouse_pos.x >= 0.0 and mouse_pos.x <= 960.0 and mouse_pos.y >= 80.0 and mouse_pos.y <= 720.0

# ==============================================================================
# GHOST PREVIEW CUSTOM VISUAL
# ==============================================================================
class _GhostPreviewVisual extends Control:
	var cells: Array[Vector2i] = []
	var module_data: PolyominoModuleData = null
	var cell_size: Vector2 = Vector2(48.0, 48.0)
	var is_valid: bool = true
	var tier: int = 1
	var rotation_step: int = 0

	func update_data(p_cells: Array[Vector2i], p_module_data: PolyominoModuleData, p_size: Vector2, p_valid: bool, p_tier: int, p_rot_step: int = 0) -> void:
		cells = p_cells
		module_data = p_module_data
		cell_size = p_size
		is_valid = p_valid
		tier = p_tier
		rotation_step = p_rot_step
		queue_redraw()

	func _draw() -> void:
		if cells.is_empty():
			return

		var fill_color: Color = Color(0.2, 0.9, 0.3, 0.65) if is_valid else Color(0.95, 0.2, 0.2, 0.65)
		var border_color: Color = Color(0.4, 1.0, 0.5, 0.9) if is_valid else Color(1.0, 0.4, 0.4, 0.9)

		var orig_cells: Array[Vector2i] = module_data.cells if module_data != null else []

		for idx in range(cells.size()):
			var c: Vector2i = cells[idx]
			var rect := Rect2(c.x * cell_size.x + 2.0, c.y * cell_size.y + 2.0, cell_size.x - 4.0, cell_size.y - 4.0)
			draw_rect(rect, fill_color)
			draw_rect(rect, border_color, false, 2.5)

			var center: Vector2 = rect.get_center()
			var orig_c: Vector2i = orig_cells[idx] if idx < orig_cells.size() else c
			var c_type: int = module_data.get_cell_type_at(orig_c) if module_data != null else 0

			if c_type == PolyominoModuleData.CellType.EMPTY:
				continue

			var orig_dir: Vector2 = module_data.get_cell_direction_at(orig_c) if module_data != null else Vector2.DOWN
			var rot_dir: Vector2 = PolyominoModuleData.get_rotated_direction(orig_dir, rotation_step)
			var icon_col: Color = border_color

			if c_type == PolyominoModuleData.CellType.BUMPER or c_type == PolyominoModuleData.CellType.POP_BUMPER:
				draw_circle(center, rect.size.x * 0.22, icon_col)
			elif c_type == PolyominoModuleData.CellType.ROTARY_BOOSTER:
				draw_arc(center, 8.0, 0, TAU, 16, icon_col, 2.0)
			elif c_type == PolyominoModuleData.CellType.FUNNEL:
				draw_line(center + Vector2(-8, -8), center + Vector2(0, 8), icon_col, 2.0)
				draw_line(center + Vector2(8, -8), center + Vector2(0, 8), icon_col, 2.0)
			else:
				# Rotated directional chevrons for ACCELERATOR, DEFLECTOR, GUIDE_TRACK, KICKERS, DIVERTER, SINKHOLE, LOCK, etc.
				var dir_norm: Vector2 = rot_dir.normalized() if rot_dir != Vector2.ZERO else Vector2.DOWN
				var head: Vector2 = center + dir_norm * (rect.size.x * 0.28)
				var perp: Vector2 = Vector2(-dir_norm.y, dir_norm.x) * (rect.size.x * 0.22)
				var base_p: Vector2 = center - dir_norm * (rect.size.x * 0.15)
				var pts: PackedVector2Array = [head, base_p + perp, base_p - perp]
				draw_colored_polygon(pts, icon_col)

