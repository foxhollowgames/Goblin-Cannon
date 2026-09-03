@tool
extends Control
class_name CircularCannonWidget
## Bottom square cannon visual widget with liquid energy fill overlay.

#region Signals
signal cannon_ready_to_fire
signal firing_anim_completed
#endregion

#region Constants
const ScrollingTerrainScript = preload("res://scenes/combat/scrolling_terrain.gd")
const DEFAULT_WIDGET_WIDTH: float = 290.0
const DEFAULT_WIDGET_HEIGHT: float = 184.0
const RECOIL_RUMBLE_INTENSITY: float = 2.5
#endregion

#region Variables
@export var energy_color: Color = Color("#ffec99")
@export var background_color: Color = Color("#121722")
@export var border_color: Color = Color("#5d7545")
@export var cannon_color: Color = Color("#8c929e")
@export var cannon_accent: Color = Color("#d97706")

var current_energy: int = 0
var max_energy: int = 10000
var liquid_ratio: float = 0.0

var _is_firing: bool = false
var _terrain: ScrollingTerrain = null
#endregion

#region Lifecycle Methods
func _ready() -> void:
	custom_minimum_size = Vector2(DEFAULT_WIDGET_WIDTH, DEFAULT_WIDGET_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_init_terrain()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_terrain_size()

func _draw() -> void:
	var box_rect := Rect2(Vector2.ZERO, size)
	if box_rect.size.x <= 0 or box_rect.size.y <= 0:
		return

	# Fallback solid background only when terrain node is not available
	if _terrain == null:
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
#endregion

#region Public Methods
## Sets current and max energy levels, recalculating liquid fill ratio.
func set_energy(p_current: int, p_max: int = 10000) -> void:
	current_energy = maxi(0, p_current)
	max_energy = maxi(1, p_max)
	var new_ratio: float = clampf(float(current_energy) / float(max_energy), 0.0, 1.0)
	if new_ratio >= 1.0 and liquid_ratio < 1.0:
		cannon_ready_to_fire.emit()
	liquid_ratio = new_ratio
	queue_redraw()

## Triggers firing animation sequence, including terrain recoil rumble and liquid drain.
func trigger_firing_anim() -> void:
	_is_firing = true
	if _terrain and _terrain.has_method("trigger_recoil_rumble"):
		_terrain.trigger_recoil_rumble(RECOIL_RUMBLE_INTENSITY)
	var tw: Tween = create_tween()
	tw.tween_property(self, "liquid_ratio", 0.0, 0.2)
	tw.tween_callback(func():
		_is_firing = false
		queue_redraw()
		firing_anim_completed.emit()
	)
	queue_redraw()

## Returns the embedded ScrollingTerrain node reference.
func get_scrolling_terrain() -> ScrollingTerrain:
	return _terrain

## Starts terrain advance scroll sequence across the specified duration and max speed.
func start_advancing(duration: float = 1.4, max_speed: float = 320.0) -> void:
	if _terrain and _terrain.has_method("start_advancing"):
		_terrain.start_advancing(duration, max_speed)

## Decelerates terrain advance scroll smoothly to a halt across the specified duration.
func stop_advancing(duration: float = 1.0) -> void:
	if _terrain and _terrain.has_method("stop_advancing"):
		_terrain.stop_advancing(duration)
#endregion

#region Private Methods
func _init_terrain() -> void:
	_terrain = get_node_or_null("ScrollingTerrain") as ScrollingTerrain
	if _terrain == null:
		_terrain = ScrollingTerrainScript.new() as ScrollingTerrain
		_terrain.name = "ScrollingTerrain"
		_terrain.show_behind_parent = true
		add_child(_terrain)
		move_child(_terrain, 0)
	else:
		_terrain.show_behind_parent = true
	_update_terrain_size()

func _update_terrain_size() -> void:
	if _terrain:
		var w: float = size.x if size.x > 0.0 else DEFAULT_WIDGET_WIDTH
		var h: float = size.y if size.y > 0.0 else DEFAULT_WIDGET_HEIGHT
		_terrain.terrain_width = w
		_terrain.terrain_height = h
		_terrain.queue_redraw()
#endregion
