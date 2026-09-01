extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "UIButtonAudit"

func run() -> void:
	test_almanac_button_wireup()
	test_bag_button_wireup()
	test_debug_tools_column_wireup()
	test_reward_draft_panel_buttons()
	test_major_upgrade_draft_panel_buttons()
	test_inventory_panel_buttons()
	test_almanac_panel_buttons()
	test_junk_box_panel_buttons()
	test_debug_modals_buttons()

func test_almanac_button_wireup() -> void:
	begin("Almanac button has pressed signal connected and triggers callback")
	var res: Array = [false]
	var cb: Callable = func() -> void: res[0] = true
	var btn: Button = GameCoordinatorUI.build_almanac_button(cb)
	assert_true(btn != null, "button created")
	assert_true(btn.pressed.is_connected(cb), "pressed signal connected")
	btn.emit_signal("pressed")
	assert_true(res[0], "callback executed on press")
	btn.free()

func test_bag_button_wireup() -> void:
	begin("Bag button has pressed signal connected and triggers callback")
	var res: Array = [false]
	var cb: Callable = func() -> void: res[0] = true
	var btn: Button = GameCoordinatorUI.build_bag_button(cb)
	assert_true(btn != null, "button created")
	assert_true(btn.pressed.is_connected(cb), "pressed signal connected")
	btn.emit_signal("pressed")
	assert_true(res[0], "callback executed on press")
	btn.free()

func test_debug_tools_column_wireup() -> void:
	begin("All 5 debug tool buttons in debug column have connected pressed handlers and open corresponding modals")
	var main: Node = Node.new()
	var mock_coord: Node = Node.new()
	main.add_child(mock_coord)
	var gc_debug: GameCoordinatorDebug = GameCoordinatorDebug.new()
	gc_debug.setup(mock_coord)
	mock_coord.add_child(gc_debug)

	var modals: Dictionary = gc_debug.create_all_debug_modals(main, null)
	assert_true(modals.has("event_spawn_modal"), "event spawn modal created")
	assert_true(modals.has("full_store_modal"), "full store modal created")
	assert_true(modals.has("city_jump_modal"), "city jump modal created")

	var col: Control = gc_debug.build_debug_tools_column()
	assert_true(col != null, "debug tools column created")
	var buttons: Array = col.get_children()
	assert_eq(buttons.size(), 5, "5 debug buttons created")
	for child in buttons:
		var btn: Button = child as Button
		assert_true(btn != null, "child is Button: " + str(child.name))
		assert_true(btn.pressed.get_connections().size() > 0, "button has connected pressed signal: " + str(btn.text))
		if btn.text == "+100 Gold":
			btn.emit_signal("pressed")
		elif btn.text == "Events":
			btn.emit_signal("pressed")
			var m: Control = modals.get("event_spawn_modal", null) as Control
			assert_true(m != null and m.visible, "Events modal is visible after click")
		elif btn.text == "Full store":
			btn.emit_signal("pressed")
			var m: Control = modals.get("full_store_modal", null) as Control
			assert_true(m != null and m.visible, "Full store modal is visible after click")
		elif btn.text == "Go to city…":
			btn.emit_signal("pressed")
			var m: Control = modals.get("city_jump_modal", null) as Control
			assert_true(m != null and m.visible, "City jump modal is visible after click")
		elif btn.text == "Merchant":
			btn.emit_signal("pressed")

	col.free()
	gc_debug.free()
	mock_coord.free()
	main.free()

func test_reward_draft_panel_buttons() -> void:
	begin("RewardDraftPanel buttons (Done, Refresh, ShowRewards) are wired and connected")
	var panel_scene: PackedScene = load("res://scenes/rewards/reward_draft_panel.tscn") as PackedScene
	assert_true(panel_scene != null, "panel scene loaded")
	var panel: Control = panel_scene.instantiate() as Control
	panel._ready()
	var done_btn: Button = panel.get("_done_btn")
	assert_true(done_btn != null, "done button exists")
	assert_true(done_btn.pressed.get_connections().size() > 0, "done button connected")
	var refresh_btn: Button = panel.get("_refresh_btn")
	assert_true(refresh_btn != null, "refresh button exists")
	assert_true(refresh_btn.pressed.get_connections().size() > 0, "refresh button connected")
	var show_btn: Button = panel.get("_show_rewards_btn")
	assert_true(show_btn != null, "show rewards button exists")
	assert_true(show_btn.pressed.get_connections().size() > 0, "show rewards button connected")
	panel.free()

func test_major_upgrade_draft_panel_buttons() -> void:
	begin("MajorUpgradeDraftPanel buttons (Skip, ShowRewards) are wired and connected")
	var panel_scene: PackedScene = load("res://scenes/rewards/major_upgrade_draft_panel.tscn") as PackedScene
	assert_true(panel_scene != null, "major panel scene loaded")
	var panel: Control = panel_scene.instantiate() as Control
	panel._ready()
	var skip_btn: Button = panel.get("_skip_btn")
	assert_true(skip_btn != null, "skip button exists")
	assert_true(skip_btn.pressed.get_connections().size() > 0, "skip button connected")
	var show_btn: Button = panel.get("_show_rewards_btn")
	assert_true(show_btn != null, "show rewards button exists")
	assert_true(show_btn.pressed.get_connections().size() > 0, "show rewards button connected")
	panel.free()

func test_inventory_panel_buttons() -> void:
	begin("InventoryPanel close button is wired and connected")
	var panel_scene: PackedScene = load("res://scenes/ui/inventory_panel.tscn") as PackedScene
	assert_true(panel_scene != null, "inventory panel scene loaded")
	var panel: Control = panel_scene.instantiate() as Control
	panel.call("_open")
	var close_btn: Button = _find_button_by_name(panel, "CloseBtn")
	assert_true(close_btn != null, "close button exists")
	assert_true(close_btn.pressed.get_connections().size() > 0, "close button connected")
	panel.free()

func test_almanac_panel_buttons() -> void:
	begin("AlmanacPanel close button is wired and connected")
	var panel_scene: PackedScene = load("res://scenes/ui/almanac_panel.tscn") as PackedScene
	assert_true(panel_scene != null, "almanac panel scene loaded")
	var panel: Control = panel_scene.instantiate() as Control
	panel.call("_open")
	var close_btn: Button = _find_button_by_name(panel, "CloseBtn")
	assert_true(close_btn != null, "close button exists")
	assert_true(close_btn.pressed.get_connections().size() > 0, "close button connected")
	panel.free()

func test_junk_box_panel_buttons() -> void:
	begin("JunkBoxPanel close and sort buttons are wired and connected")
	var panel_scene: PackedScene = load("res://scenes/ui/junk_box/junk_box_panel.tscn") as PackedScene
	assert_true(panel_scene != null, "junk box panel scene loaded")
	var panel: Control = panel_scene.instantiate() as Control
	panel._ready()
	var close_btn: Button = _find_button_by_name(panel, "CloseBtn")
	assert_true(close_btn != null, "close button exists")
	assert_true(close_btn.pressed.get_connections().size() > 0, "close button connected")
	var sort_btn: Button = _find_button_by_name(panel, "SortBtn")
	assert_true(sort_btn != null, "sort button exists")
	assert_true(sort_btn.pressed.get_connections().size() > 0, "sort button connected")
	panel.free()

func test_debug_modals_buttons() -> void:
	begin("Debug modals (event, store, city jump) have wired close buttons")
	var event_script: Script = load("res://scenes/ui/debug_event_spawn_modal.gd") as Script
	if event_script:
		var modal: Control = event_script.new() as Control
		if modal.has_method("setup"):
			modal.setup(null)
		var close_btn: Button = _find_button_by_name(modal, "Close")
		assert_true(close_btn != null and close_btn.pressed.get_connections().size() > 0, "event spawn modal close button connected")
		modal.free()

	var store_script: Script = load("res://scenes/ui/debug_full_store_modal.gd") as Script
	if store_script:
		var modal: Control = store_script.new() as Control
		if modal.has_method("setup"):
			modal.setup(null, null)
		var close_btn: Button = _find_button_by_name(modal, "Close")
		assert_true(close_btn != null and close_btn.pressed.get_connections().size() > 0, "full store modal close button connected")
		modal.free()

	var city_script: Script = load("res://scenes/ui/debug_city_jump_modal.gd") as Script
	if city_script:
		var modal: Control = city_script.new() as Control
		if modal.has_method("setup"):
			modal.setup(null)
		var close_btn: Button = _find_button_by_name(modal, "Close")
		assert_true(close_btn != null and close_btn.pressed.get_connections().size() > 0, "city jump modal close button connected")
		modal.free()

func _find_button_by_name(node: Node, key: String) -> Button:
	if node is Button and (node.name == key or node.text == key):
		return node as Button
	for child in node.get_children():
		var res: Button = _find_button_by_name(child, key)
		if res != null:
			return res
	return null
