extends "res://tests/test_base.gd"

const BoardScript = preload("res://scenes/board/board.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")

func _init() -> void:
	suite_name = "RelicBoardTriggers"

func run() -> void:
	test_relic_board_placement_zero_passive_stats()
	test_relic_board_unslot_zero_passive_stats()
	test_relic_goal_definitions_and_rewards()
	test_relic_pinball_component_registration()

func _ensure_clean_state() -> void:
	GameState.start_run(54321)
	GameState.applied_wall_break_upgrades.clear()
	GameState.applied_boss_upgrades.clear()
	GameState.explosion_radius_bonus = 0
	GameState.chain_arc_bonus = 0
	GameState.cannon_base_damage_bonus = 0
	GameState.cannon_charge_reduction = 0
	GameState.peg_recovery_speed_scale = 1.0
	GameState.chest_leech_drain_stacks = 0

func test_relic_board_placement_zero_passive_stats() -> void:
	begin("Placing polyomino relics on board mutates zero passive stats in GameState")
	_ensure_clean_state()

	var board := Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	var test_relics: Array[StringName] = [
		&"explosion_radius",
		&"chain_arc",
		&"devastating_barrage",
		&"compressed_charge",
		&"cascade_reactor"
	]

	var positions: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(4, 0),
		Vector2i(8, 0),
		Vector2i(0, 4),
		Vector2i(4, 4)
	]

	var idx: int = 0
	for relic_id in test_relics:
		var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(relic_id)
		assert_true(item != null, "item created for %s" % relic_id)
		var target_pos: Vector2i = positions[idx]
		idx += 1
		var placed: bool = board.place_module(item, target_pos, 0)
		assert_true(placed, "placed relic %s" % relic_id)

	# Verify all passive stat fields remain untouched baseline 0
	assert_eq(GameState.explosion_radius_bonus, 0, "explosion_radius_bonus is 0")
	assert_eq(GameState.chain_arc_bonus, 0, "chain_arc_bonus is 0")
	assert_eq(GameState.cannon_base_damage_bonus, 0, "cannon_base_damage_bonus is 0")
	assert_eq(GameState.cannon_charge_reduction, 0, "cannon_charge_reduction is 0")
	assert_eq(GameState.chest_leech_drain_stacks, 0, "chest_leech_drain_stacks is 0")

	board.free()

func test_relic_board_unslot_zero_passive_stats() -> void:
	begin("Unslotting relics cleans up upgrade tracking cleanly without passive errors")
	_ensure_clean_state()

	var board := Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"supernova_peg")
	board.place_module(item, Vector2i(2, 2), 0)
	assert_true(GameState.has_wall_break_upgrade(&"supernova_peg"), "supernova peg registered when placed")

	var unslotted: Resource = board.unslot_module(item.instance_id)
	assert_true(unslotted != null, "relic unslotted")
	assert_false(GameState.has_wall_break_upgrade(&"supernova_peg"), "supernova peg unregistered when unslotted")
	assert_eq(GameState.explosion_radius_bonus, 0, "explosion_radius_bonus remains 0")

	board.free()

func test_relic_goal_definitions_and_rewards() -> void:
	begin("All relics define pinball board goal descriptions and interactive rewards")
	_ensure_clean_state()

	var ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	assert_true(ids.size() > 0, "relic database contains entries")

	for relic_id in ids:
		var title: String = PolyominoRelicDatabase.get_relic_goal_title(relic_id)
		var desc: String = PolyominoRelicDatabase.get_relic_goal_description(relic_id)
		var reward_desc: String = PolyominoRelicDatabase.get_relic_reward_description(relic_id)
		assert_true(title.length() > 0, "goal title exists for %s" % relic_id)
		assert_true(desc.length() > 0, "goal desc exists for %s" % relic_id)
		assert_true(reward_desc.length() > 0, "reward desc exists for %s" % relic_id)

func test_relic_pinball_component_registration() -> void:
	begin("Relic module data instantiates kinetic pinball cell component types")
	_ensure_clean_state()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"cascade_reactor")
	assert_true(item != null and item.module_data != null, "module data generated")

	var mod_data: PolyominoModuleData = item.module_data
	assert_true(mod_data.cell_types.size() > 0, "cell types dictionary populated")
	assert_true(mod_data.goal_title.length() > 0, "goal title populated on module data")
