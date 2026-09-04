extends Control
## Junk Box UI Drawer Panel.

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxGridView = preload("res://scenes/ui/junk_box/junk_box_grid_view.gd")
const JunkBoxDragController = preload("res://scenes/ui/junk_box/junk_box_drag_controller.gd")

const MARGIN_RIGHT_OVERFLOW: int = 2
const MARGIN_RIGHT_DEFAULT: int = 6

signal closed

var _game_coordinator: Node
var _reward_handler: Node
var drag_controller: Node = null

@onready var drawer_panel: PanelContainer = $DrawerPanel
@onready var grid_view: JunkBoxGridView = $DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer/JunkBoxGridView
@onready var scroll_container: ScrollContainer = $DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer
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
	if GameState and GameState.junk_box != null:
		drag_controller.junk_box_data = GameState.junk_box

func _exit_tree() -> void:
	if drag_controller != null and is_instance_valid(drag_controller):
		if drag_controller.get_parent() != self:
			drag_controller.queue_free()
		drag_controller = null

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
		if not grid_view.grid_size_changed.is_connected(update_scroll_bar_visibility):
			grid_view.grid_size_changed.connect(update_scroll_bar_visibility)
	if drawer_panel:
		drag_controller.junk_box_panel = drawer_panel
	if scroll_container:
		drag_controller.scroll_container = scroll_container
		if not scroll_container.resized.is_connected(_on_scroll_container_resized):
			scroll_container.resized.connect(_on_scroll_container_resized)



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
	KeywordDatabase.hide_flyout()
	show()
	if _sidebar_mode:
		_apply_sidebar_layout()

func _close() -> void:
	KeywordDatabase.hide_flyout()
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
	if item == null:
		KeywordDatabase.hide_flyout()
		return
	if drag_controller and drag_controller.dragging_item != null:
		KeywordDatabase.hide_flyout()
		return
	var title_str: String = item.display_name
	var body_str: String = _format_item_tooltip(item)
	var mouse_pos: Vector2 = Vector2.ZERO
	if is_inside_tree() and get_viewport():
		mouse_pos = get_global_mouse_position()
	KeywordDatabase.show_flyout_custom(title_str, body_str, mouse_pos)

func _on_item_unhovered() -> void:
	KeywordDatabase.hide_flyout()

func _update_tooltip(item: JunkBoxItem) -> void:
	if item != null:
		_on_item_hovered(item)
	else:
		_on_item_unhovered()

func _get_tooltip_lbl() -> RichTextLabel:
	return null

func _format_item_tooltip(item: JunkBoxItem) -> String:
	if item == null:
		return ""
	var text: String = ""
	var relic_id: StringName = &""
	if "custom_payload" in item and item.custom_payload is Dictionary:
		relic_id = StringName(item.custom_payload.get("relic_id", ""))
	if relic_id == &"" and item.module_data != null:
		relic_id = item.module_data.module_id

	if item.module_data != null or relic_id != &"":
		var act_req: String = ""
		if item.module_data != null and not item.module_data.activation_requirement.is_empty():
			act_req = item.module_data.activation_requirement
		elif relic_id != &"":
			act_req = PolyominoRelicDatabase.get_relic_activation_requirement(relic_id)
		if not act_req.is_empty():
			text += "[u]Activation Requirement[/u]\n%s" % act_req

		var rew_desc: String = ""
		if item.module_data != null and not item.module_data.reward_description.is_empty():
			rew_desc = item.module_data.reward_description
		elif relic_id != &"":
			rew_desc = PolyominoRelicDatabase.get_relic_reward_description(relic_id)
		if not rew_desc.is_empty():
			if not text.is_empty():
				text += "\n\n"
			text += "[u]Relic Effect[/u]\n%s" % rew_desc

	return text.strip_edges()

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
		p.custom_minimum_size = Vector2(304, 720)

	if c_btn:
		c_btn.visible = false

	if hbox and hbox is HBoxContainer:
		(hbox as HBoxContainer).vertical = true

	if s_cont:
		s_cont.size_flags_vertical = Control.SIZE_EXPAND_FILL
		s_cont.custom_minimum_size = Vector2(290, 200)

	show()

func is_integrated_in_sidebar() -> bool:
	return _sidebar_mode

func get_pegboard_preview_scale() -> float:
	return 1.0

func update_scroll_bar_visibility() -> void:
	var s_cont: ScrollContainer = scroll_container if scroll_container else get_node_or_null("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer") as ScrollContainer
	var g_view: JunkBoxGridView = grid_view if grid_view else get_node_or_null("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer/JunkBoxGridView") as JunkBoxGridView
	if s_cont == null or g_view == null:
		return

	var v_bar: VScrollBar = s_cont.get_v_scroll_bar()
	var content_height: float = g_view.custom_minimum_size.y
	var container_height: float = s_cont.size.y if s_cont.size.y > 0.0 else s_cont.custom_minimum_size.y

	if container_height > 0.0 and content_height <= container_height:
		s_cont.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		if v_bar:
			v_bar.visible = false
	else:
		s_cont.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		if v_bar:
			v_bar.visible = true

	_adjust_container_margins()

func _adjust_container_margins() -> void:
	var s_cont: ScrollContainer = scroll_container if scroll_container else get_node_or_null("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer") as ScrollContainer
	var g_view: JunkBoxGridView = grid_view if grid_view else get_node_or_null("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer/JunkBoxGridView") as JunkBoxGridView
	if s_cont == null:
		return
	var margin_cont: MarginContainer = get_node_or_null("DrawerPanel/MarginContainer") as MarginContainer
	if margin_cont == null:
		return

	var v_bar: VScrollBar = s_cont.get_v_scroll_bar()
	var container_height: float = s_cont.size.y if s_cont.size.y > 0.0 else s_cont.custom_minimum_size.y
	var is_overflowing: bool = false
	if g_view != null and container_height > 0.0:
		is_overflowing = g_view.custom_minimum_size.y > container_height
	if v_bar != null and v_bar.visible:
		is_overflowing = true

	if is_overflowing:
		margin_cont.add_theme_constant_override("margin_right", MARGIN_RIGHT_OVERFLOW)
	else:
		margin_cont.add_theme_constant_override("margin_right", MARGIN_RIGHT_DEFAULT)


func _on_scroll_container_resized() -> void:
	if grid_view:
		grid_view.update_grid_size()


