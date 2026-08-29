extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxDragController = preload("res://scenes/ui/junk_box/junk_box_drag_controller.gd")
const BoardScript = preload("res://scenes/board/board.gd")

func _init() -> void:
	suite_name = "PolyominoDragDrop"

func run() -> void:
	test_board_grid_coordinate_math()
	test_board_module_placement_and_bounds()
	test_board_module_collision_detection()
	test_board_module_unslot_and_queries()
	test_drag_controller_rotation_and_anchoring()
	test_bag_to_board_transfer()
	test_board_to_bag_transfer()
	test_drop_rejection_and_return_to_origin()

func test_board_grid_coordinate_math() -> void:
	begin("Board grid coordinate conversion (world <-> grid)")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var start_x: float = board.BOARD_GRID_START_X
	var start_y: float = board.BOARD_GRID_START_Y
	var col_spacing: float = board.BOARD_GRID_COL_SPACING
	var row_spacing: float = board.BOARD_GRID_ROW_SPACING

	# Origin cell (0, 0)
	var w0: Vector2 = board.board_cell_to_world(Vector2i(0, 0))
	assert_eq(w0, Vector2(start_x, start_y), "cell (0,0) world pos matches origin")
	var c0: Vector2i = board.world_to_board_cell(w0)
	assert_eq(c0, Vector2i(0, 0), "world pos at origin roundtrips to (0,0)")

	# Intermediate cell (4, 3)
	var w_mid: Vector2 = board.board_cell_to_world(Vector2i(4, 3))
	assert_eq(w_mid, Vector2(start_x + 4.0 * col_spacing, start_y + 3.0 * row_spacing), "cell (4,3) world pos")
	var c_mid: Vector2i = board.world_to_board_cell(w_mid)
	assert_eq(c_mid, Vector2i(4, 3), "cell (4,3) roundtrip")

	# Snapping fuzzy coordinates
	var fuzzy_pos: Vector2 = w_mid + Vector2(10.0, -12.0)
	var c_fuzzy: Vector2i = board.world_to_board_cell(fuzzy_pos)
	assert_eq(c_fuzzy, Vector2i(4, 3), "fuzzy world position snaps to nearest grid cell")

	board.free()

func test_board_module_placement_and_bounds() -> void:
	begin("Board polyomino module placement and boundary checks")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var mod := PolyominoModuleData.new()
	mod.module_id = &"test_t_shape"
	mod.display_name = "Test T-Shape"
	mod.tier = 2
	# T-Shape (4 cells): (1,0), (0,1), (1,1), (2,1)
	mod.cells = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]

	var item := JunkBoxItem.new(&"mod_t_1", JunkBoxItem.POLYOMINO_MODULE)
	item.display_name = "Test T-Shape Item"
	item.module_data = mod

	# Valid placement inside board
	assert_true(board.can_place_module(item, Vector2i(2, 2)), "can place T-shape at (2,2)")
	assert_true(board.place_module(item, Vector2i(2, 2)), "place_module returns true")
	assert_eq(board.get_all_placed_modules().size(), 1, "1 module placed on board")
	assert_eq(board.get_module_at_cell(Vector2i(3, 2)), item, "item found at occupied cell (3,2)")
	assert_eq(board.get_module_at_cell(Vector2i(2, 3)), item, "item found at occupied cell (2,3)")
	assert_eq(board.get_module_at_cell(Vector2i(2, 2)), null, "cell (2,2) is un-occupied notch")

	# Out of bounds: negative column
	assert_false(board.can_place_module(item, Vector2i(-1, 2)), "cannot place with negative col")

	# Out of bounds: right edge overflow (T-shape width is 3 -> cols 0, 1, 2)
	assert_false(board.can_place_module(item, Vector2i(14, 2)), "cannot place overflowing right edge")
	assert_true(board.can_place_module(item, Vector2i(13, 2), -1, &"mod_t_1"), "fits right at edge (cols 13, 14, 15)")

	# Out of bounds: bottom edge overflow (T-shape height is 2 -> rows 0, 1)
	assert_false(board.can_place_module(item, Vector2i(2, 7)), "cannot place overflowing bottom edge")

	board.free()

func test_board_module_collision_detection() -> void:
	begin("Board multi-module collision prevention and self-ignore")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var mod_box := PolyominoModuleData.new()
	mod_box.module_id = &"box_2x2"
	mod_box.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

	var item_a := JunkBoxItem.new(&"item_a", JunkBoxItem.POLYOMINO_MODULE)
	item_a.module_data = mod_box
	board.place_module(item_a, Vector2i(2, 2))

	var item_b := JunkBoxItem.new(&"item_b", JunkBoxItem.POLYOMINO_MODULE)
	item_b.module_data = mod_box

	# Attempt to place item_b directly overlapping item_a
	assert_false(board.can_place_module(item_b, Vector2i(2, 2)), "cannot place on identical cells")
	assert_false(board.can_place_module(item_b, Vector2i(3, 3)), "cannot place with partial 1-cell overlap")
	assert_false(board.place_module(item_b, Vector2i(2, 2)), "place_module rejects overlapping placement")

	# Valid placement adjacent to item_a
	assert_true(board.can_place_module(item_b, Vector2i(4, 2)), "can place adjacent without overlap")
	assert_true(board.place_module(item_b, Vector2i(4, 2)), "item_b successfully placed")
	assert_eq(board.get_all_placed_modules().size(), 2, "2 items placed on board")

	# Self-ignore when moving item_a
	assert_true(board.can_place_module(item_a, Vector2i(2, 2), -1, item_a.instance_id), "self-ignore on current spot")
	assert_true(board.can_place_module(item_a, Vector2i(1, 2), -1, item_a.instance_id), "self-ignore moving by 1 cell")

	board.free()

func test_board_module_unslot_and_queries() -> void:
	begin("Board module unslot and occupied cell cleanup")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]

	var item := JunkBoxItem.new(&"bar_1", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	board.place_module(item, Vector2i(3, 4))

	assert_eq(board.get_module_at_cell(Vector2i(3, 4)), item, "item at (3,4)")
	assert_eq(board.get_module_at_cell(Vector2i(4, 4)), item, "item at (4,4)")
	assert_eq(board.get_module_at_cell(Vector2i(5, 4)), item, "item at (5,4)")
	assert_eq(board.get_module_at_cell(Vector2i(6, 4)), null, "empty cell returns null")

	var unslotted: Resource = board.unslot_module(&"bar_1")
	assert_eq(unslotted, item, "unslot_module returns the removed item")
	assert_eq(board.get_module_at_cell(Vector2i(3, 4)), null, "cell (3,4) is now cleared")
	assert_eq(board.get_module_at_cell(Vector2i(4, 4)), null, "cell (4,4) is now cleared")
	assert_eq(board.get_module_at_cell(Vector2i(5, 4)), null, "cell (5,4) is now cleared")
	assert_eq(board.get_all_placed_modules().size(), 0, "0 placed modules remaining")

	board.free()

func test_drag_controller_rotation_and_anchoring() -> void:
	begin("Drag controller in-flight 90° rotation and top-left anchoring")
	var controller := JunkBoxDragController.new()

	var mod := PolyominoModuleData.new()
	mod.module_id = &"l_shape"
	mod.cells = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]

	var item := JunkBoxItem.new(&"item_drag_1", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod

	controller.start_drag(item, JunkBoxDragController.DragSource.JUNK_BOX, Vector2i(0, 0), Vector2i(0, 0))
	assert_eq(controller.current_rotation_step, 0, "initial rotation step is 0")

	# Rotate CW step 1
	controller._rotate_item()
	assert_eq(controller.current_rotation_step, 1, "rotation step is 1")
	var rot1_cells: Array[Vector2i] = mod.get_anchored_rotated_cells(controller.current_rotation_step)
	for c in rot1_cells:
		assert_gte(c.x, 0, "rot1 cell x >= 0")
		assert_gte(c.y, 0, "rot1 cell y >= 0")

	# Rotate CW step 2
	controller._rotate_item()
	assert_eq(controller.current_rotation_step, 2, "rotation step is 2")

	# Rotate CW step 3
	controller._rotate_item()
	assert_eq(controller.current_rotation_step, 3, "rotation step is 3")

	# Rotate CW back to 0
	controller._rotate_item()
	assert_eq(controller.current_rotation_step, 0, "rotation step wrapped to 0")

	controller._cancel_drag()
	controller.free()

func test_bag_to_board_transfer() -> void:
	begin("Seamless item transfer from Junk Box to Board")
	var bag := JunkBoxData.new()
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)]

	var item := JunkBoxItem.new(&"transfer_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	bag.place_item(item, Vector2i(0, 0))
	assert_true(bag.has_item(&"transfer_item"), "item starts in bag")

	# Simulate dragging from bag and dropping onto board at (5, 2)
	assert_true(board.can_place_module(item, Vector2i(5, 2)), "can place on board")
	board.place_module(item, Vector2i(5, 2), 0)
	bag.remove_item(&"transfer_item")

	assert_false(bag.has_item(&"transfer_item"), "item removed from bag")
	assert_eq(board.get_all_placed_modules().size(), 1, "item now registered on board")
	assert_eq(board.get_module_at_cell(Vector2i(5, 2)), item, "item found on board at (5,2)")
	assert_eq(board.get_module_at_cell(Vector2i(6, 2)), item, "item found on board at (6,2)")

	board.free()

func test_board_to_bag_transfer() -> void:
	begin("Seamless item transfer from Board back to Junk Box")
	var bag := JunkBoxData.new()
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(0, 1)]

	var item := JunkBoxItem.new(&"board_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	board.place_module(item, Vector2i(2, 3))
	assert_eq(board.get_all_placed_modules().size(), 1, "item starts on board")

	# Simulate picking up from board and dropping into bag at (3, 1)
	board.unslot_module(&"board_item")
	assert_true(bag.can_place_item(item, Vector2i(3, 1)), "can place in bag")
	bag.place_item(item, Vector2i(3, 1), 0)

	assert_eq(board.get_all_placed_modules().size(), 0, "board is now empty")
	assert_true(bag.has_item(&"board_item"), "item now safely stored in bag")
	assert_eq(bag.get_item_at(Vector2i(3, 1)), item, "item located in bag at (3,1)")

	board.free()

func test_drop_rejection_and_return_to_origin() -> void:
	begin("Drop rejection restores item to original slot and rotation")
	var bag := JunkBoxData.new()
	var controller := JunkBoxDragController.new()
	controller.junk_box_data = bag

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]

	var item := JunkBoxItem.new(&"revert_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	bag.place_item(item, Vector2i(1, 2), 0)

	# Start drag
	controller.start_drag(item, JunkBoxDragController.DragSource.JUNK_BOX, Vector2i(1, 2), Vector2i(0, 0))
	controller._rotate_item() # in-flight rotation to 1

	# Cancel/reject drag
	controller._cancel_drag()

	assert_eq(item.grid_position, Vector2i(1, 2), "item grid_position reverted to original")
	assert_eq(item.rotation_step, 0, "item rotation reverted to original")
	assert_eq(bag.get_item_at(Vector2i(1, 2)), item, "bag still contains item at original slot")

	controller.free()
