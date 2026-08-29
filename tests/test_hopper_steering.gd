extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "HopperSteering"

func run() -> void:
	test_hopper_steer_left_right()
	test_hopper_boundary_clamping()
	test_hopper_horizontal_carry()
	test_hopper_manual_steer_input()
	test_game_coordinator_unhandled_keys()

func test_hopper_steer_left_right() -> void:
	begin("Hopper.steer moves position left and right")
	var hopper_script: GDScript = load("res://scenes/hopper/hopper.gd") as GDScript
	var hopper: Node2D = Node2D.new()
	hopper.set_script(hopper_script)
	hopper.global_position = Vector2(480.0, 28.0)
	
	# Steer left for 0.1s
	hopper.steer(-1.0, 0.1)
	var expected_x: float = 480.0 - (hopper.MOVE_SPEED * 0.1)
	assert_approx(hopper.global_position.x, expected_x, 0.01, "Hopper should move left")
	
	# Steer right for 0.2s
	hopper.steer(1.0, 0.2)
	expected_x += (hopper.MOVE_SPEED * 0.2)
	assert_approx(hopper.global_position.x, expected_x, 0.01, "Hopper should move right")
	hopper.free()

func test_hopper_boundary_clamping() -> void:
	begin("Hopper clamps at TRACK_X_MIN and TRACK_X_MAX")
	var hopper_script: GDScript = load("res://scenes/hopper/hopper.gd") as GDScript
	var hopper: Node2D = Node2D.new()
	hopper.set_script(hopper_script)
	hopper.global_position = Vector2(480.0, 28.0)
	
	# Move far left
	hopper.steer(-1.0, 10.0)
	assert_approx(hopper.global_position.x, hopper.TRACK_X_MIN, 0.001, "Hopper should clamp at min track X")
	
	# Move far right
	hopper.steer(1.0, 10.0)
	assert_approx(hopper.global_position.x, hopper.TRACK_X_MAX, 0.001, "Hopper should clamp at max track X")
	hopper.free()

func test_hopper_horizontal_carry() -> void:
	begin("Hopper.steer applies kinematic horizontal carry to stored balls")
	var hopper_script: GDScript = load("res://scenes/hopper/hopper.gd") as GDScript
	var hopper: Node2D = Node2D.new()
	hopper.set_script(hopper_script)
	hopper.global_position = Vector2(480.0, 28.0)
	
	var ball: RigidBody2D = RigidBody2D.new()
	var ball_script: GDScript = load("res://scenes/balls/ball.gd") as GDScript
	ball.set_script(ball_script)
	ball.global_position = Vector2(480.0, 28.0)
	hopper._stored_balls.append(ball)
	
	var start_ball_x: float = ball.global_position.x
	hopper.steer(1.0, 0.1)
	var dx: float = hopper.MOVE_SPEED * 0.1
	assert_approx(ball.global_position.x, start_ball_x + dx, 0.01, "Ball should carry with hopper dx")
	
	ball.free()
	hopper.free()

func test_hopper_manual_steer_input() -> void:
	begin("Hopper._physics_process respects set_steer_input")
	if GameState:
		GameState.start_run(42)
		GameState.set_run_flow_state(GameState.RunFlowState.FIGHTING)
		GameState.paused = false
	var hopper_script: GDScript = load("res://scenes/hopper/hopper.gd") as GDScript
	var hopper: Node2D = Node2D.new()
	hopper.set_script(hopper_script)
	hopper.global_position = Vector2(480.0, 28.0)
	
	hopper.set_steer_input(-1.0)
	hopper._physics_process(0.1)
	var expected_x: float = 480.0 - (hopper.MOVE_SPEED * 0.1)
	assert_approx(hopper.global_position.x, expected_x, 0.01, "Physics process should move hopper left on steer input")
	
	hopper.set_steer_input(0.0)
	hopper.free()

func test_game_coordinator_unhandled_keys() -> void:
	begin("GameCoordinator allows A and D to pass through to hopper")
	var gc_script: GDScript = load("res://scenes/main/game_coordinator.gd") as GDScript
	var gc: Node = Node.new()
	gc.set_script(gc_script)
	
	var debug_overlay: Control = Control.new()
	debug_overlay.visible = false
	gc._debug_overlay = debug_overlay
	
	# Key event for D
	var ev_d: InputEventKey = InputEventKey.new()
	ev_d.pressed = true
	ev_d.keycode = KEY_D
	gc._unhandled_input(ev_d)
	assert_false(debug_overlay.visible, "KEY_D must no longer toggle debug overlay")
	
	# Key event for F3
	var ev_f3: InputEventKey = InputEventKey.new()
	ev_f3.pressed = true
	ev_f3.keycode = KEY_F3
	gc._unhandled_input(ev_f3)
	assert_true(debug_overlay.visible, "KEY_F3 must toggle debug overlay")
	
	debug_overlay.free()
	gc.free()
