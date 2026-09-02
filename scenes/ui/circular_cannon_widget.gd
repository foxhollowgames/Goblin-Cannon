@tool
extends Control
class_name CircularCannonWidget
## Bottom square cannon visual widget with liquid energy fill overlay.

signal cannon_ready_to_fire
signal firing_anim_completed

@export var energy_color: Color = Color("#ffec99")
@export var background_color: Color = Color("#121722")
@export var border_color: Color = Color("#5d7545")
@export var cannon_color: Color = Color("#8c929e")
@export var cannon_accent: Color = Color("#d97706")

var current_energy: int = 0
var max_energy: int = 10000
var liquid_ratio: float = 0.0

var _is_firing: bool = false
var _recoil_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	custom_minimum_size = Vector2(290, 184)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_energy(p_current: int, p_max: int = 10000) -> void:
	current_energy = maxi(0, p_current)
	max_energy = maxi(1, p_max)
	var new_ratio: float = clampf(float(current_energy) / float(max_energy), 0.0, 1.0)
	if new_ratio >= 1.0 and liquid_ratio < 1.0:
		cannon_ready_to_fire.emit()
	liquid_ratio = new_ratio
	queue_redraw()

func trigger_firing_anim() -> void:
	_is_firing = true
	var tw: Tween = create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_recoil_scale", Vector2(1.15, 1.15), 0.1)
	tw.tween_property(self, "_recoil_scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		_is_firing = false
		liquid_ratio = 0.0
		queue_redraw()
		firing_anim_completed.emit()
	)

func _draw() -> void:
	var box_rect := Rect2(Vector2.ZERO, size)
	if box_rect.size.x <= 0 or box_rect.size.y <= 0:
		return

	# 1. Background Box (Square panel)
	draw_rect(box_rect, background_color, true)

	# 2. Rising Liquid Energy Fill (Square fill from bottom)
	if liquid_ratio > 0.0:
		var fill_h: float = box_rect.size.y * liquid_ratio
		var fill_rect := Rect2(0.0, box_rect.size.y - fill_h, box_rect.size.x, fill_h)
		var fill_col := Color(energy_color.r, energy_color.g, energy_color.b, 0.45)
		draw_rect(fill_rect, fill_col, true)
		# Surface wave line
		var wave_y: float = box_rect.size.y - fill_h
		draw_line(Vector2(0.0, wave_y), Vector2(box_rect.size.x, wave_y), energy_color, 2.0)

	# 3. Cannon Barrel & Base Illustration in center
	var center: Vector2 = box_rect.get_center()
	var base_w: float = 64.0 * _recoil_scale.x
	var base_h: float = 24.0 * _recoil_scale.y
	var barrel_w: float = 28.0 * _recoil_scale.x
	var barrel_h: float = 56.0 * _recoil_scale.y

	# Cannon Carriage / Base
	var carriage_rect := Rect2(center.x - base_w * 0.5, center.y + 10.0, base_w, base_h)
	draw_rect(carriage_rect, Color("#3a2518"), true)
	draw_rect(carriage_rect, border_color, false, 1.5)

	# Cannon Wheels
	var wheel_r: float = 14.0 * _recoil_scale.x
	draw_circle(Vector2(center.x - base_w * 0.4, center.y + 24.0), wheel_r, Color("#26170e"))
	draw_circle(Vector2(center.x + base_w * 0.4, center.y + 24.0), wheel_r, Color("#26170e"))
	draw_arc(Vector2(center.x - base_w * 0.4, center.y + 24.0), wheel_r, 0, TAU, 24, cannon_accent, 1.5)
	draw_arc(Vector2(center.x + base_w * 0.4, center.y + 24.0), wheel_r, 0, TAU, 24, cannon_accent, 1.5)

	# Cannon Barrel
	var barrel_rect := Rect2(center.x - barrel_w * 0.5, center.y - barrel_h * 0.5 - 6.0, barrel_w, barrel_h)
	draw_rect(barrel_rect, cannon_color, true)
	draw_rect(barrel_rect, cannon_accent, false, 2.0)

	# Muzzle Ring at top of barrel
	var muzzle_rect := Rect2(center.x - (barrel_w + 6.0) * 0.5, center.y - barrel_h * 0.5 - 10.0, barrel_w + 6.0, 8.0)
	draw_rect(muzzle_rect, cannon_accent, true)

	# 4. Outer Border
	draw_rect(box_rect, border_color, false, 2.0)

	# 5. Firing animation flash overlay
	if _is_firing:
		draw_rect(box_rect, Color(1, 1, 1, 0.4), true)

