extends Node2D
## Graphical goblin cannon at the bottom of the battlefield.
## Supports status effect overlays (fire, frozen, lightning) like minions; apply via apply_status().

const CANNON_ZONE_HEIGHT: float = 120.0
const CANNON_WIDTH: float = 80.0
const BARREL_LENGTH: float = 56.0
const BARREL_RADIUS: float = 14.0
const SHIELD_RADIUS: float = 52.0
const SHIELD_CENTER_OFFSET: Vector2 = Vector2(0.0, 6.0)
const STATUS_MAX_STACKS: int = 5
const STATUS_DECAY_TICKS: int = 120
const STATUS_OVERLAY_SIZE: float = 50.0  # scale for flame/ice/lightning overlays

var _shield_display: int = 0
var _status_stacks: Dictionary = {}
var _status_decay_counter: int = 0
## Per-slot cooldown state; index = sidearm slot (scene order). Empty = draw one barrel at slot 0, no cooldown.
var _sidearm_cooldowns: Array = []

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

func _cannon_stack_alpha_sat(stacks: int) -> Vector2:
	if stacks <= 0:
		return Vector2(0.0, 0.0)
	var t: float = clampf(float(stacks) / float(STATUS_MAX_STACKS), 0.0, 1.0)
	return Vector2(0.35 + 0.6 * t, 0.5 + 0.5 * t)

func set_shield(display_value: int) -> void:
	if _shield_display == display_value:
		return
	_shield_display = display_value
	queue_redraw()

## Single sidearm (slot 0). Kept for backward compatibility.
func set_sidearm_on_cooldown(on_cooldown: bool) -> void:
	if _sidearm_cooldowns.size() < 1:
		_sidearm_cooldowns.resize(1)
	if _sidearm_cooldowns[0] != on_cooldown:
		_sidearm_cooldowns[0] = on_cooldown
		queue_redraw()

## Multiple sidearms: one bool per slot (order matches Sidearms container children). Drives barrel count and cooldown dimming.
func set_sidearm_cooldowns(slots: Array) -> void:
	_sidearm_cooldowns = slots.duplicate()
	queue_redraw()

func _process(_delta: float) -> void:
	if _status_stacks.size() > 0:
		queue_redraw()

func _draw() -> void:
	var center_x: float = 0.0
	var base_y: float = CANNON_ZONE_HEIGHT * 0.5
	# Shield bubble (when shield energy > 0)
	if _shield_display > 0:
		var shield_center: Vector2 = Vector2(center_x, base_y) + SHIELD_CENTER_OFFSET
		var strength: float = clampf(float(_shield_display) / 50.0, 0.0, 1.0)
		var fill_alpha: float = 0.08 + 0.12 * strength
		var edge_alpha: float = 0.25 + 0.35 * strength
		# Soft fill
		draw_arc(shield_center, SHIELD_RADIUS, 0, TAU, 32, Color(0.35, 0.7, 1.0, fill_alpha))
		# Outer glow (wider, fainter)
		draw_arc(shield_center, SHIELD_RADIUS + 4.0, 0, TAU, 32, Color(0.4, 0.8, 1.0, edge_alpha * 0.5))
		# Crisp bubble edge
		draw_arc(shield_center, SHIELD_RADIUS, 0, TAU, 32, Color(0.4, 0.85, 1.0, edge_alpha), 2.0)
	# Base / wheels (dark metal)
	draw_circle(Vector2(-18, base_y + 20), 16, Color(0.22, 0.2, 0.18, 1))
	draw_arc(Vector2(-18, base_y + 20), 16, 0, TAU, 24, Color(0.35, 0.32, 0.3, 1), 2.0)
	draw_circle(Vector2(18, base_y + 20), 16, Color(0.22, 0.2, 0.18, 1))
	draw_arc(Vector2(18, base_y + 20), 16, 0, TAU, 24, Color(0.35, 0.32, 0.3, 1), 2.0)
	# Chassis
	var chassis := Rect2(-40, base_y - 8, 80, 28)
	draw_rect(chassis, Color(0.28, 0.25, 0.22, 1))
	draw_rect(chassis, Color(0.45, 0.38, 0.3, 1), false, 2.0)
	# Barrel (pointing up slightly)
	var barrel_start := Vector2(0, base_y - 18)
	var barrel_end := Vector2(0, base_y - 18 - BARREL_LENGTH)
	draw_line(barrel_start, barrel_end, Color(0.2, 0.18, 0.16, 1))
	for i in range(3):
		var r: float = BARREL_RADIUS - i * 2.0
		draw_arc(barrel_start, r, -PI * 0.5 - 0.2, -PI * 0.5 + 0.2, 8, Color(0.25 + i * 0.04, 0.22 + i * 0.04, 0.2, 1))
		draw_arc(barrel_end, r, PI * 0.5 - 0.2, PI * 0.5 + 0.2, 8, Color(0.25 + i * 0.04, 0.22 + i * 0.04, 0.2, 1))
	# Barrel band (copper/goblin accent)
	draw_rect(Rect2(-16, base_y - 22, 32, 8), Color(0.55, 0.35, 0.2, 1))
	draw_rect(Rect2(-16, base_y - 22, 32, 8), Color(0.7, 0.5, 0.3, 1), false, 1.0)
	# Muzzle glow (subtle)
	draw_circle(barrel_end, 6, Color(0.4, 0.35, 0.25, 0.6))
	# Sidearm barrels: one per slot to the right of main barrel (aligned with BattlefieldView SIDEARM_MUZZLE_POSITIONS). Dim when on cooldown.
	const SIDEARM_BARREL_START: Vector2 = Vector2(28.0, -42.0)
	const SIDEARM_BARREL_SPACING: float = 30.0
	const MAX_SIDEARM_SLOTS: int = 6
	var slot_count: int = _sidearm_cooldowns.size() if _sidearm_cooldowns.size() > 0 else 1
	slot_count = mini(slot_count, MAX_SIDEARM_SLOTS)
	for i in range(slot_count):
		var pos: Vector2 = SIDEARM_BARREL_START + Vector2(i * SIDEARM_BARREL_SPACING, 0.0)
		var on_cd: bool = _sidearm_cooldowns[i] if i < _sidearm_cooldowns.size() else false
		var sidearm_alpha: float = 0.4 if on_cd else 1.0
		draw_circle(pos, 5, Color(0.5, 0.22, 0.2, 0.9 * sidearm_alpha))
		draw_arc(pos, 5, 0, TAU, 8, Color(0.85, 0.35, 0.3, 0.8 * sidearm_alpha), 1.0)

	# --- Status effect overlays (flame, ice, lightning; same style as minions) ---
	var flame_stacks: int = _status_stacks.get(Constants.STATUS_FIRE, 0)
	var frozen_stacks: int = _status_stacks.get(Constants.STATUS_FROZEN, 0)
	var lightning_stacks: int = _status_stacks.get(Constants.STATUS_LIGHTNING, 0)
	var sz: float = STATUS_OVERLAY_SIZE
	var center: Vector2 = Vector2(0.0, base_y)
	if flame_stacks > 0:
		var v: Vector2 = _cannon_stack_alpha_sat(flame_stacks)
		var base_orange := Color(1.0, 0.5, 0.1, v.x)
		var tip_yellow := Color(1.0, 0.9, 0.2, v.x * 0.8)
		var flame_top: Vector2 = center + Vector2(0, -sz * 1.0)
		draw_circle(flame_top, sz * 0.35, tip_yellow)
		draw_circle(center + Vector2(0, -sz * 0.5), sz * 0.45, base_orange)
		var t: float = Time.get_ticks_msec() * 0.003
		draw_line(flame_top, flame_top + Vector2(-sz * 0.25, sz * 0.2).rotated(sin(t) * 0.3), base_orange)
		draw_line(flame_top, flame_top + Vector2(sz * 0.2, sz * 0.25).rotated(cos(t * 1.1) * 0.3), base_orange)
	if frozen_stacks > 0:
		var v: Vector2 = _cannon_stack_alpha_sat(frozen_stacks)
		var ice_color := Color(0.5, 0.85, 1.0, v.x * 0.85)
		draw_arc(center, sz * 0.9, 0, TAU, 24, ice_color, 2.5)
	if lightning_stacks > 0:
		var v: Vector2 = _cannon_stack_alpha_sat(lightning_stacks)
		var bolt_color := Color(1.0, 1.0, 0.7, v.x)
		var r: float = sz * 0.9
		var seed_val: float = Time.get_ticks_msec() * 0.002
		for i in range(4):
			var a0: float = seed_val + i * TAU / 4.0
			var a1: float = a0 + 0.4 + sin(seed_val + i) * 0.2
			var p0: Vector2 = center + Vector2.from_angle(a0) * r
			var p1: Vector2 = center + Vector2.from_angle(a1) * r * 1.15
			draw_line(p0, p1, bolt_color)
