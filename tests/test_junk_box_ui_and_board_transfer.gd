extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxDragController = preload("res://scenes/ui/junk_box/junk_box_drag_controller.gd")
const BoardScript = preload("res://scenes/board/board.gd")

func _init() -> void:
	suite_name = "JunkBoxUIAndBoardTransfer"

func run() -> void:
	test_junk_box_panel_drawer_layout_and_toggle()
	test_junk_box_tooltip_generation()
	test_drag_controller_bag_to_board_drop()
	test_drag_controller_board_to_bag_drop()
	test_drag_controller_invalid_board_placement_reverts()
	test_drag_controller_rotation_during_transfer()

func test_junk_box_panel_drawer_layout_and_toggle() -> void:
	begin("JunkBoxPanel right-drawer layout and visibility toggles")
	var scene: PackedScene = load("res://scenes/ui/junk_box/junk_box_panel.tscn") as PackedScene
	assert_true(scene != null, "junk_box_panel.tscn loads successfully")

	var panel: Control = scene.instantiate() as Control
	assert_true(panel != null, "junk_box_panel instantiates successfully")
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_IGNORE, "root panel ignores mouse so board clicks pass through")

	var drawer: PanelContainer = panel.get_node_or_null("DrawerPanel") as PanelContainer
	assert_true(drawer != null, "DrawerPanel child exists")
	assert_eq(drawer.anchor_right, 1.0, "drawer anchored to right screen edge")

	assert_false(panel.visible, "panel is hidden initially")

	var closed_emitted: Array[bool] = [false]
	panel.closed.connect(func(): closed_emitted[0] = true)

	panel.toggle()
	assert_true(panel.visible, "panel visible after first toggle")

	panel.toggle()
	assert_false(panel.visible, "panel hidden after second toggle")
	assert_true(closed_emitted[0], "closed signal emitted on close")

	panel.free()

func test_junk_box_tooltip_generation() -> void:
	begin("JunkBoxPanel tooltip formatting for kinetic module stats")
	var scene: PackedScene = load("res://scenes/ui/junk_box/junk_box_panel.tscn") as PackedScene
	var panel: Control = scene.instantiate() as Control

	var mod := PolyominoModuleData.new()
	mod.tier = 3
	mod.display_name = "Heavy Gearbox"
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	mod.cell_types[Vector2i(0, 0)] = PolyominoModuleData.CellType.BUMPER
	mod.cell_types[Vector2i(1, 0)] = PolyominoModuleData.CellType.ACCELERATOR
	mod.cell_types[Vector2i(0, 1)] = PolyominoModuleData.CellType.FUNNEL
	mod.cell_types[Vector2i(1, 1)] = PolyominoModuleData.CellType.ROTARY_BOOSTER

	var item := JunkBoxItem.new(&"gearbox_1", JunkBoxItem.POLYOMINO_MODULE)
	item.display_name = "Heavy Gearbox"
	item.module_data = mod

	panel._update_tooltip(item)
	var lbl: RichTextLabel = panel._get_tooltip_lbl()
	assert_true(lbl == null, "TooltipLabel removed from sidebar layout")
	panel._update_tooltip(null)
	panel.free()

func test_drag_controller_bag_to_board_drop() -> void:
	begin("JunkBoxDragController full drag-and-drop from JunkBox to Board")
	var bag := JunkBoxData.new()
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var controller := JunkBoxDragController.new()
	controller.junk_box_data = bag
	controller.board = board

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)]
	var item := JunkBoxItem.new(&"domino_x", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	bag.place_item(item, Vector2i(0, 0))

	assert_true(bag.has_item(&"domino_x"), "item exists in bag before drag")

	controller.start_drag(item, JunkBoxDragController.DragSource.JUNK_BOX, Vector2i(0, 0), Vector2i(0, 0))
	assert_eq(controller.dragging_item, item, "dragging_item matches item")

	# Target board grid cell (3, 2)
	var target_cell := Vector2i(3, 2)
	assert_true(board.can_place_module(item, target_cell), "board accepts placement at (3,2)")

	board.place_module(item, target_cell, controller.current_rotation_step)
	bag.remove_item(item.instance_id)
	controller._end_drag()

	assert_false(bag.has_item(&"domino_x"), "item removed from bag after drop")
	assert_eq(board.get_all_placed_modules().size(), 1, "module placed on board")
	assert_eq(board.get_module_at_cell(Vector2i(3, 2)), item, "module found at (3,2)")
	assert_eq(board.get_module_at_cell(Vector2i(4, 2)), item, "module found at (4,2)")

	controller.free()
	board.free()

func test_drag_controller_board_to_bag_drop() -> void:
	begin("JunkBoxDragController pickup from Board and drop into JunkBox")
	var bag := JunkBoxData.new()
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var controller := JunkBoxDragController.new()
	controller.junk_box_data = bag
	controller.board = board

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(0, 1)]
	var item := JunkBoxItem.new(&"vert_domino", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	board.place_module(item, Vector2i(4, 4))

	assert_eq(board.get_all_placed_modules().size(), 1, "item starts on board")

	# Pickup from board
	var unslotted: Resource = board.unslot_module(&"vert_domino")
	assert_eq(unslotted, item, "unslot returns item")
	controller.start_drag(item, JunkBoxDragController.DragSource.BOARD, Vector2i(4, 4), Vector2i(0, 0))

	# Drop into bag at (2, 5)
	var bag_target_cell := Vector2i(2, 5)
	assert_true(bag.can_place_item(item, bag_target_cell), "bag can place item at (2,5)")
	bag.place_item(item, bag_target_cell, controller.current_rotation_step)
	controller._end_drag()

	assert_eq(board.get_all_placed_modules().size(), 0, "board is empty")
	assert_true(bag.has_item(&"vert_domino"), "bag now holds item")
	assert_eq(bag.get_item_at(Vector2i(2, 5)), item, "item found in bag at (2,5)")
	assert_eq(bag.get_item_at(Vector2i(2, 6)), item, "item found in bag at (2,6)")

	controller.free()
	board.free()

func test_drag_controller_invalid_board_placement_reverts() -> void:
	begin("Invalid board drop reverts item safely to original JunkBox slot")
	var bag := JunkBoxData.new()
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var controller := JunkBoxDragController.new()
	controller.junk_box_data = bag
	controller.board = board

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var item := JunkBoxItem.new(&"long_bar", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	bag.place_item(item, Vector2i(1, 3), 0)

	controller.start_drag(item, JunkBoxDragController.DragSource.JUNK_BOX, Vector2i(1, 3), Vector2i(0, 0))
	controller._rotate_item() # Rotate to step 1 in-flight

	# Invalid placement: out of bounds on right board edge (col 15 with width 3)
	assert_false(board.can_place_module(item, Vector2i(15, 2), 0), "col 15 is out of bounds")

	# Revert drag
	controller._cancel_drag()

	assert_eq(item.grid_position, Vector2i(1, 3), "item position returned to (1,3)")
	assert_eq(item.rotation_step, 0, "item rotation reverted to 0")
	assert_eq(bag.get_item_at(Vector2i(1, 3)), item, "bag still stores item at (1,3)")

	controller.free()
	board.free()

func test_drag_controller_rotation_during_transfer() -> void:
	begin("In-flight 90° rotation persists when dropped onto board")
	var bag := JunkBoxData.new()
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var controller := JunkBoxDragController.new()
	controller.junk_box_data = bag
	controller.board = board

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)] # 2x1 horizontal
	var item := JunkBoxItem.new(&"rot_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	bag.place_item(item, Vector2i(0, 0), 0)

	controller.start_drag(item, JunkBoxDragController.DragSource.JUNK_BOX, Vector2i(0, 0), Vector2i(0, 0))
	controller._rotate_item() # Rotate 90° -> becomes 1x2 vertical (rotation_step = 1)
	assert_eq(controller.current_rotation_step, 1, "rotation step is 1")

	# Drop at board cell (2, 2)
	board.place_module(item, Vector2i(2, 2), controller.current_rotation_step)
	bag.remove_item(item.instance_id)
	controller._end_drag()

	assert_eq(item.rotation_step, 1, "placed item has rotation_step 1")
	assert_eq(board.get_module_at_cell(Vector2i(2, 2)), item, "cell (2,2) occupied")
	assert_eq(board.get_module_at_cell(Vector2i(2, 3)), item, "cell (2,3) occupied vertically")
	assert_eq(board.get_module_at_cell(Vector2i(3, 2)), null, "cell (3,2) not occupied horizontally")

	controller.free()
	board.free()
