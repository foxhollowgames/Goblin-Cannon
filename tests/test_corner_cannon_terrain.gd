extends "res://tests/test_base.gd"

const CircularCannonWidgetScript = preload("res://scenes/ui/circular_cannon_widget.gd")
const ScrollingTerrainScript = preload("res://scenes/combat/scrolling_terrain.gd")
const BattlefieldViewScript = preload("res://scenes/combat/battlefield_view.gd")

func _init() -> void:
	suite_name = "CornerCannonTerrain"

func run() -> void:
	test_widget_terrain_initialization()
	test_widget_terrain_resize()
	test_widget_clip_contents()
	test_widget_firing_recoil_rumble()
	test_widget_advance_and_stop()
	test_battlefield_view_sync_with_widget()
	cleanup()

func _add_to_tree(node: Node) -> Node:
	autofree(node)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(node)
	return node

func test_widget_terrain_initialization() -> void:
	begin("test_widget_terrain_initialization")
	var widget: Control = _add_to_tree(CircularCannonWidgetScript.new()) as Control
	var terrain: Node2D = widget.get_scrolling_terrain()
	assert_not_null_val(terrain, "ScrollingTerrain is instantiated inside CircularCannonWidget")
	assert_true(terrain.show_behind_parent, "Terrain has show_behind_parent enabled")
	assert_eq(terrain.get("terrain_width"), 290.0, "Terrain width defaults to widget custom minimum width")
	assert_eq(terrain.get("terrain_height"), 184.0, "Terrain height defaults to widget custom minimum height")

func test_widget_terrain_resize() -> void:
	begin("test_widget_terrain_resize")
	var widget: Control = _add_to_tree(CircularCannonWidgetScript.new()) as Control
	widget.size = Vector2(300.0, 200.0)
	widget._notification(Control.NOTIFICATION_RESIZED)
	var terrain: Node2D = widget.get_scrolling_terrain()
	assert_eq(terrain.get("terrain_width"), 300.0, "Terrain width updates on widget resize")
	assert_eq(terrain.get("terrain_height"), 200.0, "Terrain height updates on widget resize")

func test_widget_clip_contents() -> void:
	begin("test_widget_clip_contents")
	var widget: Control = _add_to_tree(CircularCannonWidgetScript.new()) as Control
	assert_true(widget.clip_contents, "CircularCannonWidget enables clip_contents to bound terrain drawing")

func test_widget_firing_recoil_rumble() -> void:
	begin("test_widget_firing_recoil_rumble")
	var widget: Control = _add_to_tree(CircularCannonWidgetScript.new()) as Control
	var terrain: Node2D = widget.get_scrolling_terrain()
	widget.trigger_firing_anim()
	var rumble: Vector2 = terrain.get("_rumble_offset")
	assert_gt(rumble.y, 0.0, "Firing animation excites recoil rumble offset on terrain")

func test_widget_advance_and_stop() -> void:
	begin("test_widget_advance_and_stop")
	var widget: Control = _add_to_tree(CircularCannonWidgetScript.new()) as Control
	var terrain: Node2D = widget.get_scrolling_terrain()
	widget.start_advancing(0.5, 200.0)
	assert_true(terrain.get("is_advancing"), "Terrain is_advancing is true after start_advancing")
	widget.stop_advancing(0.5)
	assert_not_null_val(terrain.get("_speed_tween"), "Speed tween is active during stop_advancing")

func test_battlefield_view_sync_with_widget() -> void:
	begin("test_battlefield_view_sync_with_widget")
	var root: Node2D = _add_to_tree(Node2D.new()) as Node2D
	var bf_view: Node2D = BattlefieldViewScript.new()
	root.add_child(bf_view)
	autofree(bf_view)
	var widget: Control = CircularCannonWidgetScript.new()
	widget.name = "CircularCannonWidget"
	root.add_child(widget)
	autofree(widget)

	bf_view.play_wall_destroyed_transition()
	var terrain: Node2D = widget.get_scrolling_terrain()
	assert_true(terrain.get("is_advancing"), "BattlefieldView forwards wall break advance to CircularCannonWidget")

	bf_view.play_next_wall_intro()
	assert_not_null_val(terrain.get("_speed_tween"), "BattlefieldView forwards next wall intro stop to CircularCannonWidget")

func assert_not_null_val(val: Variant, msg: String) -> void:
	if val != null:
		passed += 1
	else:
		failed += 1
		errors.append("%s: expected non-null value" % msg)
