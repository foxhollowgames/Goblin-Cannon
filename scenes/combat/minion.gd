extends Node2D
## Melee minion: moves to cannon, then stays and deals damage every PERIODIC_INTERVAL seconds.
## Can be killed with take_damage(). Wall 1 melee minions have 1 HP (killed by muzzle blast).
## States: APPROACHING, ABOUT_TO_ATTACK (wind-up), ATTACKING (dealing hit), AT_CANNON_IDLE.

signal deal_damage(amount: int)

enum AttackState {
	APPROACHING,
	ABOUT_TO_ATTACK,
	ATTACKING,
	AT_CANNON_IDLE
}

const SPEED: float = 85.0
const DAMAGE: int = 2
const PERIODIC_INTERVAL: float = 2.0
const WINDUP_TIME: float = 0.4  # seconds before each hit that we show "about to attack"
const ATTACK_FLASH_DURATION: float = 0.12  # seconds to hold bright flash on hit
const WINDUP_PULSE_SPEED: float = 12.0  # rad/s for wind-up color pulse
const CANNON_ZONE_TOP: float = 420.0  # matches battlefield CANNON_ZONE_TOP (600 + overlay offset)
const SIZE: float = 12.0
const MELEE_WALL1_HP: int = 1
const STATUS_MAX_STACKS: int = 5  # cap for stacking; visuals use this for alpha/saturation
const STATUS_DECAY_TICKS: int = 120  # sim ticks (2s) per stack decay
const FIRE_DOT_PER_STACK: int = 1  # damage per tick per fire stack
const FROZEN_SLOW_FRAC: float = 0.5  # movement multiplier when frozen (0.5 = half speed)

var _target_y: float = 460.0  # cannon target (CANNON_ZONE_TOP + 40), set by battlefield
var _at_cannon: bool = false
var _health: int = MELEE_WALL1_HP
var _periodic_timer: Timer
var _first_hit_timer: Timer  # one-shot windup for the first hit when reaching cannon
var _attack_state: AttackState = AttackState.APPROACHING
var _attack_anim_time: float = 0.0  # for wind-up pulse
var _flash_remaining: float = 0.0   # holds ATTACKING flash visible
## Status stacks: status_id (StringName) -> stack count (int). Visuals overlap; alpha/saturation from stacks.
var _status_stacks: Dictionary = {}  # e.g. { &"fire": 2, &"frozen": 1, &"lightning": 1 }
var _status_decay_counter: int = 0   # sim ticks for periodic decay (handled by battlefield)

func _ready() -> void:
	_periodic_timer = Timer.new()
	_periodic_timer.one_shot = false
	_periodic_timer.wait_time = PERIODIC_INTERVAL
	_periodic_timer.timeout.connect(_on_periodic_damage)
	add_child(_periodic_timer)
	_first_hit_timer = Timer.new()
	_first_hit_timer.one_shot = true
	_first_hit_timer.wait_time = WINDUP_TIME
	_first_hit_timer.timeout.connect(_on_first_hit_windup_done)
	add_child(_first_hit_timer)

func set_target_y(y: float) -> void:
	_target_y = y

## Add or refresh stacks for a status. Stacks cap at STATUS_MAX_STACKS. Visuals use stack count for alpha/saturation.
func apply_status(status_id: StringName, stacks: int) -> void:
	if stacks <= 0:
		return
	var current: int = _status_stacks.get(status_id, 0)
	_status_stacks[status_id] = mini(current + stacks, STATUS_MAX_STACKS)
	queue_redraw()

## Called once per sim tick from BattlefieldView. Decays stacks and applies fire DoT.
func status_tick(sim_tick: int) -> void:
	_status_decay_counter += 1
	if _status_decay_counter >= STATUS_DECAY_TICKS:
		_status_decay_counter = 0
		for id in _status_stacks.keys():
			_status_stacks[id] = _status_stacks[id] - 1
			if _status_stacks[id] <= 0:
				_status_stacks.erase(id)
		queue_redraw()
	var fire_stacks: int = _status_stacks.get(Constants.STATUS_FIRE, 0)
	if fire_stacks > 0 and _status_decay_counter % 60 == 1:
		take_damage(FIRE_DOT_PER_STACK * fire_stacks)

func take_damage(amount: int) -> void:
	_health -= amount
	if _health <= 0:
		queue_free()

func _process(delta: float) -> void:
	if _at_cannon:
		_attack_anim_time += delta
		if _flash_remaining > 0:
			_flash_remaining -= delta
			if _flash_remaining <= 0:
				_attack_state = AttackState.AT_CANNON_IDLE
			queue_redraw()  # keep drawing flash every frame
		else:
			_update_attack_state()
		if _status_stacks.size() > 0:
			queue_redraw()  # animate flame/lightning overlays
		return
	_attack_state = AttackState.APPROACHING
	_attack_anim_time = 0.0
	_flash_remaining = 0.0
	var frozen_stacks: int = _status_stacks.get(Constants.STATUS_FROZEN, 0)
	var speed_mult: float = 1.0 - FROZEN_SLOW_FRAC * minf(1.0, float(frozen_stacks) / 2.0)
	position.y += SPEED * speed_mult * delta
	if position.y >= _target_y:
		position.y = _target_y
		_at_cannon = true
		_attack_state = AttackState.ABOUT_TO_ATTACK
		_first_hit_timer.start()
		queue_redraw()
		return
	if _status_stacks.size() > 0:
		queue_redraw()  # animate status overlays while approaching
	queue_redraw()

func _update_attack_state() -> void:
	if _first_hit_timer.time_left > 0:
		# First hit windup already shown as ABOUT_TO_ATTACK
		queue_redraw()
		return
	if _attack_state == AttackState.ATTACKING:
		# Flash is driven by _flash_remaining in _process
		queue_redraw()
		return
	if _periodic_timer.time_left > 0:
		if _periodic_timer.time_left <= WINDUP_TIME:
			_attack_state = AttackState.ABOUT_TO_ATTACK
		else:
			_attack_state = AttackState.AT_CANNON_IDLE
	else:
		_attack_state = AttackState.AT_CANNON_IDLE
	queue_redraw()

func _on_first_hit_windup_done() -> void:
	if is_instance_valid(self) and _at_cannon:
		_attack_state = AttackState.ATTACKING
		_flash_remaining = ATTACK_FLASH_DURATION
		deal_damage.emit(DAMAGE)
		_periodic_timer.start()
		queue_redraw()

func _on_periodic_damage() -> void:
	if is_instance_valid(self) and _at_cannon:
		_attack_state = AttackState.ATTACKING
		_flash_remaining = ATTACK_FLASH_DURATION
		deal_damage.emit(DAMAGE)
		queue_redraw()

func get_attack_state() -> int:
	return _attack_state

## Returns alpha and saturation multiplier for a stack count (0..STATUS_MAX_STACKS). More stacks = more opaque and saturated.
func _stack_alpha_sat(stacks: int) -> Vector2:
	if stacks <= 0:
		return Vector2(0.0, 0.0)
	var t: float = clampf(float(stacks) / float(STATUS_MAX_STACKS), 0.0, 1.0)
	var alpha: float = 0.35 + 0.6 * t
	var sat: float = 0.5 + 0.5 * t
	return Vector2(alpha, sat)

func _draw() -> void:
	# State-based tint: wind-up = pulsing orange/red, attacking = held bright flash
	var body_inner := Color(0.25, 0.35, 0.2, 1)
	var body_outer := Color(0.35, 0.5, 0.28, 1)
	var head_inner := Color(0.45, 0.35, 0.25, 1)
	var head_outer := Color(0.55, 0.42, 0.32, 1)
	if _attack_state == AttackState.ABOUT_TO_ATTACK:
		# Pulsing glow during wind-up (0.6 .. 1.0)
		var pulse: float = 0.7 + 0.3 * sin(_attack_anim_time * WINDUP_PULSE_SPEED)
		body_outer = Color(0.6 + 0.2 * pulse, 0.3 + 0.1 * pulse, 0.1, 1)
		head_outer = Color(0.75 + 0.2 * pulse, 0.35 + 0.15 * pulse, 0.15, 1)
	elif _attack_state == AttackState.ATTACKING:
		# Bright flash (held for ATTACK_FLASH_DURATION)
		var flash_fade: float = 1.0 if _flash_remaining > 0 else 0.0
		body_outer = Color(0.9 + 0.1 * flash_fade, 0.5 + 0.25 * flash_fade, 0.2, 1)
		head_outer = Color(1.0, 0.7 + 0.2 * flash_fade, 0.3, 1)
	# Simple goblin/halfling silhouette: body + head
	draw_circle(Vector2.ZERO, SIZE * 0.6, body_inner)
	draw_arc(Vector2.ZERO, SIZE * 0.6, 0, TAU, 16, body_outer, 1.5)
	draw_circle(Vector2(0, -SIZE * 0.5), SIZE * 0.35, head_inner)
	draw_arc(Vector2(0, -SIZE * 0.5), SIZE * 0.35, 0, TAU, 12, head_outer, 1.0)

	# --- Status effect overlays (can overlap; transparency and saturation from stack count) ---
	var flame_stacks: int = _status_stacks.get(Constants.STATUS_FIRE, 0)
	var frozen_stacks: int = _status_stacks.get(Constants.STATUS_FROZEN, 0)
	var lightning_stacks: int = _status_stacks.get(Constants.STATUS_LIGHTNING, 0)

	# Fire: flame above the object
	if flame_stacks > 0:
		var v: Vector2 = _stack_alpha_sat(flame_stacks)
		var base_orange := Color(1.0, 0.5, 0.1, v.x)
		var tip_yellow := Color(1.0, 0.9, 0.2, v.x * 0.8)
		var flame_top: Vector2 = Vector2(0, -SIZE * 1.2)
		draw_circle(flame_top, SIZE * 0.35, tip_yellow)
		draw_circle(Vector2(0, -SIZE * 0.95), SIZE * 0.45, base_orange)
		# Small flicker triangles
		var t: float = Time.get_ticks_msec() * 0.003
		draw_line(flame_top, flame_top + Vector2(-SIZE * 0.25, SIZE * 0.2).rotated(sin(t) * 0.3), base_orange)
		draw_line(flame_top, flame_top + Vector2(SIZE * 0.2, SIZE * 0.25).rotated(cos(t * 1.1) * 0.3), base_orange)

	# Frozen: ice cube encasing (semi-transparent cyan outline around body)
	if frozen_stacks > 0:
		var v: Vector2 = _stack_alpha_sat(frozen_stacks)
		var ice_color := Color(0.5, 0.85, 1.0, v.x * 0.85)
		var encase_r: float = SIZE * 0.75
		draw_arc(Vector2.ZERO, encase_r, 0, TAU, 24, ice_color, 2.5)
		draw_arc(Vector2(0, -SIZE * 0.5), encase_r * 0.9, 0, TAU, 20, Color(0.7, 0.95, 1.0, v.x * 0.5), 1.5)

	# Lightning: crackles around the object (jagged bolt lines)
	if lightning_stacks > 0:
		var v: Vector2 = _stack_alpha_sat(lightning_stacks)
		var bolt_color := Color(1.0, 1.0, 0.7, v.x)
		var r: float = SIZE * 0.9
		var seed_val: float = float(hash(position.x + 1.0)) * 0.01 + Time.get_ticks_msec() * 0.002
		for i in range(4):
			var a0: float = seed_val + i * TAU / 4.0
			var a1: float = a0 + 0.4 + sin(seed_val + i) * 0.2
			var p0: Vector2 = Vector2.from_angle(a0) * r
			var p1: Vector2 = Vector2.from_angle(a1) * r * 1.15
			draw_line(p0, p1, bolt_color)
			draw_line(p0 + Vector2.from_angle(a0 + 0.5) * 3, p1, Color(1.0, 1.0, 1.0, v.x * 0.6))
