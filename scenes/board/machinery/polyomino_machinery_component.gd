extends StaticBody2D
class_name PolyominoMachineryComponent
## Base class for internal kinetic machinery sub-components inside polyomino modules.

signal component_activated(component: PolyominoMachineryComponent, ball: Node, energy_granted: int, impulse: Vector2)

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const AudioPitchRandomizer = preload("res://autoloads/audio_pitch_randomizer.gd")
const HIT_COOLDOWN_TICKS: int = 3
const DEFAULT_VOLUME_DB: float = -16.0
const MIN_AUDIO_INTERVAL_MSEC: int = 50
const MIN_PITCH_SCALE: float = 0.95
const MAX_PITCH_SCALE: float = 1.05

enum ShapeType {
	CIRCLE = 0,
	RECTANGLE = 1,
	SEGMENT = 2
}

@export var local_cell: Vector2i = Vector2i.ZERO
@export var cell_type: int = 0
@export var direction: Vector2 = Vector2.DOWN: set = set_direction
@export var base_energy: int = 0
@export var impulse_strength: float = 0.0
@export var is_permeable: bool = false
@export var component_radius: float = 18.0
@export var shape_type: int = ShapeType.CIRCLE
@export var shape_size: Vector2 = Vector2.ZERO
@export var segment_p1: Vector2 = Vector2.ZERO
@export var segment_p2: Vector2 = Vector2.ZERO
@export var footprint_cells: Array[Vector2i] = []

func set_direction(p_dir: Vector2) -> void:
	direction = p_dir
	_update_direction()
	queue_redraw()

func _update_direction() -> void:
	pass

var _last_hit_tick_by_ball: Dictionary = {}  # ball_id (int) -> int (sim_tick)
var _spring_scale: Vector2 = Vector2.ONE
var _spark_progress: float = 1.0  # 1.0 = idle, 0.0 = burst start
var _audio_player: AudioStreamPlayer2D = null
var _audio_stream: AudioStream = null
var _accent_color: Color = Color(1.0, 0.8, 0.2)

func _ready() -> void:
	_setup_collision()
	_setup_audio()
	set_process(true)

func _setup_collision() -> void:
	if is_permeable:
		# Mana siphons and pass-through sensors do not physically block balls
		collision_layer = 0
		collision_mask = 0
		return
	collision_layer = 1
	collision_mask = 1
	var col_shape := CollisionShape2D.new()
	match shape_type:
		ShapeType.RECTANGLE:
			var rect := RectangleShape2D.new()
			rect.size = shape_size if shape_size != Vector2.ZERO else Vector2(component_radius * 2.0, component_radius * 2.0)
			col_shape.shape = rect
		ShapeType.SEGMENT:
			var seg := SegmentShape2D.new()
			seg.a = segment_p1
			seg.b = segment_p2
			col_shape.shape = seg
		_:
			var circle := CircleShape2D.new()
			circle.radius = component_radius
			col_shape.shape = circle
	add_child(col_shape)

func is_multi_cell() -> bool:
	return footprint_cells.size() > 1 or component_radius > 25.0

func check_ball_contact(ball_pos: Vector2, ball_radius: float, base_world_pos: Vector2 = Vector2.ZERO) -> bool:
	var my_pos: Vector2 = global_position if is_inside_tree() else (base_world_pos + position)
	match shape_type:
		ShapeType.SEGMENT:
			var w1: Vector2 = my_pos + segment_p1
			var w2: Vector2 = my_pos + segment_p2
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(ball_pos, w1, w2)
			return ball_pos.distance_squared_to(closest) <= ((ball_radius + 4.0) * (ball_radius + 4.0))
		ShapeType.RECTANGLE:
			var hw: float = shape_size.x * 0.5
			var hh: float = shape_size.y * 0.5
			var local_p: Vector2 = ball_pos - my_pos
			var clamped := Vector2(clampf(local_p.x, -hw, hw), clampf(local_p.y, -hh, hh))
			return local_p.distance_squared_to(clamped) <= ((ball_radius + 4.0) * (ball_radius + 4.0))
		_:
			var hit_dist: float = component_radius + ball_radius + 4.0
			return ball_pos.distance_squared_to(my_pos) <= (hit_dist * hit_dist)

func _setup_audio() -> void:
	if _audio_player != null:
		return
	_audio_player = AudioStreamPlayer2D.new()
	AudioPitchRandomizer.configure_player(_audio_player, &"Machinery", DEFAULT_VOLUME_DB, 1200.0)
	if _audio_stream:
		_audio_player.stream = _audio_stream
	add_child(_audio_player)

func get_audio_player() -> AudioStreamPlayer2D:
	if _audio_player == null:
		_setup_audio()
	return _audio_player

static func reset_audio_throttle() -> void:
	AudioPitchRandomizer.reset_throttle()

func set_audio_stream(stream: AudioStream) -> void:
	_audio_stream = stream
	if _audio_player:
		_audio_player.stream = stream

func set_accent_color(col: Color) -> void:
	_accent_color = col
	queue_redraw()

func can_activate_for_ball(ball_id: int, sim_tick: int) -> bool:
	if not _last_hit_tick_by_ball.has(ball_id):
		return true
	return (sim_tick - _last_hit_tick_by_ball[ball_id]) >= HIT_COOLDOWN_TICKS

func record_activation(ball_id: int, sim_tick: int) -> void:
	_last_hit_tick_by_ball[ball_id] = sim_tick

## Virtual activation method. Override in subclasses for bespoke kinetics.
func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else ball.get_instance_id()
	if not can_activate_for_ball(bid, sim_tick):
		return { "activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO, "type": cell_type }

	record_activation(bid, sim_tick)
	_play_visual_feedback()
	_play_audio_feedback()

	var energy: int = base_energy
	if ball.has_method("add_peg_energy") and energy > 0:
		ball.add_peg_energy(energy)

	var impulse: Vector2 = _compute_impulse(ball)
	if impulse != Vector2.ZERO and "linear_velocity" in ball:
		_apply_ball_impulse(ball, impulse)

	component_activated.emit(self, ball, energy, impulse)
	return {
		"activated": true,
		"energy_granted": energy,
		"impulse_applied": impulse,
		"type": cell_type
	}

func _compute_impulse(_ball: Node) -> Vector2:
	return Vector2.ZERO

func _apply_ball_impulse(ball: Node, impulse: Vector2) -> void:
	if "linear_velocity" in ball:
		ball.linear_velocity += impulse

func _play_visual_feedback() -> void:
	_spring_scale = Vector2(1.35, 0.75)
	_spark_progress = 0.0
	queue_redraw()

func can_play_audio(now_msec: int = -1) -> bool:
	var stream_key: Variant = _audio_stream if _audio_stream else cell_type
	return AudioPitchRandomizer.can_play_audio(stream_key, MIN_AUDIO_INTERVAL_MSEC, now_msec)

func _play_audio_feedback(now_msec: int = -1) -> bool:
	if _audio_player == null:
		_setup_audio()
	var stream_key: Variant = _audio_stream if _audio_stream else cell_type
	if not AudioPitchRandomizer.can_play_audio(stream_key, MIN_AUDIO_INTERVAL_MSEC, now_msec):
		return false
	AudioPitchRandomizer.record_audio_played(stream_key, now_msec)
	if _audio_player:
		_audio_player.pitch_scale = AudioPitchRandomizer.get_randomized_pitch(MIN_PITCH_SCALE, MAX_PITCH_SCALE)
		if _audio_player.stream and is_inside_tree():
			# Protect against headless mode audio exceptions
			if AudioServer.get_output_device_list().size() > 0 or not Engine.is_editor_hint():
				_audio_player.play()
	return true

func _process(delta: float) -> void:
	var needs_redraw: bool = false
	if _spring_scale != Vector2.ONE:
		_spring_scale = _spring_scale.move_toward(Vector2.ONE, delta * 5.0)
		needs_redraw = true
	if _spark_progress < 1.0:
		_spark_progress = minf(1.0, _spark_progress + delta * 3.5)
		needs_redraw = true
	if needs_redraw:
		queue_redraw()

func _draw() -> void:
	_draw_component_body()
	if _spark_progress < 1.0:
		_draw_sparks()

func _draw_component_body() -> void:
	# Base draw: small circle scaled by spring compression
	var r: float = component_radius * _spring_scale.x
	draw_circle(Vector2.ZERO, r, _accent_color.darkened(0.4))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, _accent_color, 2.0)

func _draw_sparks() -> void:
	var t: float = _spark_progress
	var spark_r: float = lerpf(component_radius, component_radius * 2.2, t)
	var alpha: float = (1.0 - t) * 0.8
	var spark_col := Color(_accent_color.r, _accent_color.g, _accent_color.b, alpha)
	draw_arc(Vector2.ZERO, spark_r, 0, TAU, 16, spark_col, 2.0)
	for i in range(6):
		var angle: float = float(i) * (TAU / 6.0) + (t * 0.5)
		var p1: Vector2 = Vector2.from_angle(angle) * (spark_r * 0.7)
		var p2: Vector2 = Vector2.from_angle(angle) * spark_r
		draw_line(p1, p2, spark_col, 2.0)
