extends RigidBody2D
## Ball – engine-driven (Rapier2D). Same as a blank RigidBody: engine handles gravity and bounce.
## We only report peg hits for Board (energy, cooldown). No manual movement.
## Applies a tiny horizontal nudge after 2 consecutive vertical bounces so balls don't go straight up/down forever.

const VERTICAL_VELOCITY_THRESHOLD: float = 15.0  ## px/s; below this horizontal speed counts as "vertical" bounce
const ANTI_VERTICAL_NUDGE: float = 35.0  ## px/s; small horizontal nudge to break perfect vertical bounces
const SPLIT_SPIN_DURATION_SEC: float = 0.35  ## When Split happens, both balls spin rapidly for a moment
const SPLIT_SPIN_RATE: float = TAU * 18.0  ## radians per second during split spin

var _ball_id: int = 0
var _total_energy_display: int = 20
var _definition: Resource
var _last_collider: Node = null
var _consecutive_vertical_bounces: int = 0
var _was_in_vertical_bounce: bool = false
var _board_material: PhysicsMaterial
var _hopper_material: PhysicsMaterial
var _split_spin_elapsed: float = -1.0
var _split_triggered: bool = false  ## true after this ball has been part of a split (original or spawned)
var _is_split_twin: bool = false  ## true if this ball was spawned by Split (extra ball); never return to hopper, destroy on exit

func _ready() -> void:
	_total_energy_display = 20
	contact_monitor = true
	max_contacts_reported = 8
	_board_material = PhysicsMaterial.new()
	_board_material.bounce = Constants.RESTITUTION
	_board_material.friction = Constants.TANGENTIAL_FRICTION
	_hopper_material = PhysicsMaterial.new()
	_hopper_material.bounce = 0.12
	_hopper_material.friction = 0.5
	physics_material_override = _board_material

func _physics_process(delta: float) -> void:
	# Spin: drive rotation via angular_velocity so linear motion is never touched; end spin after duration
	if _split_spin_elapsed >= 0.0:
		_split_spin_elapsed += delta
		if _split_spin_elapsed >= SPLIT_SPIN_DURATION_SEC:
			_split_spin_elapsed = -1.0
			angular_velocity = 0.0
			rotation = 0.0
			lock_rotation = true
			queue_redraw()
		# else: angular_velocity already set in start_split_spin; engine integrates both linear and angular
		return
	# Skip nudge when nearly at rest (e.g. settling in hopper) to avoid disturbing stacked balls
	if linear_velocity.length() < 25.0:
		_was_in_vertical_bounce = false
		_consecutive_vertical_bounces = 0
		return
	var colliding: bool = get_colliding_bodies().size() > 0
	var is_vertical: bool = abs(linear_velocity.x) < VERTICAL_VELOCITY_THRESHOLD
	var in_vertical_bounce: bool = colliding and is_vertical

	if in_vertical_bounce:
		if not _was_in_vertical_bounce:
			_consecutive_vertical_bounces += 1
			_was_in_vertical_bounce = true
			if _consecutive_vertical_bounces >= 2:
				var nudge: float = randf_range(-ANTI_VERTICAL_NUDGE, ANTI_VERTICAL_NUDGE)
				linear_velocity.x += nudge
				_consecutive_vertical_bounces = 0
	else:
		_was_in_vertical_bounce = false

func _draw() -> void:
	var alignment: int = 0
	var shape_override: int = -1
	if _definition is BallDefinition:
		alignment = _definition.alignment
		shape_override = _definition.shape_type
	BallVisuals.draw_ball(self, Vector2.ZERO, Constants.BALL_RADIUS, alignment, shape_override)

## Called once per sim tick by Board. Ball does NOT move here – physics engine does.
## Returns one peg we're colliding with (for Board hit/energy).
func step_one_sim_tick(_sim_tick: int) -> Node:
	_last_collider = null
	for body in get_colliding_bodies():
		if body.get("peg_id") != null:
			_last_collider = body
			break
	return _last_collider

func add_peg_energy(amount: int) -> void:
	_total_energy_display += amount

func set_total_energy_display(amount: int) -> void:
	_total_energy_display = maxi(0, amount)

func get_total_energy() -> int:
	return _total_energy_display

func get_definition() -> Resource:
	return _definition

func get_ball_id() -> int:
	return _ball_id

func get_radius() -> float:
	return Constants.BALL_RADIUS

func get_sim_position() -> Vector2:
	return position

func get_global_sim_position() -> Vector2:
	return global_position

func set_ball_id(id: int) -> void:
	_ball_id = id

func set_definition(def: Resource) -> void:
	_definition = def
	queue_redraw()

func has_split_triggered() -> bool:
	return _split_triggered

func mark_split_triggered() -> void:
	_split_triggered = true

## Call when ball enters the board (spawn_ball_at_start) so Split can trigger once per run.
func reset_split_for_new_visit() -> void:
	_split_triggered = false

## Called by Board on both balls when Split triggers. Ball spins via angular_velocity so linear motion is unaffected.
func start_split_spin() -> void:
	_split_spin_elapsed = 0.0
	lock_rotation = false
	angular_velocity = SPLIT_SPIN_RATE
	queue_redraw()

func is_split_twin() -> bool:
	return _is_split_twin

func mark_as_split_twin() -> void:
	_is_split_twin = true
	modulate = Color(1.0, 1.0, 1.0, 0.55)  # semi-transparent so split balls are easy to notice
	queue_redraw()

## Use low bounce and high damp in the hopper so balls settle; restore when leaving for the board.
func apply_hopper_physics(inside: bool) -> void:
	if inside:
		physics_material_override = _hopper_material
		linear_damp = 4.0
	else:
		physics_material_override = _board_material
		linear_damp = 0.0
