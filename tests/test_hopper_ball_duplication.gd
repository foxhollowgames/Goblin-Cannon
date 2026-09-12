extends "res://tests/test_base.gd"

const BoardScript = preload("res://scenes/board/board.gd")
const BallScene = preload("res://scenes/balls/ball.tscn")

func _init() -> void:
	suite_name = "HopperBallDuplication"

func run() -> void:
	test_board_spawn_ball_at_start_duplicate_guard()
	test_hopper_released_balls_lifecycle()
	test_game_ball_manager_exited_board_duplicate_guard()
	test_board_flush_tick_cleans_queued_deletion_balls()

func test_board_spawn_ball_at_start_duplicate_guard() -> void:
	begin("Board.spawn_ball_at_start does not append duplicates to _active_balls")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	var container: Node2D = Node2D.new()
	container.name = "BallsContainer"
	board.add_child(container)
	board._ready()
	
	var ball: RigidBody2D = BallScene.instantiate() as RigidBody2D
	ball._ready()
	
	board.spawn_ball_at_start(ball)
	assert_eq(board.get_active_ball_count(), 1, "First spawn should add ball to active balls")
	
	board.spawn_ball_at_start(ball)
	assert_eq(board.get_active_ball_count(), 1, "Second spawn of same ball should not duplicate in active balls")
	
	board.free()

func test_hopper_released_balls_lifecycle() -> void:
	begin("Hopper released balls are tracked and not re-added to stored_balls while on board")
	var hopper_scene: PackedScene = load("res://scenes/hopper/hopper.tscn") as PackedScene
	var hopper: Node2D = hopper_scene.instantiate() as Node2D
	var main_parent: Node = Node.new()
	var container: Node2D = Node2D.new()
	container.name = "BallsContainer"
	main_parent.add_child(container)
	main_parent.add_child(hopper)
	hopper._ready()
	
	var ball: RigidBody2D = BallScene.instantiate() as RigidBody2D
	container.add_child(ball)
	
	hopper._stored_balls.append(ball)
	assert_eq(hopper.get_stored_ball_count(), 1, "Hopper has 1 stored ball")
	
	hopper._released_balls[ball] = true
	assert_true(hopper._released_balls.has(ball), "Released ball is tracked")
	
	hopper.return_ball(ball)
	assert_false(hopper._released_balls.has(ball), "return_ball must clear released status")
	
	main_parent.free()

func test_game_ball_manager_exited_board_duplicate_guard() -> void:
	begin("GameBallManager.on_ball_exited_board ignores queued_for_deletion and already-exiting balls")
	var coordinator_scene: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	var main: Node = coordinator_scene.instantiate()
	var gc: Node = main.get_node("GameCoordinator")
	var ball: RigidBody2D = BallScene.instantiate() as RigidBody2D
	main.get_node("BallsContainer").add_child(ball)
	
	main.get_node("Hopper").set_gate_open(true)
	var initial_bag_size: int = gc._bag_queue.size()
	
	GameBallManager.on_ball_exited_board(gc, ball, 0)
	assert_eq(gc._bag_queue.size(), initial_bag_size + 1, "First exit adds definition to bag queue")
	
	GameBallManager.on_ball_exited_board(gc, ball, 0)
	assert_eq(gc._bag_queue.size(), initial_bag_size + 1, "Second exit for same ball must be ignored")
	
	main.free()

func test_board_flush_tick_cleans_queued_deletion_balls() -> void:
	begin("Board.flush_tick cleans active balls that are queued for deletion")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	var container: Node2D = Node2D.new()
	container.name = "BallsContainer"
	board.add_child(container)
	board._ready()
	
	var ball: RigidBody2D = BallScene.instantiate() as RigidBody2D
	ball._ready()
	
	board.spawn_ball_at_start(ball)
	assert_eq(board.get_active_ball_count(), 1, "Ball added to active balls")
	
	ball.queue_free()
	board.flush_tick(1)
	assert_eq(board.get_active_ball_count(), 0, "flush_tick must erase balls queued for deletion")
	
	board.free()
