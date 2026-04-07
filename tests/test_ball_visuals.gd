extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "BallVisuals"

func run() -> void:
	test_icon_per_ability_distinct()
	test_unknown_ability_falls_back_to_plain()
	test_alignment_colors_bounded()

func test_icon_per_ability_distinct() -> void:
	begin("each ability maps to a loaded icon texture")
	var t_split: Texture2D = BallVisuals.get_icon_texture_for_ability("Split")
	var t_phantom: Texture2D = BallVisuals.get_icon_texture_for_ability("Phantom")
	assert_neq(t_split, t_phantom, "Split vs Phantom icons")
	var t_exp: Texture2D = BallVisuals.get_icon_texture_for_ability("Explosive")
	var t_en: Texture2D = BallVisuals.get_icon_texture_for_ability("Energize")
	assert_neq(t_exp, t_en, "Explosive vs Energize icons")

func test_unknown_ability_falls_back_to_plain() -> void:
	begin("unknown ability uses plain glass icon")
	var plain: Texture2D = BallVisuals.get_icon_texture_for_ability("")
	var unk: Texture2D = BallVisuals.get_icon_texture_for_ability("TotallyFakeAbility")
	assert_eq(unk, plain, "unknown matches plain")

func test_alignment_colors_bounded() -> void:
	begin("alignment indices resolve to colors")
	assert_true(BallVisuals.get_alignment_color(0).a > 0.9, "main alpha")
	assert_eq(BallVisuals.get_alignment_color(99), BallVisuals.get_alignment_color(0), "oob uses main")
