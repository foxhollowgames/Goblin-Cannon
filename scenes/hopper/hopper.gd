extends Node2D
## Hopper (§6.1). Balls spawn above the frame and fall into the bin with physics.
## Gate opens → gate blocker disabled → balls fall out; we emit ball_entered_board when one leaves the bin.
## Horizontal motion: balls are moved by the same dx as the hopper each physics tick (kinematic carry) so the
## solver does not fight velocity overrides. Catchment is larger than the bin so falling balls track the mouse.

signal ball_requested(count: int)  # optional
signal ball_entered_board(ball: Node)

const MAX_DISPLAY_BALLS: int = 100
## Global Y offset from hopper origin for spawn (above the frame). Balls fall into bin with physics.
const SPAWN_Y_OFFSET: float = -35.0
## Require this many consecutive physics frames outside the strict bin before dropping (gate closed only).
## Stops Area2D boundary flicker from ejecting balls from the stored list.
const BIN_EXIT_HYSTERESIS_FRAMES: int = 4
## Physics frames to keep new / returned balls in the horizontal carry set (until catchment overlap picks them up).
const FALLING_CARRY_FRAMES: int = 180

var _hopper_physics_frame: int = 0
var _stored_balls: Array[Node] = []
var _next_ball_id: int = 0
var _ball_scene: PackedScene
var _main_balls_container: Node2D  # Main's BallsContainer (physics world)
var _left_arm: Node2D
var _right_arm: Node2D
var _gate_blocker: CollisionShape2D
var _bin_area: Area2D
var _catchment_area: Area2D
var _gate_open: bool = false
var _width_pulse_tween: Tween
## Bodies that overlapped HopperCatchment last physics frame (used to build carry set before overlap updates).
var _prev_catchment_bodies: Array = []
## ball -> expiry physics frame; ensures spawn/return streams track hopper before catchment registers overlap.
var _falling_carry_until: Dictionary = {}
## ball -> consecutive frames outside strict bin (gate closed only)
var _outside_bin_frames: Dictionary = {}
var _manual_steer_dir: float = 0.0

const ARM_OPEN_ANGLE: float = PI / 2.0  # 90° each way when open
const ARM_ANIM_DURATION: float = 0.5
## Slide along top track; match goblin grab / board play area.
const TRACK_X_MIN: float = 60.0
const TRACK_X_MAX: float = 900.0
## Horizontal keyboard movement speed in pixels per second.
const MOVE_SPEED: float = 162.5

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
	_catchment_area = get_node_or_null("HopperCatchment") as Area2D
	scale.x = GameState.hopper_width_scale

func _physics_process(delta: float) -> void:
	if GameState and GameState.paused:
		return
	if GameState and GameState.run_flow_state != GameState.RunFlowState.FIGHTING:
		return
	_hopper_physics_frame += 1
	var prev_x: float = global_position.x
	
	var steer_dir: float = _manual_steer_dir
	if is_zero_approx(steer_dir):
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			steer_dir -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			steer_dir += 1.0
	
	if not is_zero_approx(steer_dir):
		global_position.x = clampf(global_position.x + steer_dir * MOVE_SPEED * delta, TRACK_X_MIN, TRACK_X_MAX)
	
	var dx: float = global_position.x - prev_x
	_apply_horizontal_carry(dx)
	_sync_bin_membership()
	_refresh_catchment_cache()

## Steer the hopper horizontally by a direction (-1.0 to 1.0) and time delta.
func steer(direction: float, delta: float) -> void:
	var prev_x: float = global_position.x
	global_position.x = clampf(global_position.x + direction * MOVE_SPEED * delta, TRACK_X_MIN, TRACK_X_MAX)
	var dx: float = global_position.x - prev_x
	_apply_horizontal_carry(dx)

## Sets the manual steer direction override (-1.0 to 1.0). Set to 0.0 to restore keyboard input.
func set_steer_input(dir: float) -> void:
	_manual_steer_dir = clampf(dir, -1.0, 1.0)

func _is_carryable_ball(body: Node) -> bool:
	if not body is RigidBody2D:
		return false
	if not body.has_method("get_ball_id"):
		return false
	if body.has_method("is_split_twin") and body.is_split_twin():
		return false
	return true

func _apply_horizontal_carry(dx: float) -> void:
	if absf(dx) < 0.0001:
		return
	var to_carry: Dictionary = {}
	for b in _stored_balls:
		if is_instance_valid(b):
			to_carry[b] = true
	for b in _prev_catchment_bodies:
		if is_instance_valid(b) and _is_carryable_ball(b):
			to_carry[b] = true
	for b in _falling_carry_until.keys():
		if not is_instance_valid(b):
			_falling_carry_until.erase(b)
			continue
		var until: int = int(_falling_carry_until[b])
		if _hopper_physics_frame <= until:
			to_carry[b] = true
		else:
			_falling_carry_until.erase(b)
	for b in to_carry:
		if b is RigidBody2D:
			(b as RigidBody2D).global_position.x += dx

func _refresh_catchment_cache() -> void:
	_prev_catchment_bodies.clear()
	if not _catchment_area:
		return
	for body in _catchment_area.get_overlapping_bodies():
		if _is_carryable_ball(body):
			_prev_catchment_bodies.append(body)

func _register_falling_carry(ball: Node) -> void:
	if not ball or not is_instance_valid(ball):
		return
	_falling_carry_until[ball] = _hopper_physics_frame + FALLING_CARRY_FRAMES

func _sync_bin_membership() -> void:
	if not _bin_area:
		return
	var strict_in_bin: Dictionary = {}
	for body in _bin_area.get_overlapping_bodies():
		if not _is_carryable_ball(body):
			continue
		strict_in_bin[body] = true
	# BinInterior is a tight rect; sloped side walls extend above it. Balls that bounce on those walls
	# can sit outside the rect while still inside the hopper — treat catchment overlap as "in bin" for
	# balls already stored so they are not return_ball'd to the spawn.
	var was_in: Dictionary = {}
	for b in _stored_balls:
		was_in[b] = true
	if _catchment_area:
		for body in _catchment_area.get_overlapping_bodies():
			if not _is_carryable_ball(body):
				continue
			if was_in.has(body):
				strict_in_bin[body] = true
	for body in strict_in_bin:
		if not was_in.has(body):
			_stored_balls.append(body)
			if body.has_method("apply_hopper_physics"):
				body.apply_hopper_physics(true)
			_outside_bin_frames.erase(body)
			_falling_carry_until.erase(body)
	for i in range(_stored_balls.size() - 1, -1, -1):
		var body: Node = _stored_balls[i]
		if strict_in_bin.has(body):
			_outside_bin_frames.erase(body)
			continue
		if _gate_open:
			_stored_balls.remove_at(i)
			_outside_bin_frames.erase(body)
			if body.has_method("apply_hopper_physics"):
				body.apply_hopper_physics(false)
			ball_entered_board.emit(body)
			continue
		var f: int = int(_outside_bin_frames.get(body, 0)) + 1
		_outside_bin_frames[body] = f
		if f < BIN_EXIT_HYSTERESIS_FRAMES:
			continue
		_stored_balls.remove_at(i)
		_outside_bin_frames.erase(body)
		if body.has_method("apply_hopper_physics"):
			body.apply_hopper_physics(false)
		if is_instance_valid(body) and _is_carryable_ball(body):
			return_ball(body)

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
	var spawn_offset_x: float = randf_range(-14.0, 14.0)
	ball.global_position = global_position + Vector2(spawn_offset_x, SPAWN_Y_OFFSET)
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2(randf_range(-20.0, 20.0), randf_range(0.0, 10.0))
	_main_balls_container.add_child(ball)
	_register_falling_carry(ball)

func release_next_ball() -> Node:
	return null

func get_visible_count() -> int:
	return mini(_stored_balls.size(), MAX_DISPLAY_BALLS)

func get_stored_ball_count() -> int:
	return _stored_balls.size()

func get_stored_balls() -> Array[Node]:
	return _stored_balls.duplicate()

## Remove one stored ball for which predicate returns true (destroys the node).
func remove_and_destroy_one_stored_ball_if(predicate: Callable) -> bool:
	for i in range(_stored_balls.size() - 1, -1, -1):
		var ball: Node = _stored_balls[i]
		if not is_instance_valid(ball):
			_stored_balls.remove_at(i)
			continue
		if predicate.call(ball):
			_stored_balls.remove_at(i)
			_outside_bin_frames.erase(ball)
			_falling_carry_until.erase(ball)
			ball.queue_free()
			return true
	return false

func clear_stored_balls() -> void:
	for ball in _stored_balls:
		if is_instance_valid(ball):
			ball.queue_free()
	_stored_balls.clear()
	_outside_bin_frames.clear()
	_falling_carry_until.clear()
	_prev_catchment_bodies.clear()

func return_ball(ball: Node) -> void:
	if not ball or not _main_balls_container:
		return
	_stored_balls.erase(ball)
	_outside_bin_frames.erase(ball)
	var parent: Node = ball.get_parent()
	if parent:
		parent.remove_child(ball)
	if "freeze" in ball:
		ball.freeze = false
	var spawn_offset_x: float = randf_range(-14.0, 14.0)
	ball.global_position = global_position + Vector2(spawn_offset_x, SPAWN_Y_OFFSET)
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2(randf_range(-20.0, 20.0), randf_range(0.0, 10.0))
	_main_balls_container.add_child(ball)
	_register_falling_carry(ball)

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

func set_width_scale(s: float) -> void:
	scale.x = clampf(s, 0.5, 2.0)

func refresh_width_from_game_state() -> void:
	if _width_pulse_tween and _width_pulse_tween.is_valid():
		return
	if GameState:
		scale.x = clampf(GameState.hopper_width_scale, 0.5, 2.0)

func pulse_width_temporarily(width_multiplier: float, hold_sec: float) -> void:
	if not GameState:
		return
	if _width_pulse_tween and _width_pulse_tween.is_valid():
		_width_pulse_tween.kill()
	var base: float = clampf(GameState.hopper_width_scale, 0.5, 2.0)
	var peak: float = clampf(base * width_multiplier, 0.5, 2.0)
	scale.x = base
	_width_pulse_tween = create_tween()
	_width_pulse_tween.tween_property(self, "scale", Vector2(peak, scale.y), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_width_pulse_tween.tween_interval(hold_sec)
	_width_pulse_tween.tween_property(self, "scale", Vector2(base, scale.y), 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_width_pulse_tween.tween_callback(refresh_width_from_game_state)
