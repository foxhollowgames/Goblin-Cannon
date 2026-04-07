extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "BinaryBall"

func run() -> void:
	test_binary_split_skips_split_twin_attacker()

func test_binary_split_skips_split_twin_attacker() -> void:
	begin("Binary ball–ball split does not run when attacker is a split fragment")
	if GameState:
		GameState.start_run(202)
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var board := Node2D.new()
	board.set_script(board_script)
	var ball_script: GDScript = load("res://scenes/balls/ball.gd") as GDScript
	var victim_def := TestScenario.make_ball_definition("Energize")
	var attacker := RigidBody2D.new()
	attacker.set_script(ball_script)
	attacker.set_definition(TestScenario.make_ball_definition("Binary"))
	attacker.set_ball_id(1)
	if attacker.has_method("mark_as_split_twin"):
		attacker.mark_as_split_twin()
	var victim := RigidBody2D.new()
	victim.set_script(ball_script)
	victim.set_definition(victim_def)
	victim.set_ball_id(2)
	var e0: int = victim.get_total_energy()
	board._try_binary_split_victim_from_collision(attacker, victim, 500)
	assert_eq(victim.get_total_energy(), e0, "victim energy unchanged when attacker is split twin")
