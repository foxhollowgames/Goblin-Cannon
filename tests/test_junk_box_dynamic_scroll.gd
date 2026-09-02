extends "res://tests/test_base.gd"

const JunkBoxPanelScene = preload("res://scenes/ui/junk_box/junk_box_panel.tscn")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxGridView = preload("res://scenes/ui/junk_box/junk_box_grid_view.gd")

func _init() -> void:
	suite_name = "JunkBoxDynamicScroll"

func run() -> void:
	test_scroll_bar_hidden_when_empty()
	test_scroll_bar_shown_when_overflowing()
	test_container_margin_adjustment()
	test_item_removal_hides_scroll_bar()

func test_scroll_bar_hidden_when_empty() -> void:
	begin("Scroll bar is hidden when items fit inside view panel")
	GameState.junk_box = JunkBoxData.new()
	var panel = JunkBoxPanelScene.instantiate()
	autofree(panel)

	panel._apply_sidebar_layout()
	var scroll_cont: ScrollContainer = panel.get_node("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer")
	var grid_view: JunkBoxGridView = panel.get_node("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer/JunkBoxGridView")
	scroll_cont.custom_minimum_size = Vector2(290, 300)
	grid_view.update_grid_size()
	panel.update_scroll_bar_visibility()

	var v_bar: VScrollBar = scroll_cont.get_v_scroll_bar()
	assert_eq(scroll_cont.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED, "ScrollContainer vertical scroll mode is disabled when empty")
	if v_bar:
		assert_true(not v_bar.visible, "VScrollBar is not visible when empty")

func test_scroll_bar_shown_when_overflowing() -> void:
	begin("Scroll bar is shown when items extend past visible container area")
	GameState.junk_box = JunkBoxData.new()
	var panel = JunkBoxPanelScene.instantiate()
	autofree(panel)

	panel._apply_sidebar_layout()
	var scroll_cont: ScrollContainer = panel.get_node("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer")
	var grid_view: JunkBoxGridView = panel.get_node("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer/JunkBoxGridView")
	scroll_cont.custom_minimum_size = Vector2(290, 300)

	var mod_data = PolyominoModuleData.new()
	mod_data.tier = 1
	var c_list: Array[Vector2i] = [Vector2i.ZERO]
	mod_data.cells = c_list
	var item = JunkBoxItem.new(&"test_relic_15")
	item.module_data = mod_data
	var placed: bool = GameState.junk_box.place_item(item, Vector2i(0, 15))
	assert_true(placed, "Item placed successfully at row 15")

	grid_view.update_grid_size()
	panel.update_scroll_bar_visibility()

	var v_bar: VScrollBar = scroll_cont.get_v_scroll_bar()
	assert_eq(scroll_cont.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_AUTO, "ScrollContainer vertical scroll mode is auto when overflowing")
	if v_bar:
		assert_true(v_bar.visible, "VScrollBar is visible when items overflow")

func test_container_margin_adjustment() -> void:
	begin("Container margin_right is dynamically adjusted for scroll bar toggle")
	GameState.junk_box = JunkBoxData.new()
	var panel = JunkBoxPanelScene.instantiate()
	autofree(panel)

	panel._apply_sidebar_layout()
	var scroll_cont: ScrollContainer = panel.get_node("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer")
	var grid_view: JunkBoxGridView = panel.get_node("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer/JunkBoxGridView")
	scroll_cont.custom_minimum_size = Vector2(290, 300)

	grid_view.update_grid_size()
	panel.update_scroll_bar_visibility()

	var margin_cont: MarginContainer = panel.get_node("DrawerPanel/MarginContainer")
	var margin_empty: int = margin_cont.get_theme_constant("margin_right")
	assert_eq(margin_empty, 6, "MarginContainer margin_right is 6 when scroll bar is hidden")

	var mod_data = PolyominoModuleData.new()
	mod_data.tier = 1
	var c_list: Array[Vector2i] = [Vector2i.ZERO]
	mod_data.cells = c_list
	var item = JunkBoxItem.new(&"test_relic_20")
	item.module_data = mod_data
	GameState.junk_box.place_item(item, Vector2i(0, 20))

	grid_view.update_grid_size()
	panel.update_scroll_bar_visibility()
	var margin_overflow: int = margin_cont.get_theme_constant("margin_right")
	assert_eq(margin_overflow, 2, "MarginContainer margin_right is 2 when scroll bar is visible")

func test_item_removal_hides_scroll_bar() -> void:
	begin("Removing overflowing items hides the scroll bar automatically")
	GameState.junk_box = JunkBoxData.new()
	var panel = JunkBoxPanelScene.instantiate()
	autofree(panel)

	panel._apply_sidebar_layout()
	var scroll_cont: ScrollContainer = panel.get_node("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer")
	var grid_view: JunkBoxGridView = panel.get_node("DrawerPanel/MarginContainer/VBoxContainer/HBoxContent/ScrollContainer/JunkBoxGridView")
	scroll_cont.custom_minimum_size = Vector2(290, 300)

	var mod_data = PolyominoModuleData.new()
	mod_data.tier = 1
	var c_list: Array[Vector2i] = [Vector2i.ZERO]
	mod_data.cells = c_list
	var item = JunkBoxItem.new(&"removable_item")
	item.module_data = mod_data
	GameState.junk_box.place_item(item, Vector2i(0, 25))

	grid_view.update_grid_size()
	panel.update_scroll_bar_visibility()
	assert_eq(scroll_cont.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_AUTO, "Scroll bar is active when item overflows")

	GameState.junk_box.remove_item(&"removable_item")
	grid_view.update_grid_size()
	panel.update_scroll_bar_visibility()
	assert_eq(scroll_cont.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED, "Scroll bar is disabled after removing overflowing item")
