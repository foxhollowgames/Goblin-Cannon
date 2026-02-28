extends Node2D
## Draws lightning arcs from peg to peg along a chain (hit peg → nearest → …). Used for Chain Lightning ball.

const DURATION_SEC: float = 0.35
const SEGMENTS_PER_BOLT: int = 12
const BOLT_OFFSET_MAX: float = 8.0

var _positions: Array[Vector2] = []
var _elapsed: float = 0.0
var _seed_offset: float = 0.0

func _ready() -> void:
	_seed_offset = randf() * 1000.0

func setup_chain(global_positions: Array) -> void:
	_positions.clear()
	for p in global_positions:
		if p is Vector2:
			_positions.append(p)
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= DURATION_SEC:
		queue_free()

func _draw() -> void:
	if _positions.size() < 2:
		return
	var alpha: float = 1.0 - clampf(_elapsed / DURATION_SEC, 0.0, 1.0)
	alpha = alpha * alpha
	var core := Color(0.85, 0.95, 1.0, alpha * 0.95)
	var outer := Color(0.4, 0.65, 1.0, alpha * 0.6)
	for i in range(_positions.size() - 1):
		var from_global: Vector2 = _positions[i]
		var to_global: Vector2 = _positions[i + 1]
		var from_local: Vector2 = to_local(from_global)
		var to_local_pos: Vector2 = to_local(to_global)
		_draw_lightning_bolt(from_local, to_local_pos, core, outer)

func _draw_lightning_bolt(from: Vector2, to: Vector2, core_color: Color, outer_color: Color) -> void:
	var diff: Vector2 = to - from
	var len: float = diff.length()
	if len < 1.0:
		return
	var perp: Vector2 = Vector2(-diff.y, diff.x).normalized()
	var points: PackedVector2Array = PackedVector2Array()
	points.append(from)
	var rng := RandomNumberGenerator.new()
	for s in range(1, SEGMENTS_PER_BOLT):
		rng.seed = hash(from) + hash(to) + int(_elapsed * 120.0) + int(_seed_offset) + s
		var t: float = float(s) / float(SEGMENTS_PER_BOLT)
		var base_pt: Vector2 = from + diff * t
		var offset: float = (rng.randf() - 0.5) * 2.0 * BOLT_OFFSET_MAX
		points.append(base_pt + perp * offset)
	points.append(to)
	# Outer thicker bolt
	for j in range(points.size() - 1):
		draw_line(points[j], points[j + 1], outer_color)
	# Core bright bolt
	for j in range(points.size() - 1):
		draw_line(points[j], points[j + 1], core_color)
