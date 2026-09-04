extends PolyominoMachineryComponent
class_name SlingshotKicker

func configure_segment(p1: Vector2, p2: Vector2, kick_dir: Vector2 = Vector2.ZERO) -> void:
	shape_type = ShapeType.SEGMENT
	segment_p1 = p1
	segment_p2 = p2
	if kick_dir != Vector2.ZERO:
		direction = kick_dir.normalized()
	component_radius = p1.distance_to(p2) * 0.5 + 10.0
	queue_redraw()

func configure_corner(size_px: Vector2 = Vector2(78.0, 84.0), kick_dir: Vector2 = Vector2(1, -1)) -> void:
	# Diagonal hypotenuse spanning a corner footprint
	var half_w: float = size_px.x * 0.5
	var half_h: float = size_px.y * 0.5
	configure_segment(Vector2(-half_w, half_h), Vector2(half_w, -half_h), kick_dir)

func configure_footprint(cell_count: int) -> void:
	if cell_count >= 3:
		configure_corner(Vector2(78.0, 84.0), Vector2(1, -1))
		base_energy = 12
		impulse_strength = 520.0
	else:
		configure_segment(Vector2(-36.0, 36.0), Vector2(36.0, -36.0), Vector2(0, -1))
		base_energy = 8
		impulse_strength = 460.0

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

func _draw_component_body() -> void:
	if shape_type == ShapeType.SEGMENT:
		var vib_offset: Vector2 = Vector2.ZERO
		if _spring_scale != Vector2.ONE:
			vib_offset = Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
		# Draw terminal mounting posts
		draw_circle(segment_p1, 7.0, Color(0.25, 0.25, 0.3))
		draw_circle(segment_p1, 4.0, _accent_color)
		draw_circle(segment_p2, 7.0, Color(0.25, 0.25, 0.3))
		draw_circle(segment_p2, 4.0, _accent_color)
		# Draw elastic rubber band
		draw_line(segment_p1, segment_p2 + vib_offset, Color(0.1, 0.1, 0.1), 5.0)
		draw_line(segment_p1, segment_p2 + vib_offset, _accent_color, 2.5)
	else:
		super._draw_component_body()
