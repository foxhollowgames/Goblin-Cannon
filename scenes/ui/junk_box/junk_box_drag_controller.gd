extends Control
class_name JunkBoxDragController

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")

enum DragSource { JUNK_BOX, BOARD, DRAFT }

var dragging_item: JunkBoxItem = null
var drag_source: int = DragSource.JUNK_BOX
var current_rotation_step: int = 0
var drag_origin_cell: Vector2i = Vector2i.ZERO
var grab_offset_cell: Vector2i = Vector2i.ZERO

var junk_box_data: JunkBoxData
var junk_box_grid_view: Control
var scroll_container: ScrollContainer
var board: Node

var ghost_preview: Control

const SCROLL_MARGIN = 50.0
const SCROLL_SPEED = 300.0

func _ready() -> void:
	ghost_preview = Control.new()
	ghost_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost_preview.z_index = 100
	add_child(ghost_preview)
	set_process_input(false)
	set_process(false)

func start_drag(item: JunkBoxItem, source: int, origin_cell: Vector2i, offset_cell: Vector2i) -> void:
	if item == null:
		return
	dragging_item = item
	drag_source = source
	current_rotation_step = item.rotation_step
	drag_origin_cell = origin_cell
	grab_offset_cell = offset_cell
	set_process_input(true)
	set_process(true)
	_update_ghost()

func _input(event: InputEvent) -> void:
	if dragging_item == null:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_rotate_item()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_rotate_item()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			pass # Handle drop on release, wait wait, release is handled below
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_drop()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		_update_ghost()

func _process(delta: float) -> void:
	if dragging_item == null:
		return
	
	if scroll_container:
		var mouse_pos = scroll_container.get_local_mouse_position()
		if mouse_pos.y < SCROLL_MARGIN:
			scroll_container.scroll_vertical -= int(SCROLL_SPEED * delta)
		elif mouse_pos.y > scroll_container.size.y - SCROLL_MARGIN:
			scroll_container.scroll_vertical += int(SCROLL_SPEED * delta)

func _rotate_item() -> void:
	current_rotation_step = (current_rotation_step + 1) % 4
	_update_ghost()

func _update_ghost() -> void:
	if not dragging_item or not ghost_preview:
		return
	
	var mouse_pos = get_global_mouse_position()
	ghost_preview.global_position = mouse_pos
	
	if junk_box_grid_view and _is_mouse_over(junk_box_grid_view):
		var target_cell = _get_grid_cell_at_mouse()
		var valid = false
		if junk_box_data:
			valid = junk_box_data.can_place_item(dragging_item, target_cell - grab_offset_cell, current_rotation_step, dragging_item.instance_id)
		
		# In a real implementation we'd color a sprite or polygon
		ghost_preview.modulate = Color.GREEN if valid else Color.RED
	else:
		# Maybe hovering over board
		ghost_preview.modulate = Color.WHITE

func _handle_drop() -> void:
	if junk_box_grid_view and _is_mouse_over(junk_box_grid_view):
		var target_cell = _get_grid_cell_at_mouse()
		var final_cell = target_cell - grab_offset_cell
		var valid = junk_box_data.can_place_item(dragging_item, final_cell, current_rotation_step, dragging_item.instance_id)
		if valid:
			if drag_source == DragSource.JUNK_BOX:
				junk_box_data.move_item(dragging_item.instance_id, final_cell, current_rotation_step)
			else:
				if drag_source == DragSource.BOARD and board and board.has_method("unslot_module"):
					board.unslot_module(dragging_item)
				junk_box_data.place_item(dragging_item, final_cell, current_rotation_step)
		else:
			if drag_source == DragSource.JUNK_BOX:
				junk_box_data.move_item(dragging_item.instance_id, drag_origin_cell, dragging_item.rotation_step)
			else:
				pass # cancel drag, goes back to board
	elif board and _is_mouse_over(board):
		if board.has_method("try_place_module"):
			var placed = board.try_place_module(dragging_item, get_global_mouse_position(), current_rotation_step)
			if placed and drag_source == DragSource.JUNK_BOX:
				junk_box_data.remove_item(dragging_item.instance_id)
	
	_end_drag()

func _end_drag() -> void:
	dragging_item = null
	set_process_input(false)
	set_process(false)
	if ghost_preview:
		ghost_preview.modulate = Color.TRANSPARENT

func _is_mouse_over(control: Node) -> bool:
	if not control is Control:
		return false
	var rect = Rect2(control.global_position, control.size)
	return rect.has_point(get_global_mouse_position())

func _get_grid_cell_at_mouse() -> Vector2i:
	if not junk_box_grid_view:
		return Vector2i.ZERO
	if junk_box_grid_view.has_method("get_cell_at_global_pos"):
		return junk_box_grid_view.get_cell_at_global_pos(get_global_mouse_position())
	
	# Fallback hardcoded grid math
	var local_pos = junk_box_grid_view.get_local_mouse_position()
	var cell_size = 64.0 # Assumption
	return Vector2i(int(local_pos.x / cell_size), int(local_pos.y / cell_size))
