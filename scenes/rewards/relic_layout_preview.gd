extends Control
class_name RelicLayoutPreview
## Visual preview control that renders polyomino relic shapes and machine composition.
## Shows multi-cell grid footprints, comic ink borders, and kinetic component machinery
## using PolyominoModuleNode as the single source of truth.

const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoModuleNode = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const CellType = PolyominoModuleData.CellType
const RelicTierVisuals = preload("res://scenes/ui/relic_tier_visuals.gd")

const DEFAULT_CELL_SIZE: float = 22.0
const DEFAULT_CELL_PAD: float = 1.5
const DEFAULT_PREVIEW_HEIGHT: float = 76.0
const DARK_INK_BORDER: Color = Color(0.08, 0.05, 0.12, 1.0)

var module_data: PolyominoModuleData = null
var relic_id: StringName = &""
var cell_size: float = DEFAULT_CELL_SIZE
var cell_pad: float = DEFAULT_CELL_PAD
var accent_color: Color = Color(0.9, 0.8, 0.4, 1.0)
var _module_node: PolyominoModuleNode = null

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(180, DEFAULT_PREVIEW_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func setup_for_relic(p_relic_id: StringName) -> bool:
	relic_id = p_relic_id
	if not PolyominoRelicDatabase.has_relic_definition(p_relic_id):
		module_data = null
		if _module_node:
			_module_node.visible = false
		queue_redraw()
		return false

	module_data = PolyominoRelicDatabase.create_module_for_relic(p_relic_id)
	if module_data != null:
		accent_color = RelicTierVisuals.get_tier_color(module_data.tier)
	_update_preview_node()
	queue_redraw()
	return true

func setup_for_module(data: PolyominoModuleData) -> void:
	module_data = data
	if module_data != null:
		relic_id = module_data.module_id
		accent_color = RelicTierVisuals.get_tier_color(module_data.tier)
	_update_preview_node()
	queue_redraw()

func clear() -> void:
	module_data = null
	relic_id = &""
	if _module_node:
		_module_node.visible = false
	queue_redraw()

func get_module_data() -> PolyominoModuleData:
	return module_data

func get_cell_count() -> int:
	return module_data.get_cell_count() if module_data != null else 0

func get_preview_bounds() -> Rect2:
	if module_data == null or module_data.cells.is_empty():
		return Rect2(Vector2.ZERO, size)

	var min_x: int = 9999
	var max_x: int = -9999
	var min_y: int = 9999
	var max_y: int = -9999
	for c in module_data.cells:
		min_x = mini(min_x, c.x)
		max_x = maxi(max_x, c.x)
		min_y = mini(min_y, c.y)
		max_y = maxi(max_y, c.y)

	var cols: int = max_x - min_x + 1
	var rows: int = max_y - min_y + 1
	var total_w: float = float(cols) * cell_size
	var total_h: float = float(rows) * cell_size
	var origin_x: float = (size.x - total_w) * 0.5
	var origin_y: float = (size.y - total_h) * 0.5
	return Rect2(origin_x, origin_y, total_w, total_h)

func _update_preview_node() -> void:
	if module_data == null or module_data.cells.is_empty():
		if _module_node:
			_module_node.visible = false
		return

	if _module_node == null or not is_instance_valid(_module_node):
		_module_node = PolyominoModuleNode.new()
		_module_node.name = "PreviewModuleNode"
		add_child(_module_node)

	_module_node.visible = true

	var item: JunkBoxItem = null
	if not relic_id.is_empty() and PolyominoRelicDatabase.has_relic_definition(relic_id):
		item = PolyominoRelicDatabase.create_item_for_relic(relic_id)
	if item == null:
		item = JunkBoxItem.new()
		item.module_data = module_data

	_module_node.setup_module(item, Vector2i.ZERO, 0)
	_module_node.set_ghost_state(true, 1.0)
	_position_module_node()

func _position_module_node() -> void:
	if _module_node == null or module_data == null or module_data.cells.is_empty():
		return

	var min_x: int = 9999
	var max_x: int = -9999
	var min_y: int = 9999
	var max_y: int = -9999
	for c in module_data.cells:
		min_x = mini(min_x, c.x)
		max_x = maxi(max_x, c.x)
		min_y = mini(min_y, c.y)
		max_y = maxi(max_y, c.y)

	var cols: int = max_x - min_x + 1
	var rows: int = max_y - min_y + 1
	var total_w: float = float(cols) * cell_size
	var total_h: float = float(rows) * cell_size
	var origin_x: float = (size.x - total_w) * 0.5 - float(min_x) * cell_size
	var origin_y: float = (size.y - total_h) * 0.5 - float(min_y) * cell_size

	_module_node.scale = Vector2(cell_size / 52.0, cell_size / 56.0)
	_module_node.position = Vector2(origin_x, origin_y) + Vector2(cell_size * 0.5, cell_size * 0.5)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_position_module_node()

func _draw() -> void:
	_position_module_node()
