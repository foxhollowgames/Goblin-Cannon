extends "res://tests/test_base.gd"

const DeliberateRelicCatalog = preload("res://resources/polyomino/deliberate_relic_catalog.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const RewardCardCatalog = preload("res://scenes/rewards/reward_card_catalog.gd")
const RewardHandlerScript = preload("res://scenes/rewards/reward_handler.gd")
const DebugFullStoreModalScript = preload("res://scenes/ui/debug_full_store_modal.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")

func _init() -> void:
	suite_name = "DebugStoreNewRelics"

func run() -> void:
	test_catalog_completeness_and_variations()
	test_track_polyomino_configurations()
	test_relic_database_integration()
	test_reward_card_catalog_deliberate_candidates()
	test_reward_handler_integration()
	test_debug_store_modal_tabs_and_items()
	test_debug_store_apply_relic_to_junk_box()
	cleanup()

func test_catalog_completeness_and_variations() -> void:
	begin("DeliberateRelicCatalog has 42 relics (7 archetypes x 3 tiers x 2 variations)")
	var ids: Array[StringName] = DeliberateRelicCatalog.get_all_ids()
	assert_eq(ids.size(), 42, "Expected exactly 42 deliberate relics in catalog")

	var tier_counts: Dictionary = {1: 0, 2: 0, 3: 0}
	for id in ids:
		var d: Dictionary = DeliberateRelicCatalog.get_relic(id)
		assert_false(d.is_empty(), "Relic %s must have definition" % id)
		var tier: int = int(d.get("tier", 0))
		assert_true(tier >= 1 and tier <= 3, "Relic %s has valid tier (1-3)" % id)
		tier_counts[tier] = tier_counts.get(tier, 0) + 1
		assert_false(str(d.get("display_name", "")).is_empty(), "Relic %s has display name" % id)
		assert_false(str(d.get("shape_name", "")).is_empty(), "Relic %s has shape name" % id)
		assert_false(str(d.get("machinery_desc", "")).is_empty(), "Relic %s has machinery desc" % id)

		var g: Dictionary = DeliberateRelicCatalog.get_goal(id)
		assert_false(g.is_empty(), "Relic %s has goal definition" % id)
		assert_false(str(g.get("activation_req", "")).is_empty(), "Relic %s has activation_req" % id)
		assert_false(str(g.get("reward_desc", "")).is_empty(), "Relic %s has reward_desc" % id)

	# 7 archetypes * 2 variations = 14 relics per tier
	assert_eq(tier_counts[1], 14, "Expected 14 Tier 1 deliberate relics")
	assert_eq(tier_counts[2], 14, "Expected 14 Tier 2 deliberate relics")
	assert_eq(tier_counts[3], 14, "Expected 14 Tier 3 deliberate relics")

func test_track_polyomino_configurations() -> void:
	begin("Track relics include stairs, right-angles, U-turns, zigzags, and closed loops")
	# 1. Stairs
	assert_true(DeliberateRelicCatalog.has_relic(&"track_stairs_step"), "track_stairs_step exists")
	var stairs: Dictionary = DeliberateRelicCatalog.get_relic(&"track_stairs_step")
	assert_eq(stairs.get("shape_name"), "Z-Step Polyomino", "stairs shape name matches")

	# 2. Right-angle elbow
	assert_true(DeliberateRelicCatalog.has_relic(&"track_right_angle"), "track_right_angle exists")
	var elbow: Dictionary = DeliberateRelicCatalog.get_relic(&"track_right_angle")
	assert_eq(elbow.get("shape_name"), "L-Turn Polyomino", "elbow shape name matches")

	# 3. U-turn loop
	assert_true(DeliberateRelicCatalog.has_relic(&"track_u_turn"), "track_u_turn exists")
	var uturn: Dictionary = DeliberateRelicCatalog.get_relic(&"track_u_turn")
	assert_eq(uturn.get("shape_name"), "U-Turn Polyomino", "u-turn shape name matches")

	# 4. Zigzag switchback
	assert_true(DeliberateRelicCatalog.has_relic(&"track_zigzag_chute"), "track_zigzag_chute exists")
	var zigzag: Dictionary = DeliberateRelicCatalog.get_relic(&"track_zigzag_chute")
	assert_eq(zigzag.get("shape_name"), "S-Curve Snake Polyomino", "zigzag shape name matches")

	# 5. Grand closed orbit loop
	assert_true(DeliberateRelicCatalog.has_relic(&"track_grand_orbit"), "track_grand_orbit exists")
	var orbit: Dictionary = DeliberateRelicCatalog.get_relic(&"track_grand_orbit")
	assert_eq(orbit.get("shape_name"), "Closed Loop Polyomino", "grand orbit shape name matches")

func test_relic_database_integration() -> void:
	begin("PolyominoRelicDatabase provides deliberate relics and creates items")
	var d_ids: Array[StringName] = PolyominoRelicDatabase.get_deliberate_relic_ids()
	assert_eq(d_ids.size(), 42, "PolyominoRelicDatabase exposes 42 deliberate relic IDs")

	for id in d_ids:
		assert_true(PolyominoRelicDatabase.has_relic_definition(id), "Database acknowledges %s" % id)
		var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(id)
		assert_true(item != null, "Item created for %s" % id)
		assert_true(item.module_data != null, "Module data present for %s" % id)
		assert_false(item.module_data.cells.is_empty(), "Cells present for %s" % id)
		assert_false(PolyominoRelicDatabase.get_relic_shape_name(id).is_empty(), "Shape name present for %s" % id)
		assert_false(PolyominoRelicDatabase.get_relic_kinetic_description(id).is_empty(), "Kinetic desc present for %s" % id)

func test_reward_card_catalog_deliberate_candidates() -> void:
	begin("RewardCardCatalog.build_deliberate_relic_candidates formats colon descriptions")
	var candidates: Array = RewardCardCatalog.build_deliberate_relic_candidates()
	assert_eq(candidates.size(), 42, "Expected 42 candidate upgrade definitions")

	for def in candidates:
		assert_true(def is MajorUpgradeDefinition, "Candidate is MajorUpgradeDefinition")
		var d: MajorUpgradeDefinition = def as MajorUpgradeDefinition
		assert_false(d.display_name.is_empty(), "Display name not empty for %s" % d.upgrade_id)
		assert_false(d.description.is_empty(), "Description not empty for %s" % d.upgrade_id)
		assert_true(d.description.contains(":"), "Description contains colon format for %s" % d.upgrade_id)
		assert_false(d.description.ends_with("Once."), "No trailing 'Once.' for %s" % d.upgrade_id)

func test_reward_handler_integration() -> void:
	begin("RewardHandler exposes deliberate relic definitions")
	var rh: Node = Node.new()
	rh.set_script(RewardHandlerScript)
	autofree(rh)
	assert_true(rh.has_method("get_catalog_deliberate_relic_definitions"), "RewardHandler has method")
	var defs: Array = rh.get_catalog_deliberate_relic_definitions()
	assert_eq(defs.size(), 42, "RewardHandler returns 42 deliberate relic definitions")

func test_debug_store_modal_tabs_and_items() -> void:
	begin("DebugFullStoreModal has 'Relics' tab and lists only deliberate relics")
	var modal: Control = DebugFullStoreModalScript.new() as Control
	autofree(modal)

	var rh: Node = Node.new()
	rh.set_script(RewardHandlerScript)
	autofree(rh)

	modal.setup(null, rh)
	var tab_names: Array[String] = modal.get("_tab_names")
	assert_true(tab_names.has("Relics"), "Tab list contains 'Relics'")
	assert_false(tab_names.has("Wall breaks"), "Legacy 'Wall breaks' tab is removed")
	assert_false(tab_names.has("Boss rewards"), "Legacy 'Boss rewards' tab is removed")

	modal.show_modal()
	# Relics tab is index 2
	var relic_items: Array = modal._items_for_tab(2)
	assert_eq(relic_items.size(), 42, "Relics tab contains exactly 42 deliberate items")

func test_debug_store_apply_relic_to_junk_box() -> void:
	begin("DebugFullStoreModal applies relic directly into GameState.junk_box")
	if GameState:
		GameState.junk_box = JunkBoxData.new()

	var modal: Control = DebugFullStoreModalScript.new() as Control
	autofree(modal)

	var rh: Node = Node.new()
	rh.set_script(RewardHandlerScript)
	autofree(rh)

	modal.setup(null, rh)

	var d: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	d.upgrade_id = &"pachinko_bumper_vessel"
	d.display_name = "Pachinko Bumper Vessel"

	var initial_item_count: int = GameState.junk_box.items.size() if GameState and GameState.junk_box else 0
	modal._on_apply_relic(d)

	assert_true(GameState != null and GameState.junk_box != null, "JunkBox exists")
	assert_eq(GameState.junk_box.items.size(), initial_item_count + 1, "Item added to junk_box")

	var found: bool = false
	for item_id in GameState.junk_box.items:
		var it: JunkBoxItem = GameState.junk_box.items[item_id]
		if it and it.module_data and it.module_data.module_id == &"pachinko_bumper_vessel":
			found = true
			break
	assert_true(found, "Pachinko Bumper Vessel found in JunkBox inventory")
