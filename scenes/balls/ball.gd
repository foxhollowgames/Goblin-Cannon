extends RigidBody2D
## Ball – engine-driven (Rapier2D). Same as a blank RigidBody: engine handles gravity and bounce.
## We only report peg hits for Board (energy, cooldown). No manual movement.
## Applies a tiny horizontal nudge after 2 consecutive vertical bounces so balls don't go straight up/down forever.

const VERTICAL_VELOCITY_THRESHOLD: float = 15.0  ## px/s; below this horizontal speed counts as "vertical" bounce
const ANTI_VERTICAL_NUDGE: float = 35.0  ## px/s; small horizontal nudge to break perfect vertical bounces
const SPLIT_SPIN_DURATION_SEC: float = 0.35  ## When Split happens, both balls spin rapidly for a moment
const SPLIT_SPIN_RATE: float = TAU * 18.0  ## radians per second during split spin

var _ball_id: int = 0
var _total_energy_display: int = 3
var _definition: Resource
var _last_collider: Node = null
var _consecutive_vertical_bounces: int = 0
var _was_in_vertical_bounce: bool = false
var _board_material: PhysicsMaterial
var _hopper_material: PhysicsMaterial
var _rubbery_material: PhysicsMaterial  ## Higher bounce for Rubbery ball on board
var _is_rubbery: bool = false
var _split_spin_elapsed: float = -1.0
var _split_triggered: bool = false  ## true after this ball has been part of a split (original or spawned)
var _is_split_twin: bool = false  ## true if this ball was spawned by Split (extra ball); never return to hopper, destroy on exit
var _fragment_echo_used: bool = false  ## Fragment Echo (wall break): once per fragment; after echo we destroy on next bottom
var _echo_floating: bool = false
var _echo_pulse_tween: Tween = null
var _is_phantom: bool = false
var _phantom_trail_positions: Array[Vector2] = []
var _in_hopper_bin: bool = false
## Reagent gas (Volatile clouds): stack counts from distinct clouds entered this visit; cleared when scoring at bottom.
var _gas_damage_cloud_stacks: int = 0
var _gas_energy_cloud_stacks: int = 0
var _gas_clouds_claimed: Dictionary = {}  # cloud_id -> true
const PHANTOM_TRAIL_MAX: int = 12
const PHANTOM_TRAIL_INTERVAL_PX: float = 14.0
## Same band as recording: below this, trail is cleared so it does not freeze as a static tail when the ball rests.
const PHANTOM_TRAIL_MIN_SPEED_PX: float = 30.0

func _ready() -> void:
	_total_energy_display = Constants.legacy_display_energy_to_current(20)
	contact_monitor = true
	max_contacts_reported = 8
	_board_material = PhysicsMaterial.new()
	_board_material.bounce = Constants.RESTITUTION
	_board_material.friction = Constants.TANGENTIAL_FRICTION
	_hopper_material = PhysicsMaterial.new()
	_hopper_material.bounce = 0.08
	# Lower than board friction so stacks slip and settle instead of sticking in tall columns.
	_hopper_material.friction = 0.28
	_rubbery_material = PhysicsMaterial.new()
	_rubbery_material.bounce = Constants.RUBBERY_RESTITUTION
	_rubbery_material.friction = Constants.TANGENTIAL_FRICTION
	physics_material_override = _board_material

func _physics_process(delta: float) -> void:
	if _is_phantom:
		var speed: float = linear_velocity.length()
		if speed > PHANTOM_TRAIL_MIN_SPEED_PX:
			var last_pos: Vector2 = _phantom_trail_positions[_phantom_trail_positions.size() - 1] if _phantom_trail_positions.size() > 0 else Vector2(-9999, -9999)
			if global_position.distance_to(last_pos) >= PHANTOM_TRAIL_INTERVAL_PX:
				_phantom_trail_positions.append(global_position)
				if _phantom_trail_positions.size() > PHANTOM_TRAIL_MAX:
					_phantom_trail_positions.remove_at(0)
				queue_redraw()
		elif _phantom_trail_positions.size() > 0:
			_phantom_trail_positions.clear()
			queue_redraw()
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
	if _in_hopper_bin:
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
	if _is_phantom and _phantom_trail_positions.size() > 1:
		_draw_phantom_trail()
	var alignment: int = 0
	var shape_override: int = -1
	var ability_name: String = ""
	if _definition is BallDefinition:
		alignment = _definition.alignment
		shape_override = _definition.shape_type
		ability_name = _definition.ability_name
	if _is_split_twin:
		shape_override = BallVisuals.ShapeType.HALF_CIRCLE
	BallVisuals.draw_ball(self, Vector2.ZERO, Constants.BALL_RADIUS, alignment, shape_override, ability_name)

func _draw_phantom_trail() -> void:
	var count: int = _phantom_trail_positions.size()
	for i in count:
		var t: float = float(i) / float(count)
		var alpha: float = t * 0.4
		var r: float = Constants.BALL_RADIUS * (0.3 + 0.7 * t)
		var trail_pos: Vector2 = _phantom_trail_positions[i] - global_position
		var color := Color(0.45, 0.75, 0.95, alpha)
		draw_circle(trail_pos, r, color)

## Called once per sim tick by Board. Ball does NOT move here – physics engine does.
## Returns one peg we're colliding with (for Board hit/energy).
func step_one_sim_tick(_sim_tick: int) -> Node:
	_last_collider = null
	for body in get_colliding_bodies():
		if body.get("peg_id") != null:
			_last_collider = body
			break
	return _last_collider

## Trampoline peg: apply upward speed after physics so Rapier collision resolution does not overwrite it.
func schedule_trampoline_upward_boost() -> void:
	call_deferred("_apply_trampoline_upward_boost_deferred")

func _apply_trampoline_upward_boost_deferred() -> void:
	var v: Vector2 = linear_velocity
	v.y = -Constants.TRAMPOLINE_UPWARD_SPEED
	linear_velocity = v

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
	_is_rubbery = (def is BallDefinition and (def as BallDefinition).ability_name == "Rubbery")
	_is_phantom = (def is BallDefinition and (def as BallDefinition).ability_name == "Phantom")
	reset_gas_buff_state_for_board_visit()
	if _is_phantom:
		collision_mask = 2
		modulate = Color(1.0, 1.0, 1.0, 0.7)
	else:
		collision_mask = 3
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
	modulate = Color(1.0, 1.0, 1.0, 0.75)
	queue_redraw()

## Fragment Echo (wall break): fragment can only float back to top once; then destroy on next bottom.
func has_fragment_echo_used() -> bool:
	return _fragment_echo_used

func mark_fragment_echo_used() -> void:
	_fragment_echo_used = true

func start_echo_float() -> void:
	_echo_floating = true
	modulate = Color(0.55, 0.65, 1.0, 0.35)
	_echo_pulse_tween = create_tween()
	_echo_pulse_tween.set_loops()
	_echo_pulse_tween.tween_property(self, "modulate:a", 0.55, 0.35).set_trans(Tween.TRANS_SINE)
	_echo_pulse_tween.tween_property(self, "modulate:a", 0.25, 0.35).set_trans(Tween.TRANS_SINE)

func end_echo_float() -> void:
	_echo_floating = false
	if _echo_pulse_tween:
		_echo_pulse_tween.kill()
		_echo_pulse_tween = null
	modulate = Color(1.0, 1.0, 1.0, 0.75)
	queue_redraw()

func reset_gas_buff_state_for_board_visit() -> void:
	_gas_damage_cloud_stacks = 0
	_gas_energy_cloud_stacks = 0
	_gas_clouds_claimed.clear()

## Each cloud id applies at most once. is_damage_cloud: true = +1 damage stack, false = +1 energy stack.
func try_claim_gas_cloud(cloud_id: int, is_damage_cloud: bool) -> void:
	if _gas_clouds_claimed.get(cloud_id, false):
		return
	_gas_clouds_claimed[cloud_id] = true
	if is_damage_cloud:
		_gas_damage_cloud_stacks += 1
	else:
		_gas_energy_cloud_stacks += 1

func get_gas_damage_stack_count() -> int:
	return _gas_damage_cloud_stacks

func get_gas_energy_stack_count() -> int:
	return _gas_energy_cloud_stacks

## Damage buff clears when energy is banked at the bottom; energy stacks clear for the same visit.
func clear_gas_buffs_on_score() -> void:
	_gas_damage_cloud_stacks = 0
	_gas_energy_cloud_stacks = 0
	_gas_clouds_claimed.clear()

## Use low bounce and high damp in the hopper so balls settle; restore when leaving for the board.
## Rotation is unlocked in the hopper so spheres roll and stacks collapse (locked on board for stable peg play).
## Rubbery balls use higher restitution on the board so they bounce more.
func apply_hopper_physics(inside: bool) -> void:
	_in_hopper_bin = inside
	if inside:
		physics_material_override = _hopper_material
		linear_damp = 3.0
		lock_rotation = false
		angular_damp = 6.0
		_phantom_trail_positions.clear()
	else:
		physics_material_override = _rubbery_material if _is_rubbery else _board_material
		linear_damp = 0.0
		angular_damp = 0.0
		lock_rotation = true
		angular_velocity = 0.0
		rotation = 0.0
