extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "MonstersAlsoDiePalette"

func run() -> void:
	test_palette_count_matches_hex_array()
	test_monsters_also_die_color_matches_hex_entries()
	test_monsters_also_die_color_clamps()
	test_shop_rarity_maps_tiers()
	test_ball_ability_theme_indices_distinct()

func test_palette_count_matches_hex_array() -> void:
	begin("MONSTERS_ALSO_DIE_PALETTE_COUNT matches MONSTERS_ALSO_DIE_PALETTE_HEX length")
	assert_eq(
		Constants.MONSTERS_ALSO_DIE_PALETTE_HEX.size(),
		Constants.MONSTERS_ALSO_DIE_PALETTE_COUNT,
		"hex array size"
	)

func test_monsters_also_die_color_matches_hex_entries() -> void:
	begin("monsters_also_die_color(i) matches Color.html for each swatch")
	for i in Constants.MONSTERS_ALSO_DIE_PALETTE_COUNT:
		var hex: String = Constants.MONSTERS_ALSO_DIE_PALETTE_HEX[i]
		var c: Color = Constants.monsters_also_die_color(i)
		var expected: Color = Color.html("#" + hex)
		assert_approx(c.r, expected.r, 0.002, "idx %d r" % i)
		assert_approx(c.g, expected.g, 0.002, "idx %d g" % i)
		assert_approx(c.b, expected.b, 0.002, "idx %d b" % i)
		assert_approx(c.a, expected.a, 0.002, "idx %d a" % i)

func test_monsters_also_die_color_clamps() -> void:
	begin("out-of-range indices clamp to palette ends")
	var low: Color = Constants.monsters_also_die_color(-999)
	var hi: Color = Constants.monsters_also_die_color(999)
	var first: Color = Constants.monsters_also_die_color(0)
	var last: Color = Constants.monsters_also_die_color(Constants.MONSTERS_ALSO_DIE_PALETTE_COUNT - 1)
	assert_eq(low, first, "low clamps to 0")
	assert_eq(hi, last, "high clamps to last")

func test_shop_rarity_maps_tiers() -> void:
	begin("shop_rarity_accent_color covers each tier index")
	var n: int = Constants.MAD_SHOP_RARITY_PALETTE_INDEX.size()
	assert_gt(n, 0, "rarity map non-empty")
	for t in n:
		var c: Color = Constants.shop_rarity_accent_color(t)
		assert_true(c.a > 0.2, "tier %d alpha visible" % t)

func test_ball_ability_theme_indices_distinct() -> void:
	begin("ball_ability_theme_palette_index is unique per stock ability")
	var keys: Array[String] = [
		"Plain", "Split", "Energize", "Explosive", "Chain Lightning", "Leech",
		"Rubbery", "Phantom", "Volatile", "Constellation", "Binary", "Bloom",
	]
	var seen: Dictionary = {}
	for k in keys:
		var idx: int = Constants.ball_ability_theme_palette_index(k)
		assert_false(seen.has(idx), "duplicate palette index for %s" % k)
		seen[idx] = true
