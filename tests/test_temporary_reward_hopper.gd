extends "res://tests/test_base.gd"
const Board = preload("res://scenes/board/board.gd")
const Hopper = preload("res://scenes/hopper/hopper.gd")
const Controller = preload("res://scenes/board/temporary_relic_ball_controller.gd")
const Reward = preload("res://resources/polyomino/relic_ball_reward.gd")
const Module = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const Database = preload("res://resources/polyomino/polyomino_relic_database.gd")

func _init() -> void:
	suite_name = "TemporaryRewardHopper"

func _fixture() -> Dictionary:
	var main: Node2D = Node2D.new()
	autofree(main)
	var container: Node2D = Node2D.new()
	container.name = "BallsContainer"
	main.add_child(container)
	var hopper: Node2D = Hopper.new()
	hopper.name = "Hopper"
	main.add_child(hopper)
	hopper.position = Vector2(620, 28)
	hopper._ready()
	var board: Node2D = Board.new()
	main.add_child(board)
	board._hopper = hopper
	board._balls_container = container
	board._ball_scene = load("res://scenes/balls/ball.tscn")
	var controller: RefCounted = Controller.new()
	controller.setup(board)
	board._temporary_reward_controller = controller
	var module: Node2D = Module.new()
	main.add_child(module)
	module.setup_module(Database.create_item_for_relic(&"word_bank_pop"), Vector2i.ZERO, 0)
	module.position = Vector2(100, 400)
	return {"board": board, "hopper": hopper, "controller": controller, "module": module, "container": container}


func test_default_hopper() -> void:
	begin("Default rewards follow the hopper and remain temporary")
	var f: Dictionary = _fixture()
	var reward: Resource = Reward.for_relic(&"word_bank_pop", 1)
	assert_false(reward.spawn_at_relic)
	assert_true(reward.get_description().contains("in the hopper"))
	assert_true(f.controller.queue_reward(f.module, reward, null, 0, 1))
	f.controller.process(1)
	f.hopper.position.x = 800
	f.controller.process(7)
	f.controller.process(13)
	assert_eq(f.controller.get_ball_count(), 3)
	assert_eq(f.controller.get_reserved_count(), 0)
	assert_empty(f.board._active_balls)
	assert_eq(f.container.get_child_count(), 3)
	for i: int in range(f.container.get_child_count()):
		var ball: Node = f.container.get_child(i)
		assert_true(ball.is_temporary_relic_ball())
		assert_eq(ball.get_temporary_relic_source(), &"word_bank_pop")
		assert_eq(ball.get_definition().ability_name, "")
		assert_approx(ball.global_position.y, -7.0)
		assert_true(f.hopper._falling_carry_until.has(ball))
		assert_eq(ball.get_temporary_relic_expiration_tick(), 721 + i * 6)
		var expected_x: float = 620.0 if i == 0 else 800.0
		assert_lte(absf(ball.global_position.x - expected_x), 14.0)
	var first: Node = f.container.get_child(0)
	f.board.spawn_ball_at_start(first)
	assert_eq(f.board._active_balls.size(), 1)
	assert_true(f.controller.collect_ball(first))
	assert_false(f.controller.collect_ball(first))
	assert_false(f.hopper._falling_carry_until.has(first))
	assert_eq(f.controller.get_ball_count(), 2)
	f.controller.expire(733)
	assert_eq(f.controller.get_ball_count(), 0)
	assert_true(f.hopper._falling_carry_until.is_empty())


func test_hopper_cleanup() -> void:
	begin("Discard clears every hopper owner")
	var f: Dictionary = _fixture()
	var reward: Resource = Reward.for_relic(&"bumper_vessel_twin", 1)
	assert_true(f.controller.queue_reward(f.module, reward, null, 0, 1))
	f.controller.process(1)
	var ball: Node = f.container.get_child(0)
	f.hopper._stored_balls.append(ball)
	f.hopper._prev_catchment_bodies.append(ball)
	f.hopper._released_balls[ball] = true
	f.hopper._outside_bin_frames[ball] = 1
	f.controller.discard()
	assert_empty(f.hopper._stored_balls)
	assert_empty(f.hopper._prev_catchment_bodies)
	assert_true(f.hopper._falling_carry_until.is_empty())
	assert_true(f.hopper._released_balls.is_empty())
	assert_true(f.hopper._outside_bin_frames.is_empty())
	assert_empty(f.board._active_balls)
	assert_eq(f.controller.get_ball_count(), 0)

func test_location_serialization() -> void:
	begin("Explicit outlet exception survives save and old saves default to hopper")
	var reward: Resource = Reward.for_relic(&"word_bank_pop", 1)
	var restored: Resource = Reward.new()
	restored.deserialize(reward.serialize())
	assert_false(restored.spawn_at_relic)
	reward.spawn_at_relic = true
	restored.deserialize(reward.serialize())
	assert_true(restored.spawn_at_relic)
	assert_true(restored.get_description().contains("device outlet"))
	var old_data: Dictionary = reward.serialize()
	old_data.erase("spawn_at_relic")
	restored.deserialize(old_data)
	assert_false(restored.spawn_at_relic)

func test_explicit_outlet() -> void:
	begin("Explicit outlet rewards spawn at the relic")
	var f: Dictionary = _fixture()
	var reward: Resource = Reward.for_relic(&"word_bank_pop", 1)
	reward.spawn_at_relic = true
	var port: Dictionary = f.controller._port_for(f.module, null)
	assert_true(f.controller.queue_reward(f.module, reward, null, 0, 1))
	f.controller.process(1)
	assert_eq(f.controller.get_ball_count(), 1)
	assert_eq(f.controller.get_reserved_count(), 2)
	var ball: Node = f.container.get_child(0)
	assert_eq(ball.global_position, port.position)
	assert_true(f.board._active_balls.has(ball))
	assert_false(f.hopper._falling_carry_until.has(ball))
	f.controller.discard()

func test_missing_hopper() -> void:
	begin("A missing hopper cancels instead of spawning at the relic")
	var f: Dictionary = _fixture()
	f.board._hopper = null
	var reward: Resource = Reward.for_relic(&"word_bank_pop", 1)
	assert_true(f.controller.queue_reward(f.module, reward, null, 0, 1))
	f.controller.process(1)
	assert_eq(f.container.get_child_count(), 0)
	assert_eq(f.controller.get_reserved_count(), 0)
	assert_eq(f.controller.get_ball_count(), 0)

func run() -> void:
	test_default_hopper()
	test_hopper_cleanup()
	test_location_serialization()
	test_explicit_outlet()
	test_missing_hopper()
	cleanup()

