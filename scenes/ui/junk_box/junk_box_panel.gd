extends Control
## Junk Box UI Panel.

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxGridView = preload("res://scenes/ui/junk_box/junk_box_grid_view.gd")

signal closed

var _game_coordinator: Node
var _reward_handler: Node
var _paused_before_open: bool = false

@onready var grid_view: JunkBoxGridView = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer/JunkBoxGridView
@onready var scroll_container: ScrollContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer
@onready var tooltip_lbl: RichTextLabel = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContent/VBoxInfo/TooltipLabel
@onready var close_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxTitle/CloseBtn
@onready var sort_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxTitle/SortBtn
@onready var dim_rect: ColorRect = $DimRect

func _ready() -> void:
	hide()
	grid_view.item_hovered.connect(_on_item_hovered)
	grid_view.item_unhovered.connect(_on_item_unhovered)
	close_btn.pressed.connect(_close)
	sort_btn.pressed.connect(_on_sort_pressed)
	dim_rect.gui_input.connect(_on_dim_input)

func setup(coordinator: Node, reward_handler: Node) -> void:
	_game_coordinator = coordinator
	_reward_handler = reward_handler

func toggle() -> void:
	if visible:
		_close()
	else:
		_open()

func _open() -> void:
	_paused_before_open = GameState.paused
	if not _paused_before_open:
		GameState.paused = true
	_update_tooltip(null)
	show()

func _close() -> void:
	hide()
	if not _paused_before_open:
		GameState.paused = false
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
		tooltip_lbl.text = "Hover an item to see details."
		return
	
	var text: String = "[b]%s[/b]\n" % item.display_name
	if item.module_data != null:
		text += "Tier: %d\n" % item.module_data.tier
		text += "Size: %d Cells\n" % item.module_data.get_cell_count()
		
		var b: int = 0
		var a: int = 0
		var f: int = 0
		for t in item.module_data.cell_types.values():
			if t == PolyominoModuleData.CellType.BUMPER: b += 1
			elif t == PolyominoModuleData.CellType.ACCELERATOR: a += 1
			elif t == PolyominoModuleData.CellType.FUNNEL: f += 1
		
		if b > 0 or a > 0 or f > 0:
			text += "\n[u]Kinetic Features[/u]\n"
			if b > 0: text += "- Bumpers: %d\n" % b
			if a > 0: text += "- Accelerators: %d\n" % a
			if f > 0: text += "- Funnels: %d\n" % f
	tooltip_lbl.text = text

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_close()
