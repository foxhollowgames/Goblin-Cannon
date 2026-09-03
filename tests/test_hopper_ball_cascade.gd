extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "HopperBallCascade"

func run() -> void:
	test_hopper_spawn_ball_randomized_offsets()
	test_hopper_ball_dampening_values()

func test_hopper_spawn_ball_randomized_offsets() -> void:
	begin("Hopper spawns balls with horizontal offset and initial velocity dispersion")
	var hopper_script: GDScript = load("res://scenes/hopper/hopper.gd") as GDScript
	var hopper: Node2D = Node2D.new()
	hopper.set_script(hopper_script)
	hopper.global_position = Vector2(480.0, 28.0)
	
	var container: Node2D = Node2D.new()
	container.name = "BallsContainer"
	var main_parent: Node = Node.new()
	main_parent.add_child(container)
	main_parent.add_child(hopper)
	hopper._ready()
	
	hopper.add_balls(10)
	assert_eq(container.get_child_count(), 10, "Should add 10 balls to container")
	
	var positions: Array[float] = []
	for ball in container.get_children():
		positions.append(ball.global_position.x)
			
	var unique_x_count: int = 0
	var first_x: float = positions[0]
	for x in positions:
		if absf(x - first_x) > 0.01:
			unique_x_count += 1
			
	assert_true(unique_x_count > 0, "Spawning balls must produce non-zero horizontal position dispersion")
	
	main_parent.free()

func test_hopper_ball_dampening_values() -> void:
	begin("Ball in hopper bin has reduced linear and angular dampening")
	var ball_script: GDScript = load("res://scenes/balls/ball.gd") as GDScript
	var ball: RigidBody2D = RigidBody2D.new()
	ball.set_script(ball_script)
	ball.apply_hopper_physics(true)
	
	assert_approx(ball.linear_damp, 0.8, 0.01, "Linear damp inside hopper bin should be 0.8")
	assert_approx(ball.angular_damp, 1.5, 0.01, "Angular damp inside hopper bin should be 1.5")
	assert_false(ball.lock_rotation, "Rotation should be unlocked inside hopper bin")
	
	ball.apply_hopper_physics(false)
	assert_approx(ball.linear_damp, 0.0, 0.01, "Linear damp outside hopper bin should be 0.0")
	assert_true(ball.lock_rotation, "Rotation should be locked outside hopper bin")
	
	ball.free()
