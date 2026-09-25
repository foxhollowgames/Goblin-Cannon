extends "res://tests/test_base.gd"

const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")

func _init() -> void:
	suite_name = "RewardHandler"

func run() -> void:
	_ensure_clean_state()
	test_all_ball_candidates_main_alignment()
	test_no_ball_candidates_have_status_effects()
	test_ball_abilities_are_board_focused()
	test_no_sidearm_upgrade_candidates()
	test_wall_break_candidates_exist()
	test_onboard_effect_candidates_are_physical_relics()
	test_onboard_effect_picks_are_physical_relics()
	test_legacy_stat_upgrade_main_charge_ignored()
	test_legacy_stat_upgrade_cannon_damage_ignored()
	test_legacy_stat_upgrade_cannon_energy_ignored()
	test_legacy_stat_upgrade_door_interval_ignored()
	test_legacy_stat_upgrade_door_duration_ignored()
	test_legacy_stat_upgrade_hopper_width_ignored()
	test_legacy_stat_upgrade_plain_surge_ignored()
	test_legacy_stat_upgrade_plain_horde_ignored()
	test_legacy_stat_upgrade_plain_momentum_ignored()
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

func test_onboard_effect_candidates_are_physical_relics() -> void:
	begin("onboard effect pool contains physical relics")
	var rh := _make_handler()
	assert_not_empty(rh._onboard_effect_candidates, "physical relics present")
	var seen_global: bool = false
	for def in rh._onboard_effect_candidates:
		if def is MajorUpgradeDefinition and def.upgrade_id == &"global_peg_durability":
			seen_global = true
			break
	assert_false(seen_global, "retired global peg durability is excluded")

func test_onboard_effect_picks_are_physical_relics() -> void:
	begin("onboard reward picks resolve to physical relic items")
	var rh := _make_handler()
	var picks: Array = rh.get_onboard_effect_picks(19)
	assert_not_empty(picks, "physical chest picks are available")
	for pick in picks:
		assert_true(pick is MajorUpgradeDefinition, "pick is a relic definition")
		var def: MajorUpgradeDefinition = pick as MajorUpgradeDefinition
		var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(def.upgrade_id)
		assert_true(item != null, "relic definition resolves to physical item")
		assert_true(def.description.contains("Physical device:"), "catalog description states physical trigger")

func test_legacy_stat_upgrade_main_charge_ignored() -> void:
	begin("legacy main charge stat upgrade is ignored")
	_ensure_clean_state()
	var rh := _make_handler()
	var before: float = GameState.main_charge_bonus
	rh.apply_stat_upgrade("main_charge")
	assert_approx(GameState.main_charge_bonus, before, 0.001, "legacy main_charge is ignored")

func test_legacy_stat_upgrade_cannon_damage_ignored() -> void:
	begin("legacy cannon damage stat upgrade is ignored")
	_ensure_clean_state()
	var rh := _make_handler()
	rh.apply_stat_upgrade("cannon_damage")
	assert_eq(GameState.cannon_base_damage_bonus, 0, "legacy cannon damage is ignored")

func test_legacy_stat_upgrade_cannon_energy_ignored() -> void:
	begin("legacy cannon energy stat upgrade is ignored")
	_ensure_clean_state()
	var rh := _make_handler()
	rh.apply_stat_upgrade("cannon_energy")
	assert_eq(GameState.cannon_charge_reduction, 0, "legacy charge reduction is ignored")

func test_legacy_stat_upgrade_door_interval_ignored() -> void:
	begin("legacy door interval stat upgrade is ignored")
	_ensure_clean_state()
	var rh := _make_handler()
	rh.apply_stat_upgrade("door_interval")
	assert_approx(GameState.conduit_wave_interval_scale, 1.0, 0.001, "legacy interval is ignored")

func test_legacy_stat_upgrade_door_duration_ignored() -> void:
	begin("legacy door duration stat upgrade is ignored")
	_ensure_clean_state()
	var rh := _make_handler()
	rh.apply_stat_upgrade("door_duration")
	assert_approx(GameState.conduit_open_duration_scale, 1.0, 0.001, "legacy duration is ignored")

func test_legacy_stat_upgrade_hopper_width_ignored() -> void:
	begin("legacy hopper width stat upgrade is ignored")
	_ensure_clean_state()
	var rh := _make_handler()
	rh.apply_stat_upgrade("hopper_width")
	assert_approx(GameState.hopper_width_scale, 1.0, 0.001, "legacy width is ignored")
	GameState.hopper_width_scale = 1.95
	rh.apply_stat_upgrade("hopper_width")
	assert_approx(GameState.hopper_width_scale, 1.0, 0.001, "legacy width remains ignored")

func test_legacy_stat_upgrade_plain_surge_ignored() -> void:
	begin("legacy plain surge stat upgrade is ignored")
	_ensure_clean_state()
	var rh := _make_handler()
	for _i in 7:
		rh.apply_stat_upgrade("plain_surge")
	assert_eq(GameState.plain_surge_stacks, 0, "legacy plain surge is ignored")

func test_legacy_stat_upgrade_plain_horde_ignored() -> void:
	begin("legacy plain horde stat upgrade is ignored")
	_ensure_clean_state()
	var rh := _make_handler()
	for _i in 5:
		rh.apply_stat_upgrade("plain_horde")
	assert_eq(GameState.plain_horde_stacks, 0, "legacy plain horde is ignored")

func test_legacy_stat_upgrade_plain_momentum_ignored() -> void:
	begin("legacy plain momentum stat upgrade is ignored")
	_ensure_clean_state()
	var rh := _make_handler()
	for _i in 5:
		rh.apply_stat_upgrade("plain_momentum")
	assert_eq(GameState.plain_momentum_stacks, 0, "legacy plain momentum is ignored")

func test_apply_major_upgrade_explosion_radius() -> void:
	begin("apply_major_upgrade explosion_radius adds relic to junk box")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"explosion_radius"
	def.category = MajorUpgradeDefinition.Category.BOARD_UPGRADE
	rh.apply_major_upgrade(def)
	assert_eq(GameState.junk_box.get_item_count(), 1, "relic added to junk box")
	PolyominoRelicDatabase.apply_relic_effects_to_game_state(&"explosion_radius")
	assert_false(GameState.has_wall_break_upgrade(&"explosion_radius"), "legacy registry remains empty")
	assert_eq(GameState.explosion_radius_bonus, 0, "passive stat bonus remains 0")

func test_apply_major_upgrade_chain_arc() -> void:
	begin("apply_major_upgrade chain_arc adds relic to junk box")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"chain_arc"
	def.category = MajorUpgradeDefinition.Category.BOARD_UPGRADE
	rh.apply_major_upgrade(def)
	assert_eq(GameState.junk_box.get_item_count(), 1, "relic added to junk box")
	PolyominoRelicDatabase.apply_relic_effects_to_game_state(&"chain_arc")
	assert_false(GameState.has_wall_break_upgrade(&"chain_arc"), "legacy registry remains empty")
	assert_eq(GameState.chain_arc_bonus, 0, "passive stat bonus remains 0")

func test_apply_major_upgrade_chest_leech_drain() -> void:
	begin("apply_major_upgrade chest_leech_drain adds relic to junk box")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"chest_leech_drain"
	def.category = MajorUpgradeDefinition.Category.ONBOARD_PASSIVE
	rh.apply_major_upgrade(def)
	assert_eq(GameState.junk_box.get_item_count(), 1, "relic added to junk box")
	PolyominoRelicDatabase.apply_relic_effects_to_game_state(&"chest_leech_drain")
	assert_false(GameState.has_wall_break_upgrade(&"chest_leech_drain"), "legacy registry remains empty")
	assert_eq(GameState.chest_leech_drain_stacks, 0, "passive stat stack remains 0")

func test_apply_major_upgrade_devastating_barrage_once() -> void:
	begin("apply_major_upgrade devastating_barrage adds relic to junk box")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"devastating_barrage"
	def.category = MajorUpgradeDefinition.Category.ONBOARD_PASSIVE
	rh.apply_major_upgrade(def)
	assert_eq(GameState.junk_box.get_item_count(), 1, "relic added to junk box")
	PolyominoRelicDatabase.apply_relic_effects_to_game_state(&"devastating_barrage")
	assert_false(GameState.has_wall_break_upgrade(&"devastating_barrage"), "legacy registry remains empty")
	assert_eq(GameState.cannon_base_damage_bonus, 0, "passive stat bonus remains 0")

func test_apply_major_upgrade_compressed_charge_once() -> void:
	begin("apply_major_upgrade compressed_charge adds relic to junk box")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"compressed_charge"
	def.category = MajorUpgradeDefinition.Category.ONBOARD_PASSIVE
	rh.apply_major_upgrade(def)
	assert_eq(GameState.junk_box.get_item_count(), 1, "relic added to junk box")
	PolyominoRelicDatabase.apply_relic_effects_to_game_state(&"compressed_charge")
	assert_false(GameState.has_wall_break_upgrade(&"compressed_charge"), "legacy registry remains empty")
	assert_eq(GameState.cannon_charge_reduction, 0, "passive stat reduction remains 0")

func test_onboard_effect_picks_exclude_devastating_barrage_when_taken() -> void:
	begin("get_onboard_effect_picks keeps physical cannon relic after legacy flag")
	_ensure_clean_state()
	GameState.chest_devastating_barrage_taken = true
	var rh := _make_handler()
	var picks: Array = rh.get_onboard_effect_picks(50)
	var found: bool = false
	for p in picks:
		if p is MajorUpgradeDefinition and (p as MajorUpgradeDefinition).upgrade_id == &"devastating_barrage":
			found = true
	assert_false(found, "retired cannon relic is excluded")

func test_onboard_effect_picks_exclude_compressed_charge_when_taken() -> void:
	begin("get_onboard_effect_picks keeps physical charge relic after legacy flag")
	_ensure_clean_state()
	GameState.chest_compressed_charge_taken = true
	var rh := _make_handler()
	var picks: Array = rh.get_onboard_effect_picks(50)
	var found: bool = false
	for p in picks:
		if p is MajorUpgradeDefinition and (p as MajorUpgradeDefinition).upgrade_id == &"compressed_charge":
			found = true
	assert_false(found, "retired charge relic is excluded")

func test_apply_major_upgrade_plain_horde_delegates() -> void:
	begin("apply_major_upgrade plain_horde adds relic to junk box")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"plain_horde"
	def.category = MajorUpgradeDefinition.Category.BOARD_UPGRADE
	rh.apply_major_upgrade(def)
	assert_eq(GameState.junk_box.get_item_count(), 1, "relic added to junk box")
	PolyominoRelicDatabase.apply_relic_effects_to_game_state(&"plain_horde")
	assert_false(GameState.has_wall_break_upgrade(&"plain_horde"), "legacy registry remains empty")
	assert_eq(GameState.plain_horde_stacks, 0, "passive stat stack remains 0")

func test_major_upgrade_picks_exclude_plain_swarm_at_cap() -> void:
	begin("get_major_upgrade_picks keeps physical plain relic at legacy cap")
	_ensure_clean_state()
	GameState.plain_horde_stacks = 3
	var rh := _make_handler()
	var picks: Array = rh.get_major_upgrade_picks(50)
	var found: bool = false
	for p in picks:
		if p is MajorUpgradeDefinition and (p as MajorUpgradeDefinition).upgrade_id == &"plain_horde":
			found = true
	assert_false(found, "retired plain relic is excluded")

func test_apply_major_upgrade_stack_cap_respected() -> void:
	begin("apply_major_upgrade adds relic item to junk box")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"hyper_elastic"
	def.category = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
	def.ball_type = "Rubbery"
	rh.apply_major_upgrade(def)
	assert_eq(GameState.junk_box.get_item_count(), 1, "first relic added to junk box")

func test_apply_major_upgrade_volt_primer_once() -> void:
	begin("apply_major_upgrade adds volt primer relic to junk box")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"volt_primer"
	def.category = MajorUpgradeDefinition.Category.BOARD_UPGRADE
	rh.apply_major_upgrade(def)
	assert_eq(GameState.junk_box.get_item_count(), 1, "volt primer added to junk box")

func test_apply_major_upgrade_chest_random_ball() -> void:
	begin("apply_major_upgrade adds chest random ball relic to junk box")
	_ensure_clean_state()
	var rh := _make_handler()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"chest_random_ball"
	def.category = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
	rh.apply_major_upgrade(def)
	assert_eq(GameState.junk_box.get_item_count(), 1, "chest random ball added to junk box")

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
	assert_eq(rh._major_upgrade_ball_gate_weight(def_missing), 1.0, "missing ball type does not gate physical relic")
	var cross: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	cross.required_ball_types = ["Split", "Explosive"]
	assert_eq(rh._major_upgrade_ball_gate_weight(cross), 1.0, "missing required type does not gate physical relic")

func test_major_upgrade_picks_respect_stack_cap() -> void:
	begin("get_major_upgrade_picks keeps physical relic at legacy cap")
	_ensure_clean_state()
	GameState.record_ball_ability_in_run("Rubbery")
	GameState.add_wall_break_upgrade(&"hyper_elastic", 1)
	var rh := _make_handler()
	var picks: Array = rh.get_major_upgrade_picks(50)
	var found: bool = false
	for p in picks:
		if p is MajorUpgradeDefinition and p.upgrade_id == &"hyper_elastic":
			found = true
	assert_false(found, "retired elastic relic is excluded")

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
