extends PolyominoMachineryComponent
class_name OutlaneKickback

signal kickback_fired(kickback_node: Node, ball: Node)

@export var is_active: bool = true

func _ready() -> void:
	is_permeable = false
	component_radius = 18.0
	base_energy = 10
	impulse_strength = 550.0
	set_process(true)

func arm_kickback() -> void:
	is_active = true

func _compute_impulse(_ball: Node) -> Vector2:
	var dir_norm: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	return dir_norm * impulse_strength

func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	var result: Dictionary = super.trigger_activation(ball, sim_tick)
	if is_active and result.get("activated", false):
		kickback_fired.emit(self, ball)
		is_active = false
	return result

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	draw_circle(Vector2.ZERO, r, _accent_color.darkened(0.4))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, _accent_color, 2.0)
	
	# Draw outlane plunger pin
	var dir_norm: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	var pin_length: float = component_radius * 1.5
	var pin_width: float = component_radius / 3.0
	var pin_start: Vector2 = -dir_norm * (r + pin_length)
	var pin_end: Vector2 = -dir_norm * r
	draw_line(pin_start, pin_end, _accent_color, pin_width)
