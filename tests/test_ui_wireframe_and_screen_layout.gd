extends "res://tests/test_base.gd"

const JunkBoxPanel = preload("res://scenes/ui/junk_box/junk_box_panel.gd")

func _init() -> void:
	suite_name = "UIWireframeAndScreenLayout"

func run() -> void:
	test_wireframe_specification_file_exists_and_valid()
	test_playfield_and_sidebar_proportions()
	test_junk_box_panel_dimensions_fit_sidebar()
	test_modal_wireframe_bounds()

func test_wireframe_specification_file_exists_and_valid() -> void:
	begin("docs/UI_WIREFRAME_AND_LAYOUT_SPEC.md exists and contains layout specifications")
	var file: FileAccess = FileAccess.open("res://docs/UI_WIREFRAME_AND_LAYOUT_SPEC.md", FileAccess.READ)
	assert_true(file != null, "UI_WIREFRAME_AND_LAYOUT_SPEC.md opens successfully")
	if file:
		var content: String = file.get_as_text()
		assert_true(content.contains("1280 x 720"), "spec specifies 1280 x 720 native resolution")
		assert_true(content.contains("Primary Playfield"), "spec defines Primary Playfield zone")
		assert_true(content.contains("Right Telemetry Sidebar"), "spec defines Right Telemetry Sidebar zone")
		assert_true(content.contains("Top Header Bar"), "spec defines Top Header Bar zone")
		assert_true(content.contains("Milestone Shop & Major Upgrade Draft Modal"), "spec defines Draft Modal wireframe")
		assert_true(content.contains("Fullscreen Comic Cutscene Takeover"), "spec defines Comic Cutscene wireframe")
		file.close()

func test_playfield_and_sidebar_proportions() -> void:
	begin("Root scene enforces 960px playfield and 320px right sidebar split")
	var scene: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	assert_true(scene != null, "main.tscn loads successfully")
	var main_node: Node = scene.instantiate()
	assert_true(main_node != null, "main.tscn instantiates successfully")
	var battlefield: Node2D = main_node.get_node_or_null("CombatContainer/BattlefieldView") as Node2D
	assert_true(battlefield != null, "CombatContainer/BattlefieldView exists")
	if battlefield:
		assert_eq(battlefield.position.x, 960.0, "BattlefieldView starts at X=960px boundary")
	var right_wall: Node2D = main_node.get_node_or_null("BoardWalls/RightWall") as Node2D
	assert_true(right_wall != null, "BoardWalls/RightWall exists")
	if right_wall:
		assert_gte(right_wall.position.x, 960.0, "RightWall encloses 960px playfield")
	main_node.free()

func test_junk_box_panel_dimensions_fit_sidebar() -> void:
	begin("JunkBoxPanel sidebar mode fits within 320px sidebar without horizontal overflow")
	var scene: PackedScene = load("res://scenes/ui/junk_box/junk_box_panel.tscn") as PackedScene
	assert_true(scene != null, "junk_box_panel.tscn loads")
	var panel: Control = scene.instantiate() as Control
	assert_true(panel != null, "junk_box_panel instantiates")
	var drawer: PanelContainer = panel.get_node_or_null("DrawerPanel") as PanelContainer
	assert_true(drawer != null, "DrawerPanel child exists")
	var dummy_sidebar: Control = Control.new()
	dummy_sidebar.custom_minimum_size = Vector2(320, 720)
	panel.integrate_into_sidebar(dummy_sidebar)
	if drawer:
		assert_lte(drawer.custom_minimum_size.x, 304.0, "drawer panel width fits inside 304px sidebar content zone")
	panel.free()
	dummy_sidebar.free()

func test_modal_wireframe_bounds() -> void:
	begin("Major upgrade draft panel covers 1280x720 canvas")
	var scene: PackedScene = load("res://scenes/rewards/major_upgrade_draft_panel.tscn") as PackedScene
	assert_true(scene != null, "major_upgrade_draft_panel.tscn loads")
	var modal: Control = scene.instantiate() as Control
	assert_true(modal != null, "major_upgrade_draft_panel instantiates")
	assert_eq(modal.anchor_right, 1.0, "modal anchors across full horizontal canvas")
	assert_eq(modal.anchor_bottom, 1.0, "modal anchors across full vertical canvas")
	modal.free()
