extends Node2D
class_name ScrollingTerrain
## Scrolling terrain ground for the 320x720 right-widget battlefield view.
## Stationary during normal combat; accelerates into rapid downward scroll during wall-break advance.

#region Signals
signal advance_started
signal advance_stopped
#endregion

#region Constants
const TERRAIN_WIDTH: float = 320.0
const TERRAIN_HEIGHT: float = 720.0
const TILE_REPEAT_Y: float = 180.0
const VERGE_WIDTH: float = 40.0
const ROAD_LEFT_X: float = 40.0
const ROAD_WIDTH: float = 240.0
const TRACK_WIDTH: float = 16.0
const LEFT_TRACK_X: float = 85.0
const RIGHT_TRACK_X: float = 219.0
const DEFAULT_ADVANCE_SPEED: float = 320.0
const DEFAULT_RUMBLE_DURATION: float = 0.2
const PEBBLE_RADIUS: float = 2.5
const LINE_WIDTH_BORDER: float = 2.0
const LINE_WIDTH_TUFT: float = 1.5
#endregion

#region Variables
var scroll_speed: float = 0.0
var is_advancing: bool = false
var _scroll_offset_y: float = 0.0
var _rumble_offset: Vector2 = Vector2.ZERO
var _speed_tween: Tween = null
var _rumble_tween: Tween = null

var _detail_pebbles: Array[Vector2] = [
	Vector2(65, 25), Vector2(130, 45), Vector2(185, 15), Vector2(255, 70),
	Vector2(75, 110), Vector2(150, 135), Vector2(245, 155), Vector2(110, 165)
]
var _detail_verge_tufts: Array[Vector2] = [
	Vector2(12, 20), Vector2(28, 65), Vector2(16, 125), Vector2(32, 160),
	Vector2(292, 35), Vector2(308, 80), Vector2(295, 130), Vector2(305, 170)
]
#endregion

#region Lifecycle Methods
func _process(delta: float) -> void:
	var needs_redraw: bool = false
	if not is_zero_approx(scroll_speed):
		_scroll_offset_y = fmod(_scroll_offset_y + scroll_speed * delta, TILE_REPEAT_Y)
		if _scroll_offset_y < 0.0:
			_scroll_offset_y += TILE_REPEAT_Y
		needs_redraw = true
	if _rumble_tween and _rumble_tween.is_valid() and _rumble_tween.is_running():
		needs_redraw = true
	if needs_redraw:
		queue_redraw()

func _draw() -> void:
	draw_set_transform(_rumble_offset, 0.0, Vector2.ONE)
	_draw_roadway_base()
	_draw_repeating_slices()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
#endregion

#region Public Methods
## Sets scroll speed immediately in pixels per second, canceling active speed tweens.
func set_scroll_speed(p_speed: float) -> void:
	if _speed_tween and _speed_tween.is_valid():
		_speed_tween.kill()
	scroll_speed = p_speed
	if not is_zero_approx(scroll_speed):
		queue_redraw()

## Returns current scroll speed.
func get_scroll_speed() -> float:
	return scroll_speed

## Starts advancing downward scroll using a smooth acceleration tween.
func start_advancing(duration: float = 1.4, max_speed: float = DEFAULT_ADVANCE_SPEED) -> void:
	is_advancing = true
	if _speed_tween and _speed_tween.is_valid():
		_speed_tween.kill()
	_speed_tween = create_tween()
	_speed_tween.tween_property(self, "scroll_speed", max_speed, duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	advance_started.emit()

## Decelerates scrolling smoothly to a complete standstill (0.0 px/s).
func stop_advancing(duration: float = 1.0) -> void:
	if _speed_tween and _speed_tween.is_valid():
		_speed_tween.kill()
	_speed_tween = create_tween()
	_speed_tween.tween_property(self, "scroll_speed", 0.0, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_speed_tween.tween_callback(func():
		is_advancing = false
		scroll_speed = 0.0
		advance_stopped.emit()
		queue_redraw()
	)

## Applies a brief ground shudder impulse on cannon firing with active frame redraws.
func trigger_recoil_rumble(intensity: float = 3.0) -> void:
	if _rumble_tween and _rumble_tween.is_valid():
		_rumble_tween.kill()
	_rumble_tween = create_tween()
	_rumble_offset = Vector2(0.0, intensity)
	_rumble_tween.tween_property(self, "_rumble_offset", Vector2.ZERO, DEFAULT_RUMBLE_DURATION) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_rumble_tween.tween_callback(func():
		_rumble_offset = Vector2.ZERO
		queue_redraw()
	)
	queue_redraw()
#endregion

#region Private Methods
func _draw_roadway_base() -> void:
	var c_mud: Color = MonsterPalette.DARK_OLIVE()
	var c_verge: Color = MonsterPalette.FOREST()
	var c_verge_border: Color = MonsterPalette.OLIVE()
	var c_track: Color = MonsterPalette.WARM_BROWN().lerp(c_mud, 0.65)

	# Left and right verges
	draw_rect(Rect2(0, 0, VERGE_WIDTH, TERRAIN_HEIGHT), c_verge, true)
	draw_rect(Rect2(TERRAIN_WIDTH - VERGE_WIDTH, 0, VERGE_WIDTH, TERRAIN_HEIGHT), c_verge, true)
	# Roadway center
	draw_rect(Rect2(ROAD_LEFT_X, 0, ROAD_WIDTH, TERRAIN_HEIGHT), c_mud, true)

	# Road verge boundary edges
	draw_line(Vector2(ROAD_LEFT_X, 0), Vector2(ROAD_LEFT_X, TERRAIN_HEIGHT), c_verge_border, LINE_WIDTH_BORDER)
	draw_line(Vector2(TERRAIN_WIDTH - ROAD_LEFT_X, 0), Vector2(TERRAIN_WIDTH - ROAD_LEFT_X, TERRAIN_HEIGHT), c_verge_border, LINE_WIDTH_BORDER)

	# Cart ruts running along the road
	draw_rect(Rect2(LEFT_TRACK_X, 0, TRACK_WIDTH, TERRAIN_HEIGHT), c_track, true)
	draw_rect(Rect2(RIGHT_TRACK_X, 0, TRACK_WIDTH, TERRAIN_HEIGHT), c_track, true)

func _draw_repeating_slices() -> void:
	var start_y: float = _scroll_offset_y - TILE_REPEAT_Y
	var c_pebble: Color = MonsterPalette.SLATE().lerp(MonsterPalette.TAN(), 0.3)
	var c_grass: Color = MonsterPalette.MINT().lerp(MonsterPalette.FOREST(), 0.5)

	while start_y < TERRAIN_HEIGHT + TILE_REPEAT_Y:
		for pt in _detail_pebbles:
			draw_circle(Vector2(pt.x, start_y + pt.y), PEBBLE_RADIUS, c_pebble)
		for tuft in _detail_verge_tufts:
			draw_line(Vector2(tuft.x - 3, start_y + tuft.y), Vector2(tuft.x + 3, start_y + tuft.y - 4), c_grass, LINE_WIDTH_TUFT)
			draw_line(Vector2(tuft.x, start_y + tuft.y), Vector2(tuft.x, start_y + tuft.y - 5), c_grass, LINE_WIDTH_TUFT)
		start_y += TILE_REPEAT_Y
#endregion
