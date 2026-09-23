extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "MilestoneShopData"

func run() -> void:
	test_peg_shop_copy_covers_peg_kinds()
	test_ball_blurbs_non_empty_for_core_abilities()

func test_peg_shop_copy_covers_peg_kinds() -> void:
	begin("PEG_SHOP_DISPLAY has name+desc for each PEG_SHOP_KINDS")
	for kind in MilestoneShopData.PEG_SHOP_KINDS:
		assert_true(MilestoneShopData.PEG_SHOP_DISPLAY.has(kind), "peg kind %s" % kind)
		var row: Dictionary = MilestoneShopData.PEG_SHOP_DISPLAY[kind]
		assert_false(str(row.get("name", "")).strip_edges().is_empty(), "name %s" % kind)
		assert_false(str(row.get("desc", "")).strip_edges().is_empty(), "desc %s" % kind)

func test_ball_blurbs_non_empty_for_core_abilities() -> void:
	begin("shop_blurb_for_ball_ability returns copy for each shop ball ability")
	var abilities: Array[String] = [
		"Plain", "Split", "Energize", "Explosive", "Chain Lightning", "Leech",
		"Rubbery", "Phantom", "Volatile", "Constellation", "Binary", "Bloom"
	]
	for ab in abilities:
		var s: String = MilestoneShopData.shop_blurb_for_ball_ability(ab)
		assert_false(s.strip_edges().is_empty(), "blurb for %s" % ab)
