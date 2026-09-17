extends SceneTree
## Real Rapier passage tests. Run separately from synchronous unit suites.

var Database: GDScript
var Module: GDScript
const Data = preload("res://resources/polyomino/polyomino_module_data.gd")
var _modules: Array[Node2D] = []
var _balls: Array[RigidBody2D] = []
var _checks: Array[Dictionary] = []
var _failures: int = 0
var _tick: int = 0

class FlowBall extends RigidBody2D:
	var energy: int = 0
	func get_ball_id() -> int: return get_instance_id()
	func add_peg_energy(amount: int) -> void: energy += amount

func _initialize() -> void:
	call_deferred("_run")

func _module(id: StringName, origin: Vector2, steps: int = 0) -> Node2D:
	var node: Node2D = Module.new()
	node.position = origin
	node.setup_module(Database.create_item_for_relic(id), Vector2i.ZERO, steps)
	root.add_child(node)
	_modules.append(node)
	return node

func _ball(origin: Vector2, velocity: Vector2, gravity: float = 1.0) -> RigidBody2D:
	var ball: RigidBody2D = FlowBall.new()
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	ball.add_child(shape)
	ball.position = origin
	ball.gravity_scale = gravity
	ball.linear_damp = 0.0
	ball.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	root.add_child(ball)
	ball.linear_velocity = velocity
	_balls.append(ball)
	return ball

func _run() -> void:
	root.get_node("GameState").start_run(93)
	Database = load("res://resources/polyomino/polyomino_relic_database.gd")
	Module = load("res://scenes/board/machinery/polyomino_module_node.gd")
	_build_lanes()
	_build_chambers()
	_build_tracks()
	_build_orbits()
	_build_track_handoff()
	var partial: Node2D = _module(&"wire_gate_reservoir", Vector2(4500, 200))
	var partial_ball: RigidBody2D = _ball(Vector2(4552, 100), Vector2.DOWN * 150.0)
	var partial_rewards: Array = []
	partial.goal_completed.connect(func(_m, _g, _r, _b, _d): partial_rewards.append(1))
	var full: Node2D = _module(&"wire_gate_cup", Vector2(5000, 200))
	var full_rewards: Array = []
	full.goal_completed.connect(func(_m, _g, _r, _b, _d): full_rewards.append(1))
	_ball(Vector2(5015, 100), Vector2.DOWN * 100.0)
	_ball(Vector2(5037, 65), Vector2.DOWN * 100.0)
	_build_chain()
	for tick: int in range(900):
		_tick = tick
		for node: Node2D in _modules:
			for ball: RigidBody2D in _balls:
				node.check_ball_collision(ball, tick)
		await physics_frame
	_verify_paths()
	await _verify_occupied_removal()
	_check(partial_rewards.is_empty(), "Partial reservoir grants no completion bonus")
	_check(partial_ball.position.y > 400, "Partial reservoir releases its real ball")
	_check(full_rewards.size() == 1, "Full reservoir completes exactly once")
	for node: Node2D in _modules: node.queue_free()
	for ball: RigidBody2D in _balls: ball.queue_free()
	await process_frame
	await process_frame
	print("RELIC FLOW PHYSICS: %d failures" % _failures)
	quit(1 if _failures else 0)

func _build_lanes() -> void:
	for steps: int in range(4):
		var node: Node2D = _module(&"word_bank_gob", Vector2(500 * steps, 200), steps)
		var direction: Vector2 = Data.get_rotated_direction(Vector2.DOWN, steps)
		for port: Dictionary in node.module_data.get_flow_ports(steps):
			if port.kind != "entry": continue
			var mouth: Vector2 = node.position + (port.p1 + port.p2) * 0.5 * Vector2(52, 56)
			var ball: RigidBody2D = _ball(mouth - direction * 40, direction * 450, 0.0)
			_checks.append({"ball": ball, "origin": mouth, "direction": direction, "label": "Rotated lane %d" % steps})

func _build_chambers() -> void:
	var node: Node2D = _module(&"pachinko_bumper_vessel", Vector2(2200, 200))
	for x: int in [0, 26, 52, 78, 104]:
		var ball: RigidBody2D = _ball(node.position + Vector2(x, -70), Vector2(18, 120))
		_checks.append({"ball": ball, "origin": node.position, "direction": Vector2.DOWN, "label": "Bumper chamber drain"})

func _build_tracks() -> void:
	for index: int in range(2):
		var node: Node2D = _module(&"track_u_turn" if index == 0 else &"track_right_angle", Vector2(3000 + index * 500, 200))
		var track: Node2D = node.get_unified_component()
		var ball: RigidBody2D = _ball(track.global_position + track.points[0] - Vector2(0, 40), Vector2.DOWN * 100)
		var rewards: Array = []
		node.goal_completed.connect(func(_m, _g, _r, _b, _d): rewards.append(1))
		_checks.append({"ball": ball, "rewards": rewards, "label": "Complete physical track"})

func _build_chain() -> void:
	var reservoir: Node2D = _module(&"wire_gate_cup", Vector2(5500, 150))
	var spinner: Node2D = _module(&"funneled_spinner_chute", Vector2(5474, 320))
	var chamber: Node2D = _module(&"bumper_vessel_twin", Vector2(5500, 540))
	var hits: Array = []
	spinner.machinery_triggered.connect(func(_c, _b, _e, _i): hits.append(1))
	for offset: float in [-11.0, 11.0]:
		var ball: RigidBody2D = _ball(reservoir.position + Vector2(26 + offset, -65), Vector2.DOWN * 120)
		_checks.append({"ball": ball, "origin": chamber.position, "direction": Vector2.DOWN, "label": "Reservoir-spinner-chamber chain"})
	_checks.append({"hits": hits, "label": "Chain feeds spinner blades"})

func _verify_paths() -> void:
	for check: Dictionary in _checks:
		if check.has("gravity"):
			_check(is_equal_approx(check.ball.gravity_scale, check.gravity), check.label + " restores gravity")
		if check.has("rewards"):
			_check(check.rewards.size() == 1 if check.has("gravity") else check.rewards.size() >= 1, check.label)
		elif check.has("hits"):
			_check(not check.hits.is_empty(), check.label)
		else:
			if (check.ball.position - check.origin).dot(check.direction) <= 180.0:
				print("BLOCKED ", check.label, " position=", check.ball.position, " velocity=", check.ball.linear_velocity)
			_check((check.ball.position - check.origin).dot(check.direction) > 180.0, check.label)
			_check(check.ball.energy > 0, check.label + " interacts with the device")

func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)

func _build_orbits() -> void:
	for side: int in range(2):
		var node: Node2D = _module(&"cyclone_orbit_loop", Vector2(6500 + side * 500, 300))
		var orbit: Node2D = node.get_unified_component()
		var port: Vector2 = orbit.port_a if side == 0 else orbit.port_b
		var normal: Vector2 = orbit.port_a_dir if side == 0 else orbit.port_b_dir
		var ball: RigidBody2D = _ball(orbit.global_position + port + normal * 40, -normal * 160)
		var rewards: Array = []
		node.goal_completed.connect(func(_m, _g, _r, _b, _d): rewards.append(1))
		_checks.append({"ball": ball, "rewards": rewards, "label": "Orbit complete from port %d" % side})

func _verify_occupied_removal() -> void:
	var node: Node2D = _module(&"wire_gate_cup", Vector2(8000, 200))
	var ball: RigidBody2D = _ball(Vector2(8026, 130), Vector2.DOWN * 80)
	for tick: int in range(45):
		node.check_ball_collision(ball, 1000 + tick)
		await physics_frame
	_check(ball.freeze, "Reservoir holds the original physics ball")
	_modules.erase(node)
	node.queue_free()
	await physics_frame
	await physics_frame
	_check(not ball.freeze, "Removing an occupied reservoir unfreezes its ball")
	_check(ball.linear_velocity.y > 0, "Removing an occupied reservoir releases toward its outlet")

func _build_track_handoff() -> void:
	var first: Node2D = _module(&"track_stairs_step", Vector2(9000, 200))
	var second: Node2D = _module(&"track_right_angle", Vector2(9052, 368))
	var track: Node2D = first.get_unified_component()
	var ball: RigidBody2D = _ball(track.global_position + track.points[0] - Vector2(0, 40), Vector2.DOWN * 120)
	for node: Node2D in [first, second]:
		var rewards: Array = []
		node.goal_completed.connect(func(_m, _g, _r, _b, _d): rewards.append(1))
		_checks.append({"ball": ball, "rewards": rewards, "gravity": 1.0, "label": "Adjacent track handoff"})
