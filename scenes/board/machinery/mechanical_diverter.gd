extends PolyominoMachineryComponent
class_name MechanicalDiverter

signal diverter_toggled(diverter_node: Node, is_open: bool)

@export var is_open: bool = false

func _ready() -> void:
	is_permeable = false
	component_radius = 16.0
	base_energy = 4
	impulse_strength = 260.0
	set_process(true)
	
func set_open(p_open: bool) -> void:
	if is_open != p_open:
		is_open = p_open
		diverter_toggled.emit(self, is_open)

func _compute_impulse(_ball: Node) -> Vector2:
	var dir_norm: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	var perp: Vector2 = Vector2(dir_norm.y, -dir_norm.x) if is_open else Vector2(-dir_norm.y, dir_norm.x)
	return perp * impulse_strength

func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	var result: Dictionary = super.trigger_activation(ball, sim_tick)
	if result.get("activated", false):
		set_open(!is_open)
	return result

func _draw_component_body() -> void:
	var dir_norm: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	var arm_length: float = component_radius * 1.8
	var arm_angle_offset: float = (TAU / 4.0) if is_open else (-TAU / 4.0)
	var arm_pos: Vector2 = dir_norm.rotated(arm_angle_offset) * arm_length
	draw_line(Vector2.ZERO, arm_pos, _accent_color, 3.0)
