extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "TooltipTextRefinement"

func run() -> void:
	test_trampoline_peg_tooltip_text()
	test_trampoline_shop_description_text()
	test_keyword_definitions_concise_and_non_empty()
	test_milestone_shop_peg_descriptions_concise_and_non_empty()
	test_all_ball_abilities_have_keyword_glossary_entry()
	test_format_bbcode_detects_energize_and_explosive()

func test_trampoline_peg_tooltip_text() -> void:
	begin("KeywordDatabase.KEYWORDS['Trampoline Peg'] simplified to direct action text")
	var trampoline_def: String = KeywordDatabase.get_definition("Trampoline Peg")
	assert_eq(trampoline_def, "Launches balls.", "Trampoline Peg definition is simplified to 'Launches balls.'")

func test_trampoline_shop_description_text() -> void:
	begin("MilestoneShopData.PEG_SHOP_DISPLAY['trampoline'] description simplified")
	var shop_data: Dictionary = MilestoneShopData.PEG_SHOP_DISPLAY.get("trampoline", {})
	var desc: String = str(shop_data.get("desc", ""))
	assert_eq(desc, "Launches balls. Place on any peg.", "Trampoline Peg shop desc is simplified")

func test_keyword_definitions_concise_and_non_empty() -> void:
	begin("All KeywordDatabase definitions are non-empty and under 80 characters")
	for k in KeywordDatabase.KEYWORDS:
		var key_str: String = String(k)
		var def_str: String = String(KeywordDatabase.KEYWORDS[k])
		assert_false(def_str.strip_edges().is_empty(), "definition for '%s' is not empty" % key_str)
		assert_lte(def_str.length(), 80, "definition for '%s' is concise (<= 80 chars)" % key_str)

func test_milestone_shop_peg_descriptions_concise_and_non_empty() -> void:
	begin("All MilestoneShopData peg descriptions are non-empty and under 100 characters")
	for kind in MilestoneShopData.PEG_SHOP_DISPLAY:
		var data: Dictionary = MilestoneShopData.PEG_SHOP_DISPLAY[kind]
		var desc: String = str(data.get("desc", ""))
		assert_false(desc.strip_edges().is_empty(), "shop desc for '%s' is not empty" % kind)
		assert_lte(desc.length(), 100, "shop desc for '%s' is concise (<= 100 chars)" % kind)

func test_all_ball_abilities_have_keyword_glossary_entry() -> void:
	begin("All RewardCardCatalog ball candidate abilities have non-empty glossary definitions")
	var candidates: Array = RewardCardCatalog.build_ball_candidates()
	assert_gt(candidates.size(), 0, "ball candidates exist")
	for cand in candidates:
		var def: BallDefinition = cand as BallDefinition
		if def and not def.ability_name.is_empty():
			var ability: String = def.ability_name
			var def_text: String = KeywordDatabase.get_definition(ability)
			assert_false(def_text.strip_edges().is_empty(), "glossary entry exists for ball ability '%s'" % ability)
			assert_lte(def_text.length(), 80, "glossary entry for '%s' is <= 80 chars" % ability)

func test_format_bbcode_detects_energize_and_explosive() -> void:
	begin("format_bbcode correctly formats and highlights Energize and Explosive")
	var input_text: String = "Energize the peg with Explosive blast."
	var formatted: String = KeywordDatabase.format_bbcode(input_text)
	assert_true(formatted.contains("[url=Energize]"), "contains [url=Energize]")
	assert_true(formatted.contains("[url=Explosive]"), "contains [url=Explosive]")
	assert_true(formatted.contains("[url=Blast]"), "contains [url=Blast]")
