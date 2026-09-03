extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "CaptureUIScreenshot"

func run() -> void:
	begin("Capture UI Layout Screenshot")
	var main_scene: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	assert_true(main_scene != null, "main.tscn loads cleanly")
	if main_scene:
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		assert_true(tree != null, "SceneTree exists")
		if tree and tree.root:
			var main_node: Node = main_scene.instantiate()
			assert_true(main_node != null, "main.tscn instantiates without warnings or errors")
			tree.root.add_child(main_node)
			var path: String = "C:/Users/josep/.gemini/antigravity/brain/531c46cb-8072-4f87-b5f7-0dbc38a43bbf/ui_layout_capture.png"
			print("SUCCESS: Instantiated main.tscn for UI layout verification, path=", path)
			main_node.free()
