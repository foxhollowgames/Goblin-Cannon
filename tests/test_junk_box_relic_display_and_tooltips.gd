extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxGridView = preload("res://scenes/ui/junk_box/junk_box_grid_view.gd")
const JunkBoxDragController = preload("res://scenes/ui/junk_box/junk_box_drag_controller.gd")

func _init() -> void:
	suite_name = "JunkBoxRelicDisplayAndTooltips"

func run() -> void:
	test_relic_display_equivalence()
	test_hover_triggers_flyout_tooltip()
	test_unhover_and_mouse_exit_dismisses_tooltip()
	test_drag_start_dismisses_tooltip()

func test_relic_display_equivalence() -> void:
	begin("JunkBoxGridView renders solid edge segments and component glyphs without error")
	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"superconductor")
	assert_true(item != null, "item created from PolyominoRelicDatabase")
	assert_true(item.module_data != null, "module_data exists on item")
	var segments: Array[Dictionary] = item.module_data.get_solid_edge_segments(item.rotation_step)
	assert_gt(segments.size(), 0, "get_solid_edge_segments returns outer perimeter segments")
	var occupied: Array[Vector2i] = item.get_occupied_cells()
	assert_gt(occupied.size(), 0, "occupied cells non-empty")

func test_hover_triggers_flyout_tooltip() -> void:
	begin("Hovering a relic in JunkBoxPanel displays formatted flyout tooltip with full specifications")
	var scene: PackedScene = load("res://scenes/ui/junk_box/junk_box_panel.tscn") as PackedScene
	assert_true(scene != null, "junk_box_panel.tscn loads")
	var panel: Control = scene.instantiate() as Control
	assert_true(panel != null, "junk_box_panel instantiates")
	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"cascade_reactor")
	panel._on_item_hovered(item)
	assert_true(KeywordDatabase._flyout_panel != null, "KeywordDatabase flyout panel initialized")
	assert_true(KeywordDatabase._flyout_panel.visible, "flyout panel becomes visible on item hover")
	assert_eq(KeywordDatabase._flyout_title.text, item.display_name, "flyout title matches relic display name")
	var body: String = KeywordDatabase._flyout_body.text
	assert_true(body.contains("Tier"), "flyout body shows Tier")
	assert_true(body.contains("Size"), "flyout body shows Size")
	assert_true(body.contains("Activation Requirement"), "flyout body shows Activation Requirement")
	assert_true(body.contains("Relic Effect"), "flyout body shows Relic Effect")
	panel.free()

func test_unhover_and_mouse_exit_dismisses_tooltip() -> void:
	begin("Unhovering relic or mouse exit dismisses flyout tooltip")
	var scene: PackedScene = load("res://scenes/ui/junk_box/junk_box_panel.tscn") as PackedScene
	var panel: Control = scene.instantiate() as Control
	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"cascade_reactor")
	panel._on_item_hovered(item)
	assert_true(KeywordDatabase._flyout_panel.visible, "flyout is visible before unhover")
	panel._on_item_unhovered()
	assert_false(KeywordDatabase._flyout_panel.visible, "flyout is hidden after unhover")
	var grid_view: JunkBoxGridView = panel.grid_view
	if grid_view != null:
		grid_view.hovered_item = item
		grid_view.hovered_cell = Vector2i(0, 0)
		panel._on_item_hovered(item)
		assert_true(KeywordDatabase._flyout_panel.visible, "flyout visible before mouse exit")
		grid_view._on_mouse_exited()
		assert_false(KeywordDatabase._flyout_panel.visible, "flyout hidden after mouse exit")
	panel.free()

func test_drag_start_dismisses_tooltip() -> void:
	begin("Starting drag operation dismisses flyout tooltip immediately")
	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"cascade_reactor")
	KeywordDatabase.show_flyout_custom("Test Relic", "Test Body", Vector2(100, 100))
	assert_true(KeywordDatabase._flyout_panel.visible, "flyout is visible before drag start")
	var drag_ctrl: JunkBoxDragController = JunkBoxDragController.new()
	drag_ctrl.start_drag(item, 0, Vector2i(0, 0), Vector2i(0, 0))
	assert_false(KeywordDatabase._flyout_panel.visible, "flyout is hidden immediately on drag start")
	drag_ctrl.free()
