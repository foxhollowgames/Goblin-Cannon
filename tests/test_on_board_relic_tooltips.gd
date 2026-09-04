extends "res://tests/test_base.gd"

const BoardScript = preload("res://scenes/board/board.gd")
const JunkBoxPanelScript = preload("res://scenes/ui/junk_box/junk_box_panel.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")

func _init() -> void:
	suite_name = "OnBoardRelicTooltips"

func run() -> void:
	test_on_board_relic_tooltip_omits_tier_size_shape()
	test_on_board_relic_tooltip_includes_activation_and_effect()
	test_junk_box_inventory_tooltip_omits_metadata()

func test_on_board_relic_tooltip_omits_tier_size_shape() -> void:
	begin("Board._format_module_tooltip_body omits tier, size, and shape properties")
	var board_inst = BoardScript.new()
	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"cascade_reactor")
	assert_true(item != null, "Cascade Reactor item created cleanly")
	
	var tooltip_body: String = board_inst._format_module_tooltip_body(item)
	assert_false(tooltip_body.contains("Tier:"), "On-board tooltip must not contain 'Tier:'")
	assert_false(tooltip_body.contains("Size:"), "On-board tooltip must not contain 'Size:'")
	assert_false(tooltip_body.contains("Cells"), "On-board tooltip must not contain 'Cells'")
	assert_false(tooltip_body.contains("Shape:"), "On-board tooltip must not contain 'Shape:'")
	assert_false(tooltip_body.contains("Components"), "On-board tooltip must not contain 'Components'")
	assert_false(tooltip_body.contains("Machinery & Effect"), "On-board tooltip must not contain 'Machinery & Effect'")
	board_inst.free()

func test_on_board_relic_tooltip_includes_activation_and_effect() -> void:
	begin("Board._format_module_tooltip_body includes activation requirement and relic effect")
	var board_inst = BoardScript.new()
	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"cascade_reactor")
	
	var tooltip_body: String = board_inst._format_module_tooltip_body(item)
	assert_true(tooltip_body.contains("[u]Activation Requirement[/u]"), "Contains Activation Requirement header")
	assert_true(tooltip_body.contains("Hit all 4 corner boosters"), "Contains activation requirement text")
	assert_true(tooltip_body.contains("[u]Relic Effect[/u]"), "Contains Relic Effect header")
	assert_true(tooltip_body.contains("Board Supercharge"), "Contains relic effect text")
	board_inst.free()

func test_junk_box_inventory_tooltip_omits_metadata() -> void:
	begin("JunkBoxPanel._format_item_tooltip omits tier, size, shape, components, and machinery")
	var panel_inst = JunkBoxPanelScript.new()
	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"cascade_reactor")
	
	var tooltip: String = panel_inst._format_item_tooltip(item)
	assert_false(tooltip.contains("Tier:"), "Junk Box inventory tooltip does not contain 'Tier:'")
	assert_false(tooltip.contains("Size:"), "Junk Box inventory tooltip does not contain 'Size:'")
	assert_false(tooltip.contains("Shape:"), "Junk Box inventory tooltip does not contain 'Shape:'")
	assert_false(tooltip.contains("Components"), "Junk Box inventory tooltip does not contain 'Components'")
	assert_false(tooltip.contains("Machinery & Effect"), "Junk Box inventory tooltip does not contain 'Machinery & Effect'")
	assert_true(tooltip.contains("[u]Activation Requirement[/u]"), "Junk Box tooltip contains activation requirement")
	assert_true(tooltip.contains("[u]Relic Effect[/u]"), "Junk Box tooltip contains relic effect")
	panel_inst.free()
