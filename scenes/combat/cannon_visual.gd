extends Node2D
## Graphical goblin cannon positioned at the center-left of the bottom UI.
## Renders a single crisp native cannonMobile.png sprite texture asset
## with energy charge meter overlay, white flash lead bar with smooth yellow catch-up animation,
## horizontal recoil shake tween, and Cartoon Coffee Fire VFX.

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
const FIRE_VFX_TEXTURE: Texture2D = preload("res://assets/VFX/Essentials VFX Spritesheets/Impact_Fire_Lv1_spritesheet.png")

var current_energy: int = 0
var max_energy: int = 10000
var liquid_ratio: float = 0.0
var _target_ratio: float = 0.0
var _catchup_tween: Tween

var _shield_display: int = 0
var _status_stacks: Dictionary = {}
var _status_decay_counter: int = 0

var _recoil_offset_x: float = 0.0
var _show_muzzle_flash: bool = false
var _flash_frame: int = 0

func set_energy(p_current: int, p_max: int = 10000) -> void:
	current_energy = maxi(0, p_current)
	max_energy = maxi(1, p_max)
	var new_ratio: float = clampf(float(current_energy) / float(max_energy), 0.0, 1.0)
	
	if new_ratio > _target_ratio:
		_target_ratio = new_ratio
		if _catchup_tween and _catchup_tween.is_valid():
			_catchup_tween.kill()
		_catchup_tween = create_tween()
		_catchup_tween.tween_property(self, "liquid_ratio", _target_ratio, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_target_ratio = new_ratio
		liquid_ratio = new_ratio
	queue_redraw()

func set_charge(p_current: int, p_max: int = 10000) -> void:
	set_energy(p_current, p_max)

func trigger_firing_anim() -> void:
	_recoil_offset_x = -12.0
	_show_muzzle_flash = true
	_flash_frame = 0
	
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	# Recoil shake tween: kick backward left, then return smoothly
	tw.tween_property(self, "_recoil_offset_x", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_flash_frame", 3, 0.22).set_trans(Tween.TRANS_LINEAR)
	tw.chain().tween_callback(func():
		_show_muzzle_flash = false
		_recoil_offset_x = 0.0
		_target_ratio = 0.0
		liquid_ratio = 0.0
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
	if _status_stacks.size() > 0 or absf(_recoil_offset_x) > 0.0 or _show_muzzle_flash or _target_ratio > 0.0 or liquid_ratio > 0.0:
		queue_redraw()

func _draw() -> void:
	var center_x: float = _recoil_offset_x
	var center_y: float = 0.0

	# 1. Render Cannon Sprite Asset (Crisp native scale: 43.5 x 30.0)
	if CANNON_TEXTURE:
		var sprite_w: float = 43.5
		var sprite_h: float = 30.0
		var sprite_rect := Rect2(center_x - sprite_w * 0.5, center_y - sprite_h * 0.5, sprite_w, sprite_h)
		draw_texture_rect(CANNON_TEXTURE, sprite_rect, false)

	# 2. Render Sleek Cannon Energy Charge Bar Overlay with White Lead Flash & Yellow Catch-Up
	if _target_ratio > 0.0 or liquid_ratio > 0.0:
		var bar_w: float = 54.0
		var bar_h: float = 6.0
		var bar_x: float = center_x - bar_w * 0.5
		var bar_y: float = center_y + 18.0
		var bg_rect := Rect2(bar_x, bar_y, bar_w, bar_h)
		
		# Background Box
		draw_rect(bg_rect, Color("#121722"), true)
		
		# White Lead Flash Bar (instantly jumps to new target level)
		if _target_ratio > 0.0:
			var target_w: float = (bar_w - 2.0) * _target_ratio
			if target_w > 0.0:
				var target_rect := Rect2(bar_x + 1.0, bar_y + 1.0, target_w, bar_h - 2.0)
				draw_rect(target_rect, Color(1.0, 1.0, 1.0, 0.9), true)

		# Primary Yellow Catch-Up Fill Bar (smoothly lerps/catches up to target_ratio)
		if liquid_ratio > 0.0:
			var fill_w: float = (bar_w - 2.0) * liquid_ratio
			if fill_w > 0.0:
				var fill_rect := Rect2(bar_x + 1.0, bar_y + 1.0, fill_w, bar_h - 2.0)
				var fill_col := Color("#d97706").lerp(Color("#ffec99"), liquid_ratio)
				draw_rect(fill_rect, fill_col, true)

		# Outer Border
		draw_rect(bg_rect, Color("#5d7545"), false, 1.0)

	# 3. Cartoon Coffee Fire VFX Muzzle Blast (Lined up against the right side of the sprite)
	if _show_muzzle_flash and FIRE_VFX_TEXTURE:
		var frame_idx: int = clampi(_flash_frame, 0, 15)
		var col: int = frame_idx % 4
		var row: int = frame_idx / 4
		var src_rect := Rect2(col * 1024, row * 1024, 1024, 1024)
		var flash_w: float = 48.0
		var flash_h: float = 48.0
		var muzzle_right_x: float = center_x + 21.75
		var dest_rect := Rect2(muzzle_right_x, center_y - flash_h * 0.5, flash_w, flash_h)
		draw_texture_rect_region(FIRE_VFX_TEXTURE, dest_rect, src_rect, Color(1, 1, 1, 0.95))

	# 4. Status effect overlays (flame, ice, lightning)
	var flame_stacks: int = _status_stacks.get(Constants.STATUS_FIRE, 0)
	var frozen_stacks: int = _status_stacks.get(Constants.STATUS_FROZEN, 0)
	var lightning_stacks: int = _status_stacks.get(Constants.STATUS_LIGHTNING, 0)
	var sz: float = STATUS_OVERLAY_SIZE
	var center := Vector2(center_x, center_y)
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
