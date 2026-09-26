extends SceneTree

var _failed: int = 0

func _initialize() -> void:
	call_deferred("_run")
	create_timer(15.0).timeout.connect(func() -> void: quit(1))

func _check(value: bool, label: String) -> void:
	if not value:
		_failed += 1
		printerr(label)

func _fixture() -> Dictionary:
	var main: Node2D = Node2D.new()
	var container: Node2D = Node2D.new()
	container.name = "BallsContainer"
	main.add_child(container)
	var hopper: Node2D = load("res://scenes/hopper/hopper.tscn").instantiate()
	hopper.name = "Hopper"
	hopper.position = Vector2(480, 100)
	main.add_child(hopper)
	root.add_child(main)
	var board: Node2D = load("res://scenes/board/board.gd").new()
	board._hopper = hopper
	board._balls_container = container
	board._ball_scene = load("res://scenes/balls/ball.tscn")
	var controller: RefCounted = load("res://scenes/board/temporary_relic_ball_controller.gd").new()
	controller.setup(board)
	board._temporary_reward_controller = controller
	hopper.ball_entered_board.connect(board.spawn_ball_at_start)
	var module: Node2D = load("res://scenes/board/machinery/polyomino_module_node.gd").new()
	var database: GDScript = load("res://resources/polyomino/polyomino_relic_database.gd")
	module.setup_module(database.create_item_for_relic(&"bumper_vessel_twin"), Vector2i.ZERO, 0)
	var reward: Resource = load("res://resources/polyomino/relic_ball_reward.gd").for_relic(&"bumper_vessel_twin", 1)
	_check(controller.queue_reward(module, reward, null, 0, 1), "Reward queues")
	controller.process(1)
	_check(controller.get_ball_count() == 1, "Exactly one reward spawns")
	return {"main": main, "board": board, "hopper": hopper, "module": module, "controller": controller, "ball": container.get_child(0)}

func _run() -> void:
	root.get_node("GameState").start_run(115)
	var f: Dictionary = _fixture()
	for tick: int in range(120):
		await physics_frame
	_check(f.hopper.get_stored_balls().has(f.ball), "Reward settles in closed hopper")
	_check(f.board._active_balls.is_empty(), "Closed hopper does not activate reward")
	_check(f.ball.is_temporary_relic_ball(), "Waiting preserves temporary state")
	f.hopper.set_gate_open(true)
	for tick: int in range(90):
		await physics_frame
	_check(f.board._active_balls.has(f.ball), "Open gate releases reward onto board")
	_check(f.controller.collect_ball(f.ball), "Reward collects once")
	_check(not f.controller.collect_ball(f.ball), "Reward cannot collect twice")
	_check(f.controller.get_ball_count() == 0, "Collection removes temporary ownership")
	f.module.free()
	f.board.free()
	f.main.queue_free()
	await process_frame
	await process_frame
	print("TEMPORARY HOPPER PHYSICS: %d failures" % _failed)
	quit(1 if _failed else 0)
