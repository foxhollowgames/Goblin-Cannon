extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "TopGoldCounterUI"

func run() -> void:
	test_gold_counter_node_structure_under_wall_health_bar()
	test_gold_label_text_updates_without_prefix()

func test_gold_counter_node_structure_under_wall_health_bar() -> void:
	begin("Gold counter sits in top header bar stat zone with gold icon and number label")
	var main_scene: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	assert_true(main_scene != null, "main scene loaded")
	var main: Node2D = main_scene.instantiate() as Node2D
	assert_true(main != null, "main scene instantiated")

	var left_panel: Control = main.get_node_or_null("UILayer/LeftPanel") as Control
	assert_true(left_panel != null, "LeftPanel exists")

	var top_wall: Control = left_panel.get_node_or_null("TopWallContainer") as Control
	assert_true(top_wall != null, "TopWallContainer exists")

	var health_bar: ProgressBar = top_wall.get_node_or_null("WallHealthBar") as ProgressBar
	assert_true(health_bar != null, "WallHealthBar exists inside TopWallContainer")

	var gold_container: HBoxContainer = left_panel.get_node_or_null("GoldContainer") as HBoxContainer
	assert_true(gold_container != null, "GoldContainer HBoxContainer exists inside LeftPanel top bar stat zone")

	var gold_icon: TextureRect = gold_container.get_node_or_null("GoldIcon") as TextureRect
	assert_true(gold_icon != null, "GoldIcon TextureRect exists inside GoldContainer")
	assert_true(gold_icon.texture != null, "GoldIcon has valid gold coin texture assigned")

	var run_gold: Label = gold_container.get_node_or_null("RunGold") as Label
	assert_true(run_gold != null, "RunGold Label exists inside GoldContainer")

	main.free()

func test_gold_label_text_updates_without_prefix() -> void:
	begin("set_run_gold updates Label text to formatted integer without 'Gold: ' prefix")
	var center_ui_script: Script = load("res://scenes/main/center_panel_ui.gd") as Script
	assert_true(center_ui_script != null, "center_panel_ui script loaded")
	var center_ui: Control = center_ui_script.new() as Control
	
	var label: Label = Label.new()
	label.name = "RunGold"
	center_ui.set("_run_gold_label", label)

	if center_ui.has_method("set_run_gold"):
		center_ui.call("set_run_gold", 42)
		assert_eq(label.text, "42", "Gold label displays pure number '42'")

	label.free()
	center_ui.free()
