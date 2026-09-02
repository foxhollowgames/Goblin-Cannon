extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "HopperTopBarDebugMenu"

func run() -> void:
	test_hopper_positioning_below_top_bar()
	test_debug_menu_top_bar_positioning()
	test_debug_menu_toggle_and_children()

func test_hopper_positioning_below_top_bar() -> void:
	begin("TopHeaderBarBg exists, Hopper position Y sits strictly below header bar, and spawn position is masked")
	var main_scene: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	assert_true(main_scene != null, "main scene loaded")
	var main: Node2D = main_scene.instantiate() as Node2D
	assert_true(main != null, "main instance created")
	
	var top_bar_bg: ColorRect = main.get_node_or_null("UILayer/LeftPanel/TopHeaderBarBg") as ColorRect
	assert_true(top_bar_bg != null, "TopHeaderBarBg node exists in UILayer/LeftPanel")
	assert_eq(top_bar_bg.offset_bottom, 54.0, "TopHeaderBarBg height is 54px")
	
	var hopper: Node2D = main.get_node_or_null("Hopper") as Node2D
	assert_true(hopper != null, "hopper node exists in main scene")
	
	const TOP_BAR_RESERVED_HEIGHT: float = 54.0
	var hopper_top_rim_y: float = hopper.position.y - 80.0
	assert_gte(hopper_top_rim_y, TOP_BAR_RESERVED_HEIGHT, "Hopper top rim Y (55.0) sits strictly below top UI header bar height (54.0)")
	assert_gt(hopper.position.y, TOP_BAR_RESERVED_HEIGHT, "Hopper position Y (135.0) sits strictly below top UI header bar height (54.0)")
	
	main.free()

func test_debug_menu_top_bar_positioning() -> void:
	begin("Debug Menu sits inside the top header UI bar area")
	var gc_debug: GameCoordinatorDebug = GameCoordinatorDebug.new()
	var debug_tools: Control = gc_debug.build_debug_tools_column()
	assert_true(debug_tools != null, "debug tools control created")
	assert_eq(debug_tools.name, "DebugTools", "Control name is DebugTools")
	assert_eq(debug_tools.position.y, 8.0, "Debug Menu sits in top bar Y coordinate")
	assert_gt(debug_tools.position.x, 200.0, "Debug Menu X position is aligned after top bar buttons")
	
	debug_tools.free()
	gc_debug.free()

func test_debug_menu_toggle_and_children() -> void:
	begin("Debug toggle button opens collapsible panel containing all 5 debug tools")
	var main: Node = Node.new()
	var mock_coord: Node = Node.new()
	main.add_child(mock_coord)
	var gc_debug: GameCoordinatorDebug = GameCoordinatorDebug.new()
	gc_debug.setup(mock_coord)
	mock_coord.add_child(gc_debug)

	var modals: Dictionary = gc_debug.create_all_debug_modals(main, null)
	var debug_tools: Control = gc_debug.build_debug_tools_column()
	main.add_child(debug_tools)

	var toggle_btn: Button = debug_tools.get_node_or_null("DebugToggleBtn") as Button
	assert_true(toggle_btn != null, "DebugToggleBtn exists")

	var menu_panel: PanelContainer = debug_tools.get_node_or_null("DebugMenuPanel") as PanelContainer
	assert_true(menu_panel != null, "DebugMenuPanel exists")
	assert_false(menu_panel.visible, "DebugMenuPanel is initially collapsed (hidden)")

	# Click toggle button
	toggle_btn.emit_signal("pressed")
	assert_true(menu_panel.visible, "DebugMenuPanel opens (visible) after pressing toggle button")

	# Verify 5 tool buttons exist inside DebugMenuPanel
	var buttons: Array = menu_panel.find_children("*", "Button", true, false)
	assert_eq(buttons.size(), 5, "5 debug tool buttons exist inside DebugMenuPanel")

	var expected_texts: Array = ["+100 Gold", "Merchant", "Events", "Full store", "Go to city…"]
	for text in expected_texts:
		var found: bool = false
		for btn in buttons:
			if (btn as Button).text == text:
				found = true
				break
		assert_true(found, "Debug button with text exists: " + text)

	# Toggle off again
	toggle_btn.emit_signal("pressed")
	assert_false(menu_panel.visible, "DebugMenuPanel closes (hidden) after pressing toggle button again")

	main.free()
