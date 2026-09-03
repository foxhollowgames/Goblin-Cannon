extends "res://tests/test_base.gd"

const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const BoardScript = preload("res://scenes/board/board.gd")

func _init() -> void:
	suite_name = "KeywordFlyoutTooltip"

func run() -> void:
	test_flyout_body_is_rich_text_label_with_bbcode()
	test_flyout_custom_renders_bbcode_formatting()
	test_board_relic_tooltip_bbcode_headers()
	test_flyout_position_clamping()

func test_flyout_body_is_rich_text_label_with_bbcode() -> void:
	begin("KeywordDatabase._flyout_body is a RichTextLabel with bbcode enabled")
	KeywordDatabase.show_flyout("Drain", Vector2(100, 100))
	assert_true(KeywordDatabase._flyout_body is RichTextLabel, "_flyout_body is a RichTextLabel instance")
	var rtl: RichTextLabel = KeywordDatabase._flyout_body as RichTextLabel
	assert_true(rtl.bbcode_enabled, "RichTextLabel has bbcode_enabled true")
	assert_true(rtl.fit_content, "RichTextLabel has fit_content true")
	KeywordDatabase.hide_flyout()

func test_flyout_custom_renders_bbcode_formatting() -> void:
	begin("KeywordDatabase.show_flyout_custom sets BBCode text cleanly")
	var raw_markup: String = "[u]Activation Requirement[/u]\nTrigger kinetic rollover."
	KeywordDatabase.show_flyout_custom("Test Title", raw_markup, Vector2(150, 150))
	assert_true(KeywordDatabase._flyout_panel.visible, "Flyout panel is visible")
	assert_eq(KeywordDatabase._flyout_title.text, "Test Title", "Flyout title matches")
	var rtl: RichTextLabel = KeywordDatabase._flyout_body as RichTextLabel
	assert_eq(rtl.text, raw_markup, "RichTextLabel stores full markup")
	var parsed: String = rtl.get_parsed_text()
	assert_false(parsed.contains("[u]"), "Parsed text does not contain raw [u] opening tag")
	assert_false(parsed.contains("[/u]"), "Parsed text does not contain raw [/u] closing tag")
	assert_true(parsed.contains("Activation Requirement"), "Parsed text contains clean header text")
	KeywordDatabase.hide_flyout()
	assert_false(KeywordDatabase._flyout_panel.visible, "Flyout panel is hidden after hide_flyout")

func test_board_relic_tooltip_bbcode_headers() -> void:
	begin("Board._format_module_tooltip_body produces valid BBCode headers")
	var board_inst = BoardScript.new()
	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"cascade_reactor")
	assert_true(item != null, "Cascade Reactor created successfully")

	var body_text: String = board_inst._format_module_tooltip_body(item)
	assert_true(body_text.contains("[u]Activation Requirement[/u]"), "Contains activation header with underline tag")
	assert_true(body_text.contains("[u]Relic Effect[/u]"), "Contains relic effect header with underline tag")

	KeywordDatabase.show_flyout_custom(item.display_name, body_text, Vector2(200, 200))
	var rtl: RichTextLabel = KeywordDatabase._flyout_body as RichTextLabel
	var parsed_body: String = rtl.get_parsed_text()
	assert_false(parsed_body.contains("[u]"), "Parsed body text strips raw [u] tags")
	assert_false(parsed_body.contains("[/u]"), "Parsed body text strips raw [/u] tags")
	assert_true(parsed_body.contains("Activation Requirement"), "Parsed body displays Activation Requirement")
	assert_true(parsed_body.contains("Relic Effect"), "Parsed body displays Relic Effect")

	KeywordDatabase.hide_flyout()
	board_inst.free()

func test_flyout_position_clamping() -> void:
	begin("KeywordDatabase flyout position clamps within viewport limits")
	KeywordDatabase.show_flyout_custom("Edge Test", "Clamping verification", Vector2(1900, 1000))
	assert_true(KeywordDatabase._flyout_panel.global_position.x < 1900, "Position clamped horizontally")
	assert_true(KeywordDatabase._flyout_panel.global_position.y < 1000, "Position clamped vertically")
	KeywordDatabase.hide_flyout()
