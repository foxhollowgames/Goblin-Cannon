extends "res://tests/test_base.gd"

const BoardScript = preload("res://scenes/board/board.gd")
const RewardHandlerScript = preload("res://scenes/rewards/reward_handler.gd")
const MajorUpgradeDefinition = preload("res://resources/rewards/major_upgrade_definition.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")

func _init() -> void:
	suite_name = "SlottedRelicEffects"

func run() -> void:
	test_relic_draft_populates_junk_box_without_activating_passive()
	test_board_placement_activates_relic_effect()
	test_board_unslot_removes_relic_effect()
	test_board_hover_shows_and_hides_tooltip()
	test_multiple_relics_board_slotting_and_clear()

func _ensure_clean_state() -> void:
	GameState.start_run(12345)
	GameState.applied_wall_break_upgrades.clear()
	GameState.applied_boss_upgrades.clear()
	GameState.explosion_radius_bonus = 0
	GameState.chain_arc_bonus = 0
	GameState.cannon_base_damage_bonus = 0
	GameState.cannon_charge_reduction = 0
	GameState.peg_recovery_speed_scale = 1.0
	GameState.chest_leech_drain_stacks = 0

func test_relic_draft_populates_junk_box_without_activating_passive() -> void:
	begin("Relic draft populates Junk Box without activating passive immediately")
	_ensure_clean_state()

	var rh := RewardHandlerScript.new()
	var def := MajorUpgradeDefinition.new()
	def.upgrade_id = &"supernova_peg"
	def.category = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT

	rh.apply_major_upgrade(def)

	assert_eq(GameState.junk_box.get_item_count(), 1, "junk box received 1 item")
	var item: JunkBoxItem = GameState.junk_box.get_all_items()[0]
	assert_true(item != null, "item exists in junk box")
	assert_eq(item.custom_payload.get("relic_id", ""), "supernova_peg", "payload holds relic ID")
	assert_false(GameState.has_wall_break_upgrade(&"supernova_peg"), "passive is inactive while in junk box")

	rh.free()

func test_board_placement_activates_relic_effect() -> void:
	begin("Board placement activates relic effect in GameState")
	_ensure_clean_state()

	var board := Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"explosion_radius")
	assert_true(item != null, "item created")
	assert_eq(GameState.explosion_radius_bonus, 0, "initial bonus is 0")

	var placed: bool = board.place_module(item, Vector2i(2, 2), 0)
	assert_true(placed, "module placed on board")
	assert_eq(GameState.explosion_radius_bonus, 1, "+1 explosion radius activated on board placement")

	board.free()

func test_board_unslot_removes_relic_effect() -> void:
	begin("Board unslot removes relic effect from GameState")
	_ensure_clean_state()

	var board := Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"supernova_peg")
	board.place_module(item, Vector2i(2, 2), 0)
	assert_true(GameState.has_wall_break_upgrade(&"supernova_peg"), "supernova peg active when placed")

	var unslotted: Resource = board.unslot_module(item.instance_id)
	assert_true(unslotted != null, "module unslotted")
	assert_false(GameState.has_wall_break_upgrade(&"supernova_peg"), "supernova peg inactive after unslot")

	board.free()

func test_board_hover_shows_and_hides_tooltip() -> void:
	begin("Board hover displays and hides instant flyout tooltip for placed relic")
	_ensure_clean_state()

	var board := Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"chain_conduction")
	board.place_module(item, Vector2i(4, 3), 0)

	var world_pos: Vector2 = board.board_cell_to_world(Vector2i(4, 3))
	board._update_board_module_hover(world_pos)

	assert_eq(board._hovered_module_instance_id, item.instance_id, "hovered module instance tracked")
	assert_true(KeywordDatabase._flyout_panel != null and KeywordDatabase._flyout_panel.visible, "flyout tooltip is visible")
	assert_true(KeywordDatabase._flyout_title.text.contains("Chain Conduction"), "flyout title contains relic name")

	# Move mouse away to empty cell
	var empty_world_pos: Vector2 = board.board_cell_to_world(Vector2i(0, 0))
	board._update_board_module_hover(empty_world_pos)

	assert_eq(board._hovered_module_instance_id, StringName(""), "hovered module cleared")
	assert_false(KeywordDatabase._flyout_panel.visible, "flyout tooltip is hidden")

	board.free()

func test_multiple_relics_board_slotting_and_clear() -> void:
	begin("Multiple relics slotted on board and clear_all_placed_modules cleanup")
	_ensure_clean_state()

	var board := Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	var item1: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"devastating_barrage")
	var item2: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"cascade_reactor")

	board.place_module(item1, Vector2i(0, 0), 0)
	board.place_module(item2, Vector2i(5, 0), 0)

	assert_eq(GameState.cannon_base_damage_bonus, 10, "devastating barrage active")
	assert_true(GameState.has_boss_upgrade(&"cascade_reactor"), "cascade reactor active")

	board.clear_all_placed_modules()

	assert_eq(GameState.cannon_base_damage_bonus, 0, "devastating barrage reverted on clear")
	assert_false(GameState.has_boss_upgrade(&"cascade_reactor"), "cascade reactor reverted on clear")

	board.free()
