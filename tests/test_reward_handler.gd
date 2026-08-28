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
	test_onboard_effect_candidates_exist()
	test_apply_stat_upgrade_main_charge()
	test_apply_stat_upgrade_cannon_damage()
	test_apply_stat_upgrade_cannon_energy()
	test_apply_stat_upgrade_door_interval()
	test_apply_stat_upgrade_door_duration()
	test_apply_stat_upgrade_hopper_width()
	test_apply_stat_upgrade_plain_surge_cap()
	test_apply_stat_upgrade_plain_horde_cap()
	test_apply_stat_upgrade_plain_momentum_cap()
	test_apply_major_upgrade_explosion_radius()
	test_apply_major_upgrade_chain_arc()
	test_apply_major_upgrade_chest_leech_drain()
	test_apply_major_upgrade_devastating_barrage_once()
	test_apply_major_upgrade_compressed_charge_once()
	test_onboard_effect_picks_exclude_devastating_barrage_when_taken()
	test_onboard_effect_picks_exclude_compressed_charge_when_taken()
	test_apply_major_upgrade_plain_horde_delegates()
	test_major_upgrade_picks_exclude_plain_swarm_at_cap()
	test_apply_major_upgrade_stack_cap_respected()
	test_apply_major_upgrade_volt_primer_once()
	test_apply_major_upgrade_chest_random_ball()
	test_grant_random_ball_from_city_pool()
	test_apply_peg_shop_unlock_board_pegs()
	test_apply_peg_shop_unlock_lucky_gold()
	test_major_upgrade_ball_gate_weight()
	test_major_upgrade_picks_respect_stack_cap()
	test_boss_upgrade_picks_returns_requested_count()
	test_apply_milestone_pick_basic_batch_with_stub()
	test_apply_milestone_pick_ball_upgrade_with_stub()
	test_relic_descriptions_use_standard_tags_and_no_deprecated_once()

func _ensure_clean_state() -> void:
	if GameState:
		GameState.start_run(42)

func _make_handler() -> Node:
	var script: GDScript = load("res://scenes/rewards/reward_handler.gd")
	var rh := Node.new()
	rh.set_script(script)
	rh._reward_gen = RewardGeneration.new(GameState.run_seed)
	rh._ball_candidates = rh._build_ball_candidates()
	rh._build_peg_shop_candidates()
	rh._build_wall_break_candidates()
	rh._build_onboard_effect_candidates()
	rh._build_boss_candidates()
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
	for def in rh._onboard_effect_candidates:
		if def is MajorUpgradeDefinition:
			assert_neq(def.category, MajorUpgradeDefinition.Category.SIDEARM,
				"onboard '%s' not SIDEARM category" % def.display_name)

func test_wall_break_candidates_exist() -> void:
	begin("wall break candidates have ball enhancements and board upgrades")
	var rh := _make_handler()
	assert_not_empty(rh._ball_enhancement_candidates, "ball enhancements present")
	assert_not_empty(rh._board_candidates, "board upgrades present (plain swarm)")

func test_onboard_effect_candidates_exist() -> void:
	begin("onboard effect pool has passive tag upgrades")
	var rh := _make_handler()
	assert_not_empty(rh._onboard_effect_candidates, "onboard passives present")
	var seen_global: bool = false
	for def in rh._onboard_effect_candidates:
		if def is MajorUpgradeDefinition and def.upgrade_id == &"global_peg_durability":
			seen_global = true
			break
	assert_true(seen_global, "includes global peg durability")

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
	assert_eq(GameState.cannon_charge_reduction, Constants.legacy_internal_energy_to_current(2000), "scaled charge reduction")

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

func test_apply_stat_upgrade_hopper_width() -> void:
	begin("apply_stat_upgrade 'hopper_width' increases scale capped at 2")
	_ensure_clean_state()
	var rh := _make_handler()
	rh.apply_stat_upgrade("hopper_width")
	assert_approx(GameState.hopper_width_scale, 1.1, 0.001, "+0.1 width")
	GameState.hopper_width_scale = 1.95
	rh.apply_stat_upgrade("hopper_width")
	assert_approx(GameState.hopper_width_scale, 2.0, 0.001, "capped at 2.0")

func test_apply_stat_upgrade_plain_surge_cap() -> void:
	begin("apply_stat_upgrade 'plain_surge' stacks to max 5")
	_ensure_clean_state()
	var rh := _make_handler()
	for _i in 7:
		rh.apply_stat_upgrade("plain_surge")
	assert_eq(GameState.plain_surge_stacks, 5, "capped at 5")

func test_apply_stat_upgrade_plain_horde_cap() -> void:
	begin("apply_stat_upgrade 'plain_horde' stacks to max 3")
	_ensure_clean_state()
	var rh := _make_handler()
	for _i in 5:
		rh.apply_stat_upgrade("plain_horde")
	assert_eq(GameState.plain_horde_stacks, 3, "capped at 3")

func test_apply_stat_upgrade_plain_momentum_cap() -> void:
	begin("apply_stat_upgrade 'plain_momentum' stacks to max 3")
	_ensure_clean_state()
	var rh := _make_handler()
	for _i in 5:
		rh.apply_stat_upgrade("plain_momentum")
	assert_eq(GameState.plain_momentum_stacks, 3, "capped at 3")

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

func test_apply_major_upgrade_chest_leech_drain() -> void:
	begin("apply_major_upgrade chest_leech_drain stacks (chest passive)")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"chest_leech_drain"
	def.category = MajorUpgradeDefinition.Category.ONBOARD_PASSIVE
	rh.apply_major_upgrade(def)
	assert_eq(GameState.chest_leech_drain_stacks, 1, "+1 chest leech drain stack")

func test_apply_major_upgrade_devastating_barrage_once() -> void:
	begin("apply_major_upgrade devastating_barrage grants +10 damage once")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"devastating_barrage"
	def.category = MajorUpgradeDefinition.Category.ONBOARD_PASSIVE
	rh.apply_major_upgrade(def)
	assert_eq(GameState.cannon_base_damage_bonus, 10, "+10 cannon damage")
	assert_true(GameState.chest_devastating_barrage_taken, "flag set")
	rh.apply_major_upgrade(def)
	assert_eq(GameState.cannon_base_damage_bonus, 10, "no second +10")

func test_apply_major_upgrade_compressed_charge_once() -> void:
	begin("apply_major_upgrade compressed_charge applies charge reduction once")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"compressed_charge"
	def.category = MajorUpgradeDefinition.Category.ONBOARD_PASSIVE
	var step: int = Constants.legacy_internal_energy_to_current(2000)
	rh.apply_major_upgrade(def)
	assert_eq(GameState.cannon_charge_reduction, step, "+1 cannon energy tier")
	assert_true(GameState.chest_compressed_charge_taken, "flag set")
	rh.apply_major_upgrade(def)
	assert_eq(GameState.cannon_charge_reduction, step, "no second tier")

func test_onboard_effect_picks_exclude_devastating_barrage_when_taken() -> void:
	begin("get_onboard_effect_picks omits devastating_barrage after taken")
	_ensure_clean_state()
	GameState.chest_devastating_barrage_taken = true
	var rh := _make_handler()
	var picks: Array = rh.get_onboard_effect_picks(50)
	for p in picks:
		if p is MajorUpgradeDefinition:
			assert_neq((p as MajorUpgradeDefinition).upgrade_id, &"devastating_barrage", "excluded when taken")

func test_onboard_effect_picks_exclude_compressed_charge_when_taken() -> void:
	begin("get_onboard_effect_picks omits compressed_charge after taken")
	_ensure_clean_state()
	GameState.chest_compressed_charge_taken = true
	var rh := _make_handler()
	var picks: Array = rh.get_onboard_effect_picks(50)
	for p in picks:
		if p is MajorUpgradeDefinition:
			assert_neq((p as MajorUpgradeDefinition).upgrade_id, &"compressed_charge", "excluded when taken")

func test_apply_major_upgrade_plain_horde_delegates() -> void:
	begin("apply_major_upgrade plain_horde uses same stacks as stat upgrade")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"plain_horde"
	def.category = MajorUpgradeDefinition.Category.BOARD_UPGRADE
	rh.apply_major_upgrade(def)
	assert_eq(GameState.plain_horde_stacks, 1, "+1 plain horde stack")

func test_major_upgrade_picks_exclude_plain_swarm_at_cap() -> void:
	begin("get_major_upgrade_picks omits plain swarm upgrades at stack cap")
	_ensure_clean_state()
	GameState.plain_horde_stacks = 3
	var rh := _make_handler()
	var picks: Array = rh.get_major_upgrade_picks(50)
	for p in picks:
		if p is MajorUpgradeDefinition:
			assert_neq((p as MajorUpgradeDefinition).upgrade_id, &"plain_horde", "plain_horde excluded when capped")

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

func test_apply_major_upgrade_volt_primer_once() -> void:
	begin("apply_major_upgrade volt_primer stacks once")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"volt_primer"
	def.category = MajorUpgradeDefinition.Category.BOARD_UPGRADE
	rh.apply_major_upgrade(def)
	assert_eq(GameState.get_wall_break_upgrade_stacks(&"volt_primer"), 1, "first stack applied")
	rh.apply_major_upgrade(def)
	assert_eq(GameState.get_wall_break_upgrade_stacks(&"volt_primer"), 1, "capped at 1")

func test_apply_major_upgrade_chest_random_ball() -> void:
	begin("apply_major_upgrade chest_random_ball stacks once")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"chest_random_ball"
	def.category = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
	rh.apply_major_upgrade(def)
	assert_eq(GameState.get_wall_break_upgrade_stacks(&"chest_random_ball"), 1, "first stack applied")
	rh.apply_major_upgrade(def)
	assert_eq(GameState.get_wall_break_upgrade_stacks(&"chest_random_ball"), 1, "capped at 1")

func test_grant_random_ball_from_city_pool() -> void:
	begin("grant_random_ball_from_city_pool adds one ball to hopper")
	_ensure_clean_state()
	var rh := _make_handler()
	var hopper_stub: Node = load("res://tests/hopper_reward_stub.gd").new()
	rh._hopper = hopper_stub
	rh.grant_random_ball_from_city_pool()
	assert_eq(hopper_stub.balls_added, 1, "one ball granted")

func test_apply_peg_shop_unlock_board_pegs() -> void:
	begin("apply_peg_shop_unlock handles peg unlocks with peg selection")
	_ensure_clean_state()
	var rh := _make_handler()
	rh.apply_peg_shop_unlock("bomb")
	assert_eq(GameState.bomb_peg_count, 1, "+1 bomb peg")
	assert_true(rh.has_pending_peg_selection(), "pending peg selection after bomb")
	assert_eq(rh.get_pending_peg_kind(), "bomb", "pending kind is bomb")
	rh.clear_pending_peg_selection()
	rh.apply_peg_shop_unlock("trampoline")
	assert_eq(GameState.trampoline_peg_count, 1, "+1 trampoline peg")
	assert_true(rh.has_pending_peg_selection(), "pending peg selection after trampoline")
	assert_eq(rh.get_pending_peg_kind(), "trampoline", "pending kind is trampoline")
	rh.clear_pending_peg_selection()

func test_apply_peg_shop_unlock_lucky_gold() -> void:
	begin("apply_peg_shop_unlock lucky_gold increments count and peg selection")
	_ensure_clean_state()
	var rh := _make_handler()
	rh.apply_peg_shop_unlock("lucky_gold")
	assert_eq(GameState.lucky_gold_peg_count, 1, "+1 lucky gold peg")
	assert_true(rh.has_pending_peg_selection(), "pending peg selection after lucky gold")
	assert_eq(rh.get_pending_peg_kind(), "lucky_gold", "pending kind is lucky_gold")

func test_major_upgrade_ball_gate_weight() -> void:
	begin("_major_upgrade_ball_gate_weight is full weight when types owned, reduced when missing")
	_ensure_clean_state()
	var rh := _make_handler()
	var def_ok := MajorUpgradeDefinition.new()
	def_ok.ball_type = "Rubbery"
	var def_missing := MajorUpgradeDefinition.new()
	def_missing.ball_type = "Phantom"
	GameState.record_ball_ability_in_run("Rubbery")
	assert_eq(rh._major_upgrade_ball_gate_weight(def_ok), 1.0, "owned ball type")
	assert_approx(rh._major_upgrade_ball_gate_weight(def_missing), 0.05, 0.001, "missing ball type")
	var cross: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	cross.required_ball_types = ["Split", "Explosive"]
	assert_approx(rh._major_upgrade_ball_gate_weight(cross), 0.05, 0.001, "missing required cross type")

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

func test_boss_upgrade_picks_returns_requested_count() -> void:
	begin("boss reward returns requested pick count when pool is large enough")
	_ensure_clean_state()
	var rh := _make_handler()
	var boss_picks: Array = rh.get_boss_upgrade_picks(3)
	assert_eq(boss_picks.size(), 3, "three boss picks when pool has enough unique ids")

func test_apply_milestone_pick_basic_batch_with_stub() -> void:
	begin("apply_milestone_pick BASIC_BATCH adds basic balls via coordinator")
	_ensure_clean_state()
	var rh := _make_handler()
	var stub: Node = load("res://tests/coordinator_milestone_stub.gd").new()
	rh._game_coordinator = stub
	var opt: MilestoneOption = MilestoneOption.new()
	opt.option_type = MilestoneOption.Type.BASIC_BATCH
	rh.apply_milestone_pick(opt)
	assert_eq(stub.basic_added, RewardGeneration.BASIC_BATCH_SIZE, "batch size matches constant")

func test_apply_milestone_pick_ball_upgrade_with_stub() -> void:
	begin("apply_milestone_pick BALL_UPGRADE delegates to coordinator conversion")
	_ensure_clean_state()
	var rh := _make_handler()
	var stub: Node = load("res://tests/coordinator_milestone_stub.gd").new()
	rh._game_coordinator = stub
	var d: BallDefinition = BallDefinition.new()
	d.ability_name = "Split"
	var opt: MilestoneOption = MilestoneOption.new()
	opt.option_type = MilestoneOption.Type.BALL_UPGRADE
	opt.ball_definition = d
	rh.apply_milestone_pick(opt)
	assert_true(stub.last_conversion != null, "conversion received a definition")
	assert_eq(stub.last_conversion.ability_name, "Split", "ability forwarded")

func test_relic_descriptions_use_standard_tags_and_no_deprecated_once() -> void:
	begin("relic descriptions are non-empty, use colon structure, and avoid trailing 'Once.'")
	var rh := _make_handler()
	var all_defs: Array = rh.get_catalog_wall_break_major_definitions() + rh.get_catalog_boss_definitions() + rh.get_catalog_onboard_effect_definitions()
	for d in all_defs:
		if d is MajorUpgradeDefinition:
			var desc: String = (d as MajorUpgradeDefinition).description
			assert_false(desc.strip_edges().is_empty(), "desc not empty for %s" % d.display_name)
			assert_false(desc.ends_with("Once."), "no trailing 'Once.' on %s" % d.display_name)
			assert_true(desc.contains(":"), "uses standardized prefix/colon format on %s" % d.display_name)
