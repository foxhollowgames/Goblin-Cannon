extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "KingdomBoardEvents"

func run() -> void:
	test_city_resources_match_progression_indices()
	test_sticky_elf_gates_use_city_index()
	test_sticky_rng_after_city_set_human()
	test_black_hole_rng_after_city_set_elf()
	test_notify_milestone_board_grants_plain_batch_constant()

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

func test_notify_milestone_board_grants_plain_batch_constant() -> void:
	begin("notify_milestone_reward_from_board grants plain batch via add_basic_balls(BASIC_BATCH_SIZE)")
	var gc_script: GDScript = load("res://scenes/main/game_coordinator.gd") as GDScript
	var src: String = gc_script.source_code
	var fn_i: int = src.find("func notify_milestone_reward_from_board")
	assert_gt(fn_i, -1, "notify_milestone_reward_from_board exists")
	var slice: String = src.substr(fn_i, mini(420, src.length() - fn_i))
	assert_true(slice.contains("add_basic_balls(RewardGeneration.BASIC_BATCH_SIZE)"), "board event grants +5 plain before milestone shop")

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
