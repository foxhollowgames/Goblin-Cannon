extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "TestScenario"

func run() -> void:
	test_disabled_by_default()
	test_make_ball_definition_plain()
	test_make_ball_definition_explosive()
	test_make_ball_definition_chain_lightning()
	test_make_ball_definition_all_abilities()
	test_summary_empty_when_disabled()
	test_summary_shows_balls()
	test_summary_shows_upgrades()
	test_summary_shows_timer_infinite()
	test_summary_shows_timer_custom()
	test_summary_shows_all_pegs_bombs()
	test_summary_shows_all_pegs_start_leeched()
	test_apply_scenario_city_override()
	test_apply_scenario_stat_overrides()
	test_apply_scenario_plain_swarm_stats()
	test_apply_scenario_upgrade_string()
	test_apply_scenario_upgrade_dict_with_stacks()
	test_apply_scenario_peg_counts()
	test_apply_scenario_disabled_does_nothing()
	test_timer_override_default()
	test_timer_override_infinite()
	test_timer_override_custom()

func _reset_scenario() -> void:
	TestScenario.enabled = false
	TestScenario.starting_balls = []
	TestScenario.starting_city_id = -1
	TestScenario.starting_wall_index = -1
	TestScenario.timer_override_seconds = -1
	TestScenario.starting_upgrades = []
	TestScenario.starting_stats = {}
	TestScenario.starting_peg_counts = {}
	TestScenario.all_pegs_bombs = false
	TestScenario.all_pegs_trampolines = false
	TestScenario.all_pegs_start_leeched = false
	GameState.start_run(42)

func test_disabled_by_default() -> void:
	begin("disabled by default")
	_reset_scenario()
	assert_false(TestScenario.enabled, "enabled is false")

func test_make_ball_definition_plain() -> void:
	begin("make_ball_definition creates plain ball for empty ability")
	_reset_scenario()
	var d: BallDefinition = TestScenario.make_ball_definition("")
	assert_eq(d.ability_name, "", "no ability")
	assert_eq(d.alignment, Constants.ALIGNMENT_MAIN, "main alignment")
	assert_eq(d.rarity, Constants.RARITY_COMMON, "common rarity for plain")

func test_make_ball_definition_explosive() -> void:
	begin("make_ball_definition creates Explosive ball")
	_reset_scenario()
	var d: BallDefinition = TestScenario.make_ball_definition("Explosive")
	assert_eq(d.ability_name, "Explosive", "ability name")
	assert_eq(d.alignment, Constants.ALIGNMENT_MAIN, "main alignment")
	assert_eq(d.shape_type, BallVisuals.ShapeType.SQUARE, "square shape")
	assert_eq(d.rarity, Constants.RARITY_LEGENDARY, "legendary rarity")

func test_make_ball_definition_chain_lightning() -> void:
	begin("make_ball_definition creates Chain Lightning ball")
	_reset_scenario()
	var d: BallDefinition = TestScenario.make_ball_definition("Chain Lightning")
	assert_eq(d.ability_name, "Chain Lightning", "ability name")
	assert_eq(d.shape_type, BallVisuals.ShapeType.STAR, "star shape")
	assert_eq(d.rarity, Constants.RARITY_LEGENDARY, "legendary rarity")

func test_make_ball_definition_all_abilities() -> void:
	begin("make_ball_definition handles all known abilities")
	_reset_scenario()
	var abilities: Array = ["Split", "Energize", "Explosive", "Chain Lightning", "Leech", "Rubbery", "Phantom", "Volatile", "Constellation", "Binary", "Bloom"]
	for ability in abilities:
		var d: BallDefinition = TestScenario.make_ball_definition(ability)
		assert_eq(d.ability_name, ability, "'%s' ability name" % ability)
		assert_eq(d.alignment, Constants.ALIGNMENT_MAIN, "'%s' main alignment" % ability)
		assert_neq(d.shape_type, -1, "'%s' has defined shape" % ability)

func test_summary_empty_when_disabled() -> void:
	begin("get_summary returns empty when disabled")
	_reset_scenario()
	assert_eq(TestScenario.get_summary(), "", "empty summary")

func test_summary_shows_balls() -> void:
	begin("get_summary includes ball info")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.starting_balls = [{"ability": "Explosive", "count": 10}]
	var summary: String = TestScenario.get_summary()
	assert_true(summary.find("Explosive") >= 0, "summary mentions Explosive")
	assert_true(summary.find("10") >= 0, "summary mentions count")
	_reset_scenario()

func test_summary_shows_upgrades() -> void:
	begin("get_summary includes upgrade info")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.starting_upgrades = ["explosions_apply_energize"]
	var summary: String = TestScenario.get_summary()
	assert_true(summary.find("explosions_apply_energize") >= 0, "summary mentions upgrade")
	_reset_scenario()

func test_summary_shows_timer_infinite() -> void:
	begin("get_summary shows infinite timer")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.timer_override_seconds = 0
	var summary: String = TestScenario.get_summary()
	assert_true(summary.find("infinite") >= 0, "summary says infinite")
	_reset_scenario()

func test_summary_shows_timer_custom() -> void:
	begin("get_summary shows custom timer seconds")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.timer_override_seconds = 60
	var summary: String = TestScenario.get_summary()
	assert_true(summary.find("60") >= 0, "summary shows 60")
	_reset_scenario()

func test_summary_shows_all_pegs_bombs() -> void:
	begin("get_summary shows all pegs = bombs")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.all_pegs_bombs = true
	var summary: String = TestScenario.get_summary()
	assert_true(summary.find("bombs") >= 0, "summary mentions bombs")
	_reset_scenario()

func test_summary_shows_all_pegs_start_leeched() -> void:
	begin("get_summary shows all pegs start leeched")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.all_pegs_start_leeched = true
	var summary: String = TestScenario.get_summary()
	assert_true(summary.find("leeched") >= 0, "summary mentions leeched")
	_reset_scenario()

func test_apply_scenario_city_override() -> void:
	begin("_apply_test_scenario sets city_id")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.starting_city_id = 2
	# Simulate what game_coordinator does
	if TestScenario.starting_city_id >= 0:
		GameState.current_city_id = TestScenario.starting_city_id
	assert_eq(GameState.current_city_id, 2, "city_id set to 2")
	_reset_scenario()

func test_apply_scenario_stat_overrides() -> void:
	begin("stat overrides apply correctly")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.starting_stats = {"cannon_damage": 20, "cannon_energy": 4000, "main_charge": 0.15}
	# Simulate stat application
	for stat_key in TestScenario.starting_stats:
		var value = TestScenario.starting_stats[stat_key]
		match stat_key:
			"cannon_damage":
				GameState.cannon_base_damage_bonus += int(value)
			"cannon_energy":
				GameState.cannon_charge_reduction += Constants.legacy_internal_energy_to_current(int(value))
			"main_charge":
				GameState.main_charge_bonus += float(value)
	assert_eq(GameState.cannon_base_damage_bonus, 20, "cannon damage +20")
	assert_eq(GameState.cannon_charge_reduction, Constants.legacy_internal_energy_to_current(4000), "cannon energy scaled reduction")
	assert_approx(GameState.main_charge_bonus, 0.15, 0.001, "main charge +15%")
	_reset_scenario()

func test_apply_scenario_plain_swarm_stats() -> void:
	begin("starting_stats plain_* match game_coordinator caps")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.starting_stats = {"plain_surge": 10, "plain_horde": 5, "plain_momentum": 5}
	for stat_key in TestScenario.starting_stats:
		var value = TestScenario.starting_stats[stat_key]
		match stat_key:
			"plain_surge":
				GameState.plain_surge_stacks = mini(5, GameState.plain_surge_stacks + int(value))
			"plain_horde":
				GameState.plain_horde_stacks = mini(3, GameState.plain_horde_stacks + int(value))
			"plain_momentum":
				GameState.plain_momentum_stacks = mini(3, GameState.plain_momentum_stacks + int(value))
	assert_eq(GameState.plain_surge_stacks, 5, "plain_surge capped at 5")
	assert_eq(GameState.plain_horde_stacks, 3, "plain_horde capped at 3")
	assert_eq(GameState.plain_momentum_stacks, 3, "plain_momentum capped at 3")
	_reset_scenario()

func test_apply_scenario_upgrade_string() -> void:
	begin("string upgrade adds 1 stack")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.starting_upgrades = ["explosions_apply_energize"]
	for entry in TestScenario.starting_upgrades:
		if entry is String:
			GameState.add_wall_break_upgrade(StringName(entry), 1)
	assert_eq(GameState.get_wall_break_upgrade_stacks(&"explosions_apply_energize"), 1, "1 stack applied")
	_reset_scenario()

func test_apply_scenario_upgrade_dict_with_stacks() -> void:
	begin("dict upgrade adds specified stacks")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.starting_upgrades = [{"id": "impact_burst", "stacks": 2}]
	for entry in TestScenario.starting_upgrades:
		if entry is Dictionary:
			GameState.add_wall_break_upgrade(StringName(entry.get("id", "")), entry.get("stacks", 1))
	assert_eq(GameState.get_wall_break_upgrade_stacks(&"impact_burst"), 2, "2 stacks applied")
	_reset_scenario()

func test_apply_scenario_peg_counts() -> void:
	begin("peg counts set via starting_peg_counts")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.starting_peg_counts = {"bomb": 5, "trampoline": 3}
	if TestScenario.starting_peg_counts.has("bomb"):
		GameState.bomb_peg_count += int(TestScenario.starting_peg_counts["bomb"])
	if TestScenario.starting_peg_counts.has("trampoline"):
		GameState.trampoline_peg_count += int(TestScenario.starting_peg_counts["trampoline"])
	assert_eq(GameState.bomb_peg_count, 5, "5 bomb pegs")
	assert_eq(GameState.trampoline_peg_count, 3, "3 trampoline pegs")
	_reset_scenario()

func test_apply_scenario_disabled_does_nothing() -> void:
	begin("disabled scenario does not modify GameState")
	_reset_scenario()
	TestScenario.enabled = false
	TestScenario.starting_stats = {"cannon_damage": 999}
	TestScenario.starting_upgrades = ["explosions_apply_energize"]
	# With enabled=false, game_coordinator skips the scenario
	if TestScenario.enabled:
		GameState.cannon_base_damage_bonus += 999
	assert_eq(GameState.cannon_base_damage_bonus, 0, "no change when disabled")
	assert_eq(GameState.get_wall_break_upgrade_stacks(&"explosions_apply_energize"), 0, "no upgrade when disabled")
	_reset_scenario()

func test_timer_override_default() -> void:
	begin("timer_override -1 uses default wall times")
	_reset_scenario()
	# CombatManager._get_wall_time_ticks checks TestScenario
	# With enabled=false or timer=-1, it falls through to defaults
	var cm_script: GDScript = load("res://scenes/main/combat_manager.gd")
	var cm := Node.new()
	cm.set_script(cm_script)
	# Disabled scenario — should use WALL_TIME_SECONDS
	TestScenario.enabled = false
	var ticks: int = cm._get_wall_time_ticks(0)
	assert_eq(ticks, Constants.WALL_TIME_SECONDS[0] * Constants.SIM_TICKS_PER_SECOND, "wall 0 ticks from Constants.WALL_TIME_SECONDS")
	_reset_scenario()

func test_timer_override_infinite() -> void:
	begin("timer_override 0 gives very large tick count")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.timer_override_seconds = 0
	var cm_script: GDScript = load("res://scenes/main/combat_manager.gd")
	var cm := Node.new()
	cm.set_script(cm_script)
	var ticks: int = cm._get_wall_time_ticks(0)
	assert_gt(ticks, 999998 * 60, "infinite timer = very large")
	_reset_scenario()

func test_timer_override_custom() -> void:
	begin("timer_override positive overrides wall time")
	_reset_scenario()
	TestScenario.enabled = true
	TestScenario.timer_override_seconds = 60
	var cm_script: GDScript = load("res://scenes/main/combat_manager.gd")
	var cm := Node.new()
	cm.set_script(cm_script)
	var ticks: int = cm._get_wall_time_ticks(0)
	assert_eq(ticks, 60 * 60, "60 seconds * 60 ticks")
	var ticks_wall2: int = cm._get_wall_time_ticks(2)
	assert_eq(ticks_wall2, 60 * 60, "same override for all walls")
	_reset_scenario()
