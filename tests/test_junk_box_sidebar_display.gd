extends "res://tests/test_base.gd"

const JunkBoxPanelScript = preload("res://scenes/ui/junk_box/junk_box_panel.gd")
const JunkBoxGridViewScript = preload("res://scenes/ui/junk_box/junk_box_grid_view.gd")
const PolyominoModuleNodeScript = preload("res://scenes/board/machinery/polyomino_module_node.gd")

func _init() -> void:
	suite_name = "JunkBoxSidebarDisplay"

func run() -> void:
	test_sidebar_integration_hierarchy()
	test_pegboard_preview_cell_dimension_equivalence()
	test_drag_controller_binding()

func test_sidebar_integration_hierarchy() -> void:
	begin("JunkBoxPanel integrates cleanly into right sidebar container")
	var sidebar := Control.new()
	sidebar.name = "RightSidebarPanel"

	var jb_panel: Control = JunkBoxPanelScript.new()
	jb_panel.integrate_into_sidebar(sidebar)

	assert_true(jb_panel.is_integrated_in_sidebar(), "JunkBoxPanel registers sidebar integration")
	assert_eq(jb_panel.get_parent(), sidebar, "JunkBoxPanel parented to right sidebar container")
	assert_true(jb_panel.visible, "JunkBoxPanel visible in right sidebar")

	jb_panel.free()
	sidebar.free()

func test_pegboard_preview_cell_dimension_equivalence() -> void:
	begin("JunkBoxGridView cell dimensions match JunkBoxGridView constants")
	var grid_view: JunkBoxGridView = JunkBoxGridViewScript.new()
	var cell_size: int = grid_view.get_cell_size()
	var params: Dictionary = grid_view.get_peg_preview_parameters()

	var expected_size: float = float(JunkBoxGridViewScript.CELL_SIZE)
	assert_eq(float(cell_size), expected_size, "JunkBoxGridView cell_size equals CELL_SIZE constant")
	assert_eq(params.get("cell_width", 0.0), expected_size, "preview params cell_width equals CELL_WIDTH constant")
	assert_eq(params.get("cell_height", 0.0), expected_size, "preview params cell_height equals CELL_HEIGHT constant")

	grid_view.free()

func test_drag_controller_binding() -> void:
	begin("JunkBoxPanel initializes drag controller binding")
	var jb_panel: Control = JunkBoxPanelScript.new()
	jb_panel._ensure_drag_controller_exists()

	assert_true(jb_panel.drag_controller != null, "drag controller exists on JunkBoxPanel")

	jb_panel.free()
