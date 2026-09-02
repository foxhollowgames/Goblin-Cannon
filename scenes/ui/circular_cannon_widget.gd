@tool
extends Control
class_name CircularCannonWidget
## Bottom-right circular cannon visual widget with Diablo-style liquid energy fill overlay.

signal cannon_ready_to_fire
signal firing_anim_completed

@export var energy_color: Color = Color("#ffec99")
@export var background_color: Color = Color("#111827")
@export var border_color: Color = Color("#d97706")
@export var cannon_color: Color = Color("#9ca3af")

var current_energy: int = 0
var max_energy: int = 10000
var liquid_ratio: float = 0.0

var _is_firing: bool = false
var _recoil_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	custom_minimum_size = Vector2(100, 100)
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
	tw.tween_property(self, "_recoil_scale", Vector2(1.3, 1.3), 0.1)
	tw.tween_property(self, "_recoil_scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		_is_firing = false
		liquid_ratio = 0.0
		queue_redraw()
		firing_anim_completed.emit()
	)

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.45 * _recoil_scale.x

	# 1. Background Circle
	draw_circle(center, radius, background_color)

	# 2. Rising Liquid Energy Fill (Diablo Mana Orb style)
	if liquid_ratio > 0.0:
		var fill_height: float = radius * 2.0 * liquid_ratio
		var fill_y_min: float = center.y + radius - fill_height
		var points: PackedVector2Array = []
		var steps: int = 36
		for i in range(steps + 1):
			var angle: float = (float(i) / float(steps)) * TAU
			var pt: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
			if pt.y >= fill_y_min:
				points.append(pt)
		if points.size() >= 3:
			draw_colored_polygon(points, energy_color)

	# 3. Cannon Barrel Icon Drawing
	var barrel_w: float = radius * 0.5
	var barrel_h: float = radius * 0.8
	var barrel_rect := Rect2(center.x - barrel_w * 0.5, center.y - barrel_h * 0.5, barrel_w, barrel_h)
	draw_rect(barrel_rect, cannon_color, true)
	draw_rect(barrel_rect, border_color, false, 2.0)

	# 4. Outer Ring Border
	draw_arc(center, radius, 0, TAU, 48, border_color, 3.0, true)
	if _is_firing:
		draw_circle(center, radius * 0.6, Color(1, 1, 1, 0.7))
