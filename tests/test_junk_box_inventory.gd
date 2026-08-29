extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")

func _init() -> void:
	suite_name = "JunkBoxInventory"

func run() -> void:
	test_polyomino_module_data_geometry()
	test_polyomino_module_data_serialization()
	test_junk_box_item_local_and_occupied_cells()
	test_junk_box_item_serialization()
	test_insertion_and_grid_query()
	test_collision_avoidance_and_out_of_bounds()
	test_move_and_rotation_without_self_collision()
	test_endless_vertical_rows()
	test_auto_pack()
	test_serialize_deserialize_roundtrip()
	test_game_state_junk_box_lifecycle()

func test_polyomino_module_data_geometry() -> void:
	begin("PolyominoModuleData bounding box and 4 rotation steps")
	var mod := PolyominoModuleData.new()
	mod.module_id = &"test_l_tromino"
	mod.display_name = "Test L-Tromino"
	mod.tier = 2
	mod.cells = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]

	assert_eq(mod.get_cell_count(), 3, "cell count is 3")
	var bbox := mod.get_bounding_box()
	assert_eq(bbox.position, Vector2i(0, 0), "bbox min is (0,0)")
	assert_eq(bbox.size, Vector2i(2, 2), "bbox size is 2x2")

	var rot0 := mod.get_anchored_rotated_cells(0)
	assert_eq(rot0.size(), 3, "rot0 size")
	assert_in(Vector2i(0, 0), rot0, "rot0 has (0,0)")
	assert_in(Vector2i(0, 1), rot0, "rot0 has (0,1)")
	assert_in(Vector2i(1, 1), rot0, "rot0 has (1,1)")

	var rot1 := mod.get_anchored_rotated_cells(1)
	assert_eq(rot1.size(), 3, "rot1 size")
	assert_in(Vector2i(1, 0), rot1, "rot1 has (1,0)")
	assert_in(Vector2i(0, 0), rot1, "rot1 has (0,0)")
	assert_in(Vector2i(0, 1), rot1, "rot1 has (0,1)")

	var rot2 := mod.get_anchored_rotated_cells(2)
	assert_eq(rot2.size(), 3, "rot2 size")
	assert_in(Vector2i(1, 1), rot2, "rot2 has (1,1)")
	assert_in(Vector2i(1, 0), rot2, "rot2 has (1,0)")
	assert_in(Vector2i(0, 0), rot2, "rot2 has (0,0)")

	var rot3 := mod.get_anchored_rotated_cells(3)
	assert_eq(rot3.size(), 3, "rot3 size")
	for c in rot3:
		assert_gte(c.x, 0, "rot3 cell x non-negative")
		assert_gte(c.y, 0, "rot3 cell y non-negative")

func test_polyomino_module_data_serialization() -> void:
	begin("PolyominoModuleData serialize and deserialize roundtrip")
	var mod := PolyominoModuleData.new()
	mod.module_id = &"cascade_reactor"
	mod.display_name = "Cascade Reactor"
	mod.tier = 3
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	mod.cell_types[Vector2i(0, 0)] = PolyominoModuleData.CellType.BUMPER
	mod.cell_types[Vector2i(1, 1)] = PolyominoModuleData.CellType.ACCELERATOR
	mod.cell_directions[Vector2i(1, 1)] = Vector2i(0, 1)
	mod.bumper_durability = 5
	mod.rotation_step = 1

	var dict := mod.serialize()
	var restored := PolyominoModuleData.from_dictionary(dict)

	assert_eq(restored.module_id, &"cascade_reactor", "module_id matches")
	assert_eq(restored.display_name, "Cascade Reactor", "display_name matches")
	assert_eq(restored.tier, 3, "tier matches")
	assert_eq(restored.cells.size(), 4, "cells size matches")
	assert_eq(restored.cell_types[Vector2i(0, 0)], PolyominoModuleData.CellType.BUMPER, "cell_type bumper")
	assert_eq(restored.cell_types[Vector2i(1, 1)], PolyominoModuleData.CellType.ACCELERATOR, "cell_type accelerator")
	assert_eq(restored.cell_directions[Vector2i(1, 1)], Vector2i(0, 1), "cell direction matches")
	assert_eq(restored.bumper_durability, 5, "durability matches")
	assert_eq(restored.rotation_step, 1, "rotation_step matches")

func test_junk_box_item_local_and_occupied_cells() -> void:
	begin("JunkBoxItem cell calculations, rotation, and custom payload")
	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]

	var item := JunkBoxItem.new(&"bar_item", JunkBoxItem.POLYOMINO_MODULE)
	item.display_name = "Long Bar"
	item.module_data = mod
	item.grid_position = Vector2i(2, 5)
	item.rotation_step = 0

	var occ0 := item.get_occupied_cells()
	assert_eq(occ0.size(), 3, "occ0 size 3")
	assert_in(Vector2i(2, 5), occ0, "occ0 has (2,5)")
	assert_in(Vector2i(3, 5), occ0, "occ0 has (3,5)")
	assert_in(Vector2i(4, 5), occ0, "occ0 has (4,5)")

	item.rotate_clockwise()
	assert_eq(item.rotation_step, 1, "rotation_step is now 1")
	var occ1 := item.get_occupied_cells()
	assert_eq(occ1.size(), 3, "occ1 size 3")
	assert_in(Vector2i(2, 5), occ1, "occ1 has (2,5)")
	assert_in(Vector2i(2, 6), occ1, "occ1 has (2,6)")
	assert_in(Vector2i(2, 7), occ1, "occ1 has (2,7)")

	var peg_item := JunkBoxItem.new(&"peg_item", JunkBoxItem.PEG)
	peg_item.grid_position = Vector2i(1, 1)
	var peg_cells := peg_item.get_occupied_cells()
	assert_eq(peg_cells.size(), 1, "peg occupied cells size 1")
	assert_eq(peg_cells[0], Vector2i(1, 1), "peg occupied cell is (1,1)")

func test_junk_box_item_serialization() -> void:
	begin("JunkBoxItem serialize and deserialize")
	var item := JunkBoxItem.new(&"test_item_42", JunkBoxItem.PEG)
	item.display_name = "Lucky Gold Peg"
	item.grid_position = Vector2i(3, 7)
	item.rotation_step = 2
	item.custom_payload = {"gold_value": 5, "is_guaranteed": true}

	var dict := item.serialize()
	var restored := JunkBoxItem.deserialize(dict)

	assert_eq(restored.instance_id, &"test_item_42", "instance_id matches")
	assert_eq(restored.item_type, JunkBoxItem.PEG, "item_type matches")
	assert_eq(restored.display_name, "Lucky Gold Peg", "display_name matches")
	assert_eq(restored.grid_position, Vector2i(3, 7), "grid_position matches")
	assert_eq(restored.rotation_step, 2, "rotation_step matches")
	assert_eq(restored.custom_payload.get("gold_value"), 5, "payload gold_value matches")
	assert_eq(restored.custom_payload.get("is_guaranteed"), true, "payload is_guaranteed matches")

func test_insertion_and_grid_query() -> void:
	begin("JunkBoxData place_item (1x1 and multi-cell), get_item_at, and signals")
	var box := JunkBoxData.new()
	var added_signals: Array[JunkBoxItem] = []
	var inv_changed: Array[int] = [0]
	box.item_added.connect(func(item: JunkBoxItem): added_signals.append(item))
	box.inventory_changed.connect(func(): inv_changed[0] += 1)

	# 1. Multi-cell polyomino module placement
	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)]
	var item := JunkBoxItem.new(&"domino_1", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod

	var place_ok := box.place_item(item, Vector2i(1, 2))
	assert_true(place_ok, "place_item returned true for 2x1 domino")
	assert_eq(box.get_item_count(), 1, "item count is 1")
	assert_eq(added_signals.size(), 1, "item_added emitted once")
	assert_eq(inv_changed[0], 1, "inventory_changed emitted once")

	assert_eq(box.get_item_at(Vector2i(1, 2)), item, "item at (1,2)")
	assert_eq(box.get_item_at(Vector2i(2, 2)), item, "item at (2,2)")
	assert_eq(box.get_item_at(Vector2i(0, 2)), null, "no item at (0,2)")
	assert_eq(box.get_item_at(Vector2i(1, 3)), null, "no item at (1,3)")

	# 2. 1x1 item placement (e.g. PEG)
	var peg_item := JunkBoxItem.new(&"single_peg", JunkBoxItem.PEG)
	var peg_ok := box.place_item(peg_item, Vector2i(5, 5))
	assert_true(peg_ok, "place_item returned true for 1x1 peg")
	assert_eq(box.get_item_count(), 2, "item count is now 2")
	assert_eq(added_signals.size(), 2, "item_added emitted twice")
	assert_eq(inv_changed[0], 2, "inventory_changed emitted twice")
	assert_eq(box.get_item_at(Vector2i(5, 5)), peg_item, "peg item at (5,5)")

func test_collision_avoidance_and_out_of_bounds() -> void:
	begin("JunkBoxData collision avoidance and boundary constraints (x < 0, x >= 8, y < 0)")
	var box := JunkBoxData.new()
	box.grid_columns = 8

	var mod2x2 := PolyominoModuleData.new()
	mod2x2.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

	var item1 := JunkBoxItem.new(&"box_1", JunkBoxItem.POLYOMINO_MODULE)
	item1.module_data = mod2x2
	assert_true(box.place_item(item1, Vector2i(0, 0)), "placed item1 at (0,0)")

	var item2 := JunkBoxItem.new(&"box_2", JunkBoxItem.POLYOMINO_MODULE)
	item2.module_data = mod2x2
	assert_false(box.can_place_item(item2, Vector2i(1, 0)), "can_place_item returns false on overlap")
	assert_false(box.place_item(item2, Vector2i(1, 0)), "place_item returns false on overlap")
	assert_eq(box.get_item_count(), 1, "item count unchanged after failed placement")

	# Bounds checking
	assert_false(box.can_place_item(item2, Vector2i(-1, 0)), "negative x out of bounds (x < 0)")
	assert_false(box.can_place_item(item2, Vector2i(-5, 2)), "deep negative x out of bounds")
	assert_false(box.can_place_item(item2, Vector2i(0, -1)), "negative y out of bounds (y < 0)")
	assert_false(box.can_place_item(item2, Vector2i(2, -10)), "deep negative y out of bounds")
	assert_false(box.can_place_item(item2, Vector2i(7, 0)), "x=7 with width 2 exceeds columns (8)")
	assert_false(box.can_place_item(item2, Vector2i(8, 0)), "x=8 exceeds columns (8)")
	assert_false(box.can_place_item(item2, Vector2i(12, 0)), "x=12 exceeds columns (8)")
	assert_true(box.can_place_item(item2, Vector2i(6, 0)), "x=6 with width 2 fits in 8 columns")

	# Single cell item bounds checking
	var single := JunkBoxItem.new(&"single", JunkBoxItem.PEG)
	assert_true(box.can_place_item(single, Vector2i(7, 0)), "1x1 item fits at x=7")
	assert_false(box.can_place_item(single, Vector2i(8, 0)), "1x1 item rejected at x=8 (x >= 8)")
	assert_false(box.can_place_item(single, Vector2i(-1, 0)), "1x1 item rejected at x=-1 (x < 0)")
	assert_false(box.can_place_item(single, Vector2i(0, -1)), "1x1 item rejected at y=-1 (y < 0)")

func test_move_and_rotation_without_self_collision() -> void:
	begin("JunkBoxData move_item, all 4 rotation steps, self-collision exclusion, and signals")
	var box := JunkBoxData.new()
	var moved_signals: Array[JunkBoxItem] = []
	var removed_signals: Array[JunkBoxItem] = []
	var inv_changed: Array[int] = [0]
	box.item_moved.connect(func(it: JunkBoxItem): moved_signals.append(it))
	box.item_removed.connect(func(it: JunkBoxItem): removed_signals.append(it))
	box.inventory_changed.connect(func(): inv_changed[0] += 1)

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]

	var item := JunkBoxItem.new(&"v_shape", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	box.place_item(item, Vector2i(2, 2), 0)
	assert_eq(inv_changed[0], 1, "inventory_changed count 1 after place")

	# Move with rotation step 1 without self-collision
	var move_ok := box.move_item(&"v_shape", Vector2i(2, 3), 1)
	assert_true(move_ok, "move_item succeeded without self-collision")
	assert_eq(item.grid_position, Vector2i(2, 3), "new grid position is (2,3)")
	assert_eq(item.rotation_step, 1, "new rotation is 1")
	assert_eq(moved_signals.size(), 1, "item_moved emitted")
	assert_eq(inv_changed[0], 2, "inventory_changed emitted on move")

	# Test all 4 rotation steps in-place (no self-collision)
	for rot in range(4):
		var rot_ok := box.move_item(&"v_shape", Vector2i(2, 3), rot)
		assert_true(rot_ok, "rotated in-place to step %d without self collision" % rot)
		assert_eq(item.rotation_step, rot, "rotation step updated to %d" % rot)

	# Place obstacle at distinct cell (0, 0)
	var obs := JunkBoxItem.new(&"obstacle", JunkBoxItem.PEG)
	var placed_obs := box.place_item(obs, Vector2i(0, 0))
	assert_true(placed_obs, "placed obstacle at (0,0)")

	# Attempt invalid move onto obstacle
	var bad_move := box.move_item(&"v_shape", Vector2i(0, 0))
	assert_false(bad_move, "move onto obstacle failed")
	assert_eq(item.grid_position, Vector2i(2, 3), "position preserved on failed move")

	# Removal and cell freeing
	var removed := box.remove_item(&"v_shape")
	assert_eq(removed, item, "removed correct item")
	assert_eq(box.get_item_count(), 1, "item count is now 1 (only obstacle)")
	assert_eq(box.get_item_at(Vector2i(2, 3)), null, "cells cleared on remove")
	assert_eq(removed_signals.size(), 1, "item_removed emitted")

func test_endless_vertical_rows() -> void:
	begin("JunkBoxData endless vertical rows (y=20, y=50, y=100+) and max_row calculation")
	var box := JunkBoxData.new()
	assert_eq(box.get_max_row(), JunkBoxData.DEFAULT_MIN_ROWS - 1, "default max row is 11")

	# Place at y=20
	var item_20 := JunkBoxItem.new(&"peg_20", JunkBoxItem.PEG)
	var placed_20 := box.place_item(item_20, Vector2i(2, 20))
	assert_true(placed_20, "placed item at row y=20")
	assert_eq(box.get_max_row(), 20, "max row is now 20")

	# Place at y=50
	var item_50 := JunkBoxItem.new(&"peg_50", JunkBoxItem.PEG)
	var placed_50 := box.place_item(item_50, Vector2i(4, 50))
	assert_true(placed_50, "placed item at row y=50")
	assert_eq(box.get_max_row(), 50, "max row is now 50")

	# Place at y=100+
	var item_100 := JunkBoxItem.new(&"peg_100", JunkBoxItem.PEG)
	var placed_100 := box.place_item(item_100, Vector2i(0, 100))
	assert_true(placed_100, "placed item at row y=100")
	assert_eq(box.get_max_row(), 100, "max row is now 100")

	# Move item at y=100 to y=150
	var move_high := box.move_item(&"peg_100", Vector2i(3, 150))
	assert_true(move_high, "moved item to row y=150")
	assert_eq(box.get_max_row(), 150, "max row is now 150")
	assert_eq(box.get_item_at(Vector2i(3, 150)), item_100, "item retrieved at y=150")

	var auto_item := JunkBoxItem.new(&"auto_peg", JunkBoxItem.PEG)
	var slot := box.find_first_available_slot(auto_item)
	assert_eq(slot, Vector2i(0, 0), "first slot is (0,0)")

func test_auto_pack() -> void:
	begin("JunkBoxData auto_pack compacts and prioritizes higher tiers")
	var box := JunkBoxData.new()

	var peg := JunkBoxItem.new(&"peg_0", JunkBoxItem.PEG)
	box.place_item(peg, Vector2i(0, 40))

	var mod_t1 := PolyominoModuleData.new()
	mod_t1.tier = 1
	mod_t1.cells = [Vector2i(0, 0), Vector2i(1, 0)]
	var item_t1 := JunkBoxItem.new(&"domino_t1", JunkBoxItem.POLYOMINO_MODULE)
	item_t1.module_data = mod_t1
	box.place_item(item_t1, Vector2i(0, 30))

	var mod_t3 := PolyominoModuleData.new()
	mod_t3.tier = 3
	mod_t3.cells = []
	for x in range(3):
		for y in range(3):
			mod_t3.cells.append(Vector2i(x, y))
	var item_t3 := JunkBoxItem.new(&"boss_t3", JunkBoxItem.POLYOMINO_MODULE)
	item_t3.module_data = mod_t3
	box.place_item(item_t3, Vector2i(0, 50))

	assert_eq(box.get_max_row(), 52, "max row before pack is 52")
	assert_eq(box.get_max_occupied_row(), 52, "max occupied row before pack is 52")

	box.auto_pack()

	assert_lte(box.get_max_occupied_row(), 3, "max occupied row compacted to <= 3")
	assert_eq(box.get_max_row(), JunkBoxData.DEFAULT_MIN_ROWS - 1, "max row returns default minimum")
	assert_eq(item_t3.grid_position, Vector2i(0, 0), "Tier 3 item packed at (0,0)")
	assert_eq(box.items.size(), 3, "all 3 items preserved")
	assert_eq(box.occupied_cells.size(), 1 + 2 + 9, "total occupied cell count is 12")

func test_serialize_deserialize_roundtrip() -> void:
	begin("JunkBoxData full inventory serialize and deserialize roundtrip")
	var box := JunkBoxData.new()

	var mod := PolyominoModuleData.new()
	mod.module_id = &"superconductor"
	mod.display_name = "Superconductor"
	mod.tier = 3
	mod.cells = [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1)]
	mod.cell_types[Vector2i(0, 0)] = PolyominoModuleData.CellType.BUMPER

	var item1 := JunkBoxItem.new(&"sc_1", JunkBoxItem.POLYOMINO_MODULE)
	item1.module_data = mod
	box.place_item(item1, Vector2i(1, 3), 1)

	var item2 := JunkBoxItem.new(&"peg_gold", JunkBoxItem.PEG)
	item2.display_name = "Gold Stash Peg"
	item2.custom_payload = {"gold": 10}
	box.place_item(item2, Vector2i(5, 7))

	var saved_dict := box.serialize()

	var new_box := JunkBoxData.new()
	new_box.deserialize(saved_dict)

	assert_eq(new_box.get_item_count(), 2, "deserialized item count is 2")
	assert_true(new_box.has_item(&"sc_1"), "has sc_1")
	assert_true(new_box.has_item(&"peg_gold"), "has peg_gold")

	var res_item1 := new_box.items[&"sc_1"] as JunkBoxItem
	assert_eq(res_item1.grid_position, Vector2i(1, 3), "sc_1 position matches")
	assert_eq(res_item1.rotation_step, 1, "sc_1 rotation matches")
	assert_eq(res_item1.module_data.module_id, &"superconductor", "module_id matches")

	var res_item2 := new_box.items[&"peg_gold"] as JunkBoxItem
	assert_eq(res_item2.grid_position, Vector2i(5, 7), "peg position matches")
	assert_eq(res_item2.custom_payload.get("gold"), 10, "payload gold matches")

	for item in new_box.get_all_items():
		for cell in item.get_occupied_cells():
			assert_eq(new_box.occupied_cells.get(cell), item.instance_id, "occupied cell mapping correct")

func test_game_state_junk_box_lifecycle() -> void:
	begin("GameState junk_box initialization and start_run reset")
	assert_true(GameState.junk_box != null, "GameState.junk_box is initialized")

	var test_item := JunkBoxItem.new(&"run_item", JunkBoxItem.PEG)
	GameState.junk_box.add_item_auto(test_item)
	assert_eq(GameState.junk_box.get_item_count(), 1, "item added to GameState.junk_box")

	GameState.start_run(9999)
	assert_true(GameState.junk_box != null, "GameState.junk_box is valid after start_run")
	assert_eq(GameState.junk_box.get_item_count(), 0, "GameState.junk_box reset to empty on start_run")
