extends Node2D
## Graphical goblin cannon at the bottom of the battlefield.
## Uses cannonMobile.png sprite texture asset with recoil shake tween and muzzle flash VFX.

const CANNON_ZONE_HEIGHT: float = 120.0
const CANNON_WIDTH: float = 80.0
const BARREL_LENGTH: float = 56.0
const BARREL_RADIUS: float = 14.0
const SHIELD_RADIUS: float = 52.0
const SHIELD_CENTER_OFFSET: Vector2 = Vector2(0.0, 6.0)
const STATUS_MAX_STACKS: int = 5
const STATUS_DECAY_TICKS: int = 120
const STATUS_OVERLAY_SIZE: float = 50.0

const CANNON_TEXTURE: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Pirate Pack/PNG/Retina/Ship parts/cannonMobile.png")
const MUZZLE_FLASH_TEXTURE: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Pirate Pack/PNG/Retina/Effects/explosion1.png")

var _shield_display: int = 0
var _status_stacks: Dictionary = {}
var _status_decay_counter: int = 0

var _recoil_offset_y: float = 0.0
var _show_muzzle_flash: bool = false
var _flash_alpha: float = 0.0

func trigger_firing_anim() -> void:
	_recoil_offset_y = 14.0
	_show_muzzle_flash = true
	_flash_alpha = 1.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "_recoil_offset_y", 0.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_flash_alpha", 0.0, 0.18).set_trans(Tween.TRANS_LINEAR)
	tw.chain().tween_callback(func():
		_show_muzzle_flash = false
		queue_redraw()
	)
	queue_redraw()

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

func set_sidearm_on_cooldown(_on_cooldown: bool) -> void:
	pass

func set_sidearm_cooldowns(_slots: Array) -> void:
	pass

func _process(_delta: float) -> void:
	if _status_stacks.size() > 0 or _recoil_offset_y > 0.0 or _show_muzzle_flash:
		queue_redraw()

func _draw() -> void:
	var base_y: float = CANNON_ZONE_HEIGHT * 0.5 + _recoil_offset_y

	# 1. Render Cannon Sprite Asset
	if CANNON_TEXTURE:
		var sprite_w: float = 76.0
		var sprite_h: float = 76.0 * (CANNON_TEXTURE.get_height() / float(CANNON_TEXTURE.get_width()))
		var sprite_rect := Rect2(-sprite_w * 0.5, base_y - sprite_h * 0.5 - 6.0, sprite_w, sprite_h)
		draw_texture_rect(CANNON_TEXTURE, sprite_rect, false)

	# 2. Muzzle Flash Particle Blast
	if _show_muzzle_flash and MUZZLE_FLASH_TEXTURE and _flash_alpha > 0.0:
		var flash_w: float = 54.0
		var flash_h: float = 54.0
		var muzzle_top_y: float = base_y - 48.0
		var flash_rect := Rect2(-flash_w * 0.5, muzzle_top_y - flash_h * 0.5, flash_w, flash_h)
		var flash_color := Color(1.0, 1.0, 1.0, _flash_alpha)
		draw_texture_rect(MUZZLE_FLASH_TEXTURE, flash_rect, false, flash_color)

	# 3. Status effect overlays (flame, ice, lightning)
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
