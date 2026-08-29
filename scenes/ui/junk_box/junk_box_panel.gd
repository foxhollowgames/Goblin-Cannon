extends Control
## Junk Box UI Drawer Panel.

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
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

func _ready() -> void:
	hide()
	drag_controller = JunkBoxDragController.new()
	drag_controller.name = "JunkBoxDragController"
	add_child(drag_controller)
	drag_controller.junk_box_grid_view = grid_view
	drag_controller.junk_box_panel = drawer_panel
	drag_controller.scroll_container = scroll_container
	grid_view.drag_controller = drag_controller

	grid_view.item_hovered.connect(_on_item_hovered)
	grid_view.item_unhovered.connect(_on_item_unhovered)
	close_btn.pressed.connect(_close)
	sort_btn.pressed.connect(_on_sort_pressed)

func setup(coordinator: Node, reward_handler: Node) -> void:
	_game_coordinator = coordinator
	_reward_handler = reward_handler
	if coordinator:
		var b: Node = coordinator.get("board") if "board" in coordinator else coordinator.get("_board")
		if b:
			set_board(b)

func set_board(p_board: Node) -> void:
	if drag_controller:
		drag_controller.board = p_board
	if p_board and p_board.has_method("set_drag_controller"):
		p_board.set_drag_controller(drag_controller)

func toggle() -> void:
	if visible:
		_close()
	else:
		_open()

func _open() -> void:
	_update_tooltip(null)
	show()

func _close() -> void:
	hide()
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			_close()
			get_viewport().set_input_as_handled()

func _on_sort_pressed() -> void:
	if GameState.junk_box != null:
		GameState.junk_box.auto_pack()

func _on_item_hovered(item: JunkBoxItem) -> void:
	_update_tooltip(item)

func _on_item_unhovered() -> void:
	_update_tooltip(null)

func _update_tooltip(item: JunkBoxItem) -> void:
	if item == null:
		tooltip_lbl.text = "[color=#cfbba8]Hover an item in the box to inspect details.[/color]"
		return
	
	var text: String = "[b][color=#f4d06f]%s[/color][/b]\n" % item.display_name
	if item.module_data != null:
		text += "Tier: [b]%d[/b]\n" % item.module_data.tier
		text += "Size: [b]%d[/b] Cells\n" % item.module_data.get_cell_count()
		
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
			text += "\n[u]Kinetic Machinery[/u]\n"
			if b > 0: text += "• Bumpers: %d\n" % b
			if a > 0: text += "• Accelerators: %d\n" % a
			if f > 0: text += "• Funnels: %d\n" % f
			if r > 0: text += "• Boosters: %d\n" % r
	tooltip_lbl.text = text
