extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "CityProgression"

func run() -> void:
	test_all_city_definitions_loadable()
	test_human_kingdom_fields()
	test_elf_palace_fields()
	test_human_kingdom_wall_hp_scaling()
	test_elf_palace_wall_hp_scaling()
	test_city_progression_order()
	test_combat_manager_with_human_kingdom()
	test_combat_manager_with_elf_palace()
	test_max_rarity_per_city()
	test_ball_candidates_have_city_2_weights()
	test_tier_3_balls_exist()
	test_ball_reward_rarity_by_ability()

func test_all_city_definitions_loadable() -> void:
	begin("all CITY_DEFINITION_PATHS load valid CityDefinition resources")
	for i in Constants.CITY_DEFINITION_PATHS.size():
		var path: String = Constants.CITY_DEFINITION_PATHS[i]
		var res: Resource = load(path) as Resource
		assert_true(res is CityDefinition, "city %d at '%s' is CityDefinition" % [i, path])

func test_human_kingdom_fields() -> void:
	begin("Human Kingdom has correct identity fields")
	var city: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[1]) as CityDefinition
	assert_eq(city.city_id, &"human_kingdom", "city_id")
	assert_eq(city.display_name, "Human Kingdom", "display_name")
	assert_eq(city.wall_names.size(), 3, "3 walls")
	assert_gt(city.wall_hp_max, 50, "higher base HP than Halfling Shire")

func test_elf_palace_fields() -> void:
	begin("Elf Palace has correct identity fields")
	var city: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[2]) as CityDefinition
	assert_eq(city.city_id, &"elf_palace", "city_id")
	assert_eq(city.display_name, "Elf Palace", "display_name")
	assert_eq(city.wall_names.size(), 3, "3 walls")
	assert_gt(city.wall_hp_max, 150, "higher base HP than Human Kingdom")

func test_human_kingdom_wall_hp_scaling() -> void:
	begin("Human Kingdom wall HP scales with index")
	var city: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[1]) as CityDefinition
	var hp0: int = city.get_wall_hp_max_for_index(0)
	var hp1: int = city.get_wall_hp_max_for_index(1)
	var hp2: int = city.get_wall_hp_max_for_index(2)
	assert_eq(hp0, city.wall_hp_max, "wall 0 = base HP")
	assert_gt(hp1, hp0, "wall 1 > wall 0")
	assert_gt(hp2, hp1, "wall 2 > wall 1")

func test_elf_palace_wall_hp_scaling() -> void:
	begin("Elf Palace wall HP scales with index")
	var city: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[2]) as CityDefinition
	var hp0: int = city.get_wall_hp_max_for_index(0)
	var hp1: int = city.get_wall_hp_max_for_index(1)
	var hp2: int = city.get_wall_hp_max_for_index(2)
	assert_eq(hp0, city.wall_hp_max, "wall 0 = base HP")
	assert_gt(hp1, hp0, "wall 1 > wall 0")
	assert_gt(hp2, hp1, "wall 2 > wall 1")

func test_city_progression_order() -> void:
	begin("cities progress in difficulty: Halfling < Human < Elf")
	var halfling: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[0]) as CityDefinition
	var human: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[1]) as CityDefinition
	var elf: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[2]) as CityDefinition
	assert_lt(halfling.wall_hp_max, human.wall_hp_max, "Halfling HP < Human HP")
	assert_lt(human.wall_hp_max, elf.wall_hp_max, "Human HP < Elf HP")
	var h_thresh: int = int(halfling.milestone_thresholds.back())
	var hk_thresh: int = int(human.milestone_thresholds.back())
	var e_thresh: int = int(elf.milestone_thresholds.back())
	assert_lt(h_thresh, hk_thresh, "Halfling last milestone < Human last milestone")
	assert_lt(hk_thresh, e_thresh, "Human last milestone < Elf last milestone")

func test_combat_manager_with_human_kingdom() -> void:
	begin("CombatManager initializes correctly from Human Kingdom")
	var cm := _make_combat_manager()
	var city: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[1]) as CityDefinition
	cm.init_from_city(city)
	assert_eq(cm.get_wall_hp(), city.wall_hp_max, "wall HP = Human Kingdom base")
	assert_eq(cm.get_city_display_name(), "Human Kingdom", "city display name")
	assert_eq(cm.get_current_gate_name(), "Outer Rampart", "first wall name")
	cm.advance_to_next_wall()
	assert_eq(cm.get_current_gate_name(), "King's Garrison", "second wall name")
	cm.advance_to_next_wall()
	assert_eq(cm.get_current_gate_name(), "Royal Keep", "third wall name")

func test_combat_manager_with_elf_palace() -> void:
	begin("CombatManager initializes correctly from Elf Palace")
	var cm := _make_combat_manager()
	var city: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[2]) as CityDefinition
	cm.init_from_city(city)
	assert_eq(cm.get_wall_hp(), city.wall_hp_max, "wall HP = Elf Palace base")
	assert_eq(cm.get_city_display_name(), "Elf Palace", "city display name")
	assert_eq(cm.get_current_gate_name(), "Moonwood Gate", "first wall name")
	cm.advance_to_next_wall()
	assert_eq(cm.get_current_gate_name(), "Crystal Sanctum", "second wall name")
	cm.advance_to_next_wall()
	assert_eq(cm.get_current_gate_name(), "Throne of Stars", "third wall name")

func test_max_rarity_per_city() -> void:
	begin("MAX_RARITY_BY_CITY covers all 3 cities")
	assert_eq(Constants.MAX_RARITY_BY_CITY.size(), 3, "3 entries")
	assert_eq(Constants.MAX_RARITY_BY_CITY[0], Constants.RARITY_RARE, "Halfling: max Rare (milestone can offer rare balls)")
	assert_eq(Constants.MAX_RARITY_BY_CITY[1], 3, "Human: max Purple")
	assert_eq(Constants.MAX_RARITY_BY_CITY[2], 5, "Elf: max Epic")

func test_ball_candidates_have_city_2_weights() -> void:
	begin("Tier 2 ball candidates include city 2 weights for Elf Palace")
	GameState.start_run(42)
	var rh := _make_handler()
	var has_t2_city2: bool = false
	for def in rh._ball_candidates:
		if def is BallDefinition and def.tier == 2:
			if def.city_weights.has(2) and def.city_weights[2] > 0:
				has_t2_city2 = true
				break
	assert_true(has_t2_city2, "at least one T2 ball has city 2 weight")

func test_tier_3_balls_exist() -> void:
	begin("Tier 3 ball candidates exist for Elf Palace")
	GameState.start_run(42)
	var rh := _make_handler()
	var t3_count: int = 0
	for def in rh._ball_candidates:
		if def is BallDefinition and def.tier == 3:
			t3_count += 1
	assert_gt(t3_count, 0, "at least one Tier 3 ball exists")

func test_ball_reward_rarity_by_ability() -> void:
	begin("milestone ball rarities: Volatile rare; Explosive/Chain/Constellation/Binary/Bloom legendary; Split/Rubbery/Phantom/Energize/Leech uncommon")
	GameState.start_run(42)
	var rh := _make_handler()
	var rare: Array = ["Volatile"]
	var legendary: Array = ["Explosive", "Chain Lightning", "Constellation", "Binary", "Bloom"]
	for def in rh._ball_candidates:
		if not def is BallDefinition:
			continue
		var n: String = def.ability_name
		if n in legendary:
			assert_eq(def.rarity, Constants.RARITY_LEGENDARY, "'%s' tier %d is legendary" % [n, def.tier])
		elif n in rare:
			assert_eq(def.rarity, Constants.RARITY_RARE, "'%s' tier %d is rare" % [n, def.tier])
		else:
			assert_eq(def.rarity, Constants.RARITY_UNCOMMON, "'%s' tier %d is uncommon" % [n, def.tier])

func _make_combat_manager() -> Node:
	var script: GDScript = load("res://scenes/main/combat_manager.gd")
	var cm := Node.new()
	cm.set_script(script)
	return cm

func _make_handler() -> Node:
	var script: GDScript = load("res://scenes/rewards/reward_handler.gd")
	var rh := Node.new()
	rh.set_script(script)
	rh._reward_gen = RewardGeneration.new(GameState.run_seed)
	rh._ball_candidates = rh._build_ball_candidates()
	rh._build_wall_break_candidates()
	rh._build_boss_candidates()
	return rh
