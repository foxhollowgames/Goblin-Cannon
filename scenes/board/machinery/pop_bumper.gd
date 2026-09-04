extends PolyominoMachineryComponent
class_name PopBumper


func configure_footprint(cell_count: int) -> void:
	if cell_count >= 9:
		component_radius = 76.0
		base_energy = 50
		impulse_strength = 850.0
	elif cell_count >= 4:
		component_radius = 48.0
		base_energy = 20
		impulse_strength = 650.0
	else:
		component_radius = 20.0
		base_energy = 1
		impulse_strength = 450.0
	queue_redraw()

func _init() -> void:
	is_permeable = false
	component_radius = 20.0
	base_energy = 1
	impulse_strength = 450.0
	cell_type = PolyominoModuleData.CellType.POP_BUMPER

func _ready() -> void:
	is_permeable = false
	super._ready()

func _compute_impulse(ball: Node) -> Vector2:
	var ball_pos: Vector2 = (ball.global_position if ball.is_inside_tree() else ball.position) if "position" in ball else Vector2.ZERO
	var my_pos: Vector2 = global_position if is_inside_tree() else position
	var dir: Vector2 = (ball_pos - my_pos).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	return dir * impulse_strength

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	# Outer skirt ring
	draw_circle(Vector2.ZERO, r, _accent_color.darkened(0.5))
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, _accent_color, 2.5)
	# Inner wafer ring
	draw_circle(Vector2.ZERO, r * 0.7, Color(0.9, 0.9, 0.95))
	draw_arc(Vector2.ZERO, r * 0.7, 0, TAU, 24, _accent_color.lightened(0.3), 1.5)
	# Central dome cap
	draw_circle(Vector2.ZERO, r * 0.45, _accent_color)
	draw_circle(Vector2.ZERO, r * 0.2, Color.WHITE)
