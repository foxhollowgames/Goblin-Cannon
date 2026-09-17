@tool
extends RefCounted
## Shared wall and port geometry in cell units.

const SIDES: Array[String] = ["N", "E", "S", "W"]
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

## Returns physical wall edges after rotating the original device.
static func segments(data: Resource, steps: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var offset: Vector2 = _offset(data, steps)
	for cell: Vector2i in data.cells:
		for side: int in range(4):
			if _solid(data, cell, side):
				result.append(_edge(data, cell, side, steps, offset))
	if data.goal_type == 9:
		_append_spinner_funnel(data, steps, offset, result)
	return result

## Returns entrance and exit edges, including explicitly removed walls.
static func ports(data: Resource, steps: int = 0) -> Array[Dictionary]:
	if data.unified_component_type == 17 and data.goal_target_sequence.size() > 1:
		return _track_ports(data, steps)
	var result: Array[Dictionary] = []
	var offset: Vector2 = _offset(data, steps)
	for cell: Vector2i in data.cells:
		for side: int in range(4):
			if data.cells.has(cell + DIRS[side]) or _solid(data, cell, side):
				continue
			var passage: bool = (data.enclosure_type in [2, 3] or data.unified_component_type == 11) and side in [0, 2]
			if not passage and not _overrides(data, cell).has("-" + SIDES[side]):
				continue
			var edge: Dictionary = _edge(data, cell, side, steps, offset)
			edge["kind"] = "entry" if side == 0 else "exit"
			result.append(edge)
	return result

static func _track_ports(data: Resource, steps: int) -> Array[Dictionary]:
	var path: Array = data.goal_target_sequence
	var first: Vector2i = path[0]
	var last: Vector2i = path[-1]
	var end_dir: Vector2i = last - path[-2]
	var offset: Vector2 = _offset(data, steps)
	var entry: Dictionary = _edge(data, first, 0, steps, offset)
	var outlet: Dictionary = _edge(data, last, DIRS.find(end_dir), steps, offset)
	entry["kind"] = "entry"
	outlet["kind"] = "exit"
	return [entry, outlet]

static func _append_spinner_funnel(data: Resource, steps: int, offset: Vector2, result: Array[Dictionary]) -> void:
	var max_x: int = 0
	for cell: Vector2i in data.cells: max_x = maxi(max_x, cell.x)
	for side: int in [0, 1]:
		var start: Vector2 = Vector2(-0.5 if side == 0 else float(max_x) + 0.5, -0.5)
		var finish: Vector2 = Vector2(0.55 if side == 0 else 1.45, 0.65)
		result.append({"p1": rotate_point(start, steps) + offset,
			"p2": rotate_point(finish, steps) + offset, "normal": Vector2.UP,
			"side": "rail", "cell": Vector2i.ZERO, "is_internal": true})

## Rotates a point clockwise in exact quarter turns.
static func rotate_point(point: Vector2, steps: int) -> Vector2:
	for _step: int in range(posmod(steps, 4)):
		point = Vector2(-point.y, point.x)
	return point

static func _offset(data: Resource, steps: int) -> Vector2:
	var minimum: Vector2 = Vector2(INF, INF)
	for cell: Vector2i in data.cells:
		minimum = minimum.min(rotate_point(Vector2(cell), steps))
	return -minimum if not data.cells.is_empty() else Vector2.ZERO

static func _overrides(data: Resource, cell: Vector2i) -> Array:
	return data.custom_wall_edges.get(cell, data.custom_wall_edges.get("%d,%d" % [cell.x, cell.y], []))

static func _solid(data: Resource, cell: Vector2i, side: int) -> bool:
	var exterior: bool = not data.cells.has(cell + DIRS[side])
	var solid: bool = data.enclosure_type == 1 and exterior
	if data.enclosure_type in [2, 3]:
		solid = exterior and side in [1, 3]
	if data.enclosure_type == 3 and side == 1 and not exterior:
		solid = true
	var overrides: Array = _overrides(data, cell)
	if overrides.has(SIDES[side]):
		solid = true
	if overrides.has("-" + SIDES[side]):
		solid = false
	return solid

static func _edge(data: Resource, cell: Vector2i, side: int, steps: int, offset: Vector2) -> Dictionary:
	var normal: Vector2 = Vector2(DIRS[side])
	var tangent: Vector2 = Vector2(-normal.y, normal.x)
	var center: Vector2 = Vector2(cell) + normal * 0.5
	return {
		"p1": rotate_point(center - tangent * 0.5, steps) + offset,
		"p2": rotate_point(center + tangent * 0.5, steps) + offset,
		"normal": rotate_point(normal, steps), "side": SIDES[posmod(side + steps, 4)],
		"cell": Vector2i(rotate_point(Vector2(cell), steps) + offset),
		"is_internal": data.cells.has(cell + DIRS[side])
	}
