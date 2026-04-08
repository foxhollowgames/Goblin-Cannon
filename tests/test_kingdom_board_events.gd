extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "KingdomBoardEvents"

func run() -> void:
	test_city_resources_match_progression_indices()
	test_sticky_elf_gates_use_city_index()
	test_sticky_rng_after_city_set_human()
	test_black_hole_rng_after_city_set_elf()

func _attach_holder() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree")
	var holder := Node.new()
	tree.root.add_child(holder)
	return holder

func test_city_resources_match_progression_indices() -> void:
	begin("CITY_DEFINITION_PATHS indices match human_kingdom and elf_palace ids for board events")
	var h: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[Constants.CITY_INDEX_HUMAN_KINGDOM]) as CityDefinition
	var e: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[Constants.CITY_INDEX_ELF_PALACE]) as CityDefinition
	assert_true(h != null and e != null, "definitions load")
	assert_eq(h.city_id, &"human_kingdom", "human city_id")
	assert_eq(e.city_id, &"elf_palace", "elf city_id")

func test_sticky_elf_gates_use_city_index() -> void:
	begin("StickySlimeController and BlackHoleController gate on GameState.current_city_id (Human=1, Elf=2)")
	GameState.start_run(8003)
	var holder: Node = _attach_holder()
	var sticky := Node2D.new()
	sticky.set_script(load("res://scenes/board/sticky_slime_controller.gd"))
	var bh := Node2D.new()
	bh.set_script(load("res://scenes/board/black_hole_controller.gd"))
	holder.add_child(sticky)
	holder.add_child(bh)
	GameState.current_city_id = Constants.CITY_INDEX_HALFLING_SHIRE
	assert_eq(bool(sticky.call("_is_human_kingdom")), false, "sticky off at Halfling")
	assert_eq(bool(bh.call("_is_elf_palace")), false, "black hole off at Halfling")
	GameState.current_city_id = Constants.CITY_INDEX_HUMAN_KINGDOM
	assert_eq(bool(sticky.call("_is_human_kingdom")), true, "sticky on at Human")
	assert_eq(bool(bh.call("_is_elf_palace")), false, "black hole off at Human")
	GameState.current_city_id = Constants.CITY_INDEX_ELF_PALACE
	assert_eq(bool(sticky.call("_is_human_kingdom")), false, "sticky off at Elf")
	assert_eq(bool(bh.call("_is_elf_palace")), true, "black hole on at Elf")
	holder.queue_free()

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
