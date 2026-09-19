extends Control
class_name JunkBoxGridView

const PolyominoModuleNode = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxDragController = preload("res://scenes/ui/junk_box/junk_box_drag_controller.gd")
const RelicTierVisuals = preload("res://scenes/ui/relic_tier_visuals.gd")

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
var _item_nodes: Dictionary = {}

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
	sync_item_nodes()
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	var data: JunkBoxData = get_junk_box_data()
	if data != null and not data.inventory_changed.is_connected(_on_inventory_changed):
		data.inventory_changed.connect(_on_inventory_changed)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	update_grid_size()
	sync_item_nodes()

func _on_mouse_exited() -> void:
	if hovered_cell != Vector2i(-1, -1) or hovered_item != null:
		hovered_cell = Vector2i(-1, -1)
		hovered_item = null
		item_unhovered.emit()
		queue_redraw()

func _on_inventory_changed() -> void:
	update_grid_size()
	sync_item_nodes()
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

func sync_item_nodes() -> void:
	var data: JunkBoxData = get_junk_box_data()
	if data == null:
		for inst_id in _item_nodes.keys():
			var old_node: Node = _item_nodes[inst_id]
			if is_instance_valid(old_node):
				old_node.queue_free()
		_item_nodes.clear()
		return

	var all_items: Array[JunkBoxItem] = data.get_all_items()
	var current_ids: Dictionary = {}
	for it in all_items:
		var iid: StringName = it.instance_id if "instance_id" in it and not it.instance_id.is_empty() else StringName(str(it.get_instance_id()))
		current_ids[iid] = it

	# Remove nodes for items no longer in junk box
	var to_remove: Array = []
	for inst_id in _item_nodes.keys():
		if not current_ids.has(inst_id):
			var old_node: Node = _item_nodes[inst_id]
			if is_instance_valid(old_node):
				old_node.queue_free()
			to_remove.append(inst_id)
	for rid in to_remove:
		_item_nodes.erase(rid)

	# Update or create nodes for existing items
	var dragging_item: JunkBoxItem = drag_controller.dragging_item if (drag_controller != null and "dragging_item" in drag_controller) else null
	for iid in current_ids.keys():
		var item: JunkBoxItem = current_ids[iid]
		var being_dragged: bool = (dragging_item == item)
		var node: PolyominoModuleNode = _item_nodes.get(iid, null)
		if node == null or not is_instance_valid(node):
			node = PolyominoModuleNode.new()
			node.name = "JunkItem_%s" % str(iid)
			add_child(node)
			_item_nodes[iid] = node

		node.position = Vector2((float(item.grid_position.x) + 0.5) * float(CELL_SIZE), (float(item.grid_position.y) + 0.5) * float(CELL_SIZE))
		node.scale = Vector2(float(CELL_SIZE) / 52.0, float(CELL_SIZE) / 56.0)
		if node.item != item or node.rotation_step != item.rotation_step or node.grid_position != item.grid_position:
			node.setup_module(item, item.grid_position, item.rotation_step)
		node.set_ghost_state(true, 0.35 if being_dragged else 1.0)

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
					sync_item_nodes()
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
	if not is_dragging and hovered_cell.x >= 0 and hovered_cell.x < cols and hovered_cell.y >= 0 and hovered_cell.y < rows:
		var highlight_rect: Rect2 = Rect2(hovered_cell.x * CELL_SIZE, hovered_cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		if hovered_item != null:
			for c in hovered_item.get_occupied_cells():
				var r: Rect2 = Rect2(c.x * CELL_SIZE, c.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
				draw_rect(r, Color(1.0, 1.0, 1.0, 0.2))
		else:
			draw_rect(highlight_rect, Color(1.0, 1.0, 1.0, 0.1))
