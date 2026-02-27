extends CharacterBody2D
## Ball (§6.5). Kinematic + manual bounce (ARCHITECTURE §1.5).
## Rapier2D provides collision and contact normal via move_and_collide(); we apply gravity
## and bounce response ourselves each sim tick so the sim stays deterministic and slow-mo safe.
## To get Rapier's full bounce (engine restitution) we'd switch to RigidBody2D and 1 tick = 1 physics frame.

var _ball_id: int = 0
var _total_energy_display: int = 20
var _definition: Resource
var _last_collider: Node = null
var _sim_position: Vector2 = Vector2.ZERO
var _prev_sim_position: Vector2 = Vector2.ZERO
func _ready() -> void:
	velocity = Vector2.ZERO
	_sim_position = position
	_prev_sim_position = position

func _process(_delta: float) -> void:
	# Smooth rendering: interpolate between prev and current sim position to remove afterimage/streak
	position = _prev_sim_position.lerp(_sim_position, GameState.sim_step_alpha)

## Called once per sim tick by Board. Do NOT use _physics_process for movement.
## Returns the collider (peg) if this tick had a collision, for Board hit resolution.
func step_one_sim_tick(_sim_tick: int) -> Node:
	_last_collider = null
	position = _sim_position
	_prev_sim_position = _sim_position
	_integrate_one_tick(_sim_tick)
	_sim_position = position
	return _last_collider

func _integrate_one_tick(sim_tick: int) -> void:
	velocity.y += Constants.GRAVITY
	velocity.x *= (1.0 - Constants.LINEAR_DRAG)
	velocity.y *= (1.0 - Constants.LINEAR_DRAG)
	var max_speed_pt: float = Constants.MAX_BALL_SPEED / float(Constants.SIM_TICKS_PER_SECOND)
	var speed: float = velocity.length()
	if speed > max_speed_pt:
		velocity = velocity.normalized() * max_speed_pt
	var motion: Vector2 = velocity
	# Rapier2D provides collision and normal; we still apply our own bounce for deterministic sim.
	var col: KinematicCollision2D = move_and_collide(motion, false, 0.08)
	if col:
		var collider: Node = col.get_collider()
		var peg_global: Vector2 = collider.global_position if collider else global_position
		if collider and collider.get("peg_id") != null:
			_last_collider = collider
		# Use geometric normal (peg center → ball center) so bounce is always "away from peg" and visible.
		var to_ball: Vector2 = global_position - peg_global
		var dist: float = to_ball.length()
		if dist < 0.001:
			to_ball = col.get_normal()
			dist = 1.0
		var n: Vector2 = (to_ball / dist)
		var v_dot_n: float = velocity.dot(n)
		# Bounce when moving into the peg (v_dot_n < 0). Use geometric normal so we always get a clear kick.
		if v_dot_n < 0:
			var v_perp: Vector2 = v_dot_n * n
			var v_tan: Vector2 = velocity - v_perp
			velocity = (-Constants.RESTITUTION * v_dot_n) * n + v_tan * (1.0 - Constants.TANGENTIAL_FRICTION)
			var away_x: float = sign(to_ball.x)
			if away_x == 0:
				away_x = 1.0
			var tan_len: float = v_tan.length()
			var nudge: float = 4.0 if tan_len < 2.0 else 1.0
			velocity.x += away_x * nudge
		# Depenetration: minimal push; always do this.
		var sum_radii: float = Constants.BALL_RADIUS + Constants.PEG_RADIUS
		var push_amount: float = (sum_radii + Constants.PEG_DEPENETRATE_MARGIN) - dist
		if push_amount > 0:
			global_position += n * push_amount
	else:
		_last_collider = null

func add_peg_energy(amount: int) -> void:
	_total_energy_display += amount

func get_total_energy() -> int:
	return _total_energy_display

func get_definition() -> Resource:
	return _definition

func get_ball_id() -> int:
	return _ball_id

func get_radius() -> float:
	return Constants.BALL_RADIUS

## Use for gameplay (bottom zone, etc.); display position is interpolated in _process.
func get_sim_position() -> Vector2:
	return _sim_position

func get_global_sim_position() -> Vector2:
	return get_parent().global_position + _sim_position

func set_ball_id(id: int) -> void:
	_ball_id = id

func set_definition(def: Resource) -> void:
	_definition = def

func _draw() -> void:
	draw_circle(Vector2.ZERO, Constants.BALL_RADIUS, Color(0.85, 0.25, 0.25, 1))
