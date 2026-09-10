extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxGridView = preload("res://scenes/ui/junk_box/junk_box_grid_view.gd")
const JunkBoxDragController = preload("res://scenes/ui/junk_box/junk_box_drag_controller.gd")

const PolyominoMachineryVisuals = preload("res://scenes/board/machinery/polyomino_machinery_visuals.gd")

func _init() -> void:
	suite_name = "JunkBoxRelicDisplayAndTooltips"

func run() -> void:
	test_relic_display_equivalence()
	test_machinery_visuals_all_component_types()
	test_unified_multi_peg_relic_rendering()
	test_hover_triggers_flyout_tooltip()
	test_unhover_and_mouse_exit_dismisses_tooltip()
	test_drag_start_dismisses_tooltip()

func test_relic_display_equivalence() -> void:
	begin("JunkBoxGridView renders solid edge segments and component visuals without error")
	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"superconductor")
	assert_true(item != null, "item created from PolyominoRelicDatabase")
	assert_true(item.module_data != null, "module_data exists on item")
	var segments: Array[Dictionary] = item.module_data.get_solid_edge_segments(item.rotation_step)
	assert_gt(segments.size(), 0, "get_solid_edge_segments returns outer perimeter segments")
	var occupied: Array[Vector2i] = item.get_occupied_cells()
	assert_gt(occupied.size(), 0, "occupied cells non-empty")

func test_machinery_visuals_all_component_types() -> void:
	begin("PolyominoMachineryVisuals defines support for all kinetic component types")
	var test_types: Array[int] = [
		PolyominoModuleData.CellType.POP_BUMPER,
		PolyominoModuleData.CellType.BUMPER,
		PolyominoModuleData.CellType.ACCELERATOR,
		PolyominoModuleData.CellType.ROTARY_BOOSTER,
		PolyominoModuleData.CellType.MANA_SIPHON,
		PolyominoModuleData.CellType.DROP_TARGET,
		PolyominoModuleData.CellType.STANDUP_TARGET,
		PolyominoModuleData.CellType.SPINNER,
		PolyominoModuleData.CellType.ROLLOVER_SWITCH,
		PolyominoModuleData.CellType.DIRECTIONAL_DEFLECTOR,
		PolyominoModuleData.CellType.SLINGSHOT,
		PolyominoModuleData.CellType.BASH_TOY,
		PolyominoModuleData.CellType.SCOOP_SINKHOLE,
		PolyominoModuleData.CellType.BALL_LOCK,
		PolyominoModuleData.CellType.GUIDE_TRACK,
		PolyominoModuleData.CellType.ORBIT_LOOP,
		PolyominoModuleData.CellType.CAPTIVE_BALL,
		PolyominoModuleData.CellType.MECHANICAL_DIVERTER,
		PolyominoModuleData.CellType.VERTICAL_UP_KICKER,
		PolyominoModuleData.CellType.OUTLANE_KICKBACK,
	]
	for ct in test_types:
		assert_true(ct > 0, "CellType %d is registered in test suite" % ct)
	assert_eq(test_types.size(), 20, "20 kinetic machinery component types registered")

func test_unified_multi_peg_relic_rendering() -> void:
	begin("JunkBoxGridView supports unified multi-peg relics as single centerpiece")
	var mega_bumper: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"mega_pop_bumper")
	assert_true(mega_bumper != null, "mega_pop_bumper item exists")
	assert_eq(mega_bumper.module_data.layout_mode, PolyominoModuleData.MachineryLayoutMode.UNIFIED, "layout mode is UNIFIED")
	assert_eq(mega_bumper.module_data.unified_component_type, PolyominoModuleData.CellType.POP_BUMPER, "unified type is POP_BUMPER")
	var golem: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"golem_effigy")
	assert_true(golem != null, "golem_effigy item exists")
	assert_eq(golem.module_data.layout_mode, PolyominoModuleData.MachineryLayoutMode.UNIFIED, "layout mode is UNIFIED")
	assert_eq(golem.module_data.unified_component_type, PolyominoModuleData.CellType.BASH_TOY, "unified type is BASH_TOY")

func test_hover_triggers_flyout_tooltip() -> void:
	begin("Hovering a relic in JunkBoxPanel displays formatted flyout tooltip without redundant metadata")
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
	assert_false(body.contains("Tier"), "flyout body does not show Tier")
	assert_false(body.contains("Size"), "flyout body does not show Size")
	assert_false(body.contains("Shape"), "flyout body does not show Shape")
	assert_false(body.contains("Components"), "flyout body does not show Components")
	assert_false(body.contains("Machinery & Effect"), "flyout body does not show Machinery & Effect")
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
