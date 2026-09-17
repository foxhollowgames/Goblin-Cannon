extends "res://tests/test_base.gd"

const MilestoneOption = preload("res://resources/rewards/milestone_option.gd")
const RewardHandlerScript = preload("res://scenes/rewards/reward_handler.gd")
const Constants = preload("res://autoloads/constants.gd")
const DeliberateRelicCatalog = preload("res://resources/polyomino/deliberate_relic_catalog.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")

func _init() -> void:
	suite_name = "ShopRelicFocus"

func run() -> void:
	test_shop_pricing_constants()
	test_milestone_reward_picks_contain_only_relics_and_pegs()
	test_city_tier_limits_in_shop()
	test_apply_milestone_pick_relic_adds_to_junk_box()
	cleanup()

func test_shop_pricing_constants() -> void:
	begin("Shop relic pricing returns tier constants")
	assert_eq(Constants.shop_price_for_relic_tier(1), 15, "Tier 1 relic costs 15 gold")
	assert_eq(Constants.shop_price_for_relic_tier(2), 25, "Tier 2 relic costs 25 gold")
	assert_eq(Constants.shop_price_for_relic_tier(3), 40, "Tier 3 relic costs 40 gold")

func test_milestone_reward_picks_contain_only_relics_and_pegs() -> void:
	begin("Milestone reward picks contain only relics and pegs, zero balls, zero stats")
	var rh: Node = Node.new()
	rh.set_script(RewardHandlerScript)
	autofree(rh)
	rh._ready()

	GameState.current_city_id = 0
	var picks: Array = rh.get_milestone_reward_picks(4)

	assert_true(picks.size() > 0, "Picks array is not empty")
	for pick in picks:
		var opt: MilestoneOption = pick as MilestoneOption
		assert_true(opt != null, "Pick is a MilestoneOption")
		assert_true(
			opt.option_type == MilestoneOption.Type.RELIC or opt.option_type == MilestoneOption.Type.PEG_UPGRADE,
			"Pick option type is RELIC or PEG_UPGRADE"
		)
		assert_false(opt.option_type == MilestoneOption.Type.BALL_UPGRADE, "Pick option type is not BALL_UPGRADE")
		assert_false(opt.option_type == MilestoneOption.Type.STAT, "Pick option type is not STAT")

		if opt.option_type == MilestoneOption.Type.RELIC:
			assert_eq(opt.rarity, 1, "In City 0, shop relics default to Tier 1")
			assert_false(opt.relic_id.is_empty(), "Relic pick has a valid relic_id")

func test_city_tier_limits_in_shop() -> void:
	begin("Shop relic options respect max city tiers")
	var rh: Node = Node.new()
	rh.set_script(RewardHandlerScript)
	autofree(rh)
	rh._ready()

	GameState.current_city_id = 1
	var picks_city1: Array = rh.get_milestone_reward_picks(6)
	for pick in picks_city1:
		var opt: MilestoneOption = pick as MilestoneOption
		if opt and opt.option_type == MilestoneOption.Type.RELIC:
			assert_true(opt.rarity <= 2, "In City 1, shop relics tier is <= 2")

func test_apply_milestone_pick_relic_adds_to_junk_box() -> void:
	begin("Applying RELIC milestone pick adds item to GameState.junk_box")
	if GameState.junk_box == null:
		GameState.junk_box = JunkBoxData.new()

	var start_count: int = GameState.junk_box.items.size()
	var opt: MilestoneOption = MilestoneOption.new()
	opt.option_type = MilestoneOption.Type.RELIC
	opt.relic_id = &"bumper_vessel_twin"
	opt.rarity = 1

	var rh: Node = Node.new()
	rh.set_script(RewardHandlerScript)
	autofree(rh)

	rh.apply_milestone_pick(opt)

	assert_eq(GameState.junk_box.items.size(), start_count + 1, "Junk box item count incremented by 1")

