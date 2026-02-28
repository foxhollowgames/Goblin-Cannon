extends Control
## When a ball hits the bottom zone: plays a small particle burst at start_pos, then particles flow to end_pos (energy bar).
## Add to UILayer; use screen/viewport coordinates for start_pos and end_pos.

const BURST_COUNT: int = 12
const BURST_DURATION: float = 0.18
const BURST_SIZE: float = 5.0
const BURST_RADIUS: float = 28.0
const PARTICLE_COUNT: int = 18
const PARTICLE_SIZE: float = 6.0
const DURATION: float = 0.7

var _start_pos: Vector2 = Vector2.ZERO
var _end_pos: Vector2 = Vector2.ZERO
var _particle_color: Color = Color(0.95, 0.8, 0.35, 0.95)
var _particles: Array[Control] = []
var _burst_particles: Array[Control] = []
var _tween: Tween

## start_pos: ball exit; end_pos: target bar center; particle_color: by alignment (yellow/red/blue).
func setup(start_pos: Vector2, end_pos: Vector2, particle_color: Color) -> void:
	_start_pos = start_pos
	_end_pos = end_pos
	_particle_color = particle_color

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_run_burst()

func _run_burst() -> void:
	var half: Vector2 = Vector2(BURST_SIZE * 0.5, BURST_SIZE * 0.5)
	for i in BURST_COUNT:
		var rect: ColorRect = ColorRect.new()
		rect.size = Vector2(BURST_SIZE, BURST_SIZE)
		rect.position = _start_pos - half
		rect.color = _particle_color
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_burst_particles.append(rect)
		var angle: float = randf() * TAU
		var dir: Vector2 = Vector2.from_angle(angle)
		var end_pos_burst: Vector2 = _start_pos + dir * BURST_RADIUS - half
		var t: Tween = create_tween()
		t.set_parallel(true)
		t.tween_property(rect, "position", end_pos_burst, BURST_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(rect, "modulate:a", 0.0, BURST_DURATION * 0.7).set_delay(BURST_DURATION * 0.3)
	create_tween().tween_callback(_on_burst_done).set_delay(BURST_DURATION)

func _on_burst_done() -> void:
	for p in _burst_particles:
		if is_instance_valid(p):
			p.queue_free()
	_burst_particles.clear()
	_start_flow_to_bar()

func _start_flow_to_bar() -> void:
	_spawn_particles()
	_tween = create_tween()
	_tween.set_parallel(true)
	for i in _particles.size():
		var p: ColorRect = _particles[i] as ColorRect
		var delay: float = randf() * 0.12
		_tween.tween_property(p, "position", _end_pos - Vector2(PARTICLE_SIZE * 0.5, PARTICLE_SIZE * 0.5), DURATION).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if p:
			_tween.tween_property(p, "modulate:a", 0.0, DURATION * 0.5).set_delay(delay + DURATION * 0.4)
	_tween.tween_callback(_on_particles_done).set_delay(DURATION + 0.15)

func _spawn_particles() -> void:
	for i in PARTICLE_COUNT:
		var rect: ColorRect = ColorRect.new()
		rect.size = Vector2(PARTICLE_SIZE, PARTICLE_SIZE)
		rect.position = _start_pos + Vector2(randf_range(-8, 8), randf_range(-4, 4)) - Vector2(PARTICLE_SIZE * 0.5, PARTICLE_SIZE * 0.5)
		rect.color = _particle_color
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_particles.append(rect)

func _on_particles_done() -> void:
	for p in _particles:
		p.queue_free()
	_particles.clear()
	queue_free()
