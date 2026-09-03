extends PolyominoMachineryComponent
class_name DropTarget

signal target_dropped(target_node: DropTarget)

@export var is_dropped: bool = false

func _ready() -> void:
	is_permeable = false
	component_radius = 16.0
	base_energy = 5
	super._ready()

func reset_target() -> void:
	is_dropped = false
	is_permeable = false
	_setup_collision()
	queue_redraw()

func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	if is_dropped:
		return {"activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO}
	var res: Dictionary = super.trigger_activation(ball, sim_tick)
	if res.get("activated", false):
		is_dropped = true
		is_permeable = true
		target_dropped.emit(self)
		queue_redraw()
	return res

func _draw_component_body() -> void:
	if is_dropped:
		draw_rect(Rect2(-12, -4, 24, 8), Color(0.2, 0.2, 0.2, 0.5))
	else:
		draw_rect(Rect2(-14, -14, 28, 28), _accent_color)
		draw_rect(Rect2(-12, -12, 24, 24), Color(0.9, 0.9, 0.9))
