extends PolyominoMachineryComponent
class_name RolloverSwitch

signal switch_state_changed(switch_node: RolloverSwitch, is_lit: bool)

@export var is_lit: bool = false
@export var bank_id: StringName = &"bank_1"

func _ready() -> void:
	is_permeable = true
	component_radius = 14.0
	base_energy = 3
	super._ready()

func set_lit(p_lit: bool) -> void:
	if is_lit != p_lit:
		is_lit = p_lit
		switch_state_changed.emit(self, is_lit)
		queue_redraw()

func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else ball.get_instance_id()
	if not can_activate_for_ball(bid, sim_tick):
		return { "activated": false, "energy_granted": 0, "impulse_applied": Vector2.ZERO, "type": cell_type }
	set_lit(true)
	return super.trigger_activation(ball, sim_tick)

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	var fill_col: Color = Color(1.0, 0.9, 0.2) if is_lit else Color(0.25, 0.25, 0.35)
	var border_col: Color = Color(1.0, 0.95, 0.5) if is_lit else _accent_color
	draw_circle(Vector2.ZERO, r, fill_col)
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, border_col, 2.5 if is_lit else 1.5)
