extends PolyominoMachineryComponent
class_name PopBumper


func _init() -> void:
	is_permeable = false
	component_radius = 20.0
	base_energy = 1
	impulse_strength = 450.0
	cell_type = PolyominoModuleData.CellType.POP_BUMPER

func _ready() -> void:
	is_permeable = false
	component_radius = 20.0
	base_energy = 1
	impulse_strength = 450.0
	super._ready()

func _compute_impulse(ball: Node) -> Vector2:
	var ball_pos: Vector2 = (ball.global_position if ball.is_inside_tree() else ball.position) if "position" in ball else Vector2.ZERO
	var my_pos: Vector2 = global_position if is_inside_tree() else position
	var dir: Vector2 = (ball_pos - my_pos).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	return dir * impulse_strength
