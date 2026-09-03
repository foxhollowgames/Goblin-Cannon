extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxPanel = preload("res://scenes/ui/junk_box/junk_box_panel.gd")
const JunkBoxDragController = preload("res://scenes/ui/junk_box/junk_box_drag_controller.gd")

func _init() -> void:
	suite_name = "JunkBoxManualPlacement"

func run() -> void:
	test_manual_placement_within_junk_box()
	test_manual_placement_with_rotation()
	test_manual_placement_self_collision_exclusion()
	test_manual_placement_collision_rejection_reverts()
	test_manual_placement_drag_cancellation()
	test_manual_placement_out_of_bounds_rejection()
	test_dynamic_vertical_row_expansion()

func _create_panel() -> Control:
	GameState.start_run()
	var scene: PackedScene = load("res://scenes/ui/junk_box/junk_box_panel.tscn") as PackedScene
	var panel: Control = scene.instantiate() as Control
	var tree_root: Window = Engine.get_main_loop().root
	tree_root.add_child(panel)

	panel._apply_sidebar_layout()
	panel.show()
	panel.position = Vector2(960, 0)
	panel.custom_minimum_size = Vector2(320, 720)
	if panel.grid_view:
		panel.grid_view.update_grid_size()
	return panel

func _free_panel(panel: Control) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	if "drag_controller" in panel and panel.drag_controller != null and is_instance_valid(panel.drag_controller):
		panel.drag_controller.free()
		panel.drag_controller = null
	panel.free()

func test_manual_placement_within_junk_box() -> void:
	begin("Move relic to empty target location inside junk box")
	var panel: Control = _create_panel()
	var bag: JunkBoxData = GameState.junk_box
	var controller: JunkBoxDragController = panel.drag_controller

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"superconductor")
	# 2x2 shape
	bag.place_item(item, Vector2i(0, 0), 0)
	assert_eq(bag.get_item_at(Vector2i(0, 0)), item, "item starts at (0, 0)")

	# Start drag at (0, 0)
	controller.start_drag(item, JunkBoxDragController.DragSource.JUNK_BOX, Vector2i(0, 0), Vector2i(0, 0))
	assert_eq(controller.dragging_item, item, "drag active")

	# Target cell (2, 2)
	var target_global_pos: Vector2 = panel.grid_view.get_global_pos_for_cell(Vector2i(2, 2)) + Vector2(10, 10)
	var motion := InputEventMouseMotion.new()
	motion.position = target_global_pos
	motion.global_position = target_global_pos
	controller._input(motion)

	# Release mouse button at target
	var mb_up := InputEventMouseButton.new()
	mb_up.button_index = MOUSE_BUTTON_LEFT
	mb_up.pressed = false
	mb_up.position = target_global_pos
	mb_up.global_position = target_global_pos
	controller._input(mb_up)

	assert_true(controller.dragging_item == null, "drag ended")
	assert_eq(item.grid_position, Vector2i(2, 2), "item moved to (2, 2)")
	assert_eq(bag.get_item_at(Vector2i(2, 2)), item, "item occupies (2, 2)")
	assert_eq(bag.get_item_at(Vector2i(3, 3)), item, "item occupies (3, 3)")
	assert_eq(bag.get_item_at(Vector2i(0, 0)), null, "old position (0, 0) cleared")
	_free_panel(panel)

func test_manual_placement_with_rotation() -> void:
	begin("Rotate relic 90 degrees while repositioning inside junk box")
	var panel: Control = _create_panel()
	var bag: JunkBoxData = GameState.junk_box
	var controller: JunkBoxDragController = panel.drag_controller

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)] # 3x1 horizontal
	var item := JunkBoxItem.new(&"bar_test", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod
	bag.place_item(item, Vector2i(0, 0), 0)

	controller.start_drag(item, JunkBoxDragController.DragSource.JUNK_BOX, Vector2i(0, 0), Vector2i(0, 0))
	controller._rotate_item() # Now 1x3 vertical, rot=1

	var target_global_pos: Vector2 = panel.grid_view.get_global_pos_for_cell(Vector2i(3, 1)) + Vector2(10, 10)
	var mb_up := InputEventMouseButton.new()
	mb_up.button_index = MOUSE_BUTTON_LEFT
	mb_up.pressed = false
	mb_up.position = target_global_pos
	mb_up.global_position = target_global_pos
	controller._input(mb_up)

	assert_eq(item.grid_position, Vector2i(3, 1), "moved to (3, 1)")
	assert_eq(item.rotation_step, 1, "rotation is 1")
	assert_eq(bag.get_item_at(Vector2i(3, 1)), item, "cell (3, 1) occupied")
	assert_eq(bag.get_item_at(Vector2i(3, 2)), item, "cell (3, 2) occupied")
	assert_eq(bag.get_item_at(Vector2i(3, 3)), item, "cell (3, 3) occupied")
	assert_eq(bag.get_item_at(Vector2i(0, 0)), null, "old cell (0, 0) cleared")
	_free_panel(panel)

func test_manual_placement_self_collision_exclusion() -> void:
	begin("Moving relic by 1 cell overlapping itself does not cause collision")
	var panel: Control = _create_panel()
	var bag: JunkBoxData = GameState.junk_box
	var controller: JunkBoxDragController = panel.drag_controller

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"superconductor")
	bag.place_item(item, Vector2i(1, 1), 0)

	# Shift from (1, 1) to (2, 1) -> overlaps columns
	controller.start_drag(item, JunkBoxDragController.DragSource.JUNK_BOX, Vector2i(1, 1), Vector2i(0, 0))
	var target_global_pos: Vector2 = panel.grid_view.get_global_pos_for_cell(Vector2i(2, 1)) + Vector2(10, 10)
	var mb_up := InputEventMouseButton.new()
	mb_up.button_index = MOUSE_BUTTON_LEFT
	mb_up.pressed = false
	mb_up.position = target_global_pos
	mb_up.global_position = target_global_pos
	controller._input(mb_up)

	assert_eq(item.grid_position, Vector2i(2, 1), "shifted cleanly without self-collision")
	assert_eq(bag.get_item_at(Vector2i(2, 1)), item, "cell (2, 1) occupied")
	assert_eq(bag.get_item_at(Vector2i(1, 1)), null, "unshared old cell cleared")
	_free_panel(panel)

func test_manual_placement_collision_rejection_reverts() -> void:
	begin("Dropping relic onto another stored relic rejects and reverts")
	var panel: Control = _create_panel()
	var bag: JunkBoxData = GameState.junk_box
	var controller: JunkBoxDragController = panel.drag_controller

	var item_a: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"superconductor")
	item_a.instance_id = &"item_test_relic_a"
	var item_b: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"superconductor")
	item_b.instance_id = &"item_test_relic_b"
	bag.place_item(item_a, Vector2i(0, 0), 0)
	bag.place_item(item_b, Vector2i(0, 4), 0)

	# Drag item_b onto item_a at (0, 0)
	controller.start_drag(item_b, JunkBoxDragController.DragSource.JUNK_BOX, Vector2i(0, 4), Vector2i(0, 0))
	var target_global_pos: Vector2 = panel.grid_view.get_global_pos_for_cell(Vector2i(0, 0)) + Vector2(10, 10)
	var mb_up := InputEventMouseButton.new()
	mb_up.button_index = MOUSE_BUTTON_LEFT
	mb_up.pressed = false
	mb_up.position = target_global_pos
	mb_up.global_position = target_global_pos
	controller._input(mb_up)

	assert_eq(item_b.grid_position, Vector2i(0, 4), "item_b reverted to original pos (0, 4)")
	assert_eq(bag.get_item_at(Vector2i(0, 4)), item_b, "item_b still at (0, 4)")
	assert_eq(bag.get_item_at(Vector2i(0, 0)), item_a, "item_a still at (0, 0)")
	_free_panel(panel)

func test_manual_placement_drag_cancellation() -> void:
	begin("Escape key cancels drag and restores original position and rotation")
	var panel: Control = _create_panel()
	var bag: JunkBoxData = GameState.junk_box
	var controller: JunkBoxDragController = panel.drag_controller

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"superconductor")
	bag.place_item(item, Vector2i(2, 2), 0)

	controller.start_drag(item, JunkBoxDragController.DragSource.JUNK_BOX, Vector2i(2, 2), Vector2i(0, 0))
	controller._rotate_item()
	assert_eq(controller.current_rotation_step, 1, "rotated in-flight")

	var key_esc := InputEventKey.new()
	key_esc.keycode = KEY_ESCAPE
	key_esc.pressed = true
	controller._input(key_esc)

	assert_true(controller.dragging_item == null, "drag cancelled")
	assert_eq(item.grid_position, Vector2i(2, 2), "position restored")
	assert_eq(item.rotation_step, 0, "rotation restored")
	assert_eq(bag.get_item_at(Vector2i(2, 2)), item, "bag still stores item at (2, 2)")
	_free_panel(panel)

func test_manual_placement_out_of_bounds_rejection() -> void:
	begin("Dropping relic out of grid bounds reverts safely")
	var panel: Control = _create_panel()
	var bag: JunkBoxData = GameState.junk_box
	var controller: JunkBoxDragController = panel.drag_controller

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"superconductor")
	bag.place_item(item, Vector2i(0, 0), 0)

	# Drag to column 5 (2x2 would need column 5 and 6, exceeding cols=6)
	controller.start_drag(item, JunkBoxDragController.DragSource.JUNK_BOX, Vector2i(0, 0), Vector2i(0, 0))
	var target_global_pos: Vector2 = panel.grid_view.get_global_pos_for_cell(Vector2i(5, 0)) + Vector2(10, 10)
	var mb_up := InputEventMouseButton.new()
	mb_up.button_index = MOUSE_BUTTON_LEFT
	mb_up.pressed = false
	mb_up.position = target_global_pos
	mb_up.global_position = target_global_pos
	controller._input(mb_up)

	assert_eq(item.grid_position, Vector2i(0, 0), "reverted to (0, 0)")
	assert_eq(bag.get_item_at(Vector2i(0, 0)), item, "item remains at (0, 0)")
	_free_panel(panel)

func test_dynamic_vertical_row_expansion() -> void:
	begin("Placing a relic near bottom triggers dynamic vertical row expansion in JunkBoxGridView")
	var panel: Control = _create_panel()
	var bag: JunkBoxData = GameState.junk_box
	var grid_view: JunkBoxGridView = panel.grid_view

	var initial_height: float = grid_view.custom_minimum_size.y
	assert_gt(initial_height, 0.0, "initial height is positive")

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"superconductor")
	bag.place_item(item, Vector2i(0, 18), 0)

	var expanded_height: float = grid_view.custom_minimum_size.y
	var expected_min_height: float = float((18 + 4) * JunkBoxGridView.CELL_SIZE)
	assert_gte(expanded_height, expected_min_height, "grid height expanded dynamically to accommodate row 18")

	_free_panel(panel)

