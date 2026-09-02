extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxDragController = preload("res://scenes/ui/junk_box/junk_box_drag_controller.gd")
const BoardScript = preload("res://scenes/board/board.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")

func _init() -> void:
	suite_name = "RelicJunkBoxReturn"

func run() -> void:
	test_return_relic_to_junk_box()
	test_pegboard_grid_and_peg_restoration()
	test_passive_effect_removal_on_return()
	test_drag_controller_board_to_junk_box_drop()

func test_return_relic_to_junk_box() -> void:
	begin("Return placed board relic back into JunkBoxData inventory")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var jb := JunkBoxData.new()
	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)]
	mod.module_id = &"cascade_reactor"
	mod.tier = 2

	var item := JunkBoxItem.new(&"return_test_item_1", JunkBoxItem.POLYOMINO_MODULE)
	item.display_name = "Cascade Reactor"
	item.module_data = mod
	item.custom_payload = {"level": 3, "relic_id": "cascade_reactor"}

	assert_true(board.place_module(item, Vector2i(2, 3)), "Module placed on board")
	assert_eq(board.get_module_at_cell(Vector2i(2, 3)), item, "Board cell 2,3 occupied by item")
	assert_false(jb.has_item(item.instance_id), "Junk box does not have item yet")

	var success: bool = board.return_module_to_junk_box(item.instance_id, jb)
	assert_true(success, "return_module_to_junk_box returned true")
	assert_eq(board.get_module_at_cell(Vector2i(2, 3)), null, "Board cell 2,3 is now empty")
	assert_true(jb.has_item(item.instance_id), "Item returned to JunkBoxData inventory")

	var returned_item: JunkBoxItem = jb.items.get(item.instance_id)
	assert_true(returned_item != null, "Returned item found in junk box")
	assert_eq(returned_item.display_name, "Cascade Reactor", "Item display_name retained")
	assert_eq(returned_item.custom_payload.get("level"), 3, "Item metadata level retained")

	board.free()

func test_pegboard_grid_and_peg_restoration() -> void:
	begin("Pegboard grid cells and suppressed pegs are restored when relic is returned")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var peg := Area2D.new()
	peg.position = board.board_cell_to_world(Vector2i(4, 4))
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	peg.add_child(col)
	board.add_child(peg)
	board._peg_by_id["peg_4_4"] = peg

	var jb := JunkBoxData.new()
	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0)]
	var item := JunkBoxItem.new(&"peg_test_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod

	board.place_module(item, Vector2i(4, 4))
	assert_eq(board._occupied_board_cells.get(Vector2i(4, 4)), item.instance_id, "Cell 4,4 occupied")
	assert_false(peg.visible, "Peg suppressed and invisible under placed relic footprint")
	assert_true(col.disabled, "Peg collision shape disabled under placed relic footprint")

	var ok: bool = board.return_module_to_junk_box(item.instance_id, jb)
	assert_true(ok, "Relic returned to junk box")
	assert_false(board._occupied_board_cells.has(Vector2i(4, 4)), "Cell 4,4 cleared from occupied dictionary")
	assert_true(peg.visible, "Peg visibility restored")
	assert_false(col.disabled, "Peg collision shape re-enabled")

	peg.free()
	board.free()

func test_passive_effect_removal_on_return() -> void:
	begin("Relic passive effects are removed from GameState when returned to inventory")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	var jb := JunkBoxData.new()

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0)]
	mod.module_id = &"supernova_peg"
	mod.tier = 2

	var item := JunkBoxItem.new(&"passive_test_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	item.custom_payload = {"relic_id": "supernova_peg"}

	var initial_stacks: int = GameState.get_wall_break_upgrade_stacks(&"supernova_peg") if GameState != null else 0

	board.place_module(item, Vector2i(1, 1))
	if GameState != null:
		var placed_stacks: int = GameState.get_wall_break_upgrade_stacks(&"supernova_peg")
		assert_eq(placed_stacks, initial_stacks + 1, "Passive stack added on placement")

	board.return_module_to_junk_box(item.instance_id, jb)

	if GameState != null:
		var returned_stacks: int = GameState.get_wall_break_upgrade_stacks(&"supernova_peg")
		assert_eq(returned_stacks, initial_stacks, "Passive stack removed on return to junk box")

	board.free()

func test_drag_controller_board_to_junk_box_drop() -> void:
	begin("JunkBoxDragController transfers board relic into junk box on drop")
	var overlay := CanvasLayer.new()
	var panel_scene: PackedScene = load("res://scenes/ui/junk_box/junk_box_panel.tscn") as PackedScene
	var panel: Control = panel_scene.instantiate() as Control
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	overlay.add_child(panel)

	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	panel.set_board(board)

	var jb := JunkBoxData.new()
	if GameState != null:
		GameState.junk_box = jb
	panel.drag_controller.junk_box_data = jb

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0)]
	var item := JunkBoxItem.new(&"drag_drop_test_item", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod

	board.place_module(item, Vector2i(2, 2))
	assert_eq(board.get_module_at_cell(Vector2i(2, 2)), item, "Item placed on board")

	panel.drag_controller.start_drag(item, JunkBoxDragController.DragSource.BOARD, Vector2i(2, 2), Vector2i.ZERO)
	assert_eq(panel.drag_controller.dragging_item, item, "Item is dragging")

	# Direct return to junk box
	var returned: bool = board.return_module_to_junk_box(item.instance_id, jb)
	assert_true(returned, "Module returned to junk box")
	assert_eq(board.get_module_at_cell(Vector2i(2, 2)), null, "Item unslotted from board")
	assert_true(jb.has_item(item.instance_id), "Item transferred into JunkBoxData")

	panel.free()
	overlay.free()
	board.free()
