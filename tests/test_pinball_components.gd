extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const CellType = PolyominoModuleData.CellType

const StandupTargetScript = preload("res://scenes/board/machinery/standup_target.gd")
const SpinnerScript = preload("res://scenes/board/machinery/spinner.gd")
const OrbitLoopScript = preload("res://scenes/board/machinery/orbit_loop.gd")
const CaptiveBallScript = preload("res://scenes/board/machinery/captive_ball.gd")
const BashToyScript = preload("res://scenes/board/machinery/bash_toy.gd")
const PolyominoModuleNodeScript = preload("res://scenes/board/machinery/polyomino_module_node.gd")

class MockBall extends Node2D:
	var peg_energy: int = 0
	var linear_velocity: Vector2 = Vector2.ZERO
	func add_peg_energy(amount: int) -> void:
		peg_energy += amount
	func get_ball_id() -> int:
		return 101

func _init() -> void:
	suite_name = "PinballComponents"

func run() -> void:
	test_component_instantiation()
	test_standup_target_activation()
	test_spinner_activation()
	test_orbit_loop_activation()
	test_captive_ball_activation()
	test_bash_toy_progression_and_breaking()
	test_spring_and_spark_process_decay()
	test_cooldown_suppression()
	test_polyomino_module_node_factory()
	cleanup()

func test_component_instantiation() -> void:
	begin("component_instantiation")
	var standup: Node2D = StandupTargetScript.new() as Node2D
	autofree(standup)
	assert_not_null_val(standup, "StandupTarget instantiated")
	assert_false(standup.get("is_permeable"), "StandupTarget is solid / non-permeable")

	var spinner: Node2D = SpinnerScript.new() as Node2D
	autofree(spinner)
	assert_not_null_val(spinner, "Spinner instantiated")
	assert_true(spinner.get("is_permeable"), "Spinner is permeable / pass-through")

	var orbit: Node2D = OrbitLoopScript.new() as Node2D
	autofree(orbit)
	assert_not_null_val(orbit, "OrbitLoop instantiated")
	assert_true(orbit.get("is_permeable"), "OrbitLoop is permeable")

	var captive: Node2D = CaptiveBallScript.new() as Node2D
	autofree(captive)
	assert_not_null_val(captive, "CaptiveBall instantiated")
	assert_false(captive.get("is_permeable"), "CaptiveBall is solid")

	var bash: Node2D = BashToyScript.new() as Node2D
	autofree(bash)
	assert_not_null_val(bash, "BashToy instantiated")
	assert_false(bash.get("is_permeable"), "BashToy is solid")

func test_standup_target_activation() -> void:
	begin("standup_target_activation")
	var target: Node2D = StandupTargetScript.new() as Node2D
	autofree(target)
	var hit_emitted: Array = [false]
	target.connect("target_hit", func(_n: Node, _b: Node): hit_emitted[0] = true)

	var dummy_ball: MockBall = MockBall.new()
	autofree(dummy_ball)
	dummy_ball.position = Vector2(0, -10)

	var res: Dictionary = target.trigger_activation(dummy_ball, 1)
	assert_true(res.get("activated", false), "Standup target activated")
	assert_true(hit_emitted[0], "target_hit signal emitted")
	assert_eq(target.get("hit_count"), 1, "hit_count incremented to 1")
	assert_gt(dummy_ball.peg_energy, 0, "Ball received energy from standup target")

func test_spinner_activation() -> void:
	begin("spinner_activation")
	var spinner: Node2D = SpinnerScript.new() as Node2D
	autofree(spinner)
	var spun_emitted: Array = [false]
	spinner.connect("spinner_spun", func(_n: Node, _c: int): spun_emitted[0] = true)

	var dummy_ball: MockBall = MockBall.new()
	autofree(dummy_ball)

	var res: Dictionary = spinner.trigger_activation(dummy_ball, 1)
	assert_true(res.get("activated", false), "Spinner activated")
	assert_true(spun_emitted[0], "spinner_spun signal emitted")
	assert_gt(spinner.get("spin_velocity"), 0.0, "spin_velocity accelerated")
	assert_eq(spinner.get("total_spins"), 1, "total_spins incremented to 1")

func test_orbit_loop_activation() -> void:
	begin("orbit_loop_activation")
	var orbit: Node2D = OrbitLoopScript.new() as Node2D
	autofree(orbit)
	orbit.direction = Vector2.RIGHT
	var traversed: Array = [false]
	orbit.connect("orbit_traversed", func(_n: Node, _b: Node): traversed[0] = true)

	var dummy_ball: MockBall = MockBall.new()
	autofree(dummy_ball)

	var res: Dictionary = orbit.trigger_activation(dummy_ball, 1)
	assert_true(res.get("activated", false), "OrbitLoop activated")
	assert_true(traversed[0], "orbit_traversed signal emitted")
	var impulse: Vector2 = res.get("impulse_applied", Vector2.ZERO)
	assert_gt(impulse.x, 0.0, "Impulse directed along orbit direction (positive X)")

func test_captive_ball_activation() -> void:
	begin("captive_ball_activation")
	var captive: Node2D = CaptiveBallScript.new() as Node2D
	autofree(captive)
	var struck: Array = [false]
	captive.connect("captive_ball_struck", func(_n: Node, _b: Node): struck[0] = true)

	var dummy_ball: MockBall = MockBall.new()
	autofree(dummy_ball)

	var res: Dictionary = captive.trigger_activation(dummy_ball, 1)
	assert_true(res.get("activated", false), "CaptiveBall activated")
	assert_true(struck[0], "captive_ball_struck signal emitted")
	assert_gt(captive.get("displacement"), 0.0, "displacement excited on strike")
	assert_eq(captive.get("strike_count"), 1, "strike_count incremented to 1")

func test_bash_toy_progression_and_breaking() -> void:
	begin("bash_toy_progression_and_breaking")
	var bash: Node2D = BashToyScript.new() as Node2D
	autofree(bash)
	bash.set("max_hits", 3)
	var broken_emitted: Array = [false]
	var signal_energy_emitted: Array = [0]
	bash.connect("bash_toy_broken", func(_n: Node): broken_emitted[0] = true)
	bash.connect("component_activated", func(_c: Node, _b: Node, energy: int, _imp: Vector2): signal_energy_emitted[0] = energy)

	var dummy_ball: MockBall = MockBall.new()
	autofree(dummy_ball)

	# Hit 1 (normal hit)
	bash.trigger_activation(dummy_ball, 1)
	assert_eq(bash.get("current_hits"), 1, "Hit 1 accumulated")
	assert_eq(dummy_ball.peg_energy, 12, "Normal hit awarded base energy 12 to ball")

	# Hit 2 (normal hit)
	bash.trigger_activation(dummy_ball, 10)
	assert_eq(bash.get("current_hits"), 2, "Hit 2 accumulated")
	assert_false(bash.get("is_broken"), "Bash toy not broken yet")
	assert_eq(dummy_ball.peg_energy, 24, "Two hits awarded 24 total energy to ball")

	# Hit 3 (breaking hit)
	var res: Dictionary = bash.trigger_activation(dummy_ball, 20)
	assert_eq(bash.get("current_hits"), 3, "Hits reached max 3")
	assert_true(bash.get("is_broken"), "Bash toy is broken")
	assert_true(broken_emitted[0], "bash_toy_broken signal emitted")
	assert_eq(res.get("energy_granted", 0), 37, "Breaking hit returned 37 energy (12 + 25 bonus)")
	assert_eq(signal_energy_emitted[0], 37, "component_activated reported 37 energy")
	assert_eq(dummy_ball.peg_energy, 61, "Ball received full bonus energy (24 + 37 = 61)")

func test_spring_and_spark_process_decay() -> void:
	begin("spring_and_spark_process_decay")
	var bash: Node2D = BashToyScript.new() as Node2D
	autofree(bash)
	var dummy_ball: MockBall = MockBall.new()
	autofree(dummy_ball)

	bash.trigger_activation(dummy_ball, 1)
	assert_neq(bash.get("_spring_scale"), Vector2.ONE, "Spring scale excited on impact")
	assert_lt(bash.get("_spark_progress"), 1.0, "Spark progress started on impact")

	# Process decay over several frames
	bash._process(0.5)
	assert_approx(bash.get("_spark_progress"), 1.0, 0.05, "Spark progress decayed back to 1.0 via super._process")
	assert_approx(bash.get("_spring_scale").x, 1.0, 0.05, "Spring scale X returned to 1.0")
	assert_approx(bash.get("_spring_scale").y, 1.0, 0.05, "Spring scale Y returned to 1.0")

func test_cooldown_suppression() -> void:
	begin("cooldown_suppression")
	var target: Node2D = StandupTargetScript.new() as Node2D
	autofree(target)
	var dummy_ball: MockBall = MockBall.new()
	autofree(dummy_ball)

	var res1: Dictionary = target.trigger_activation(dummy_ball, 10)
	assert_true(res1.get("activated", false), "First activation accepted")

	# Immediate re-activation on same tick is suppressed by cooldown
	var res2: Dictionary = target.trigger_activation(dummy_ball, 10)
	assert_false(res2.get("activated", true), "Immediate re-activation suppressed by cooldown")

func test_polyomino_module_node_factory() -> void:
	begin("polyomino_module_node_factory")
	var node: PolyominoModuleNode = PolyominoModuleNodeScript.new() as PolyominoModuleNode
	autofree(node)

	var standup = node._create_component_for_type(CellType.STANDUP_TARGET)
	autofree(standup)
	assert_not_null_val(standup, "Factory produces standup target")
	assert_true(is_instance_of(standup, StandupTargetScript), "Standup target matches StandupTargetScript")

	var spinner = node._create_component_for_type(CellType.SPINNER)
	autofree(spinner)
	assert_not_null_val(spinner, "Factory produces spinner")
	assert_true(is_instance_of(spinner, SpinnerScript), "Spinner matches SpinnerScript")

	var orbit = node._create_component_for_type(CellType.ORBIT_LOOP)
	autofree(orbit)
	assert_not_null_val(orbit, "Factory produces orbit loop")
	assert_true(is_instance_of(orbit, OrbitLoopScript), "Orbit loop matches OrbitLoopScript")

	var captive = node._create_component_for_type(CellType.CAPTIVE_BALL)
	autofree(captive)
	assert_not_null_val(captive, "Factory produces captive ball")
	assert_true(is_instance_of(captive, CaptiveBallScript), "Captive ball matches CaptiveBallScript")

	var bash = node._create_component_for_type(CellType.BASH_TOY)
	autofree(bash)
	assert_not_null_val(bash, "Factory produces bash toy")
	assert_true(is_instance_of(bash, BashToyScript), "Bash toy matches BashToyScript")

func assert_not_null_val(val: Variant, msg: String) -> void:
	if val != null:
		passed += 1
	else:
		failed += 1
		errors.append("%s: value was null" % msg)
