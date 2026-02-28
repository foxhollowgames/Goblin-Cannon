extends Node2D
## Turret on the wall that shoots projectiles at the cannon on a timer (sim ticks).
## States: IDLE, ABOUT_TO_ATTACK (wind-up ticks), ATTACKING (frame of firing).

signal shot_fired(damage: int)

enum AttackState {
	IDLE,
	ABOUT_TO_ATTACK,
	ATTACKING
}

const FIRE_INTERVAL_TICKS: int = 90  # 1.5 seconds at 60 ticks/s
const WINDUP_TICKS: int = 18  # 0.3s at 60 ticks/s — show "about to attack" before firing
const MUZZLE_FLASH_DURATION: float = 0.15  # seconds to hold bright flash when firing
const WINDUP_PULSE_SPEED: float = 10.0  # rad/s for wind-up muzzle glow pulse
const PROJECTILE_DAMAGE: int = 3
const PROJECTILE_SPEED: float = 280.0
const TURRET_SIZE: float = 14.0
const STATUS_MAX_STACKS: int = 5
const STATUS_DECAY_TICKS: int = 120

var _ticks_until_fire: int = 0
var _projectile_scene: PackedScene
var _battlefield: Node2D
var _attack_state: AttackState = AttackState.IDLE
var _turret_anim_time: float = 0.0  # for wind-up pulse
var _flash_remaining: float = 0.0   # holds ATTACKING muzzle flash visible
var _status_stacks: Dictionary = {}
var _status_decay_counter: int = 0

func apply_status(status_id: StringName, stacks: int) -> void:
	if stacks <= 0:
		return
	var current: int = _status_stacks.get(status_id, 0)
	_status_stacks[status_id] = mini(current + stacks, STATUS_MAX_STACKS)
	queue_redraw()

func status_tick(_sim_tick: int) -> void:
	_status_decay_counter += 1
	if _status_decay_counter >= STATUS_DECAY_TICKS:
		_status_decay_counter = 0
		for id in _status_stacks.keys():
			_status_stacks[id] = _status_stacks[id] - 1
			if _status_stacks[id] <= 0:
				_status_stacks.erase(id)
		queue_redraw()
	if _status_stacks.size() > 0:
		queue_redraw()

func _turret_stack_alpha_sat(stacks: int) -> Vector2:
	if stacks <= 0:
		return Vector2(0.0, 0.0)
	var t: float = clampf(float(stacks) / float(STATUS_MAX_STACKS), 0.0, 1.0)
	return Vector2(0.35 + 0.6 * t, 0.5 + 0.5 * t)

func _ready() -> void:
	_ticks_until_fire = FIRE_INTERVAL_TICKS * 2 / 3  # stagger first shot
	_projectile_scene = load("res://scenes/combat/fortification_projectile.tscn") as PackedScene
	var p: Node = get_parent()
	while p and not p.has_method("get_projectiles_container"):
		p = p.get_parent()
	_battlefield = p as Node2D
	# Stagger each turret's first shot
	var idx: int = get_index()
	_ticks_until_fire += idx * (FIRE_INTERVAL_TICKS / 4)

func get_attack_state() -> int:
	return _attack_state

func _process(delta: float) -> void:
	_turret_anim_time += delta
	if _flash_remaining > 0:
		_flash_remaining -= delta
		if _flash_remaining <= 0:
			_attack_state = AttackState.IDLE
		queue_redraw()
	elif _attack_state == AttackState.ABOUT_TO_ATTACK:
		queue_redraw()  # keep pulsing every frame
	if _status_stacks.size() > 0:
		queue_redraw()  # animate status overlays

func sim_tick(_tick: int) -> void:
	if _attack_state == AttackState.ATTACKING:
		# Flash is driven by _flash_remaining in _process
		return
	_ticks_until_fire -= 1
	if _ticks_until_fire <= 0:
		_ticks_until_fire = FIRE_INTERVAL_TICKS
		_attack_state = AttackState.ATTACKING
		_flash_remaining = MUZZLE_FLASH_DURATION
		_fire()
		queue_redraw()
		return
	if _ticks_until_fire <= WINDUP_TICKS:
		_attack_state = AttackState.ABOUT_TO_ATTACK
	else:
		_attack_state = AttackState.IDLE
	queue_redraw()

func _fire() -> void:
	if _projectile_scene == null or _battlefield == null:
		return
	var container: Node2D = _battlefield.get_projectiles_container() if _battlefield.has_method("get_projectiles_container") else _battlefield
	var proj: Node2D = _projectile_scene.instantiate() as Node2D
	if proj == null:
		return
	proj.position = container.to_local(global_position) + Vector2(0, 8)
	# Set meta before add_child so projectile _ready() can read them
	var target: Vector2 = _battlefield.get_cannon_target_position() if _battlefield.has_method("get_cannon_target_position") else Vector2(160.0, 460.0)
	proj.set_meta("damage", PROJECTILE_DAMAGE)
	proj.set_meta("speed", PROJECTILE_SPEED)
	proj.set_meta("target", target)
	container.add_child(proj)
	if _battlefield and proj.has_signal("hit_cannon") and _battlefield.has_method("_on_cannon_hit"):
		proj.hit_cannon.connect(_battlefield._on_cannon_hit)
	shot_fired.emit(PROJECTILE_DAMAGE)

func _draw() -> void:
	# State-based muzzle glow: wind-up = pulsing orange, attacking = held bright flash
	var muzzle_inner := Color(0.2, 0.18, 0.16, 1)
	var muzzle_outer := Color(0.35, 0.3, 0.28, 1)
	if _attack_state == AttackState.ABOUT_TO_ATTACK:
		# Pulsing glow during wind-up (0.65 .. 1.0)
		var pulse: float = 0.75 + 0.25 * sin(_turret_anim_time * WINDUP_PULSE_SPEED)
		muzzle_inner = Color(0.4 + 0.2 * pulse, 0.2 + 0.1 * pulse, 0.08, 1)
		muzzle_outer = Color(0.7 + 0.2 * pulse, 0.4 + 0.15 * pulse, 0.15 + 0.1 * pulse, 1)
	elif _attack_state == AttackState.ATTACKING:
		muzzle_inner = Color(0.95, 0.55, 0.2, 1)
		muzzle_outer = Color(1.0, 0.8, 0.4, 1)
	# Turret base (stone)
	draw_rect(Rect2(-TURRET_SIZE, -TURRET_SIZE * 0.5, TURRET_SIZE * 2, TURRET_SIZE), Color(0.3, 0.27, 0.24, 1))
	draw_rect(Rect2(-TURRET_SIZE, -TURRET_SIZE * 0.5, TURRET_SIZE * 2, TURRET_SIZE), Color(0.45, 0.4, 0.35, 1), false, 1.5)
	# Cannon muzzle (small)
	draw_circle(Vector2(0, -TURRET_SIZE * 0.8), 6, muzzle_inner)
	draw_arc(Vector2(0, -TURRET_SIZE * 0.8), 6, 0, TAU, 12, muzzle_outer, 1.0)

	# --- Status effect overlays (flame, ice, lightning; same style as minions) ---
	var flame_stacks: int = _status_stacks.get(Constants.STATUS_FIRE, 0)
	var frozen_stacks: int = _status_stacks.get(Constants.STATUS_FROZEN, 0)
	var lightning_stacks: int = _status_stacks.get(Constants.STATUS_LIGHTNING, 0)
	var sz: float = TURRET_SIZE * 1.4
	if flame_stacks > 0:
		var v: Vector2 = _turret_stack_alpha_sat(flame_stacks)
		var base_orange := Color(1.0, 0.5, 0.1, v.x)
		var tip_yellow := Color(1.0, 0.9, 0.2, v.x * 0.8)
		var flame_top: Vector2 = Vector2(0, -sz * 1.0)
		draw_circle(flame_top, sz * 0.35, tip_yellow)
		draw_circle(Vector2(0, -sz * 0.5), sz * 0.45, base_orange)
		var tm: float = Time.get_ticks_msec() * 0.003
		draw_line(flame_top, flame_top + Vector2(-sz * 0.25, sz * 0.2).rotated(sin(tm) * 0.3), base_orange)
		draw_line(flame_top, flame_top + Vector2(sz * 0.2, sz * 0.25).rotated(cos(tm * 1.1) * 0.3), base_orange)
	if frozen_stacks > 0:
		var v: Vector2 = _turret_stack_alpha_sat(frozen_stacks)
		var ice_color := Color(0.5, 0.85, 1.0, v.x * 0.85)
		draw_arc(Vector2.ZERO, sz * 0.9, 0, TAU, 24, ice_color, 2.0)
	if lightning_stacks > 0:
		var v: Vector2 = _turret_stack_alpha_sat(lightning_stacks)
		var bolt_color := Color(1.0, 1.0, 0.7, v.x)
		var r: float = sz * 0.9
		var seed_val: float = Time.get_ticks_msec() * 0.002
		for i in range(4):
			var a0: float = seed_val + i * TAU / 4.0
			var a1: float = a0 + 0.4 + sin(seed_val + i) * 0.2
			var p0: Vector2 = Vector2.from_angle(a0) * r
			var p1: Vector2 = Vector2.from_angle(a1) * r * 1.15
			draw_line(p0, p1, bolt_color)
