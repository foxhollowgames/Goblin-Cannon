extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "RewardHandler"

func run() -> void:
	_ensure_clean_state()
	test_all_ball_candidates_main_alignment()
	test_no_ball_candidates_have_status_effects()
	test_ball_abilities_are_board_focused()
	test_no_sidearm_upgrade_candidates()
	test_wall_break_candidates_exist()
	test_apply_stat_upgrade_main_charge()
	test_apply_stat_upgrade_cannon_damage()
	test_apply_stat_upgrade_cannon_energy()
	test_apply_stat_upgrade_door_interval()
	test_apply_stat_upgrade_door_duration()
	test_apply_major_upgrade_explosion_radius()
	test_apply_major_upgrade_chain_arc()
	test_apply_major_upgrade_stack_cap_respected()
	test_apply_major_upgrade_board_upgrades()
	test_major_upgrade_picks_filter_by_ability_in_run()
	test_major_upgrade_picks_respect_stack_cap()

func _ensure_clean_state() -> void:
	if GameState:
		GameState.start_run(42)

func _make_handler() -> Node:
	var script: GDScript = load("res://scenes/rewards/reward_handler.gd")
	var rh := Node.new()
	rh.set_script(script)
	# Manually initialize what _ready() would do, without needing the scene tree
	rh._reward_gen = RewardGeneration.new(GameState.run_seed)
	rh._ball_candidates = rh._build_ball_candidates()
	rh._build_wall_break_candidates()
	return rh

func test_all_ball_candidates_main_alignment() -> void:
	begin("all ball candidates have ALIGNMENT_MAIN (0)")
	var rh := _make_handler()
	for def in rh._ball_candidates:
		if def is BallDefinition:
			assert_eq(def.alignment, Constants.ALIGNMENT_MAIN,
				"ball '%s' alignment" % def.ability_name)

func test_no_ball_candidates_have_status_effects() -> void:
	begin("no ball candidates have status_effects")
	var rh := _make_handler()
	for def in rh._ball_candidates:
		if def is BallDefinition:
			assert_true(def.status_effects.is_empty(),
				"ball '%s' has no status effects" % def.ability_name)

func test_ball_abilities_are_board_focused() -> void:
	begin("ball abilities are all board-focused (no Flame/Frost/etc.)")
	var rh := _make_handler()
	var removed_abilities: Array = [
		"Flame", "Frost", "Spark", "Ember", "Chill", "Bolt",
		"Flare", "Surge", "Blaze", "Inferno", "Glacier", "Volt",
		"Ward", "Aegis"
	]
	for def in rh._ball_candidates:
		if def is BallDefinition:
			assert_not_in(def.ability_name, removed_abilities,
				"'%s' should not be in candidates" % def.ability_name)

func test_no_sidearm_upgrade_candidates() -> void:
	begin("no SIDEARM category in ball_enhancement or board candidates")
	var rh := _make_handler()
	for def in rh._ball_enhancement_candidates:
		if def is MajorUpgradeDefinition:
			assert_neq(def.category, MajorUpgradeDefinition.Category.SIDEARM,
				"enhancement '%s' not SIDEARM category" % def.display_name)
	for def in rh._board_candidates:
		if def is MajorUpgradeDefinition:
			assert_neq(def.category, MajorUpgradeDefinition.Category.SIDEARM,
				"board '%s' not SIDEARM category" % def.display_name)

func test_wall_break_candidates_exist() -> void:
	begin("wall break candidates have ball enhancements and board upgrades")
	var rh := _make_handler()
	assert_not_empty(rh._ball_enhancement_candidates, "ball enhancements present")
	assert_not_empty(rh._board_candidates, "board upgrades present")

func test_apply_stat_upgrade_main_charge() -> void:
	begin("apply_stat_upgrade 'main_charge' increases bonus")
	_ensure_clean_state()
	var rh := _make_handler()
	var before: float = GameState.main_charge_bonus
	rh.apply_stat_upgrade("main_charge")
	assert_approx(GameState.main_charge_bonus, before + 0.05, 0.001, "+0.05 main_charge")

func test_apply_stat_upgrade_cannon_damage() -> void:
	begin("apply_stat_upgrade 'cannon_damage' increases bonus")
	_ensure_clean_state()
	var rh := _make_handler()
	rh.apply_stat_upgrade("cannon_damage")
	assert_eq(GameState.cannon_base_damage_bonus, 5, "+5 cannon damage")

func test_apply_stat_upgrade_cannon_energy() -> void:
	begin("apply_stat_upgrade 'cannon_energy' increases reduction")
	_ensure_clean_state()
	var rh := _make_handler()
	rh.apply_stat_upgrade("cannon_energy")
	assert_eq(GameState.cannon_charge_reduction, 2000, "+2000 charge reduction")

func test_apply_stat_upgrade_door_interval() -> void:
	begin("apply_stat_upgrade 'door_interval' reduces scale")
	_ensure_clean_state()
	var rh := _make_handler()
	rh.apply_stat_upgrade("door_interval")
	assert_approx(GameState.conduit_wave_interval_scale, 0.9, 0.001, "1.0 - 0.1 = 0.9")

func test_apply_stat_upgrade_door_duration() -> void:
	begin("apply_stat_upgrade 'door_duration' increases scale")
	_ensure_clean_state()
	var rh := _make_handler()
	rh.apply_stat_upgrade("door_duration")
	assert_approx(GameState.conduit_open_duration_scale, 1.1, 0.001, "1.0 + 0.1 = 1.1")

func test_apply_major_upgrade_explosion_radius() -> void:
	begin("apply_major_upgrade explosion_radius increases bonus")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"explosion_radius"
	def.category = MajorUpgradeDefinition.Category.BOARD_UPGRADE
	rh.apply_major_upgrade(def)
	assert_eq(GameState.explosion_radius_bonus, 1, "+1 explosion radius")

func test_apply_major_upgrade_chain_arc() -> void:
	begin("apply_major_upgrade chain_arc increases bonus")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"chain_arc"
	def.category = MajorUpgradeDefinition.Category.BOARD_UPGRADE
	rh.apply_major_upgrade(def)
	assert_eq(GameState.chain_arc_bonus, 1, "+1 chain arc")

func test_apply_major_upgrade_stack_cap_respected() -> void:
	begin("apply_major_upgrade respects stack cap")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"hyper_elastic"
	def.category = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
	def.ball_type = "Rubbery"
	rh.apply_major_upgrade(def)
	assert_eq(GameState.get_wall_break_upgrade_stacks(&"hyper_elastic"), 1, "first stack applied")
	rh.apply_major_upgrade(def)
	assert_eq(GameState.get_wall_break_upgrade_stacks(&"hyper_elastic"), 1, "capped at 1, second not applied")

func test_apply_major_upgrade_board_upgrades() -> void:
	begin("apply_major_upgrade handles board peg upgrades")
	_ensure_clean_state()
	var rh := _make_handler()
	var bomb := MajorUpgradeDefinition.new()
	bomb.upgrade_id = &"add_bomb_peg"
	bomb.category = MajorUpgradeDefinition.Category.BOARD_UPGRADE
	rh.apply_major_upgrade(bomb)
	assert_eq(GameState.bomb_peg_count, 1, "+1 bomb peg")
	var tramp := MajorUpgradeDefinition.new()
	tramp.upgrade_id = &"add_trampoline_peg"
	tramp.category = MajorUpgradeDefinition.Category.BOARD_UPGRADE
	rh.apply_major_upgrade(tramp)
	assert_eq(GameState.trampoline_peg_count, 1, "+1 trampoline peg")

func test_major_upgrade_picks_filter_by_ability_in_run() -> void:
	begin("get_major_upgrade_picks filters ball enhancements by ability in run")
	_ensure_clean_state()
	var rh := _make_handler()
	# No abilities recorded — ball enhancements with ball_type should be excluded
	var picks: Array = rh.get_major_upgrade_picks(50)
	for p in picks:
		if p is MajorUpgradeDefinition and p.category == MajorUpgradeDefinition.Category.BALL_ENHANCEMENT:
			assert_true(p.ball_type.is_empty(),
				"only generic ball enhancements offered when no abilities in run; got '%s' for type '%s'" % [p.display_name, p.ball_type])

func test_major_upgrade_picks_respect_stack_cap() -> void:
	begin("get_major_upgrade_picks excludes at-cap upgrades")
	_ensure_clean_state()
	GameState.record_ball_ability_in_run("Rubbery")
	GameState.add_wall_break_upgrade(&"hyper_elastic", 1)
	var rh := _make_handler()
	var picks: Array = rh.get_major_upgrade_picks(50)
	for p in picks:
		if p is MajorUpgradeDefinition:
			assert_neq(p.upgrade_id, &"hyper_elastic", "hyper_elastic excluded at cap")
