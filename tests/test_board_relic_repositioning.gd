extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxDragController = preload("res://scenes/ui/junk_box/junk_box_drag_controller.gd")
const BoardScript = preload("res://scenes/board/board.gd")

func _init() -> void:
	suite_name = "BoardRelicRepositioning"

func run() -> void:
	test_board_click_starts_drag()
	test_board_reposition_and_drop()
	test_board_relic_replaces_pegs_on_drop()
	test_board_drag_cancellation_restores_position_and_rotation()
	test_board_drag_to_junk_box_transfer()
	test_in_flight_rotation_dynamic_grab_offset()
	test_board_input_click_triggers_drag_with_closed_junk_box_panel()

func test_board_input_click_triggers_drag_with_closed_junk_box_panel() -> void:
	begin("Board _input click triggers drag and keeps ghost preview visible when junk box is closed")
	var overlay := CanvasLayer.new()
	var scene: PackedScene = load("res://scenes/ui/junk_box/junk_box_panel.tscn") as PackedScene
	var panel: Control = scene.instantiate() as Control
	overlay.add_child(panel)

	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	panel.set_board(board)

	assert_false(panel.visible, "junk box panel is closed/hidden")
	assert_true(panel.drag_controller != null, "drag controller exists")
	assert_eq(panel.drag_controller.get_parent(), overlay, "drag controller reparented to overlay")

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)]
	var item := JunkBoxItem.new(&"live_drag_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	board.place_module(item, Vector2i(3, 2))

	# Click on cell (3, 2)
	var click_world_pos: Vector2 = board.board_cell_to_world(Vector2i(3, 2))
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = click_world_pos

	board._input(event)

	assert_eq(panel.drag_controller.dragging_item, item, "drag initiated via _input")
	assert_eq(panel.drag_controller.drag_source, JunkBoxDragController.DragSource.BOARD, "drag source is BOARD")
	assert_true(panel.drag_controller.ghost_preview.visible, "ghost preview is visible")

	panel.drag_controller._cancel_drag()
	panel.free()
	overlay.free()
	board.free()

func test_board_click_starts_drag() -> void:
	begin("Board click on placed relic initiates drag mode with accurate grab offset")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var controller := JunkBoxDragController.new()
	controller.board = board
	board.set_drag_controller(controller)

	var mod := PolyominoModuleData.new()
	mod.module_id = &"domino_h"
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)]

	var item := JunkBoxItem.new(&"item_domino_1", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	board.place_module(item, Vector2i(3, 2))

	assert_eq(board.get_all_placed_modules().size(), 1, "module placed at (3,2)")
	assert_eq(board.get_module_at_cell(Vector2i(3, 2)), item, "cell (3,2) occupied")
	assert_eq(board.get_module_at_cell(Vector2i(4, 2)), item, "cell (4,2) occupied")

	# Simulate mouse click at cell (4, 2) (grab offset (1, 0))
	var click_world_pos: Vector2 = board.board_cell_to_world(Vector2i(4, 2))
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = click_world_pos

	# Simulate unhandled input on board with fake mouse position logic
	var cell: Vector2i = board.world_to_board_cell(click_world_pos)
	var found_item: Resource = board.get_module_at_cell(cell)
	assert_eq(found_item, item, "found item at click location")

	var origin_cell: Vector2i = item.grid_position
	var grab_offset: Vector2i = cell - origin_cell
	board.unslot_module(item.instance_id)
	controller.start_drag(item, JunkBoxDragController.DragSource.BOARD, origin_cell, grab_offset)

	assert_eq(controller.dragging_item, item, "controller is dragging item")
	assert_eq(controller.drag_source, JunkBoxDragController.DragSource.BOARD, "drag source is BOARD")
	assert_eq(controller.drag_origin_cell, Vector2i(3, 2), "drag origin cell is (3,2)")
	assert_eq(controller.grab_offset_cell, Vector2i(1, 0), "grab offset cell is (1,0)")
	assert_eq(controller.grabbed_cell_index, 1, "grabbed cell index is 1")
	assert_eq(board.get_module_at_cell(Vector2i(3, 2)), null, "item unslotted from board during drag")
	assert_eq(board.get_module_at_cell(Vector2i(4, 2)), null, "cell (4,2) cleared during drag")

	controller._end_drag()
	controller.free()
	board.free()

func test_board_reposition_and_drop() -> void:
	begin("Relic repositioning and dropping onto a new board grid location")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var controller := JunkBoxDragController.new()
	controller.board = board

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)]

	var item := JunkBoxItem.new(&"move_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	board.place_module(item, Vector2i(2, 2))

	# Pickup from board
	board.unslot_module(&"move_item")
	controller.start_drag(item, JunkBoxDragController.DragSource.BOARD, Vector2i(2, 2), Vector2i(0, 0))

	# Drop at new cell (5, 4)
	var new_cell := Vector2i(5, 4)
	assert_true(board.can_place_module(item, new_cell), "can place at (5,4)")
	board.place_module(item, new_cell, controller.current_rotation_step)
	controller._end_drag()

	assert_eq(board.get_all_placed_modules().size(), 1, "1 module placed on board")
	assert_eq(board.get_module_at_cell(Vector2i(5, 4)), item, "item found at (5,4)")
	assert_eq(board.get_module_at_cell(Vector2i(6, 4)), item, "item found at (6,4)")
	assert_eq(board.get_module_at_cell(Vector2i(2, 2)), null, "old cell (2,2) is empty")
	assert_eq(board.get_module_at_cell(Vector2i(3, 2)), null, "old cell (3,2) is empty")

	controller.free()
	board.free()

func test_board_relic_replaces_pegs_on_drop() -> void:
	begin("Relic placement suppresses pegs on occupied cells and unslotting restores them")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	# Cell (2, 2) is a valid checkerboard peg position (2+2 % 2 == 0)
	var peg_before: Node = board.get_peg_at_cell(Vector2i(2, 2))
	assert_true(peg_before != null, "peg exists at (2,2) initially")

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)] # 2x1 covering (2,2) and (3,2)

	var item := JunkBoxItem.new(&"peg_crusher", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod

	# Place relic over cell (2, 2)
	assert_true(board.can_place_module(item, Vector2i(2, 2)), "can place relic over pegs")
	board.place_module(item, Vector2i(2, 2))

	assert_eq(board.get_peg_at_cell(Vector2i(2, 2)), null, "peg at (2,2) is suppressed when relic is placed")
	assert_false(peg_before.visible, "suppressed peg is hidden")
	assert_eq(peg_before.collision_layer, 0, "suppressed peg collision is disabled")
	assert_eq(board.get_module_at_cell(Vector2i(2, 2)), item, "module placed at (2,2)")

	# Move / unslot relic from (2, 2) to (6, 4)
	board.unslot_module(item.instance_id)
	assert_eq(board.get_peg_at_cell(Vector2i(2, 2)), peg_before, "peg at (2,2) is fully restored after unslotting")
	assert_true(peg_before.visible, "restored peg is visible")
	assert_eq(peg_before.collision_layer, 1, "restored peg collision is re-enabled")

	# Move relic to another cell and verify moving back and forth preserves all pegs
	board.place_module(item, Vector2i(6, 4))
	assert_eq(board.get_peg_at_cell(Vector2i(2, 2)), peg_before, "peg at (2,2) remains restored while relic is at (6,4)")
	board.unslot_module(item.instance_id)

	board.free()

func test_board_drag_cancellation_restores_position_and_rotation() -> void:
	begin("Drag cancellation restores relic to original board position and rotation")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var controller := JunkBoxDragController.new()
	controller.board = board

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)] # 2x1 horizontal

	var item := JunkBoxItem.new(&"cancel_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	board.place_module(item, Vector2i(4, 3), 0)

	# Pickup from board
	board.unslot_module(&"cancel_item")
	controller.start_drag(item, JunkBoxDragController.DragSource.BOARD, Vector2i(4, 3), Vector2i(0, 0))

	# Rotate in-flight
	controller._rotate_item()
	assert_eq(controller.current_rotation_step, 1, "in-flight rotation is 1")

	# Cancel drag
	controller._cancel_drag()

	assert_eq(board.get_all_placed_modules().size(), 1, "module restored on board")
	assert_eq(item.grid_position, Vector2i(4, 3), "grid position restored to (4,3)")
	assert_eq(item.rotation_step, 0, "rotation restored to 0")
	assert_eq(board.get_module_at_cell(Vector2i(4, 3)), item, "item found at (4,3)")
	assert_eq(board.get_module_at_cell(Vector2i(5, 3)), item, "item found at (5,3) horizontally")
	assert_eq(board.get_module_at_cell(Vector2i(4, 4)), null, "cell (4,4) is not occupied vertically")

	controller.free()
	board.free()

func test_board_drag_to_junk_box_transfer() -> void:
	begin("Relic dragging from Board directly into Junk Box inventory")
	var bag := JunkBoxData.new()
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var controller := JunkBoxDragController.new()
	controller.junk_box_data = bag
	controller.board = board

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(0, 1)]

	var item := JunkBoxItem.new(&"board_to_bag_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	board.place_module(item, Vector2i(3, 3))

	assert_eq(board.get_all_placed_modules().size(), 1, "starts on board")

	# Pickup from board and drop into junk box
	board.unslot_module(&"board_to_bag_item")
	controller.start_drag(item, JunkBoxDragController.DragSource.BOARD, Vector2i(3, 3), Vector2i(0, 0))

	var bag_cell := Vector2i(2, 1)
	assert_true(bag.can_place_item(item, bag_cell), "can place in bag at (2,1)")
	bag.place_item(item, bag_cell, controller.current_rotation_step)
	controller._end_drag()

	assert_eq(board.get_all_placed_modules().size(), 0, "board is now empty")
	assert_true(bag.has_item(&"board_to_bag_item"), "item now safely stored in junk box")
	assert_eq(bag.get_item_at(Vector2i(2, 1)), item, "item at (2,1) in bag")
	assert_eq(bag.get_item_at(Vector2i(2, 2)), item, "item at (2,2) in bag")

	controller.free()
	board.free()

func test_in_flight_rotation_dynamic_grab_offset() -> void:
	begin("In-flight rotation dynamically adjusts grab offset to preserve held cell")
	var controller := JunkBoxDragController.new()

	var mod := PolyominoModuleData.new()
	mod.module_id = &"l_shape_drag"
	mod.cells = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]

	var item := JunkBoxItem.new(&"l_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod

	# Grab at cell (1, 1) -> index 2 in original cells
	controller.start_drag(item, JunkBoxDragController.DragSource.BOARD, Vector2i(0, 0), Vector2i(1, 1))
	assert_eq(controller.grabbed_cell_index, 2, "grabbed cell index is 2")
	assert_eq(controller.get_current_grab_offset(), Vector2i(1, 1), "rot 0 grab offset is (1,1)")

	# Rotate 90 deg CW (step 1)
	controller._rotate_item()
	assert_eq(controller.current_rotation_step, 1, "rotation step is 1")
	assert_eq(controller.get_current_grab_offset(), Vector2i(0, 1), "rot 1 grab offset is (0,1)")

	# Rotate 90 deg CW (step 2)
	controller._rotate_item()
	assert_eq(controller.current_rotation_step, 2, "rotation step is 2")
	assert_eq(controller.get_current_grab_offset(), Vector2i(0, 0), "rot 2 grab offset is (0,0)")

	# Rotate 90 deg CW (step 3)
	controller._rotate_item()
	assert_eq(controller.current_rotation_step, 3, "rotation step is 3")
	assert_eq(controller.get_current_grab_offset(), Vector2i(1, 0), "rot 3 grab offset is (1,0)")

	controller._cancel_drag()
	controller.free()

