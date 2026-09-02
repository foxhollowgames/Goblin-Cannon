extends Control
## Junk Box UI Drawer Panel.

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxGridView = preload("res://scenes/ui/junk_box/junk_box_grid_view.gd")
const JunkBoxDragController = preload("res://scenes/ui/junk_box/junk_box_drag_controller.gd")

signal closed

var _game_coordinator: Node
var _reward_handler: Node
var drag_controller: Node = null

@onready var drawer_panel: PanelContainer = $DrawerPanel
@onready var grid_view: JunkBoxGridView = $DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer/JunkBoxGridView
@onready var scroll_container: ScrollContainer = $DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer
@onready var tooltip_lbl: RichTextLabel = $DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/VBoxInfo/InfoPanel/TooltipLabel
@onready var close_btn: Button = $DrawerPanel/MarginContainer/VBoxContainer/HBoxTitle/CloseBtn
@onready var sort_btn: Button = $DrawerPanel/MarginContainer/VBoxContainer/HBoxTitle/SortBtn

func _ensure_drag_controller_exists() -> void:
	if drag_controller == null:
		drag_controller = JunkBoxDragController.new()
		drag_controller.name = "JunkBoxDragController"
		var p: Node = get_parent()
		if p:
			p.add_child(drag_controller)
		else:
			add_child(drag_controller)

func _ready() -> void:
	if _sidebar_mode:
		show()
		_apply_sidebar_layout()
	else:
		hide()
	_ensure_drag_controller_exists()
	if grid_view:
		drag_controller.junk_box_grid_view = grid_view
		grid_view.drag_controller = drag_controller
		if not grid_view.item_hovered.is_connected(_on_item_hovered):
			grid_view.item_hovered.connect(_on_item_hovered)
		if not grid_view.item_unhovered.is_connected(_on_item_unhovered):
			grid_view.item_unhovered.connect(_on_item_unhovered)
	if drawer_panel:
		drag_controller.junk_box_panel = drawer_panel
	if scroll_container:
		drag_controller.scroll_container = scroll_container

	if close_btn and not close_btn.pressed.is_connected(_close):
		close_btn.pressed.connect(_close)
	if sort_btn and not sort_btn.pressed.is_connected(_on_sort_pressed):
		sort_btn.pressed.connect(_on_sort_pressed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		_ensure_drag_controller_on_parent()

func _ensure_drag_controller_on_parent() -> void:
	_ensure_drag_controller_exists()
	if drag_controller and drag_controller.get_parent() == self:
		var p: Node = get_parent()
		if p:
			remove_child(drag_controller)
			p.add_child(drag_controller)

func setup(coordinator: Node, reward_handler: Node) -> void:
	_ensure_drag_controller_on_parent()
	_game_coordinator = coordinator
	_reward_handler = reward_handler
	if coordinator:
		var b: Node = coordinator.get("board") if "board" in coordinator else coordinator.get("_board")
		if b:
			set_board(b)

func set_board(p_board: Node) -> void:
	_ensure_drag_controller_on_parent()
	if drag_controller:
		drag_controller.board = p_board
	if p_board and p_board.has_method("set_drag_controller"):
		p_board.set_drag_controller(drag_controller)

func toggle() -> void:
	if _sidebar_mode:
		show()
		return
	if visible:
		_close()
	else:
		_open()

func _open() -> void:
	_update_tooltip(null)
	show()
	if _sidebar_mode:
		_apply_sidebar_layout()

func _close() -> void:
	if _sidebar_mode:
		show()
		return
	hide()
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			if not _sidebar_mode:
				_close()
				get_viewport().set_input_as_handled()

func _on_sort_pressed() -> void:
	if GameState.junk_box != null:
		GameState.junk_box.auto_pack()

func _on_item_hovered(item: JunkBoxItem) -> void:
	_update_tooltip(item)

func _on_item_unhovered() -> void:
	_update_tooltip(null)

func _get_tooltip_lbl() -> RichTextLabel:
	if tooltip_lbl:
		return tooltip_lbl
	tooltip_lbl = get_node_or_null("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/VBoxInfo/InfoPanel/TooltipLabel") as RichTextLabel
	return tooltip_lbl

func _update_tooltip(item: JunkBoxItem) -> void:
	var lbl: RichTextLabel = _get_tooltip_lbl()
	if lbl == null:
		return
	if item == null:
		lbl.text = "[color=#cfbba8]Hover an item in the box to inspect details.[/color]"
		return
	
	var text: String = "[b][color=#f4d06f]%s[/color][/b]\n" % item.display_name
	var relic_id: StringName = &""
	if "custom_payload" in item and item.custom_payload is Dictionary:
		relic_id = StringName(item.custom_payload.get("relic_id", ""))
	if relic_id == &"" and item.module_data != null:
		relic_id = item.module_data.module_id

	if item.module_data != null:
		text += "Tier: [b]%d[/b]\n" % item.module_data.tier
		text += "Size: [b]%d[/b] Cells\n" % item.module_data.get_cell_count()
		
		var shape_name: String = PolyominoRelicDatabase.get_relic_shape_name(relic_id) if relic_id != &"" else ""
		if not shape_name.is_empty():
			text += "Shape: [b]%s[/b]\n" % shape_name
		
		var desc: String = PolyominoRelicDatabase.get_relic_kinetic_description(relic_id) if relic_id != &"" else ""
		if not desc.is_empty():
			text += "\n[u]Machinery & Effect[/u]\n%s\n" % desc

		var b: int = 0
		var a: int = 0
		var f: int = 0
		var r: int = 0
		for t in item.module_data.cell_types.values():
			if t == PolyominoModuleData.CellType.BUMPER: b += 1
			elif t == PolyominoModuleData.CellType.ACCELERATOR: a += 1
			elif t == PolyominoModuleData.CellType.FUNNEL: f += 1
			elif t == PolyominoModuleData.CellType.ROTARY_BOOSTER: r += 1
		
		if b > 0 or a > 0 or f > 0 or r > 0:
			text += "\n[u]Components[/u]\n"
			if b > 0: text += "• Bumpers: %d\n" % b
			if a > 0: text += "• Accelerators: %d\n" % a
			if f > 0: text += "• Funnels: %d\n" % f
			if r > 0: text += "• Boosters: %d\n" % r
	lbl.text = text

var _sidebar_mode: bool = false

func integrate_into_sidebar(parent_container: Control) -> void:
	if parent_container == null:
		return
	_sidebar_mode = true
	var p: Node = get_parent()
	if p and p != parent_container:
		p.remove_child(self)
	if get_parent() != parent_container:
		parent_container.add_child(self)

	_apply_sidebar_layout()

func _apply_sidebar_layout() -> void:
	_sidebar_mode = true
	var p: PanelContainer = drawer_panel if drawer_panel else get_node_or_null("DrawerPanel") as PanelContainer
	var c_btn: Button = close_btn if close_btn else get_node_or_null("DrawerPanel/MarginContainer/VBoxContainer/HBoxTitle/CloseBtn") as Button
	var s_cont: ScrollContainer = scroll_container if scroll_container else get_node_or_null("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer") as ScrollContainer
	var hbox: BoxContainer = get_node_or_null("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent") as BoxContainer

	anchors_preset = Control.PRESET_FULL_RECT
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	if p:
		p.anchors_preset = Control.PRESET_FULL_RECT
		p.anchor_left = 0.0
		p.anchor_top = 0.0
		p.anchor_right = 1.0
		p.anchor_bottom = 1.0
		p.offset_left = 0
		p.offset_top = 0
		p.offset_right = 0
		p.offset_bottom = 0
		p.custom_minimum_size = Vector2(320, 720)

	if c_btn:
		c_btn.visible = false

	if hbox:
		hbox.vertical = true

	if s_cont:
		s_cont.custom_minimum_size = Vector2(290, 360)

	show()

func is_integrated_in_sidebar() -> bool:
	return _sidebar_mode

func get_pegboard_preview_scale() -> float:
	return 1.0
