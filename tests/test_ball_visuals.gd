extends "res://tests/test_base.gd"

const BallVisuals = preload("res://scenes/balls/ball_visuals.gd")

func _init() -> void:
	suite_name = "BallVisuals"

func run() -> void:
	test_icon_per_ability_distinct()
	test_unknown_ability_falls_back_to_plain()
	test_alignment_colors_bounded()
	test_three_way_icon_rotation()
	test_ability_theme_colors_distinct()

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

func test_three_way_icon_rotation() -> void:
	begin("Energize / Rubbery / Plain use three different icons (rotated assets)")
	var t_en: Texture2D = BallVisuals.get_icon_texture_for_ability("Energize")
	var t_rb: Texture2D = BallVisuals.get_icon_texture_for_ability("Rubbery")
	var t_pl: Texture2D = BallVisuals.get_icon_texture_for_ability("")
	assert_neq(t_en, t_rb, "Energize vs Rubbery")
	assert_neq(t_rb, t_pl, "Rubbery vs Plain")
	assert_neq(t_en, t_pl, "Energize vs Plain")

func test_ability_theme_colors_distinct() -> void:
	begin("each ability maps to a distinct theme color")
	var keys: Array[String] = ["Plain", "Split", "Energize", "Explosive", "Chain Lightning", "Leech", "Rubbery", "Phantom", "Volatile", "Constellation", "Binary", "Bloom"]
	var seen: Dictionary = {}
	for k in keys:
		var c: Color = BallVisuals.get_ability_theme_color(k)
		var key := "%.3f,%.3f,%.3f" % [c.r, c.g, c.b]
		assert_false(seen.has(key), "unique tint for %s" % k)
		seen[key] = true
