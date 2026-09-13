extends PolyominoMachineryComponent
class_name SlingshotKicker
## Triangular slingshot bumper that crackles with electricity as it charges and detonates on full charge.

signal triangle_detonated(triangle_node: Node, origin_pos: Vector2, ball: Node)

@export var hits_to_detonate: int = 3
@export var current_charge: int = 0
@export var is_triangle_bumper: bool = true
@export var detonation_bonus_energy: int = 80

var _lightning_points: PackedVector2Array = []
var _lightning_timer: float = 0.0

func configure_segment(p1: Vector2, p2: Vector2, kick_dir: Vector2 = Vector2.ZERO) -> void:
	shape_type = ShapeType.SEGMENT
	segment_p1 = p1
	segment_p2 = p2
	if kick_dir != Vector2.ZERO:
		direction = kick_dir.normalized()
	component_radius = p1.distance_to(p2) * 0.5 + 10.0
	_refresh_lightning()
	queue_redraw()

func configure_corner(size_px: Vector2 = Vector2(78.0, 84.0), kick_dir: Vector2 = Vector2(1, -1)) -> void:
	var half_w: float = size_px.x * 0.5
	var half_h: float = size_px.y * 0.5
	configure_segment(Vector2(-half_w, half_h), Vector2(half_w, -half_h), kick_dir)

func configure_footprint(cell_count: int) -> void:
	if cell_count >= 3:
		configure_corner(Vector2(78.0, 84.0), Vector2(1, -1))
		base_energy = 12
		impulse_strength = 520.0
		hits_to_detonate = 4
	else:
		configure_segment(Vector2(-36.0, 36.0), Vector2(36.0, -36.0), Vector2(0, -1))
		base_energy = 8
		impulse_strength = 460.0
		hits_to_detonate = 3

func _init() -> void:
	is_permeable = false
	component_radius = 35.0
	base_energy = 6
	impulse_strength = 480.0
	cell_type = PolyominoModuleData.CellType.SLINGSHOT
	shape_type = ShapeType.SEGMENT
	segment_p1 = Vector2(-36.0, 36.0)
	segment_p2 = Vector2(36.0, -36.0)

func _ready() -> void:
	is_permeable = false
	set_process(true)
	super._ready()

func _compute_impulse(_ball: Node) -> Vector2:
	if shape_type == ShapeType.SEGMENT:
		var seg_vec: Vector2 = segment_p2 - segment_p1
		if seg_vec.length_squared() > 0.01:
			var normal: Vector2 = Vector2(-seg_vec.y, seg_vec.x).normalized()
			if direction != Vector2.ZERO and normal.dot(direction) < 0.0:
				normal = -normal
			return normal * impulse_strength
	var kick_dir: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	return kick_dir * impulse_strength

func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	var res: Dictionary = super.trigger_activation(ball, sim_tick)
	if res.get("activated", false):
		current_charge += 1
		_refresh_lightning()
		if current_charge >= hits_to_detonate:
			_detonate_explosion(ball)
		queue_redraw()
	return res

func _detonate_explosion(ball: Node) -> void:
	var my_p: Vector2 = global_position if is_inside_tree() else position
	triangle_detonated.emit(self, my_p, ball)
	if is_instance_valid(ball) and ball.has_method("add_peg_energy") and detonation_bonus_energy > 0:
		ball.add_peg_energy(detonation_bonus_energy)
	current_charge = 0
	_lightning_points.clear()

func _process(delta: float) -> void:
	super._process(delta)
	if current_charge > 0:
		_lightning_timer -= delta
		if _lightning_timer <= 0.0:
			_lightning_timer = randf_range(0.04, 0.09)
			_refresh_lightning()
			queue_redraw()

func _refresh_lightning() -> void:
	_lightning_points.clear()
	if current_charge <= 0:
		return
	var p1: Vector2 = segment_p1
	var p2: Vector2 = segment_p2
	var seg_vec: Vector2 = p2 - p1
	var seg_len: float = seg_vec.length()
	if seg_len < 1.0:
		return
	var normal: Vector2 = Vector2(-seg_vec.y, seg_vec.x).normalized()
	var steps: int = maxi(5, int(seg_len / 12.0))
	var amp: float = 4.0 + float(current_charge) * 2.5
	_lightning_points.append(p1)
	for i in range(1, steps):
		var t: float = float(i) / float(steps)
		var base_pt: Vector2 = p1.lerp(p2, t)
		var jitter: float = randf_range(-amp, amp)
		_lightning_points.append(base_pt + normal * jitter)
	_lightning_points.append(p2)

func get_crackle_line_count() -> int:
	return _lightning_points.size()

func _draw_component_body() -> void:
	var p1: Vector2 = segment_p1
	var p2: Vector2 = segment_p2
	var p3: Vector2 = Vector2(p1.x, p2.y)

	if is_triangle_bumper:
		var tri: PackedVector2Array = [p1, p3, p2]
		draw_colored_polygon(tri, Color(0.08, 0.08, 0.12))
		var frame_col: Color = Color(0.95, 0.95, 0.95)
		draw_line(p1, p3, frame_col, 4.0)
		draw_line(p3, p2, frame_col, 4.0)
		draw_line(p1, p2, frame_col, 3.5)

		if current_charge > 0:
			var cyan_glow: Color = Color(0.2, 0.75, 1.0, 0.4 + 0.15 * float(current_charge))
			draw_line(p1, p3, cyan_glow, 2.0)
			draw_line(p3, p2, cyan_glow, 2.0)
			draw_line(p1, p2, cyan_glow, 2.5)

		draw_circle(p1, 5.0, Color(0.95, 0.95, 0.95))
		draw_circle(p2, 5.0, Color(0.95, 0.95, 0.95))
		draw_circle(p3, 5.0, Color(0.95, 0.95, 0.95))
	else:
		draw_circle(p1, 6.0, Color(0.95, 0.95, 0.95))
		draw_circle(p2, 6.0, Color(0.95, 0.95, 0.95))
		draw_line(p1, p2, Color(0.95, 0.95, 0.95), 3.5)

	if current_charge > 0 and _lightning_points.size() >= 2:
		var glow_w: float = 2.0 + float(current_charge) * 1.0
		var outer_col: Color = Color(0.2, 0.75, 1.0, 0.85)
		var inner_col: Color = Color(0.85, 0.95, 1.0, 0.95)
		for i in range(_lightning_points.size() - 1):
			draw_line(_lightning_points[i], _lightning_points[i + 1], outer_col, glow_w)
			draw_line(_lightning_points[i], _lightning_points[i + 1], inner_col, 1.5)
