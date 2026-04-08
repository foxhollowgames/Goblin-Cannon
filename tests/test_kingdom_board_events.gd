extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "KingdomBoardEvents"

func run() -> void:
	test_sticky_rng_after_city_set_human()
	test_black_hole_rng_after_city_set_elf()

func _attach_holder() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree")
	var holder := Node.new()
	tree.root.add_child(holder)
	return holder

func test_sticky_rng_after_city_set_human() -> void:
	begin("StickySlimeController initializes RNG when city becomes Human after controller _ready")
	GameState.start_run(9001)
	GameState.current_city_id = 0
	var holder: Node = _attach_holder()
	var ctrl := Node2D.new()
	ctrl.set_script(load("res://scenes/board/sticky_slime_controller.gd"))
	holder.add_child(ctrl)
	## GameCoordinator applies TestScenario / progression after board children _ready; simulate that.
	GameState.current_city_id = 1
	GameState.set_run_flow_state(GameState.RunFlowState.FIGHTING)
	ctrl._process(0.05)
	assert_eq(bool(ctrl.get("_rng_ready")), true, "_rng_ready")
	assert_true(ctrl.get("_rng") != null, "_rng non-null")
	holder.queue_free()

func test_black_hole_rng_after_city_set_elf() -> void:
	begin("BlackHoleController initializes RNG when city becomes Elf Palace after controller _ready")
	GameState.start_run(9002)
	GameState.current_city_id = 0
	var holder: Node = _attach_holder()
	var ctrl := Node2D.new()
	ctrl.set_script(load("res://scenes/board/black_hole_controller.gd"))
	holder.add_child(ctrl)
	GameState.current_city_id = 2
	GameState.set_run_flow_state(GameState.RunFlowState.FIGHTING)
	ctrl._process(0.05)
	assert_eq(bool(ctrl.get("_rng_ready")), true, "_rng_ready")
	assert_true(ctrl.get("_rng") != null, "_rng non-null")
	holder.queue_free()
