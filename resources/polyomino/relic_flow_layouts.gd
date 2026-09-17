@tool
extends RefCounted
## Applies the playable ball-flow contract to catalog modules and old saves.

const Data = preload("res://resources/polyomino/polyomino_module_data.gd")
const C = Data.CellType
const G = Data.GoalArchetype

## Keeps shop definitions and runtime modules on the same physical layout.
static func apply_definition(id: StringName, definition: Dictionary, goal: Dictionary) -> void:
	var data: Resource = Data.new()
	data.module_id = id
	data.tier = definition.tier
	data.cells.assign(definition.cells)
	data.cell_types = definition.cell_types.duplicate()
	data.cell_letters = definition.get("cell_letters", {}).duplicate()
	data.cell_directions = definition.get("cell_directions", {}).duplicate()
	data.enclosure_type = definition.enclosure_type
	data.layout_mode = definition.layout_mode
	data.unified_component_type = definition.unified_component_type
	data.goal_type = goal.get("type", 0)
	data.required_widget_type = goal.get("required_widget", 0)
	data.activation_threshold = goal.get("threshold", 0)
	apply(data)
	goal["threshold"] = data.activation_threshold
	for key: String in ["cells", "cell_types", "cell_letters", "cell_directions", "enclosure_type", "layout_mode", "unified_component_type"]:
		definition[key] = data.get(key)
	if not data.activation_requirement.is_empty():
		goal["activation_req"] = data.activation_requirement
		goal["desc"] = data.activation_requirement
		definition["machinery_desc"] = data.activation_requirement
	if not data.goal_target_sequence.is_empty(): goal["sequence"] = data.goal_target_sequence

## Builds clear passages while preserving relic IDs, effects, and tier values.
static func apply(data: Resource) -> void:
	if data.enclosure_type == Data.EnclosureType.FULL_ENCLOSURE:
		data.enclosure_type = Data.EnclosureType.DIRECTIONAL_FUNNEL
	for cell: Vector2i in data.cell_types:
		if not data.cells.has(cell):
			data.cells.append(cell)
	if data.goal_type == G.ROLLOVER_SPELL:
		_word_bank(data)
	elif data.required_widget_type == C.WIRE_GATE:
		_reservoir(data)
	elif data.goal_type == G.SPINNER_RPM:
		_spinner(data)
	elif String(data.module_id).begins_with("track_"):
		_track(data)
	elif data.goal_type in [G.SEQUENCE_ROUTE, G.ORBIT_FLOW] and data.layout_mode == Data.MachineryLayoutMode.PER_CELL:
		_legacy_route(data)
	elif _is_chamber(data):
		_chamber(data)

static func _legacy_route(data: Resource) -> void:
	var start: Vector2i = data.cells[0]
	var paths: Dictionary = {start: [start]} ## cell -> shortest connected path
	var queue: Array[Vector2i] = [start]
	var longest: Array = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for delta: Vector2i in [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP]:
			var next: Vector2i = cell + delta
			if not data.cells.has(next) or paths.has(next): continue
			var path: Array = paths[cell].duplicate()
			path.append(next)
			paths[next] = path
			queue.append(next)
			if path.size() > longest.size(): longest = path
	if longest.size() < 2: return
	data.goal_target_sequence.assign(longest)
	data.layout_mode = Data.MachineryLayoutMode.UNIFIED
	data.unified_component_type = C.GUIDE_TRACK
	data.cell_types.clear()
	data.enclosure_type = Data.EnclosureType.OPEN_FRAME
	data.custom_wall_edges.clear()
	data.cell_directions.clear()
	data.activation_requirement = "Guide one ball from the entrance through the complete rail to its outlet."

static func _rectangle(data: Resource, width: int, height: int) -> void:
	data.cells.clear()
	for y: int in range(height):
		for x: int in range(width):
			data.cells.append(Vector2i(x, y))
	data.cell_types.clear()
	data.cell_directions.clear()
	data.custom_wall_edges.clear()
	data.layout_mode = Data.MachineryLayoutMode.PER_CELL
	data.unified_component_type = C.EMPTY

static func _word_bank(data: Resource) -> void:
	var letters: Array = data.cell_letters.values()
	if letters.is_empty():
		letters = ["G", "O", "B"]
	_rectangle(data, letters.size(), 3 if data.tier == 3 else 2)
	data.cell_letters.clear()
	for x: int in range(letters.size()):
		data.cell_types[Vector2i(x, 0)] = C.ROLLOVER_SWITCH
		data.cell_letters[Vector2i(x, 0)] = letters[x]
	data.enclosure_type = Data.EnclosureType.DIVIDED_LANES
	data.activation_threshold = letters.size()
	data.activation_requirement = "Light each letter by passing through its lane."

static func _reservoir(data: Resource) -> void:
	_rectangle(data, 2 if data.tier == 1 else 3, 3 if data.tier == 3 else 2)
	data.layout_mode = Data.MachineryLayoutMode.UNIFIED
	data.unified_component_type = C.WIRE_GATE
	data.enclosure_type = Data.EnclosureType.OPEN_FRAME
	data.activation_threshold = clampi(data.activation_threshold, 2, 6)
	data.activation_requirement = "Hold %d balls, then release. Partial fills drain after 6 seconds without the bonus." % data.activation_threshold

static func _spinner(data: Resource) -> void:
	_rectangle(data, 4 if data.tier == 3 else 3, 2 if data.tier == 1 else 3)
	data.cell_types[Vector2i(1, 1)] = C.SPINNER
	data.enclosure_type = Data.EnclosureType.DIRECTIONAL_FUNNEL
	data.activation_requirement = "Feed balls through the spinner to reach its speed mark. Bonus cooldown: 3 seconds."

static func _is_chamber(data: Resource) -> bool:
	return String(data.module_id).begins_with("bumper_vessel_") or data.module_id in [&"pachinko_bumper_vessel", &"cyclone_bounce_vault"]

static func _chamber(data: Resource) -> void:
	var width: int = 2 if data.tier == 1 else (4 if data.tier == 3 else 3)
	_rectangle(data, width, 3)
	data.enclosure_type = Data.EnclosureType.DIRECTIONAL_FUNNEL
	data.cell_types[Vector2i(0, 1)] = data.required_widget_type
	data.cell_types[Vector2i(width - 1, 2 if width == 2 else 1)] = data.required_widget_type
	if width >= 3:
		data.cell_types[Vector2i(1, 2)] = data.required_widget_type
	if width == 4:
		data.cell_types[Vector2i(2, 0)] = data.required_widget_type
	data.activation_requirement = "Make %d bumper hits. Balls leave through the open drain." % data.activation_threshold

static func _track(data: Resource) -> void:
	var paths: Dictionary = { # StringName -> ordered cell path
		&"track_stairs_step": [Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,2)],
		&"track_right_angle": [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)],
		&"track_u_turn": [Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(2,0)],
		&"track_zigzag_chute": [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)],
		&"track_grand_orbit": [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2), Vector2i(3,1), Vector2i(3,0)],
		&"track_cascade_switchback": [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2), Vector2i(3,2), Vector2i(3,1), Vector2i(3,0)]
	}
	if not paths.has(data.module_id):
		return
	data.goal_target_sequence.assign(paths[data.module_id])
	data.cell_types.clear()
	data.layout_mode = Data.MachineryLayoutMode.UNIFIED
	data.unified_component_type = C.GUIDE_TRACK
	data.enclosure_type = Data.EnclosureType.OPEN_FRAME
	data.activation_requirement = "One ball must enter the arrowed mouth, follow the whole track, and leave the outlet."
