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
	tw.tween_property(self, "liquid_ratio", 0.0, 0.2)
	tw.tween_callback(func():
		_is_firing = false
		queue_redraw()
		firing_anim_completed.emit()
	)
	queue_redraw()

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

	# 3. Outer Border
	draw_rect(box_rect, border_color, false, 2.0)
