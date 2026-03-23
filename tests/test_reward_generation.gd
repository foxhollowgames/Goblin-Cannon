extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "RewardGeneration"

func run() -> void:
	test_pick_ball_rewards_count()
	test_pick_ball_rewards_empty_candidates()
	test_pick_ball_rewards_zero_count()
	test_pick_ball_rewards_unique()
	test_pick_ball_rewards_capped_at_candidates()
	test_pick_major_upgrades_count()
	test_pick_major_upgrades_unique_ids()
	test_pick_major_upgrades_empty()
	test_pick_wall_break_trio_one_from_each()
	test_pick_wall_break_trio_empty_lists()
	test_pick_milestone_options_count()
	test_pick_milestone_options_returns_milestone_options()
	test_pick_milestone_options_stat_ids_valid()
	test_shuffle_deterministic_with_seed()
	test_randi_range()
	test_milestone_stat_ids_no_sidearm_or_shield()

func _make_rg(s: int = 42) -> RewardGeneration:
	return RewardGeneration.new(s)

func _make_ball_def(name: String) -> BallDefinition:
	var d := BallDefinition.new()
	d.ability_name = name
	d.alignment = 0
	d.tier = 1
	d.rarity = 0
	d.base_energy = 20
	d.city_weights = {0: 100}
	return d

func _make_major_upgrade(uid: String) -> MajorUpgradeDefinition:
	var u := MajorUpgradeDefinition.new()
	u.upgrade_id = StringName(uid)
	u.display_name = uid
	u.category = MajorUpgradeDefinition.Category.BOARD_UPGRADE
	return u

func test_pick_ball_rewards_count() -> void:
	begin("pick_ball_rewards returns requested count")
	var rg := _make_rg()
	var candidates: Array = [_make_ball_def("A"), _make_ball_def("B"), _make_ball_def("C"), _make_ball_def("D")]
	var picks: Array = rg.pick_ball_rewards(candidates, 2)
	assert_eq(picks.size(), 2, "requested 2, got 2")

func test_pick_ball_rewards_empty_candidates() -> void:
	begin("pick_ball_rewards returns empty for empty candidates")
	var rg := _make_rg()
	var picks: Array = rg.pick_ball_rewards([], 3)
	assert_empty(picks, "empty candidates = empty result")

func test_pick_ball_rewards_zero_count() -> void:
	begin("pick_ball_rewards returns empty for count=0")
	var rg := _make_rg()
	var picks: Array = rg.pick_ball_rewards([_make_ball_def("A")], 0)
	assert_empty(picks, "count 0 = empty result")

func test_pick_ball_rewards_unique() -> void:
	begin("pick_ball_rewards returns unique picks")
	var rg := _make_rg()
	var a := _make_ball_def("A")
	var b := _make_ball_def("B")
	var c := _make_ball_def("C")
	var picks: Array = rg.pick_ball_rewards([a, b, c], 3)
	assert_eq(picks.size(), 3, "3 unique from 3 candidates")

func test_pick_ball_rewards_capped_at_candidates() -> void:
	begin("pick_ball_rewards capped at candidate count")
	var rg := _make_rg()
	var candidates: Array = [_make_ball_def("A"), _make_ball_def("B")]
	var picks: Array = rg.pick_ball_rewards(candidates, 10)
	assert_lte(picks.size(), 2, "cannot exceed candidate count")

func test_pick_major_upgrades_count() -> void:
	begin("pick_major_upgrades returns correct count")
	var rg := _make_rg()
	var candidates: Array = [_make_major_upgrade("a"), _make_major_upgrade("b"), _make_major_upgrade("c"), _make_major_upgrade("d")]
	var picks: Array = rg.pick_major_upgrades(candidates, 3)
	assert_eq(picks.size(), 3, "requested 3, got 3")

func test_pick_major_upgrades_unique_ids() -> void:
	begin("pick_major_upgrades returns unique upgrade_ids")
	var rg := _make_rg()
	var candidates: Array = [_make_major_upgrade("x"), _make_major_upgrade("y"), _make_major_upgrade("z")]
	var picks: Array = rg.pick_major_upgrades(candidates, 3)
	var ids: Dictionary = {}
	for p in picks:
		ids[p.upgrade_id] = true
	assert_eq(ids.size(), picks.size(), "all unique ids")

func test_pick_major_upgrades_empty() -> void:
	begin("pick_major_upgrades returns empty for empty candidates")
	var rg := _make_rg()
	assert_empty(rg.pick_major_upgrades([], 3), "empty in = empty out")

func test_pick_wall_break_trio_one_from_each() -> void:
	begin("pick_wall_break_trio picks one from each category")
	var rg := _make_rg()
	var sidearms: Array = [_make_major_upgrade("sa")]
	var balls: Array = [_make_major_upgrade("ba")]
	var boards: Array = [_make_major_upgrade("bo")]
	var trio: Array = rg.pick_wall_break_trio(sidearms, balls, boards)
	assert_eq(trio.size(), 3, "one from each of 3 categories")

func test_pick_wall_break_trio_empty_lists() -> void:
	begin("pick_wall_break_trio handles empty category lists")
	var rg := _make_rg()
	var trio: Array = rg.pick_wall_break_trio([], [_make_major_upgrade("b")], [])
	assert_eq(trio.size(), 1, "only ball list had entries")

func test_pick_milestone_options_count() -> void:
	begin("pick_milestone_options returns total_count options")
	var rg := _make_rg()
	var candidates: Array = []
	for n in ["A", "B", "C", "D", "E", "F", "G", "H"]:
		candidates.append(_make_ball_def(n))
	var options: Array = rg.pick_milestone_options(candidates, 5)
	assert_eq(options.size(), 5, "5 options total")

func test_pick_milestone_options_returns_milestone_options() -> void:
	begin("pick_milestone_options returns MilestoneOption resources")
	var rg := _make_rg()
	var candidates: Array = [_make_ball_def("A"), _make_ball_def("B")]
	var options: Array = rg.pick_milestone_options(candidates, 5)
	for opt in options:
		assert_true(opt is MilestoneOption, "each option is MilestoneOption")

func test_pick_milestone_options_stat_ids_valid() -> void:
	begin("milestone stat options only use valid stat IDs")
	var rg := _make_rg()
	var candidates: Array = [_make_ball_def("A")]
	var valid_ids: Array = ["main_charge", "door_interval", "door_duration", "cannon_damage", "cannon_energy"]
	# Run multiple times to sample RNG variance
	for _trial in 10:
		var options: Array = rg.pick_milestone_options(candidates, 5)
		for opt in options:
			if opt is MilestoneOption and opt.option_type == MilestoneOption.Type.STAT:
				assert_in(opt.stat_id, valid_ids, "stat_id '%s' is valid" % opt.stat_id)

func test_shuffle_deterministic_with_seed() -> void:
	begin("same seed produces same shuffle order")
	var rg1 := _make_rg(100)
	var rg2 := _make_rg(100)
	var arr1: Array = [1, 2, 3, 4, 5]
	var arr2: Array = [1, 2, 3, 4, 5]
	rg1.shuffle_array(arr1)
	rg2.shuffle_array(arr2)
	assert_eq(arr1, arr2, "same seed = same shuffle")

func test_randi_range() -> void:
	begin("randi_range stays within bounds")
	var rg := _make_rg()
	for _i in 100:
		var val: int = rg.randi_range(5, 10)
		assert_gte(val, 5, "val >= 5")
		assert_lte(val, 10, "val <= 10")

func test_milestone_stat_ids_no_sidearm_or_shield() -> void:
	begin("MILESTONE_STAT_IDS contains no sidearm/shield/health stats")
	var forbidden: Array = ["sidearm_cap", "shield_cap", "health_max", "shield_max"]
	for stat_id in RewardGeneration.MILESTONE_STAT_IDS:
		assert_not_in(stat_id, forbidden, "stat_id '%s' is not a removed stat" % stat_id)
