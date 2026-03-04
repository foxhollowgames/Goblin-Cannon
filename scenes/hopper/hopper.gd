extends Node2D
## Hopper (§6.1). Balls spawn above the frame and fall into the bin with physics.
## Gate opens → gate blocker disabled → balls fall out; we emit ball_entered_board when one exits.

signal ball_requested(count: int)  # optional
signal ball_entered_board(ball: Node)

const MAX_DISPLAY_BALLS: int = 100
## Global Y offset from hopper origin for spawn (above the frame). Balls fall into bin with physics.
const SPAWN_Y_OFFSET: float = -180.0

var _stored_balls: Array[Node] = []
var _next_ball_id: int = 0
var _ball_scene: PackedScene
var _main_balls_container: Node2D  # Main's BallsContainer (physics world)
var _left_arm: Node2D
var _right_arm: Node2D
var _gate_blocker: CollisionShape2D
var _bin_area: Area2D
var _gate_open: bool = false

const ARM_OPEN_ANGLE: float = PI / 2.0  # 90° each way when open
const ARM_ANIM_DURATION: float = 0.5

func _ready() -> void:
	_ball_scene = load("res://scenes/balls/ball.tscn") as PackedScene
	var main: Node = get_parent()
	_main_balls_container = main.get_node_or_null("BallsContainer") as Node2D
	var gate_arms: Node2D = get_node_or_null("GateArms") as Node2D
	if gate_arms:
		_left_arm = gate_arms.get_node_or_null("LeftArm") as Node2D
		_right_arm = gate_arms.get_node_or_null("RightArm") as Node2D
	_gate_blocker = get_node_or_null("BinCollision/GateBlocker") as CollisionShape2D
	_bin_area = get_node_or_null("BinInterior") as Area2D
	if _bin_area:
		_bin_area.body_entered.connect(_on_bin_body_entered)
		_bin_area.body_exited.connect(_on_bin_body_exited)
	scale.x = GameState.hopper_width_scale

func add_balls(count: int) -> void:
	for i in count:
		_add_single_ball(null)

func add_balls_with_definition(count: int, ball_def: Resource) -> void:
	for i in count:
		_add_single_ball(ball_def)

func _add_single_ball(ball_def: Resource) -> void:
	if not _ball_scene or not _main_balls_container:
		return
	_next_ball_id += 1
	var ball: Node = _ball_scene.instantiate()
	if ball.has_method("set_ball_id"):
		ball.set_ball_id(_next_ball_id)
	if ball.has_method("set_definition") and ball_def:
		ball.set_definition(ball_def)
	if "freeze" in ball:
		ball.freeze = false
	ball.global_position = global_position + Vector2(0.0, SPAWN_Y_OFFSET)
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO
	_main_balls_container.add_child(ball)
	# _stored_balls filled by BinInterior body_entered when ball lands in bin

func release_next_ball() -> Node:
	# Balls are released by physics when gate opens; hopper emits ball_entered_board on exit.
	return null

func get_visible_count() -> int:
	return mini(_stored_balls.size(), MAX_DISPLAY_BALLS)

func get_stored_ball_count() -> int:
	return _stored_balls.size()

## Remove and free all balls in the bin; used when resetting the starting ball pool.
func clear_stored_balls() -> void:
	for ball in _stored_balls:
		if is_instance_valid(ball):
			ball.queue_free()
	_stored_balls.clear()

## Re-add a ball that left the board: spawn above the frame so it falls into the hopper with physics.
func return_ball(ball: Node) -> void:
	if not ball or not _main_balls_container:
		return
	var parent: Node = ball.get_parent()
	if parent:
		parent.remove_child(ball)
	if "freeze" in ball:
		ball.freeze = false
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO
	ball.global_position = global_position + Vector2(0.0, SPAWN_Y_OFFSET)
	_main_balls_container.add_child(ball)

func set_gate_open(open: bool) -> void:
	_gate_open = open
	if _gate_blocker:
		_gate_blocker.disabled = open
	if _left_arm and _right_arm:
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		if open:
			tween.tween_property(_left_arm, "rotation", ARM_OPEN_ANGLE, ARM_ANIM_DURATION)
			tween.tween_property(_right_arm, "rotation", -ARM_OPEN_ANGLE, ARM_ANIM_DURATION)
		else:
			tween.tween_property(_left_arm, "rotation", 0.0, ARM_ANIM_DURATION)
			tween.tween_property(_right_arm, "rotation", 0.0, ARM_ANIM_DURATION)

func is_gate_open() -> bool:
	return _gate_open

## Apply width scale from major upgrade (wall break). Called when player picks Wider Hopper.
func set_width_scale(s: float) -> void:
	scale.x = clampf(s, 0.5, 2.0)

func _on_bin_body_entered(body: Node) -> void:
	if not body is RigidBody2D:
		return
	if body.has_method("get_ball_id") and body not in _stored_balls:
		_stored_balls.append(body)
		if body.has_method("apply_hopper_physics"):
			body.apply_hopper_physics(true)

func _on_bin_body_exited(body: Node) -> void:
	if body in _stored_balls:
		_stored_balls.erase(body)
		if body.has_method("apply_hopper_physics"):
			body.apply_hopper_physics(false)
		# Always emit so the coordinator adds the ball to the board; otherwise a ball that bounces out
		# while the gate is closed would be removed from count but never tracked (lost ball).
		ball_entered_board.emit(body)
