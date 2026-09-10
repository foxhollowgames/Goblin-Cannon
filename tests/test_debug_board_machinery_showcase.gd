extends "res://tests/test_base.gd"

const BoardScript = preload("res://scenes/board/board.gd")
const BoardMachineryShowcase = preload("res://scenes/board/machinery/board_machinery_showcase.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const GameCoordinatorDebug = preload("res://scenes/main/game_coordinator_debug.gd")

func _init() -> void:
	suite_name = "DebugBoardMachineryShowcase"

func run() -> void:
	test_showcase_definitions_catalog()
	test_showcase_board_grid_no_overlap()
	test_showcase_board_population_and_components()
	test_showcase_item_tooltip_formatting()
	test_campaign_relic_tooltip_regression()
	test_debug_menu_button_present()

func test_showcase_definitions_catalog() -> void:
	begin("BoardMachineryShowcase defines complete catalog of machinery permutations")
	var defs: Array[Dictionary] = BoardMachineryShowcase.get_all_showcase_definitions()
	assert_gt(defs.size(), 20, "Catalog has at least 20 machinery definitions")
	assert_eq(defs.size(), 31, "Catalog has exactly 31 machinery permutations and sizes")

	for def in defs:
		assert_true(def.has("id"), "Definition has 'id'")
		assert_true(def.has("name"), "Definition has 'name'")
		assert_true(def.has("grid_pos"), "Definition has 'grid_pos'")
		assert_true(def.has("cells"), "Definition has 'cells'")
		assert_true(def.has("category"), "Definition has 'category'")
		assert_true(def.has("behavior"), "Definition has 'behavior'")
		assert_true(def.has("stats"), "Definition has 'stats'")
		var stats: Dictionary = def["stats"]
		assert_true(stats.has("Classification"), "Stats has 'Classification'")
		assert_true(stats.has("Footprint"), "Stats has 'Footprint'")
		assert_true(stats.has("Energy"), "Stats has 'Energy'")
		assert_true(stats.has("Impulse"), "Stats has 'Impulse'")

func test_showcase_board_grid_no_overlap() -> void:
	begin("All showcase items fit on 15x8 board grid without cell overlaps")
	var defs: Array[Dictionary] = BoardMachineryShowcase.get_all_showcase_definitions()
	var occupied_cells: Dictionary = {}

	for def in defs:
		var grid_pos: Vector2i = def["grid_pos"]
		var raw_cells: Array = def["cells"]
		for c in raw_cells:
			var cell: Vector2i = grid_pos + c
			assert_true(cell.x >= 0 and cell.x < 15, "Cell X %d within bounds [0..14]" % cell.x)
			assert_true(cell.y >= 0 and cell.y < 8, "Cell Y %d within bounds [0..7]" % cell.y)
			assert_false(occupied_cells.has(cell), "Cell %s not previously occupied (no overlap with %s)" % [str(cell), str(occupied_cells.get(cell, ""))])
			occupied_cells[cell] = str(def["id"])

func test_showcase_board_population_and_components() -> void:
	begin("Board.setup_machinery_showcase places all items and instantiates nodes")
	var board: Node = BoardScript.new()
	var placed_count: int = board.setup_machinery_showcase()
	assert_eq(placed_count, 31, "All 31 showcase items successfully placed on board")

	var all_placed: Array = board.get_all_placed_modules()
	assert_eq(all_placed.size(), 31, "Board reports 31 placed modules")

	var giga_item = board.get_module_at_cell(Vector2i(0, 0))
	assert_true(giga_item != null, "Giga Pop Bumper placed at (0,0)")
	assert_eq(giga_item.display_name, "Giga Pop Bumper (3x3)", "Giga Pop Bumper title matches")

	var mega_item = board.get_module_at_cell(Vector2i(3, 0))
	assert_true(mega_item != null, "Mega Pop Bumper placed at (3,0)")

	var maw_item = board.get_module_at_cell(Vector2i(3, 2))
	assert_true(maw_item != null, "Abyssal Maw placed at (3,2)")

	var golem_item = board.get_module_at_cell(Vector2i(0, 3))
	assert_true(golem_item != null, "Golem Effigy placed at (0,3)")

	var slingshot_item = board.get_module_at_cell(Vector2i(0, 5))
	assert_true(slingshot_item != null, "Corner Slingshot placed at (0,5)")

	board.clear_all_placed_modules()
	board.free()

func test_showcase_item_tooltip_formatting() -> void:
	begin("Board._format_module_tooltip_body includes behavior and stats for showcase items")
	var board: Node = BoardScript.new()
	var defs: Array[Dictionary] = BoardMachineryShowcase.get_all_showcase_definitions()
	var item: JunkBoxItem = BoardMachineryShowcase.create_showcase_item(defs[0])

	var body: String = board._format_module_tooltip_body(item)
	assert_true(body.contains("[u]Behavior[/u]"), "Contains Behavior header")
	assert_true(body.contains(item.custom_payload["behavior"]), "Contains behavior text")
	assert_true(body.contains("[u]Stats[/u]"), "Contains Stats header")
	assert_true(body.contains("Classification"), "Contains Classification stat")
	assert_true(body.contains("Footprint"), "Contains Footprint stat")
	assert_true(body.contains("Energy"), "Contains Energy stat")
	assert_true(body.contains("Impulse"), "Contains Impulse stat")

	board.free()

func test_campaign_relic_tooltip_regression() -> void:
	begin("Standard campaign relics retain simplified tooltip without metadata")
	var board: Node = BoardScript.new()
	var relic_item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"cascade_reactor")
	var body: String = board._format_module_tooltip_body(relic_item)

	assert_true(body.contains("[u]Activation Requirement[/u]"), "Contains Activation Requirement")
	assert_true(body.contains("[u]Relic Effect[/u]"), "Contains Relic Effect")
	assert_false(body.contains("[u]Stats[/u]"), "Does not contain Stats header")
	assert_false(body.contains("[u]Behavior[/u]"), "Does not contain Behavior header")

	board.free()

func test_debug_menu_button_present() -> void:
	begin("GameCoordinatorDebug build_debug_tools_column contains 'All Machinery' button")
	var gcd := GameCoordinatorDebug.new()
	var tools_ui: Control = gcd.build_debug_tools_column()
	assert_true(tools_ui != null, "DebugTools UI built")

	var btn: Button = null
	var panel: PanelContainer = tools_ui.get_node_or_null("DebugMenuPanel") as PanelContainer
	if panel:
		var vbox: VBoxContainer = panel.get_node_or_null("DebugMenuVBox") as VBoxContainer
		if vbox:
			for child in vbox.get_children():
				if child is Button and child.text == "All Machinery":
					btn = child
					break

	assert_true(btn != null, "'All Machinery' button exists in DebugMenuVBox")
	assert_eq(btn.text, "All Machinery", "Button text is 'All Machinery'")
	tools_ui.free()
	gcd.free()
