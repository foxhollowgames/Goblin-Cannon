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

const CELL_SIZE: int = 48
const CELL_PAD: int = 2

var hovered_cell: Vector2i = Vector2i(-1, -1)
var hovered_item: JunkBoxItem = null
var drag_controller: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	GameState.junk_box.inventory_changed.connect(_on_inventory_changed)
	_update_size()

func _on_inventory_changed() -> void:
	_update_size()
	queue_redraw()

func _update_size() -> void:
	var rows: int = maxi(GameState.junk_box.get_max_row() + 4, GameState.junk_box.DEFAULT_MIN_ROWS)
	var cols: int = GameState.junk_box.grid_columns
	custom_minimum_size = Vector2(cols * CELL_SIZE, rows * CELL_SIZE)
	size = custom_minimum_size

func get_cell_at_global_pos(global_pos: Vector2) -> Vector2i:
	var local_pos: Vector2 = global_pos - global_position
	return Vector2i(int(floor(local_pos.x / CELL_SIZE)), int(floor(local_pos.y / CELL_SIZE)))

func get_global_pos_for_cell(cell: Vector2i) -> Vector2:
	return global_position + Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cell: Vector2i = _pos_to_cell(event.position)
		if cell != hovered_cell:
			hovered_cell = cell
			var item: JunkBoxItem = GameState.junk_box.get_item_at(cell)
			if item != hovered_item:
				hovered_item = item
				if item != null:
					item_hovered.emit(item)
				else:
					item_unhovered.emit()
			queue_redraw()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var cell: Vector2i = _pos_to_cell(event.position)
			var item: JunkBoxItem = GameState.junk_box.get_item_at(cell)
			if item != null:
				item_clicked.emit(item)
				if drag_controller:
					var grab_offset: Vector2i = cell - item.grid_position
					drag_controller.start_drag(item, 0, item.grid_position, grab_offset) # DragSource.JUNK_BOX = 0
			else:
				cell_clicked.emit(cell)

func _pos_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / CELL_SIZE)), int(floor(pos.y / CELL_SIZE)))

func _draw() -> void:
	var cols: int = GameState.junk_box.grid_columns
	var rows: int = maxi(GameState.junk_box.get_max_row() + 4, GameState.junk_box.DEFAULT_MIN_ROWS)
	
	var bg_color: Color = Constants.ui_buckets_panel_bg()
	var border_color: Color = Constants.ui_buckets_panel_border()
	for y in range(rows):
		for x in range(cols):
			var rect: Rect2 = Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			draw_rect(rect, bg_color)
			draw_rect(rect, border_color, false, 1.0)
			draw_circle(rect.get_center(), 1.0, Color(border_color.r, border_color.g, border_color.b, 0.5))

	for item in GameState.junk_box.get_all_items():
		_draw_item(item)

	if hovered_cell.x >= 0 and hovered_cell.x < cols and hovered_cell.y >= 0 and hovered_cell.y < rows:
		var highlight_rect: Rect2 = Rect2(hovered_cell.x * CELL_SIZE, hovered_cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		if hovered_item != null:
			for c in hovered_item.get_occupied_cells():
				var r: Rect2 = Rect2(c.x * CELL_SIZE, c.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
				draw_rect(r, Color(1.0, 1.0, 1.0, 0.2))
		else:
			draw_rect(highlight_rect, Color(1.0, 1.0, 1.0, 0.1))

func _draw_item(item: JunkBoxItem) -> void:
	var tier: int = item.module_data.tier if item.module_data != null else 0
	var color: Color = Constants.shop_rarity_accent_color(tier)
	
	var occupied: Array[Vector2i] = item.get_occupied_cells()
	for c in occupied:
		var rect: Rect2 = Rect2(c.x * CELL_SIZE + CELL_PAD, c.y * CELL_SIZE + CELL_PAD, CELL_SIZE - CELL_PAD * 2, CELL_SIZE - CELL_PAD * 2)
		draw_rect(rect, color)
		draw_rect(rect, color.lightened(0.2), false, 2.0)
		
		if item.module_data != null:
			var local_cells: Array[Vector2i] = item.get_local_cells()
			var idx: int = occupied.find(c)
			if idx >= 0:
				var l_cell: Vector2i = local_cells[idx]
				var c_type: int = PolyominoModuleData.CellType.EMPTY
				if item.module_data.cell_types.has(l_cell):
					c_type = item.module_data.cell_types[l_cell]
				elif item.module_data.cell_types.has("%d,%d" % [l_cell.x, l_cell.y]):
					c_type = item.module_data.cell_types["%d,%d" % [l_cell.x, l_cell.y]]
				_draw_primitive_icon(rect.get_center(), c_type, color)

func _draw_primitive_icon(center: Vector2, c_type: int, base_color: Color) -> void:
	var c: Color = base_color.darkened(0.5)
	if c_type == PolyominoModuleData.CellType.BUMPER:
		draw_circle(center, CELL_SIZE * 0.25, c)
	elif c_type == PolyominoModuleData.CellType.ACCELERATOR:
		var pts = PackedVector2Array([center + Vector2(0, -10), center + Vector2(10, 10), center + Vector2(-10, 10)])
		draw_colored_polygon(pts, c)
	elif c_type == PolyominoModuleData.CellType.FUNNEL:
		draw_line(center + Vector2(-10, -10), center + Vector2(0, 10), c, 2)
		draw_line(center + Vector2(10, -10), center + Vector2(0, 10), c, 2)
	elif c_type == PolyominoModuleData.CellType.ROTARY_BOOSTER:
		draw_arc(center, 10, 0, TAU, 16, c, 2)
