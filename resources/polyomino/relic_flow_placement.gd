extends RefCounted
## Detects a neighboring wall directly across a declared passage port.

## Returns false when either device seals the other's entrance or outlet.
static func ports_clear(item: Resource, origin: Vector2i, steps: int, placed: Dictionary, ignore_id: StringName = &"") -> bool:
	if not ("module_data" in item) or item.module_data == null:
		return true
	for id: Variant in placed:
		if id == ignore_id: continue
		var other: Resource = placed[id]
		if other.module_data == null: continue
		if _blocks(item.module_data, origin, steps, other.module_data, other.grid_position, other.rotation_step):
			return false
		if _blocks(other.module_data, other.grid_position, other.rotation_step, item.module_data, origin, steps):
			return false
	return true

static func _blocks(data: Resource, origin: Vector2i, steps: int, other: Resource, other_origin: Vector2i, other_steps: int) -> bool:
	var walls: Array[Dictionary] = other.get_solid_edge_segments(other_steps)
	for port: Dictionary in data.get_flow_ports(steps):
		var midpoint: Vector2 = (port.p1 + port.p2) * 0.5 + Vector2(origin)
		for wall: Dictionary in walls:
			var a: Vector2 = wall.p1 + Vector2(other_origin)
			var b: Vector2 = wall.p2 + Vector2(other_origin)
			if midpoint.distance_to(Geometry2D.get_closest_point_to_segment(midpoint, a, b)) < 0.1:
				return true
	return false
