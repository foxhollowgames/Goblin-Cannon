extends "res://tests/test_base.gd"

const BoardScript = preload("res://scenes/board/board.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")

func _init() -> void:
	suite_name = "PegGridAlignment"

func run() -> void:
	test_coordinate_mapping_and_spacing()
	test_initial_pegs_grid_alignment()
	test_pegs_and_polyomino_share_alignment()
	test_grid_query_helpers()
	test_dynamic_peg_spawning_targets_empty_grid_cells()
	test_unslot_and_place_peg_at_cell()

func test_coordinate_mapping_and_spacing() -> void:
	begin("Unified grid coordinate conversions and constants")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	assert_eq(board.BOARD_GRID_COLS, 16, "BOARD_GRID_COLS is 16")
	assert_eq(board.BOARD_GRID_ROWS, 8, "BOARD_GRID_ROWS is 8")
	assert_eq(board.BOARD_GRID_COL_SPACING, 52.0, "BOARD_GRID_COL_SPACING is 52.0")
	assert_eq(board.BOARD_GRID_ROW_SPACING, 56.0, "BOARD_GRID_ROW_SPACING is 56.0")
	assert_eq(board.BOARD_GRID_START_X, 90.0, "BOARD_GRID_START_X is 90.0")
	assert_eq(board.BOARD_GRID_START_Y, 200.0, "BOARD_GRID_START_Y is 200.0")

	for r in range(board.BOARD_GRID_ROWS):
		for c in range(board.BOARD_GRID_COLS):
			var cell := Vector2i(c, r)
			var world_pos: Vector2 = board.board_cell_to_world(cell)
			var expected_x: float = board.BOARD_GRID_START_X + float(c) * board.BOARD_GRID_COL_SPACING
			var expected_y: float = board.BOARD_GRID_START_Y + float(r) * board.BOARD_GRID_ROW_SPACING
			assert_eq(world_pos, Vector2(expected_x, expected_y), "cell %s matches expected world coordinates" % str(cell))
			var roundtrip: Vector2i = board.world_to_board_cell(world_pos)
			assert_eq(roundtrip, cell, "world position roundtrips to grid cell %s" % str(cell))

	# Test fuzzy coordinate snapping
	var fuzzy: Vector2 = Vector2(90.0 + 3.0 * 52.0 + 12.0, 200.0 + 4.0 * 56.0 - 15.0)
	var snapped: Vector2i = board.world_to_board_cell(fuzzy)
	assert_eq(snapped, Vector2i(3, 4), "fuzzy position snaps to nearest grid cell (3, 4)")

	board.free()

func test_initial_pegs_grid_alignment() -> void:
	begin("Initial peg layout spawns in staggered pattern (every other cell) on integer grid coordinates")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	var expected_total_pegs: int = (board.BOARD_GRID_COLS * board.BOARD_GRID_ROWS) / 2
	assert_eq(board._peg_by_id.size(), expected_total_pegs, "spawned exact 64 initial pegs (half of 16x8 cells)")

	for r in range(board.BOARD_GRID_ROWS):
		for c in range(board.BOARD_GRID_COLS):
			var cell := Vector2i(c, r)
			var peg: Node = board.get_peg_at_cell(cell)
			if (r + c) % 2 == 0:
				assert_true(peg != null, "peg exists at staggered grid cell %s" % str(cell))
				if peg:
					var expected_pos: Vector2 = board.board_cell_to_world(cell)
					assert_eq(peg.position, expected_pos, "peg at %s matches exact cell world position" % str(cell))
					assert_eq(board.world_to_board_cell(peg.position), cell, "peg position maps to cell %s" % str(cell))
			else:
				assert_true(peg == null, "no peg at empty spot %s" % str(cell))
				assert_true(board.is_cell_empty(cell), "cell %s is empty" % str(cell))

	# Verify rows are staggered: Row 0 has even cols, Row 1 has odd cols
	for c in range(board.BOARD_GRID_COLS):
		var p_row0: Node = board.get_peg_at_cell(Vector2i(c, 0))
		var p_row1: Node = board.get_peg_at_cell(Vector2i(c, 1))
		if c % 2 == 0:
			assert_true(p_row0 != null, "row 0 has peg at even col %d" % c)
			assert_true(p_row1 == null, "row 1 has empty space at even col %d" % c)
		else:
			assert_true(p_row0 == null, "row 0 has empty space at odd col %d" % c)
			assert_true(p_row1 != null, "row 1 has peg at odd col %d" % c)

	board.free()

func test_pegs_and_polyomino_share_alignment() -> void:
	begin("Pegs and polyomino relics share identical spatial grid mapping and spacing")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	# Create a 2x2 box module
	var mod := PolyominoModuleData.new()
	mod.module_id = &"box_2x2_align"
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

	var item := JunkBoxItem.new(&"box_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod

	var target_cell := Vector2i(2, 2)
	var expected_origin_world: Vector2 = board.board_cell_to_world(target_cell)

	var peg_at_target: Node = board.get_peg_at_cell(target_cell)
	assert_true(peg_at_target != null, "peg at target cell exists")
	if peg_at_target:
		assert_eq(peg_at_target.position, expected_origin_world, "peg position matches target grid origin")

	# Check multi-cell offset positions match grid spacing
	for offset in mod.cells:
		var cell_world: Vector2 = board.board_cell_to_world(target_cell + offset)
		var expected_cell_pos: Vector2 = expected_origin_world + Vector2(
			float(offset.x) * board.BOARD_GRID_COL_SPACING,
			float(offset.y) * board.BOARD_GRID_ROW_SPACING
		)
		assert_eq(cell_world, expected_cell_pos, "polyomino cell offset %s matches grid step" % str(offset))

	board.free()

func test_grid_query_helpers() -> void:
	begin("Board grid helper functions (bounds, queries, emptiness)")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	# Bounds check
	assert_true(board.is_cell_in_bounds(Vector2i(0, 0)), "(0,0) is in bounds")
	assert_true(board.is_cell_in_bounds(Vector2i(15, 7)), "(15,7) is in bounds")
	assert_false(board.is_cell_in_bounds(Vector2i(-1, 0)), "(-1,0) is out of bounds")
	assert_false(board.is_cell_in_bounds(Vector2i(16, 0)), "(16,0) is out of bounds")
	assert_false(board.is_cell_in_bounds(Vector2i(0, 8)), "(0,8) is out of bounds")

	# Staggered board has 64 empty cells initially
	assert_eq(board.get_empty_grid_cells().size(), 64, "64 empty cells on initial staggered board")
	assert_false(board.is_cell_empty(Vector2i(0, 0)), "cell (0,0) has peg")
	assert_true(board.is_cell_empty(Vector2i(1, 0)), "cell (1,0) is empty spot")

	# Unslot peg at (0, 0)
	var removed: Node = board.unslot_peg_at_cell(Vector2i(0, 0))
	assert_true(removed != null, "unslot_peg_at_cell returns peg")
	assert_true(board.is_cell_empty(Vector2i(0, 0)), "cell (0,0) is now empty")
	assert_eq(board.get_peg_at_cell(Vector2i(0, 0)), null, "get_peg_at_cell returns null for unslotted cell")
	assert_eq(board.get_empty_grid_cells().size(), 65, "65 empty cells on board")

	if removed:
		removed.free()
	board.free()

func test_dynamic_peg_spawning_targets_empty_grid_cells() -> void:
	begin("Dynamic peg resolution targets valid empty grid cells aligned to grid coordinates")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	# (1, 0) is an empty cell in the staggered layout
	assert_true(board.is_cell_empty(Vector2i(1, 0)), "cell (1,0) is empty")

	# Resolve position preferring near (1, 0)
	var pref_world: Vector2 = board.board_cell_to_world(Vector2i(1, 0)) + Vector2(3.0, 4.0)
	var resolved: Vector2 = board.resolve_milestone_event_position(pref_world, 100.0, 800.0)
	var expected_pos: Vector2 = board.board_cell_to_world(Vector2i(1, 0))
	assert_eq(resolved, expected_pos, "resolved position matches empty grid cell (1,0)")
	assert_eq(board.world_to_board_cell(resolved), Vector2i(1, 0), "resolved cell is (1,0)")

	# Milestone event peg spawn
	var dynamic_id: int = board.spawn_milestone_event_peg_at(pref_world, 100.0, 800.0)
	var dynamic_peg: Node = board.get_peg_by_id(dynamic_id)
	assert_true(dynamic_peg != null, "milestone peg spawned")
	if dynamic_peg:
		assert_eq(dynamic_peg.position, expected_pos, "milestone peg placed at exact grid coordinates")
		assert_eq(board.world_to_board_cell(dynamic_peg.position), Vector2i(1, 0), "milestone peg at cell (1,0)")

	board.free()

func test_unslot_and_place_peg_at_cell() -> void:
	begin("Placing and unslotting pegs maintains grid coordinate integrity")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	# (0, 0) has a peg initially
	var old_peg: Node = board.unslot_peg_at_cell(Vector2i(0, 0))
	assert_true(old_peg != null, "old peg unslotted from (0,0)")
	if old_peg: old_peg.free()

	assert_true(board.is_cell_empty(Vector2i(0, 0)), "cell (0,0) is now empty")

	# Place new bomb peg into empty staggered cell (1, 0)
	assert_true(board.is_cell_empty(Vector2i(1, 0)), "cell (1,0) starts empty")
	var new_peg: Node = board.place_peg_at_cell(Vector2i(1, 0), null, "bomb")
	assert_true(new_peg != null, "new peg placed at cell (1,0)")
	if new_peg:
		assert_eq(new_peg.position, board.board_cell_to_world(Vector2i(1, 0)), "new peg placed at exact grid world pos")
		assert_eq(new_peg.peg_extra_kind, "bomb", "peg kind is bomb")
		assert_eq(board.get_peg_at_cell(Vector2i(1, 0)), new_peg, "get_peg_at_cell returns new peg")
		assert_false(board.is_cell_empty(Vector2i(1, 0)), "cell is no longer empty")

	board.free()
