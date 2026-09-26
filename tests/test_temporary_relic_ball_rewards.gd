extends "res://tests/test_base.gd"

const RelicBallReward = preload("res://resources/polyomino/relic_ball_reward.gd")
const DeliberateRelicCatalog = preload("res://resources/polyomino/deliberate_relic_catalog.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const Ball = preload("res://scenes/balls/ball.gd")
const Board = preload("res://scenes/board/board.gd")
const PolyominoModuleNode = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")

func _init() -> void:
	suite_name = "TemporaryRelicBallRewards"

func test_all_deliberate_rewards_are_authored() -> void:
	begin("All 42 deliberate relics have fixed visible rewards")
	var ids: Array[StringName] = DeliberateRelicCatalog.get_all_ids()
	assert_eq(ids.size(), 42)
	for relic_id: StringName in ids:
		var row: Dictionary = DeliberateRelicCatalog.get_relic(relic_id)
		var tier: int = int(row.get("tier", 1))
		var reward: RelicBallReward = RelicBallReward.for_relic(relic_id, tier)
		assert_true(reward != null, str(relic_id))
		assert_true(reward.is_valid_for_tier(tier), str(relic_id))
		assert_true(reward.get_description().contains(str(reward.count)), str(relic_id))

func test_tier_budget_gates() -> void:
	begin("Reward budgets gate rarity by relic tier")
	var common: RelicBallReward = RelicBallReward.new()
	common.source_id = &"test_common"
	common.ball_type = "Binary"
	common.count = 1
	assert_false(common.is_valid_for_tier(1))
	assert_false(common.is_valid_for_tier(2))
	common.source_id = &"test_tier_three"
	common.minimum_relic_tier = 3
	assert_true(common.is_valid_for_tier(3))
	var high_count: RelicBallReward = RelicBallReward.for_relic(&"cyclone_bounce_vault", 3)
	assert_eq(high_count.ball_type, "Rubbery")
	assert_eq(high_count.count, 10)
	var tier_one: RelicBallReward = RelicBallReward.for_relic(&"bumper_vessel_twin", 1)
	assert_eq(tier_one.count, 1)
	assert_eq(tier_one.ball_type, "Rubbery")

func test_reward_serialization() -> void:
	begin("Reward definitions serialize without losing authored identity")
	var source: RelicBallReward = RelicBallReward.for_relic(&"blood_tithe", 3)
	var restored: RelicBallReward = RelicBallReward.new()
	restored.deserialize(source.serialize())
	assert_eq(restored.source_id, &"blood_tithe")
	assert_eq(restored.ball_type, "Binary")
	assert_eq(restored.count, 1)
	assert_eq(restored.life_ticks, 720)
	assert_eq(restored.spacing_ticks, 6)

func test_temporary_ball_lifecycle_marker() -> void:
	begin("Temporary ball marker supports expiry and one payout")
	var ball: Node = Ball.new()
	autofree(ball)
	ball.mark_temporary_relic_ball(720, &"test_source")
	assert_true(ball.is_temporary_relic_ball())
	assert_eq(ball.get_temporary_relic_expiration_tick(), 720)
	assert_eq(ball.get_temporary_relic_source(), &"test_source")
	assert_true(ball.mark_temporary_relic_collected())
	assert_false(ball.mark_temporary_relic_collected())
	assert_false(ball.is_temporary_relic_ball())

func test_reward_type_migration() -> void:
	begin("Deliberate goals use temporary reward dispatch")
	for relic_id: StringName in DeliberateRelicCatalog.get_all_ids():
		var goal: Dictionary = DeliberateRelicCatalog.get_goal(relic_id)
		assert_eq(int(goal.get("reward", -1)), PolyominoModuleData.RewardType.TEMPORARY_BALLS, str(relic_id))

func test_temporary_population_and_expiry() -> void:
	begin("Temporary population uses its own cap and expires captured balls")
	var board: Node = Board.new()
	autofree(board)
	var container: Node2D = Node2D.new()
	board.add_child(container)
	board._balls_container = container
	board._ball_scene = load("res://scenes/balls/ball.tscn")
	board._temporary_reward_controller = board._temporary_reward_controller if board._temporary_reward_controller != null else preload("res://scenes/board/temporary_relic_ball_controller.gd").new()
	board._temporary_reward_controller.setup(board)
	var reward: RelicBallReward = RelicBallReward.for_relic(&"cyclone_bounce_vault", 3)
	for index: int in range(10):
		var ball: Node = board._temporary_reward_controller._spawn(reward, Vector2.ZERO, Vector2.DOWN, 170.0, 0)
		assert_true(ball != null)
	assert_eq(board._temporary_relic_balls.size(), 10)
	for index: int in range(30):
		var permanent_ball: Node = Ball.new()
		board._active_balls.append(permanent_ball)
		autofree(permanent_ball)
	assert_true(board._temporary_slot_available())
	for index: int in range(14):
		board._temporary_reward_controller._spawn(reward, Vector2.ZERO, Vector2.DOWN, 170.0, 0)
	assert_false(board._temporary_slot_available())
	board._expire_temporary_relic_balls(720)
	assert_eq(board._temporary_relic_balls.size(), 0)

func test_queue_defers_allocation_and_rejects_duplicate_activation() -> void:
	begin("Queued rewards allocate on the next tick and consume one activation key")
	var board: Node = Board.new()
	autofree(board)
	var container: Node2D = Node2D.new()
	board.add_child(container)
	board._balls_container = container
	board._ball_scene = load("res://scenes/balls/ball.tscn")
	var controller: RefCounted = preload("res://scenes/board/temporary_relic_ball_controller.gd").new()
	controller.setup(board)
	board._temporary_reward_controller = controller
	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"bumper_vessel_twin")
	var module: Node = PolyominoModuleNode.new()
	module.setup_module(item, Vector2i.ZERO, 0)
	var triggering_ball: Node2D = Node2D.new()
	var reward: RelicBallReward = RelicBallReward.for_relic(&"bumper_vessel_twin", 1)
	reward.spawn_at_relic = true
	assert_true(controller.queue_reward(module, reward, triggering_ball, 0, 7))
	assert_false(controller.queue_reward(module, reward, triggering_ball, 0, 7))
	controller.process(0)
	assert_eq(controller.get_reserved_count(), 0)
	controller.process(1)
	assert_eq(controller.get_reserved_count(), reward.count - 1)
	assert_eq(controller.get_ball_count(), 1)
	module.free()
	triggering_ball.free()

func test_invalid_source_cancels_full_offer_and_collection_is_once() -> void:
	begin("Invalid sources cancel the full offer and collection is one-time")
	var board: Node = Board.new()
	autofree(board)
	var container: Node2D = Node2D.new()
	board.add_child(container)
	board._balls_container = container
	board._ball_scene = load("res://scenes/balls/ball.tscn")
	var controller: RefCounted = preload("res://scenes/board/temporary_relic_ball_controller.gd").new()
	controller.setup(board)
	var reward: RelicBallReward = RelicBallReward.for_relic(&"bumper_vessel_twin", 1)
	var status: Array = []
	controller.reward_status.connect(func(source_id: StringName, offered: int, emitted: int, canceled: int, blocked: bool) -> void:
		status.append({"offered": offered, "emitted": emitted, "canceled": canceled, "blocked": blocked})
	)
	var invalid_module: Node = PolyominoModuleNode.new()
	invalid_module.setup_module(PolyominoRelicDatabase.create_item_for_relic(&"bumper_vessel_twin"), Vector2i.ZERO, 0)
	var triggering_ball: Node2D = Node2D.new()
	assert_true(controller.queue_reward(invalid_module, reward, triggering_ball, 0, 9))
	invalid_module.queue_free()
	controller.process(1)
	assert_eq(status.size(), 2)
	assert_eq(status[1]["canceled"], reward.count)
	assert_false(status[1]["blocked"])
	var ball: Node = controller._spawn(reward, Vector2.ZERO, Vector2.DOWN, 170.0, 0)
	assert_true(controller.collect_ball(ball))
	assert_false(controller.collect_ball(ball))
	assert_eq(controller.get_ball_count(), 0)
	triggering_ball.free()

func test_blocked_outlet_cancels_after_sixty_ticks() -> void:
	begin("Blocked outlets cancel a reserved reward after sixty ticks")
	var board: Node = Board.new()
	autofree(board)
	var container: Node2D = Node2D.new()
	board.add_child(container)
	board._balls_container = container
	board._ball_scene = load("res://scenes/balls/ball.tscn")
	var controller: RefCounted = preload("res://scenes/board/temporary_relic_ball_controller.gd").new()
	controller.setup(board)
	var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"bumper_vessel_twin")
	var module: Node = PolyominoModuleNode.new()
	module.setup_module(item, Vector2i.ZERO, 0)
	var triggering_ball: Node2D = Node2D.new()
	var reward: RelicBallReward = RelicBallReward.for_relic(&"bumper_vessel_twin", 1)
	reward.spawn_at_relic = true
	var status: Array = []
	controller.reward_status.connect(func(source_id: StringName, offered: int, emitted: int, canceled: int, blocked: bool) -> void:
		status.append({"canceled": canceled, "blocked": blocked})
	)
	assert_true(controller.queue_reward(module, reward, triggering_ball, 0, 10))
	var outlet: Vector2 = controller._queue[0]["port"].position
	var blocker: Node = Ball.new()
	blocker.global_position = outlet
	board._active_balls.append(blocker)
	controller.process(1)
	for tick: int in range(2, 61):
		controller.process(tick)
	assert_eq(controller.get_reserved_count(), 0)
	assert_eq(status[-1]["canceled"], 1)
	assert_true(status[-1]["blocked"])
	blocker.free()
	module.free()
	triggering_ball.free()

func test_temporary_binary_split_conserves_odd_energy_and_lifetime() -> void:
	begin("Temporary Binary splits conserve odd energy and inherit expiry")
	var board: Node = Board.new()
	autofree(board)
	var container: Node2D = Node2D.new()
	board.add_child(container)
	board._balls_container = container
	board._ball_scene = load("res://scenes/balls/ball.tscn")
	var controller: RefCounted = preload("res://scenes/board/temporary_relic_ball_controller.gd").new()
	controller.setup(board)
	board._temporary_reward_controller = controller
	var attacker: RigidBody2D = RigidBody2D.new()
	attacker.set_script(load("res://scenes/balls/ball.gd"))
	attacker.set_definition(TestScenario.make_ball_definition("Binary"))
	attacker.set_ball_id(1)
	var victim: RigidBody2D = RigidBody2D.new()
	victim.set_script(load("res://scenes/balls/ball.gd"))
	victim.set_definition(TestScenario.make_ball_definition("Plain"))
	victim.set_ball_id(2)
	victim.set_total_energy_display(21)
	victim.mark_temporary_relic_ball(500, &"test_binary", 100)
	controller.register_ball(victim)
	var before: int = victim.get_total_energy()
	board._try_binary_split_victim_from_collision(attacker, victim, 200)
	assert_eq(victim.get_total_energy(), before - before / 2)
	assert_eq(board._active_balls.size(), 1)
	var fragment: Node = board._active_balls[0]
	assert_eq(fragment.get_total_energy() + victim.get_total_energy(), before)
	assert_true(fragment.is_temporary_relic_ball())
	assert_eq(fragment.get_temporary_relic_expiration_tick(), 500)
	attacker.free()
	victim.free()

func test_capture_detach_clears_all_supported_owner_collections() -> void:
	begin("Temporary removal clears capture arrays and traveler dictionaries")
	var board: Node = Board.new()
	autofree(board)
	var controller: RefCounted = preload("res://scenes/board/temporary_relic_ball_controller.gd").new()
	controller.setup(board)
	var ball: Node = Ball.new()
	ball.set_ball_id(77)
	var wire_gate: WireGate = preload("res://scenes/board/machinery/wire_gate.gd").new()
	wire_gate.retained_balls.append(ball)
	wire_gate._balls_awaiting_exit.append(ball)
	wire_gate._previous_freeze[ball.get_instance_id()] = true
	var trap: BallTrap = preload("res://scenes/board/machinery/ball_trap.gd").new()
	trap._captured_balls.append(ball)
	var lock: BallLock = preload("res://scenes/board/machinery/ball_lock.gd").new()
	lock.locked_balls.append(ball)
	var flow: Node = preload("res://scenes/board/machinery/flow_track.gd").new()
	flow._travelers[ball.get_instance_id()] = {"ball": ball}
	var guide: GuideTrack = preload("res://scenes/board/machinery/guide_track.gd").new()
	guide._guided_balls[ball.get_ball_id()] = ball
	for owner: Node in [wire_gate, trap, lock, flow, guide]:
		controller._detach_from_component(owner, ball, ball.get_ball_id())
	assert_empty(wire_gate.retained_balls)
	assert_empty(wire_gate._balls_awaiting_exit)
	assert_false(wire_gate._previous_freeze.has(ball.get_instance_id()))
	assert_empty(trap._captured_balls)
	assert_empty(lock.locked_balls)
	assert_false(flow._travelers.has(ball.get_instance_id()))
	assert_false(guide._guided_balls.has(ball.get_ball_id()))
	for owner: Node in [wire_gate, trap, lock, flow, guide]:
		owner.free()
	ball.free()

func run() -> void:
	test_all_deliberate_rewards_are_authored()
	test_tier_budget_gates()
	test_reward_serialization()
	test_temporary_ball_lifecycle_marker()
	test_reward_type_migration()
	test_temporary_population_and_expiry()
	test_queue_defers_allocation_and_rejects_duplicate_activation()
	test_invalid_source_cancels_full_offer_and_collection_is_once()
	test_blocked_outlet_cancels_after_sixty_ticks()
	test_temporary_binary_split_conserves_odd_energy_and_lifetime()
	test_capture_detach_clears_all_supported_owner_collections()
	cleanup()
