extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "KeywordDatabase"

func run() -> void:
	test_keywords_dictionary_non_empty_and_valid()
	test_get_definition_returns_definitions()
	test_format_bbcode_wraps_keywords_in_url_tags_without_hints()
	test_format_bbcode_overdrive_and_multiword_keywords()
	test_format_bbcode_includes_no_outline_and_no_underline_when_unhovered()
	test_format_bbcode_hovered_state_bolds_keyword()
	test_leech_blurb_uses_drain()
	test_phantom_blurb_uses_intangible()
	test_instant_flyout_tooltip_lifecycle()
	test_attach_rich_text_label_syncs_bold_font_size_and_handles_hover()

func test_keywords_dictionary_non_empty_and_valid() -> void:
	begin("KeywordDatabase.KEYWORDS contains valid keywords and definitions")
	assert_gt(KeywordDatabase.KEYWORDS.size(), 20, "contains at least 20 canonical keywords")
	for k in KeywordDatabase.KEYWORDS:
		var key_str: String = String(k)
		assert_false(key_str.strip_edges().is_empty(), "keyword name not empty")
		var def_str: String = String(KeywordDatabase.KEYWORDS[k])
		assert_false(def_str.strip_edges().is_empty(), "definition for '%s' not empty" % key_str)

func test_get_definition_returns_definitions() -> void:
	begin("KeywordDatabase.get_definition handles exact and case-insensitive lookups")
	var drain_def: String = KeywordDatabase.get_definition("Drain")
	assert_false(drain_def.is_empty(), "Drain definition exists")
	assert_true(drain_def.contains("Energy"), "Drain definition explains energy drain")

	var drain_lower: String = KeywordDatabase.get_definition("drain")
	assert_eq(drain_lower, drain_def, "case-insensitive lookup matches")

	var intangible_def: String = KeywordDatabase.get_definition("Intangible")
	assert_false(intangible_def.is_empty(), "Intangible definition exists")
	assert_true(intangible_def.contains("Phases"), "Intangible definition explains phasing")

	var intangible_lower: String = KeywordDatabase.get_definition("intangible")
	assert_eq(intangible_lower, intangible_def, "case-insensitive Intangible lookup matches")

	var unknown: String = KeywordDatabase.get_definition("NonExistentTerm123")
	assert_true(unknown.is_empty(), "unknown keyword returns empty string")

func test_format_bbcode_wraps_keywords_in_url_tags_without_hints() -> void:
	begin("KeywordDatabase.format_bbcode wraps keywords in url tags and omits hint tags")
	var input_text: String = "Applies Drain to pegs."
	var formatted: String = KeywordDatabase.format_bbcode(input_text)
	assert_false(formatted.contains("[hint="), "omits [hint] BBCode tag to prevent duplicate default tooltip")
	assert_true(formatted.contains("[url=Drain]"), "contains [url] BBCode tag for instant hover")
	assert_true(formatted.contains("Drain"), "contains Drain text")
	assert_true(formatted.contains(KeywordDatabase.HIGHLIGHT_COLOR), "applies highlight color")

	var intangible_formatted: String = KeywordDatabase.format_bbcode("Intangible.")
	assert_true(intangible_formatted.contains("[url=Intangible]"), "wraps Intangible in url tag")

	var empty_res: String = KeywordDatabase.format_bbcode("")
	assert_eq(empty_res, "", "empty input returns empty string")

func test_format_bbcode_overdrive_and_multiword_keywords() -> void:
	begin("KeywordDatabase.format_bbcode formats Overdrive N and multi-word keywords")
	var input_text: String = "Overdrive 6: Next hit fires Chain Lightning from that peg."
	var formatted: String = KeywordDatabase.format_bbcode(input_text)
	assert_true(formatted.contains("[url=Overdrive 6]"), "formats Overdrive 6 url tag correctly")
	assert_true(formatted.contains("[url=Chain Lightning]"), "formats multi-word Chain Lightning url tag correctly")

func test_format_bbcode_includes_no_outline_and_no_underline_when_unhovered() -> void:
	begin("KeywordDatabase.format_bbcode has no outline and no underline when unhovered")
	var formatted: String = KeywordDatabase.format_bbcode("Drain")
	assert_false(formatted.contains("outline_size="), "no outline_size tag")
	assert_false(formatted.contains("outline_color="), "no outline_color tag")
	assert_false(formatted.contains("[u]"), "no underline tag")
	assert_false(formatted.contains("[b]"), "unhovered is not bold")

func test_format_bbcode_hovered_state_bolds_keyword() -> void:
	begin("KeywordDatabase.format_bbcode bolds keyword when hovered without outline or underline")
	var formatted: String = KeywordDatabase.format_bbcode("Requires less Energy to fire.", KeywordDatabase.HIGHLIGHT_COLOR, "Energy")
	assert_true(formatted.contains("[b]Energy[/b]"), "bolds hovered keyword")
	assert_false(formatted.contains("[u]"), "no underline on hovered keyword")
	assert_false(formatted.contains("outline_size="), "no outline on hovered keyword")

func test_leech_blurb_uses_drain() -> void:
	begin("MilestoneShopData Leech blurb uses 'Applies Drain to pegs.'")
	var blurb: String = MilestoneShopData.shop_blurb_for_ball_ability("Leech")
	assert_eq(blurb, "Applies Drain to pegs.", "Leech shop blurb matches exact requirement")

func test_phantom_blurb_uses_intangible() -> void:
	begin("MilestoneShopData Phantom blurb uses 'Intangible.'")
	var blurb: String = MilestoneShopData.shop_blurb_for_ball_ability("Phantom")
	assert_eq(blurb, "Intangible.", "Phantom shop blurb matches exact requirement")

func test_instant_flyout_tooltip_lifecycle() -> void:
	begin("KeywordDatabase instant flyout tooltip show and hide lifecycle")
	KeywordDatabase.show_flyout("Drain", Vector2(120, 150))
	assert_true(KeywordDatabase._flyout_panel.visible, "flyout panel becomes visible")
	assert_eq(KeywordDatabase._flyout_title.text, "Drain", "flyout title matches keyword")
	assert_true(KeywordDatabase._flyout_body.text.contains("Energy"), "flyout body shows definition")

	KeywordDatabase.show_flyout("Intangible", Vector2(120, 150))
	assert_true(KeywordDatabase._flyout_panel.visible, "flyout panel becomes visible for Intangible")
	assert_eq(KeywordDatabase._flyout_title.text, "Intangible", "flyout title matches Intangible")
	assert_true(KeywordDatabase._flyout_body.text.contains("Phases"), "flyout body shows Intangible definition")

	KeywordDatabase.hide_flyout()
	assert_false(KeywordDatabase._flyout_panel.visible, "flyout panel becomes hidden")

func test_attach_rich_text_label_syncs_bold_font_size_and_handles_hover() -> void:
	begin("KeywordDatabase.format_and_attach syncs bold font size and updates hover text")
	var rtl := RichTextLabel.new()
	rtl.add_theme_font_size_override("normal_font_size", 10)
	KeywordDatabase.format_and_attach(rtl, "Requires less Energy to fire.")
	assert_false(rtl.meta_underlined, "meta_underlined is false to disable keyword underline")
	assert_false(rtl.hint_underlined, "hint_underlined is false")
	assert_eq(rtl.get_theme_font_size("bold_font_size"), 10, "bold font size matches normal font size")
	assert_false(rtl.text.contains("outline_size="), "initial text has no outline")
	assert_false(rtl.text.contains("[u]"), "initial text has no underline")

	KeywordDatabase._on_rtl_meta_hover_started(rtl, "Energy")
	assert_true(KeywordDatabase._flyout_panel.visible, "flyout shows on meta hover")
	assert_true(rtl.text.contains("[b]Energy[/b]"), "rtl text becomes bold on hover")
	assert_false(rtl.text.contains("[u]"), "no underline on hover")
	assert_false(rtl.text.contains("outline_size="), "no outline on hover")

	KeywordDatabase._on_rtl_meta_hover_ended(rtl, "Energy")
	assert_false(KeywordDatabase._flyout_panel.visible, "flyout hides on meta unhover")
	assert_false(rtl.text.contains("outline_size="), "no outline on unhover")
	assert_false(rtl.text.contains("[u]"), "no underline on unhover")
	rtl.free()
