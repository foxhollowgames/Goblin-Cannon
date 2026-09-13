extends "res://tests/test_base.gd"

const BattlefieldViewScript: GDScript = preload("res://scenes/combat/battlefield_view.gd")
const CityMobVisualScript: GDScript = preload("res://scenes/combat/city_mob_visual.gd")
const CannonVisualScript: GDScript = preload("res://scenes/combat/cannon_visual.gd")

func _init() -> void:
	suite_name = "TopBattlefieldAndMobTimer"

func run() -> void:
	test_battlefield_view_top_coordinates_and_dimensions()
	test_city_mob_visual_theme_selection()
	test_city_mob_visual_timer_progression()
	test_cannon_explosion_trigger()
	test_junk_drawer_full_height_without_cannon_widget()
	test_main_scene_layout_integration()
	test_no_circular_cannon_widget_on_ui_layer()
	test_hopper_position_and_battlefield_layering()
	test_combat_manager_extend_timer_and_cannon_pushback()
	test_city_mob_pushback_displacement()

func test_battlefield_view_top_coordinates_and_dimensions() -> void:
	begin("BattlefieldView constants define 1280x110 top banner arena")
	assert_eq(BattlefieldViewScript.BATTLEFIELD_WIDTH, 1280.0, "Battlefield width is 1280.0")
	assert_eq(BattlefieldViewScript.BATTLEFIELD_HEIGHT, 110.0, "Battlefield height is 110.0")
	assert_approx(BattlefieldViewScript.CANNON_MUZZLE_POS.y, 58.0, 0.01, "Cannon muzzle is at Y=58.0")
	assert_approx(BattlefieldViewScript.WALL_IMPACT_POS.y, 58.0, 0.01, "Wall impact is at Y=58.0")
	assert_true(BattlefieldViewScript.CANNON_MUZZLE_POS.x < BattlefieldViewScript.WALL_IMPACT_POS.x, "Cannon is on left, wall on right")

func test_city_mob_visual_theme_selection() -> void:
	begin("CityMobVisual switches sprite textures and scale per city definition")
	var mob: Node2D = CityMobVisualScript.new() as Node2D
	mob._ready()

	mob.call("apply_city_theme", Constants.CITY_INDEX_HALFLING_SHIRE)
	assert_eq(mob.get("current_city_id"), Constants.CITY_INDEX_HALFLING_SHIRE, "City ID set to Halfling Shire")

	mob.call("apply_city_theme", Constants.CITY_INDEX_HUMAN_KINGDOM)
	assert_eq(mob.get("current_city_id"), Constants.CITY_INDEX_HUMAN_KINGDOM, "City ID set to Human Kingdom")

	mob.call("apply_city_theme", Constants.CITY_INDEX_ELF_PALACE)
	assert_eq(mob.get("current_city_id"), Constants.CITY_INDEX_ELF_PALACE, "City ID set to Elf Palace")

	mob.free()

func test_city_mob_visual_timer_progression() -> void:
	begin("CityMobVisual marches from START_X to TARGET_X over timer duration")
	var mob: Node2D = CityMobVisualScript.new() as Node2D
	mob._ready()

	mob.call("set_timer_progress", 120.0, 120.0)
	assert_approx(mob.position.x, CityMobVisualScript.START_X, 0.1, "Starts at START_X when time is full")

	mob.call("set_timer_progress", 60.0, 120.0)
	var expected_mid: float = (CityMobVisualScript.START_X + CityMobVisualScript.TARGET_X) * 0.5
	assert_approx(mob.position.x, expected_mid, 1.0, "Reaches midpoint at 50% timer duration")

	var reached_emitted: Array = [false]
	mob.connect("mob_reached_cannon", func(): reached_emitted[0] = true)

	mob.call("set_timer_progress", 0.0, 120.0)
	assert_approx(mob.position.x, CityMobVisualScript.TARGET_X, 0.1, "Reaches cannon at TARGET_X when time expires")
	assert_true(reached_emitted[0], "mob_reached_cannon signal emitted upon reaching cannon")

	mob.free()

func test_cannon_explosion_trigger() -> void:
	begin("CannonVisual and BattlefieldView trigger explosion and emit signal")
	var bf: Node2D = BattlefieldViewScript.new() as Node2D
	bf._ready()

	var exploded: Array = [false]
	bf.cannon_exploded.connect(func(): exploded[0] = true)

	bf.trigger_cannon_explosion()
	assert_true(exploded[0], "cannon_exploded signal emitted on trigger_cannon_explosion")

	bf.free()

func test_junk_drawer_full_height_without_cannon_widget() -> void:
	begin("JunkBoxPanel has no bottom circular cannon widget and fills sidebar height")
	var scene: PackedScene = load("res://scenes/ui/junk_box/junk_box_panel.tscn") as PackedScene
	assert_true(scene != null, "junk_box_panel.tscn loads")
	var panel: Control = scene.instantiate() as Control
	assert_true(panel != null, "junk_box_panel instantiates")

	var widget: Control = panel.find_child("CircularCannonWidget", true, false) as Control
	assert_true(widget == null, "CircularCannonWidget is removed from JunkBoxPanel")

	var drawer: PanelContainer = panel.get_node_or_null("DrawerPanel") as PanelContainer
	assert_true(drawer != null, "DrawerPanel exists")
	if drawer:
		assert_eq(drawer.custom_minimum_size.y, 610.0, "DrawerPanel height matches 610px sidebar area")

	panel.free()

func test_main_scene_layout_integration() -> void:
	begin("Main scene positions top battlefield and pushes junk drawer down")
	var scene: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	assert_true(scene != null, "main.tscn loads")
	var main: Node = scene.instantiate()
	assert_true(main != null, "main instantiates")

	var bf: Node2D = main.get_node_or_null("CombatContainer/BattlefieldView") as Node2D
	assert_true(bf != null, "BattlefieldView exists in main scene")
	if bf:
		assert_eq(bf.position, Vector2.ZERO, "BattlefieldView positioned at top-left (0, 0)")

	var center_panel: Control = main.get_node_or_null("UILayer/CenterPanel") as Control
	assert_true(center_panel != null, "CenterPanel exists")
	if center_panel:
		assert_eq(center_panel.offset_top, 110.0, "CenterPanel pushed down to Y=110.0")
		assert_eq(center_panel.offset_bottom, 720.0, "CenterPanel extends to bottom of screen at Y=720.0")

	var right_bg: ColorRect = main.get_node_or_null("BackgroundLayer/RightPanelBg") as ColorRect
	assert_true(right_bg != null, "RightPanelBg exists")
	if right_bg:
		assert_eq(right_bg.offset_top, 110.0, "RightPanelBg offset_top starts at 110.0")
		assert_eq(right_bg.offset_bottom, 720.0, "RightPanelBg offset_bottom extends to 720.0")

	main.free()

func test_no_circular_cannon_widget_on_ui_layer() -> void:
	begin("No CircularCannonWidget or extra green-bordered panel exists on UILayer")
	var scene: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	var main: Node = scene.instantiate()
	var ui_layer: Node = main.get_node_or_null("UILayer")
	assert_true(ui_layer != null, "UILayer exists")
	var widget: Node = main.find_child("CircularCannonWidget", true, false)
	assert_true(widget == null, "CircularCannonWidget is null in main scene")
	main.free()

func test_hopper_position_and_battlefield_layering() -> void:
	begin("Hopper position is moved down and BattlefieldView renders on top")
	var scene: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	var main: Node = scene.instantiate()
	var hopper: Node2D = main.get_node_or_null("Hopper") as Node2D
	assert_true(hopper != null, "Hopper exists")
	if hopper:
		assert_approx(hopper.position.y, 150.0, 1.0, "Hopper position Y is 150.0")
	var bf: Node2D = main.get_node_or_null("CombatContainer/BattlefieldView") as Node2D
	assert_true(bf != null, "BattlefieldView exists")
	if bf and hopper:
		assert_gt(bf.z_index, hopper.z_index, "BattlefieldView z_index (20) renders in front of Hopper (10)")
	main.free()

func test_combat_manager_extend_timer_and_cannon_pushback() -> void:
	begin("CombatManager extend_timer adds seconds and cannon firing extends timer")
	var cm_scene: GDScript = load("res://scenes/main/combat_manager.gd") as GDScript
	var cm: Node = cm_scene.new()
	cm._timer_ticks_remaining = 60 * 60 # 60 seconds
	cm._wall_hp = 200
	cm._wall_hp_max = 200
	cm.call("extend_timer", 4.0)
	assert_approx(cm.call("get_timer_seconds_remaining"), 64.0, 0.1, "extend_timer adds 4.0 seconds")

	# Firing cannon adds CANNON_PUSHBACK_SECONDS
	var pre_fire: float = cm.call("get_timer_seconds_remaining")
	cm.call("_on_main_fired", 25)
	var post_fire: float = cm.call("get_timer_seconds_remaining")
	assert_approx(post_fire, pre_fire + cm.get("CANNON_PUSHBACK_SECONDS"), 0.1, "Cannon firing adds CANNON_PUSHBACK_SECONDS")
	cm.free()

func test_city_mob_pushback_displacement() -> void:
	begin("CityMobVisual trigger_pushback displaces position backward towards START_X")
	var mob: Node2D = CityMobVisualScript.new() as Node2D
	mob._ready()
	mob.call("set_timer_progress", 60.0, 120.0)
	var x_before: float = mob.position.x
	mob.call("trigger_pushback", 30.0)
	mob.call("set_timer_progress", 64.0, 120.0)
	assert_gt(mob.position.x, x_before, "Mob position pushed back rightward towards START_X")
	mob.free()
