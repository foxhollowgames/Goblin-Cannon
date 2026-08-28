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

signal arrived

var _start_pos: Vector2 = Vector2.ZERO
var _end_pos: Vector2 = Vector2.ZERO
var _particle_color: Color = Color(MonsterPalette.SWATCH_CREAM().r, MonsterPalette.SWATCH_CREAM().g, MonsterPalette.SWATCH_CREAM().b, 0.95)
var _particles: Array[Control] = []
var _burst_particles: Array[Control] = []
var _tween: Tween
var _arrival_callback: Callable = Callable()
var _custom_particle_count: int = -1
var _is_round: bool = false

## start_pos: ball exit; end_pos: target bar center; particle_color: by alignment (yellow/red/blue); particle_count: optional explicit count; is_round: draw round circle particles.
func setup(start_pos: Vector2, end_pos: Vector2, particle_color: Color, particle_count: int = -1, is_round: bool = false) -> void:
	_start_pos = start_pos
	_end_pos = end_pos
	_particle_color = particle_color
	if particle_count > 0:
		_custom_particle_count = particle_count
	_is_round = is_round

func set_arrival_callback(cb: Callable) -> void:
	_arrival_callback = cb

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_run_burst()

func _create_particle_node(p_size: float, p_color: Color) -> Control:
	if _is_round:
		var node: Control = Control.new()
		node.custom_minimum_size = Vector2(p_size, p_size)
		node.size = Vector2(p_size, p_size)
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var radius: float = p_size * 0.5
		node.draw.connect(func() -> void:
			node.draw_circle(Vector2(radius, radius), radius, p_color)
			node.draw_circle(Vector2(radius, radius), radius * 0.6, p_color.lightened(0.25))
		)
		return node
	else:
		var rect: ColorRect = ColorRect.new()
		rect.size = Vector2(p_size, p_size)
		rect.color = p_color
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return rect

func _get_particle_count() -> int:
	if _custom_particle_count > 0:
		return _custom_particle_count
	return PARTICLE_COUNT

func _get_burst_count() -> int:
	if _custom_particle_count > 0:
		return mini(BURST_COUNT, maxi(_custom_particle_count * 2, 2))
	return BURST_COUNT

func _run_burst() -> void:
	var burst_total: int = _get_burst_count()
	var half: Vector2 = Vector2(BURST_SIZE * 0.5, BURST_SIZE * 0.5)
	for i in burst_total:
		var p: Control = _create_particle_node(BURST_SIZE, _particle_color)
		p.position = _start_pos - half
		add_child(p)
		_burst_particles.append(p)
		var angle: float = randf() * TAU
		var dir: Vector2 = Vector2.from_angle(angle)
		var end_pos_burst: Vector2 = _start_pos + dir * BURST_RADIUS - half
		var t: Tween = create_tween()
		t.set_parallel(true)
		t.tween_property(p, "position", end_pos_burst, BURST_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(p, "modulate:a", 0.0, BURST_DURATION * 0.7).set_delay(BURST_DURATION * 0.3)
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
	var single_particle: bool = _particles.size() == 1
	for i in _particles.size():
		var p: Control = _particles[i] as Control
		var delay: float = 0.0 if single_particle else randf() * 0.12
		_tween.tween_property(p, "position", _end_pos - Vector2(PARTICLE_SIZE * 0.5, PARTICLE_SIZE * 0.5), DURATION).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if p:
			_tween.tween_property(p, "modulate:a", 0.0, DURATION * 0.5).set_delay(delay + DURATION * 0.4)
	_tween.tween_callback(_on_arrived).set_delay(DURATION)
	_tween.tween_callback(_on_particles_done).set_delay(DURATION + 0.15)

func _on_arrived() -> void:
	arrived.emit()
	if _arrival_callback.is_valid():
		_arrival_callback.call()

func _spawn_particles() -> void:
	var particle_total: int = _get_particle_count()
	var half: Vector2 = Vector2(PARTICLE_SIZE * 0.5, PARTICLE_SIZE * 0.5)
	for i in particle_total:
		var p: Control = _create_particle_node(PARTICLE_SIZE, _particle_color)
		var jitter: Vector2 = Vector2.ZERO
		if particle_total > 1:
			jitter = Vector2(randf_range(-6, 6), randf_range(-3, 3))
		p.position = _start_pos + jitter - half
		add_child(p)
		_particles.append(p)

func _on_particles_done() -> void:
	for p in _particles:
		p.queue_free()
	_particles.clear()
	queue_free()
