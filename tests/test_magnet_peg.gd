extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "MagnetPeg"

func run() -> void:
	test_rigidbody_has_linear_velocity_property_for_in_operator()
	test_magnet_applies_impulse_to_active_ball()
	test_magnet_no_pull_while_peg_in_recovery()
	test_gravity_well_no_drag_while_peg_in_recovery()

func test_rigidbody_has_linear_velocity_property_for_in_operator() -> void:
	begin("RigidBody2D: 'linear_velocity' in body for Board magnet guard")
	var b := RigidBody2D.new()
	assert_true("linear_velocity" in b, "in operator must see linear_velocity or magnet skips all balls")
	assert_true("global_position" in b, "in operator must see global_position")

func test_magnet_applies_impulse_to_active_ball() -> void:
	begin("Board._apply_magnet_and_gravity_well_forces pulls ball toward magnet peg")
	if GameState:
		GameState.start_run(42)
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var board := Node2D.new()
	board.set_script(board_script)
	# Skip _ready layout: only need _peg_by_id and _active_balls behavior
	var peg_script: GDScript = load("res://scenes/board/peg.gd") as GDScript
	var peg := StaticBody2D.new()
	peg.set_script(peg_script)
	peg.peg_id = 0
	peg.peg_extra_kind = "magnet"
	peg.global_position = Vector2(400, 300)
	board._peg_by_id[0] = peg
	var ball_script: GDScript = load("res://scenes/balls/ball.gd") as GDScript
	var ball := RigidBody2D.new()
	ball.set_script(ball_script)
	ball.mass = 1.0
	# Within MAGNET_PEG_RADIUS_PX, not overlapping peg center (dist > 5)
	ball.global_position = Vector2(300, 300)
	ball.linear_velocity = Vector2(50, 0)
	var active: Array[Node] = []
	active.append(ball)
	board._active_balls = active
	var v_before: Vector2 = ball.linear_velocity
	board._apply_magnet_and_gravity_well_forces()
	assert_gt(ball.linear_velocity.distance_to(v_before), 0.01, "velocity should change toward magnet")

func test_magnet_no_pull_while_peg_in_recovery() -> void:
	begin("magnet does not pull while peg is recovering")
	if GameState:
		GameState.start_run(42)
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var board := Node2D.new()
	board.set_script(board_script)
	var peg_script: GDScript = load("res://scenes/board/peg.gd") as GDScript
	var peg := StaticBody2D.new()
	peg.set_script(peg_script)
	peg.peg_id = 0
	peg.peg_extra_kind = "magnet"
	peg._recovery_ticks_remaining = 200
	peg.global_position = Vector2(400, 300)
	board._peg_by_id[0] = peg
	var ball_script: GDScript = load("res://scenes/balls/ball.gd") as GDScript
	var ball := RigidBody2D.new()
	ball.set_script(ball_script)
	ball.mass = 1.0
	ball.global_position = Vector2(300, 300)
	ball.linear_velocity = Vector2(10, 0)
	var active: Array[Node] = []
	active.append(ball)
	board._active_balls = active
	var v_before: Vector2 = ball.linear_velocity
	board._apply_magnet_and_gravity_well_forces()
	assert_approx(ball.linear_velocity.x, v_before.x, 0.0001)
	assert_approx(ball.linear_velocity.y, v_before.y, 0.0001)

func test_gravity_well_no_drag_while_peg_in_recovery() -> void:
	begin("gravity well does not slow balls while peg is recovering")
	if GameState:
		GameState.start_run(42)
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var board := Node2D.new()
	board.set_script(board_script)
	var peg_script: GDScript = load("res://scenes/board/peg.gd") as GDScript
	var peg := StaticBody2D.new()
	peg.set_script(peg_script)
	peg.peg_id = 0
	peg.peg_extra_kind = "gravity_well"
	peg._recovery_ticks_remaining = 200
	peg.global_position = Vector2(400, 300)
	board._peg_by_id[0] = peg
	var ball := RigidBody2D.new()
	ball.global_position = Vector2(400, 200)
	ball.linear_velocity = Vector2(100, 50)
	var active: Array[Node] = []
	active.append(ball)
	board._active_balls = active
	var v_before: Vector2 = ball.linear_velocity
	board._apply_magnet_and_gravity_well_forces()
	assert_approx(ball.linear_velocity.x, v_before.x, 0.0001)
	assert_approx(ball.linear_velocity.y, v_before.y, 0.0001)
