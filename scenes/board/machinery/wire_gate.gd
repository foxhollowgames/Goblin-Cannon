extends PolyominoMachineryComponent
class_name WireGate

func _ready() -> void:
	is_permeable = true
	component_radius = 16.0
	base_energy = 4
	super._ready()

func trigger_activation(ball: Node, sim_tick: int) -> Dictionary:
	var vel: Vector2 = ball.linear_velocity if "linear_velocity" in ball else Vector2.ZERO
	var dot: float = vel.dot(direction)
	if dot < -0.1:
		if "linear_velocity" in ball:
			ball.linear_velocity = vel.bounce(-direction) * 0.8
		return {"activated": true, "energy_granted": 0, "impulse_applied": -direction * 100.0}
	return super.trigger_activation(ball, sim_tick)

func _compute_impulse(_ball: Node) -> Vector2:
	return direction * 150.0
