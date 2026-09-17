extends PolyominoMachineryComponent
class_name RolloverSwitch

signal switch_state_changed(switch_node: RolloverSwitch, is_lit: bool)

@export var is_lit: bool = false
@export var bank_id: StringName = &"bank_1"
@export var letter: String = ""
@export var switch_energy_bonus: int = 10

func _init() -> void:
	is_permeable = true
	component_radius = 14.0
	base_energy = 3
	cell_type = PolyominoModuleData.CellType.ROLLOVER_SWITCH

func _ready() -> void:
	is_permeable = true
	component_radius = 14.0
	base_energy = 3
	cell_type = PolyominoModuleData.CellType.ROLLOVER_SWITCH
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
	var was_unlit: bool = not is_lit
	set_lit(true)
	var granted_energy: int = base_energy
	if was_unlit:
		granted_energy += switch_energy_bonus
	var orig_base: int = base_energy
	base_energy = granted_energy
	var res: Dictionary = super.trigger_activation(ball, sim_tick)
	base_energy = orig_base
	return res

func _draw_component_body() -> void:
	var r: float = component_radius * _spring_scale.x
	var fill_col: Color = Color(1.0, 0.9, 0.2) if is_lit else Color(0.25, 0.25, 0.35)
	var border_col: Color = Color(1.0, 0.95, 0.5) if is_lit else _accent_color
	draw_circle(Vector2.ZERO, r, fill_col)
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, border_col, 2.5 if is_lit else 1.5)
	if not letter.is_empty():
		var font: Font = ThemeDB.fallback_font
		var f_col: Color = Color(1.0, 1.0, 1.0) if is_lit else Color(0.65, 0.68, 0.75)
		draw_string(font, Vector2(-4.0, 5.0), letter, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, f_col)
