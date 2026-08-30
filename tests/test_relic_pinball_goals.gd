extends "res://tests/test_base.gd"

const BoardScript = preload("res://scenes/board/board.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoModuleNode = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const PolyominoGoalRewardHandler = preload("res://scenes/board/machinery/polyomino_goal_reward_handler.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")

const GoalArchetype = PolyominoModuleData.GoalArchetype
const RewardType = PolyominoModuleData.RewardType

func _init() -> void:
	suite_name = "RelicPinballGoals"

func run() -> void:
	test_all_database_relics_have_valid_pinball_goals()
	test_target_bank_goal_triggers_on_all_components_hit()
	test_sequential_route_goal_progression()
	test_orbit_flow_loop_counter()
	test_sinkhole_lock_goal_triggers()
	test_jackpot_accumulator_pool_and_payout()
	test_hurry_up_frenzy_timer_and_trigger()
	test_board_goal_completion_rewards()

func _ensure_clean_state() -> void:
	GameState.start_run(12345)
	GameState.applied_wall_break_upgrades.clear()
	GameState.applied_boss_upgrades.clear()

func test_all_database_relics_have_valid_pinball_goals() -> void:
	begin("All database relics have valid pinball goal archetypes and descriptions")
	_ensure_clean_state()

	var all_ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	assert_true(all_ids.size() >= 50, "relic database contains all campaign relics")

	for rid in all_ids:
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(rid)
		assert_true(mod != null, "module creates for %s" % rid)
		assert_true(mod.goal_type != GoalArchetype.NONE, "%s has non-NONE goal_type (%d)" % [rid, mod.goal_type])
		assert_true(mod.reward_type != RewardType.NONE, "%s has non-NONE reward_type (%d)" % [rid, mod.reward_type])
		assert_false(mod.goal_title.is_empty(), "%s has goal_title" % rid)
		assert_false(mod.goal_description.is_empty(), "%s has goal_description" % rid)
		assert_false(mod.reward_description.is_empty(), "%s has reward_description" % rid)

func test_target_bank_goal_triggers_on_all_components_hit() -> void:
	begin("Target Bank goal triggers after all components are hit and resets")
	_ensure_clean_state()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"plain_surge")
	var node: PolyominoModuleNode = PolyominoModuleNode.new()
	node.setup_module(item, Vector2i.ZERO, 0)

	var goal_completed_calls: Array = []
	node.goal_completed.connect(func(mod, g_type, r_type, ball, r_data) -> void:
		goal_completed_calls.append({"mod": mod, "g_type": g_type, "r_type": r_type, "data": r_data})
	)

	var comps: Array = node.get_all_components()
	assert_true(comps.size() >= 2, "plain_surge has at least 2 interactive components")

	var dummy_ball: Node2D = Node2D.new()

	# Hit only first component
	comps[0].trigger_activation(dummy_ball, 1)
	assert_eq(goal_completed_calls.size(), 0, "goal not completed after 1 of 2 components hit")

	# Hit second component
	comps[1].trigger_activation(dummy_ball, 2)
	assert_eq(goal_completed_calls.size(), 1, "goal completed once all components hit")
	assert_eq(goal_completed_calls[0]["g_type"], GoalArchetype.TARGET_BANK, "goal type is TARGET_BANK")

	# Hit first component again -> start second cycle
	comps[0].trigger_activation(dummy_ball, 10)
	assert_eq(goal_completed_calls.size(), 1, "second cycle in progress, not completed yet")

	comps[1].trigger_activation(dummy_ball, 11)
	assert_eq(goal_completed_calls.size(), 2, "second cycle completed successfully")

	dummy_ball.free()
	node.free()

func test_sequential_route_goal_progression() -> void:
	begin("Sequential Route goal advances step by step and completes on final step")
	_ensure_clean_state()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"plain_momentum")
	var node: PolyominoModuleNode = PolyominoModuleNode.new()
	node.setup_module(item, Vector2i.ZERO, 0)

	var goal_completed_calls: Array = []
	node.goal_completed.connect(func(mod, g_type, r_type, ball, r_data) -> void:
		goal_completed_calls.append({"g_type": g_type, "r_type": r_type})
	)

	var comps: Array = node.get_all_components()
	assert_true(comps.size() >= 2, "plain_momentum has 2 components in sequence")

	var dummy_ball: Node2D = Node2D.new()

	# Hit second step first (wrong order)
	comps[1].trigger_activation(dummy_ball, 1)
	assert_eq(goal_completed_calls.size(), 0, "wrong order does not trigger goal")

	# Hit step 0 (first in sequence)
	comps[0].trigger_activation(dummy_ball, 2)
	assert_eq(goal_completed_calls.size(), 0, "step 1 registered")

	# Hit step 1 at tick 10 (after cooldown)
	comps[1].trigger_activation(dummy_ball, 10)
	assert_eq(goal_completed_calls.size(), 1, "sequence completed successfully")
	assert_eq(goal_completed_calls[0]["g_type"], GoalArchetype.SEQUENCE_ROUTE, "goal type is SEQUENCE_ROUTE")

	dummy_ball.free()
	node.free()

func test_orbit_flow_loop_counter() -> void:
	begin("Orbit Flow goal counts loops and completes at threshold")
	_ensure_clean_state()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"hyper_elastic")
	var node: PolyominoModuleNode = PolyominoModuleNode.new()
	node.setup_module(item, Vector2i.ZERO, 0)

	var goal_completed_calls: Array = []
	node.goal_completed.connect(func(mod, g_type, r_type, ball, r_data) -> void:
		goal_completed_calls.append({"g_type": g_type})
	)

	var comps: Array = node.get_all_components()
	var dummy_ball: Node2D = Node2D.new()

	# Hit loop passes
	comps[0].trigger_activation(dummy_ball, 1)
	assert_eq(goal_completed_calls.size(), 0, "orbit 1 recorded")

	comps[1].trigger_activation(dummy_ball, 10)
	assert_eq(goal_completed_calls.size(), 1, "orbit threshold completed goal")
	assert_eq(goal_completed_calls[0]["g_type"], GoalArchetype.ORBIT_FLOW, "goal is ORBIT_FLOW")

	dummy_ball.free()
	node.free()

func test_sinkhole_lock_goal_triggers() -> void:
	begin("Sinkhole Lock goal completes upon entering catch funnel")
	_ensure_clean_state()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"overcharged_drain")
	var node: PolyominoModuleNode = PolyominoModuleNode.new()
	node.setup_module(item, Vector2i.ZERO, 0)

	var goal_completed_calls: Array = []
	node.goal_completed.connect(func(mod, g_type, r_type, ball, r_data) -> void:
		goal_completed_calls.append({"g_type": g_type, "r_type": r_type})
	)

	var comps: Array = node.get_all_components()
	var dummy_ball: Node2D = Node2D.new()

	comps[0].trigger_activation(dummy_ball, 1)
	assert_eq(goal_completed_calls.size(), 1, "sinkhole entry completed goal")
	assert_eq(goal_completed_calls[0]["g_type"], GoalArchetype.SINKHOLE_LOCK, "goal is SINKHOLE_LOCK")

	dummy_ball.free()
	node.free()

func test_jackpot_accumulator_pool_and_payout() -> void:
	begin("Jackpot Accumulator accumulates charge and pays out jackpot on collector hit")
	_ensure_clean_state()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"compressed_charge")
	var node: PolyominoModuleNode = PolyominoModuleNode.new()
	node.setup_module(item, Vector2i.ZERO, 0)

	var goal_completed_calls: Array = []
	node.goal_completed.connect(func(mod, g_type, r_type, ball, r_data) -> void:
		goal_completed_calls.append({"energy": r_data.get("energy", 0)})
	)

	var comps: Array = node.get_all_components()
	var dummy_ball: Node2D = Node2D.new()

	comps[0].trigger_activation(dummy_ball, 1)
	assert_true(goal_completed_calls.size() >= 1, "jackpot collected")
	assert_true(goal_completed_calls[0]["energy"] >= 15, "payout energy is positive")

	dummy_ball.free()
	node.free()

func test_hurry_up_frenzy_timer_and_trigger() -> void:
	begin("Hurry-Up Frenzy starts countdown and completes if hit before expiry")
	_ensure_clean_state()

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"superconductor")
	var node: PolyominoModuleNode = PolyominoModuleNode.new()
	node.setup_module(item, Vector2i.ZERO, 0)

	var goal_completed_calls: Array = []
	node.goal_completed.connect(func(mod, g_type, r_type, ball, r_data) -> void:
		goal_completed_calls.append({"g_type": g_type})
	)

	var comps: Array = node.get_all_components()
	var dummy_ball: Node2D = Node2D.new()

	# Hit 1: activates hurry up frenzy
	comps[0].trigger_activation(dummy_ball, 1)
	assert_eq(goal_completed_calls.size(), 0, "hurry up frenzy armed")

	# Hit 2: completes goal during active window
	comps[1].trigger_activation(dummy_ball, 10)
	assert_eq(goal_completed_calls.size(), 1, "hurry up frenzy completed")
	assert_eq(goal_completed_calls[0]["g_type"], GoalArchetype.HURRY_UP_FRENZY, "goal is HURRY_UP_FRENZY")

	dummy_ball.free()
	node.free()

func test_board_goal_completion_rewards() -> void:
	begin("Board executes goal rewards (Supercharge, Multiball, Global Knock, Concussive)")
	_ensure_clean_state()

	var board := Node2D.new()
	board.set_script(BoardScript)

	var board_relic_signals: Array = []
	board.relic_goal_achieved.connect(func(mod, g_type, r_type, ball, r_data) -> void:
		board_relic_signals.append({"r_type": r_type})
	)

	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"cascade_reactor")
	item.grid_position = Vector2i(2, 2)
	board.place_module(item, Vector2i(2, 2), 0)

	# Trigger board supercharge reward
	board._on_module_goal_completed(null, GoalArchetype.TARGET_BANK, RewardType.BOARD_SUPERCHARGE, null, {"energy": 100})
	assert_eq(board_relic_signals.size(), 1, "supercharge signal received")

	# Trigger multiball cascade reward
	board._on_module_goal_completed(null, GoalArchetype.TARGET_BANK, RewardType.MULTIBALL_CASCADE, null, {"ball_count": 3})
	assert_eq(board_relic_signals.size(), 2, "multiball signal received")

	# Trigger global board knock reward
	board._on_module_goal_completed(null, GoalArchetype.TARGET_BANK, RewardType.GLOBAL_BOARD_KNOCK, null, {})
	assert_eq(board_relic_signals.size(), 3, "global board knock signal received")

	# Trigger concussive overdrive reward
	board._on_module_goal_completed(null, GoalArchetype.TARGET_BANK, RewardType.CONCUSSIVE_OVERDRIVE, null, {"energy": 120})
	assert_eq(board_relic_signals.size(), 4, "concussive overdrive signal received")

	board.free()
