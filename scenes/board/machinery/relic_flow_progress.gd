extends RefCounted
## Reads progress from the physical device instead of counting unrelated contacts.

## Returns current progress and its target, or an empty vector for old counters.
static func read(data: Resource, components: Array) -> Vector2i:
	if data.goal_type == 8:
		var lit: int = 0
		var total: int = 0
		for component: Node in components:
			if component.cell_type == 8:
				total += 1
				if component.is_lit: lit += 1
		return Vector2i(lit, total)
	if data.goal_type == 9:
		for component: Node in components:
			if component.cell_type == 14:
				return Vector2i(int(component.spin_velocity), int(component.rpm_trigger_threshold))
	if data.required_widget_type == 11:
		for component: Node in components:
			if component.cell_type == 11:
				return Vector2i(component.retained_balls.size(), component.max_capacity)
	return Vector2i(-1, -1)
