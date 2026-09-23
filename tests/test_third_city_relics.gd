extends "res://tests/test_base.gd"

const Handler = preload("res://scenes/rewards/reward_handler.gd")
const DB = preload("res://resources/polyomino/polyomino_relic_database.gd")

func _init() -> void:
	suite_name = "ThirdCityRelics"

func test_city_gates() -> void:
	begin("Normal relic city gates")
	GameState.start_run(102)

	var node: Node = Node.new()
	node.set_script(Handler)
	autofree(node)
	node._ready()

	for city in range(3):
		GameState.current_city_id = city
		for seed in range(20):
			node._reward_gen.set_seed(seed)
			var merchant5: Array = node.get_milestone_reward_picks(5)

			assert_true(not merchant5.is_empty())

			for opt in merchant5:
				if opt.option_type == MilestoneOption.Type.RELIC:
					assert_true(opt.rarity <= clampi(city + 1, 1, 3))

			for method_name in ["get_major_upgrade_picks", "get_boss_upgrade_picks", "get_onboard_effect_picks"]:
				var picks: Array = node.call(method_name, 3)
				assert_true(not picks.is_empty())

				for pick in picks:
					if city < 2:
						assert_true(DB.get_relic_tier(pick.upgrade_id) <= 2)
					else:
						assert_true(DB.get_relic_tier(pick.upgrade_id) <= 3)

func test_reachability() -> void:
	begin("All Tier 3 relics have normal routes")
	GameState.start_run(102)
	GameState.current_city_id = 2

	var node: Node = Node.new()
	node.set_script(Handler)
	autofree(node)
	node._ready()

	var seen_shop: Dictionary = {}
	var seen_wall: Dictionary = {}

	for seed_value in range(500):
		node._reward_gen.set_seed(seed_value)
		for opt in node.get_milestone_reward_picks(5):
			if opt.option_type == MilestoneOption.Type.RELIC:
				seen_shop[opt.relic_id] = true

		for pick in node.get_major_upgrade_picks(3):
			seen_wall[pick.upgrade_id] = true

	for uid in DB.get_all_relic_ids():
		if DB.get_relic_tier(uid) == 3:
			assert_true(seen_shop.has(uid), str(uid))
			assert_true(seen_wall.has(uid), str(uid))

	var deliberate_count: int = 0
	for uid in DB.get_deliberate_relic_ids():
		if DB.get_relic_tier(uid) == 3:
			deliberate_count += 1

	assert_eq(deliberate_count, 14)

func test_purchase() -> void:
	begin("Tier 3 purchase cost and duplicate protection")
	GameState.start_run(102)
	GameState.current_city_id = 2

	var node: Node = Node.new()
	node.set_script(Handler)
	autofree(node)
	node._ready()

	var opt: MilestoneOption = MilestoneOption.new()
	opt.option_type = MilestoneOption.Type.RELIC
	opt.relic_id = node._third_city_relic_candidates()[0].upgrade_id
	opt.rarity = 3

	var panel: Control = Control.new()
	panel.set_script(load("res://scenes/rewards/reward_draft_panel.gd"))
	autofree(panel)

	panel._picks = [opt]
	panel._purchased_flags = [false]

	panel.pick_selected.connect(node.apply_milestone_pick)

	GameState.run_gold = 39
	panel._on_pick_pressed(0)
	assert_eq(GameState.junk_box.get_item_count(), 0)
	assert_eq(GameState.run_gold, 39)

	# Set gold to 40 and press again
	GameState.run_gold = 40
	panel._on_pick_pressed(0)
	var count1: int = GameState.junk_box.get_item_count()
	assert_eq(count1, 1)
	assert_eq(GameState.run_gold, 0)

	# Set gold to 40 and press again
	GameState.run_gold = 40
	panel._on_pick_pressed(0)
	var count2: int = GameState.junk_box.get_item_count()
	assert_eq(count2, 1)
	assert_eq(GameState.run_gold, 40)

	var item: Resource = GameState.junk_box.get_all_items()[0]
	assert_eq(item.custom_payload.get("relic_id", ""), str(opt.relic_id))

func run() -> void:
	test_city_gates()
	test_reachability()
	test_purchase()
	test_weights_and_seed()
	cleanup()

func test_weights_and_seed() -> void:
	begin("Tier weights and deterministic offers")
	var gen: RewardGeneration = RewardGeneration.new(102)
	assert_eq(gen._relic_tier_for_roll(3, 1), 1)
	assert_eq(gen._relic_tier_for_roll(3, 2), 2)
	assert_eq(gen._relic_tier_for_roll(3, 3), 3)
	assert_eq(gen._relic_tier_for_roll(2, 3), 2)
	assert_eq(gen._relic_tier_for_roll(1, 3), 1)

	for wall in range(3):
		var weights: Array = Constants.milestone_reward_rarity_weights(2, wall, false)
		assert_true(weights[3] > 0)

	GameState.start_run(102)
	GameState.current_city_id = 2
	var node: Node = Node.new()
	node.set_script(Handler)
	autofree(node)
	node._ready()

	node._reward_gen.set_seed(123)
	var first: Array = node.get_milestone_reward_picks(5)
	node._reward_gen.set_seed(123)
	var second: Array = node.get_milestone_reward_picks(5)

	assert_eq(first.size(), second.size())

	var seen: Dictionary = {}
	for i in range(first.size()):
		assert_eq(first[i].option_type, second[i].option_type)
		assert_eq(first[i].relic_id, second[i].relic_id)
		assert_eq(first[i].peg_kind, second[i].peg_kind)

		if first[i].option_type == MilestoneOption.Type.RELIC:
			assert_false(seen.has(first[i].relic_id))
			seen[first[i].relic_id] = true

