extends "res://tests/test_base.gd"

const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")
const JunkBoxGridView = preload("res://scenes/ui/junk_box/junk_box_grid_view.gd")
const JunkBoxDragController = preload("res://scenes/ui/junk_box/junk_box_drag_controller.gd")
const RelicLayoutPreview = preload("res://scenes/rewards/relic_layout_preview.gd")
const PolyominoModuleNode = preload("res://scenes/board/machinery/polyomino_module_node.gd")

func _init() -> void:
	suite_name = "JunkBoxPhysicalVisuals"

func run() -> void:
	test_junk_box_grid_view_instantiates_polyomino_module_nodes()
	test_junk_box_drag_dimming_sync()
	test_drag_controller_ghost_preview_module_node()
	test_relic_layout_preview_uses_module_node()

func test_junk_box_grid_view_instantiates_polyomino_module_nodes() -> void:
	begin("JunkBoxGridView instantiates PolyominoModuleNode children with exact board visuals and 0 collision")
	var data: JunkBoxData = JunkBoxData.new()
	var grid_view: JunkBoxGridView = JunkBoxGridView.new()
	autofree(grid_view)
	grid_view.set_junk_box_data(data)

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"superconductor")
	assert_true(item != null, "relic item created successfully")
	item.grid_position = Vector2i(1, 2)
	data.items[item.instance_id] = item
	for c in item.get_occupied_cells():
		data.occupied_cells[c] = item.instance_id

	grid_view.sync_item_nodes()

	assert_true(grid_view._item_nodes.has(item.instance_id), "item node registered in grid view")
	var node: PolyominoModuleNode = grid_view._item_nodes.get(item.instance_id) as PolyominoModuleNode
	assert_true(node != null, "child node is an authentic PolyominoModuleNode")
	assert_true(node.is_ghost, "module node is marked as ghost state for UI display")
	assert_true(is_equal_approx(node.modulate.a, 1.0), "normal idle relic module has alpha 1.0")

	var expected_pos := Vector2((1.0 + 0.5) * float(JunkBoxGridView.CELL_SIZE), (2.0 + 0.5) * float(JunkBoxGridView.CELL_SIZE))
	assert_eq(node.position, expected_pos, "node positioned at center of target grid cell")

	var expected_scale := Vector2(float(JunkBoxGridView.CELL_SIZE) / 52.0, float(JunkBoxGridView.CELL_SIZE) / 56.0)
	assert_eq(node.scale, expected_scale, "node scale maps CELL_WIDTH/HEIGHT to JunkBox CELL_SIZE")

	# Verify collision layers are 0
	for comp in node._components:
		assert_eq(comp.collision_layer, 0, "machinery component has collision disabled in junk box")

	cleanup()

func test_junk_box_drag_dimming_sync() -> void:
	begin("Dragging item dims the inventory module in grid view and undims on drop")
	var data: JunkBoxData = JunkBoxData.new()
	var grid_view: JunkBoxGridView = JunkBoxGridView.new()
	autofree(grid_view)
	grid_view.set_junk_box_data(data)

	var drag_ctrl: JunkBoxDragController = JunkBoxDragController.new()
	autofree(drag_ctrl)
	drag_ctrl.junk_box_data = data
	drag_ctrl.junk_box_grid_view = grid_view
	grid_view.drag_controller = drag_ctrl

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"superconductor")
	item.grid_position = Vector2i(0, 0)
	data.items[item.instance_id] = item
	grid_view.sync_item_nodes()

	var node: PolyominoModuleNode = grid_view._item_nodes.get(item.instance_id) as PolyominoModuleNode
	assert_true(node != null, "superconductor module node created")
	assert_eq(node.modulate.a, 1.0, "initial alpha is 1.0")

	drag_ctrl.start_drag(item, JunkBoxDragController.DragSource.JUNK_BOX, item.grid_position, Vector2i.ZERO)
	assert_true(is_equal_approx(node.modulate.a, 0.35), "alpha dimmed to ~0.35 while being dragged")

	drag_ctrl._end_drag()
	assert_true(is_equal_approx(node.modulate.a, 1.0), "alpha restored to 1.0 when drag ends")

	cleanup()

func test_drag_controller_ghost_preview_module_node() -> void:
	begin("JunkBoxDragController ghost visual hosts authentic PolyominoModuleNode")
	var data: JunkBoxData = JunkBoxData.new()
	var drag_ctrl: JunkBoxDragController = JunkBoxDragController.new()
	autofree(drag_ctrl)
	drag_ctrl.junk_box_data = data

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"cascade_reactor")
	item.grid_position = Vector2i(0, 0)
	data.items[item.instance_id] = item

	drag_ctrl.start_drag(item, JunkBoxDragController.DragSource.JUNK_BOX, item.grid_position, Vector2i.ZERO)

	assert_true(drag_ctrl._ghost_visual != null, "ghost visual exists")
	var ghost_node: PolyominoModuleNode = drag_ctrl._ghost_visual._module_node
	assert_true(ghost_node != null, "ghost visual instantiated child PolyominoModuleNode")
	assert_true(ghost_node.is_ghost, "ghost module node is in ghost state")

	drag_ctrl._end_drag()
	cleanup()

func test_relic_layout_preview_uses_module_node() -> void:
	begin("RelicLayoutPreview hosts authentic PolyominoModuleNode for shop and rewards")
	var preview: RelicLayoutPreview = RelicLayoutPreview.new()
	autofree(preview)

	var ok: bool = preview.setup_for_relic(&"cascade_reactor")
	assert_true(ok, "cascade_reactor setup succeeded")
	assert_true(preview._module_node != null, "preview instantiated PolyominoModuleNode")
	assert_true(preview._module_node.visible, "preview module node is visible")
	assert_true(preview._module_node.is_ghost, "preview module node is in ghost mode")

	# Verify clear hides the node
	preview.clear()
	assert_false(preview._module_node.visible, "clearing preview hides module node")

	cleanup()
