@tool
extends Resource
class_name PolyominoModuleData
## Polyomino module shape, kinetic machinery, and metadata definition.

enum CellType {
	EMPTY = 0,
	GUIDE_RAIL = 1,
	FUNNEL = 2,
	BUMPER = 3,
	ACCELERATOR = 4,
	ROTARY_BOOSTER = 5,
	MANA_SIPHON = 6,
	DIRECTIONAL_DEFLECTOR = 7
}

enum EnclosureType {
	OPEN_FRAME = 0,
	FULL_ENCLOSURE = 1,
	DIRECTIONAL_FUNNEL = 2,
	DIVIDED_LANES = 3
}

enum GoalArchetype {
	NONE = 0,
	TARGET_BANK = 1,
	SEQUENCE_ROUTE = 2,
	ORBIT_FLOW = 3,
	SINKHOLE_LOCK = 4,
	JACKPOT_ACCUMULATOR = 5,
	HURRY_UP_FRENZY = 6,
	MULTIBALL_RESERVOIR = 7
}

enum RewardType {
	NONE = 0,
	ENERGY_SURGE = 1,
	BOARD_SUPERCHARGE = 2,
	MULTIBALL_CASCADE = 3,
	GLOBAL_BOARD_KNOCK = 4,
	CONCUSSIVE_OVERDRIVE = 5
}

@export var module_id: StringName = &""
@export var display_name: String = ""
@export var tier: int = 1
## Local cell coordinate offsets before rotation (e.g. [(0,0), (1,0)]).
@export var cells: Array[Vector2i] = []
## Map from cell coordinate (Vector2i) to CellType (int).
@export var cell_types: Dictionary = {}
## Map from cell coordinate (Vector2i) to direction Vector2i or int.
@export var cell_directions: Dictionary = {}
## Map from cell coordinate (Vector2i) to bonus energy amount (int).
@export var energy_values: Dictionary = {}
## Durability for embedded bumpers/machinery (0 = infinite/standard).
@export var bumper_durability: int = 0
## Default or current rotation step (0..3).
@export var rotation_step: int = 0
## Wall enclosure architecture.
@export var enclosure_type: int = EnclosureType.OPEN_FRAME
## Custom wall side overrides per local cell coord: Vector2i -> Array of side strings ("N", "E", "S", "W").
@export var custom_wall_edges: Dictionary = {}

## Pinball goal archetype and reward definition
@export var goal_type: int = GoalArchetype.NONE
@export var reward_type: int = RewardType.NONE
@export var goal_target_sequence: Array[Vector2i] = []
@export var goal_target_count: int = 0
@export var goal_time_limit: float = 0.0
@export var reward_energy: int = 0
@export var reward_ball_count: int = 0
@export var goal_title: String = ""
@export var goal_description: String = ""
@export var reward_description: String = ""

func get_cell_count() -> int:
	return cells.size()

func get_bounding_box() -> Rect2i:
	if cells.is_empty():
		return Rect2i(0, 0, 0, 0)
	var min_p := cells[0]
	var max_p := cells[0]
	for c in cells:
		min_p.x = mini(min_p.x, c.x)
		min_p.y = mini(min_p.y, c.y)
		max_p.x = maxi(max_p.x, c.x)
		max_p.y = maxi(max_p.y, c.y)
	return Rect2i(min_p.x, min_p.y, max_p.x - min_p.x + 1, max_p.y - min_p.y + 1)

## Returns raw rotated cells around origin for given steps (0..3 CW).
func get_rotated_cells(steps: int = 0) -> Array[Vector2i]:
	var s: int = posmod(steps, 4)
	var result: Array[Vector2i] = []
	for c in cells:
		match s:
			0:
				result.append(c)
			1:  # 90 deg CW: (x, y) -> (-y, x)
				result.append(Vector2i(-c.y, c.x))
			2:  # 180 deg CW: (x, y) -> (-x, -y)
				result.append(Vector2i(-c.x, -c.y))
			3:  # 270 deg CW: (x, y) -> (y, -x)
				result.append(Vector2i(c.y, -c.x))
	return result

## Returns rotated cells normalized/anchored so top-left min coordinate is (0,0).
func get_anchored_rotated_cells(steps: int = 0) -> Array[Vector2i]:
	var raw: Array[Vector2i] = get_rotated_cells(steps)
	if raw.is_empty():
		return []
	var min_x: int = raw[0].x
	var min_y: int = raw[0].y
	for c in raw:
		min_x = mini(min_x, c.x)
		min_y = mini(min_y, c.y)
	var offset := Vector2i(min_x, min_y)
	var anchored: Array[Vector2i] = []
	for c in raw:
		anchored.append(c - offset)
	return anchored

func get_cell_type_at(cell: Vector2i) -> int:
	if cell_types.has(cell):
		return int(cell_types[cell])
	var key_str: String = "%d,%d" % [cell.x, cell.y]
	if cell_types.has(key_str):
		return int(cell_types[key_str])
	return CellType.EMPTY

func is_cell_empty(cell: Vector2i) -> bool:
	return get_cell_type_at(cell) == CellType.EMPTY

func get_occupied_machine_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for c in cells:
		if get_cell_type_at(c) != CellType.EMPTY:
			result.append(c)
	return result

func get_empty_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for c in cells:
		if get_cell_type_at(c) == CellType.EMPTY:
			result.append(c)
	return result

func set_cell_type_at(cell: Vector2i, type: int) -> void:
	cell_types[cell] = type

func get_cell_direction_at(cell: Vector2i) -> Vector2:
	var raw_val = null
	if cell_directions.has(cell):
		raw_val = cell_directions[cell]
	else:
		var key_str: String = "%d,%d" % [cell.x, cell.y]
		if cell_directions.has(key_str):
			raw_val = cell_directions[key_str]
	if raw_val is Vector2:
		return raw_val
	elif raw_val is Vector2i:
		return Vector2(raw_val.x, raw_val.y)
	elif raw_val is Array and raw_val.size() >= 2:
		return Vector2(float(raw_val[0]), float(raw_val[1]))
	return Vector2.DOWN

func set_cell_direction_at(cell: Vector2i, dir: Variant) -> void:
	if dir is Vector2:
		cell_directions[cell] = Vector2i(int(round(dir.x)), int(round(dir.y)))
	else:
		cell_directions[cell] = dir

func get_cell_energy_value(cell: Vector2i) -> int:
	if energy_values.has(cell):
		return int(energy_values[cell])
	var key_str: String = "%d,%d" % [cell.x, cell.y]
	if energy_values.has(key_str):
		return int(energy_values[key_str])
	var t: int = get_cell_type_at(cell)
	match t:
		CellType.BUMPER:
			return 5
		CellType.MANA_SIPHON:
			return 8
		CellType.ACCELERATOR, CellType.ROTARY_BOOSTER:
			return 3
		CellType.DIRECTIONAL_DEFLECTOR, CellType.FUNNEL, CellType.GUIDE_RAIL:
			return 2
		_:
			return 0

func set_cell_energy_value(cell: Vector2i, amount: int) -> void:
	energy_values[cell] = amount

static func get_rotated_direction(dir: Vector2, steps: int = 0) -> Vector2:
	var s: int = posmod(steps, 4)
	match s:
		0:
			return dir
		1: # 90 deg CW (x, y) -> (-y, x)
			return Vector2(-dir.y, dir.x)
		2: # 180 deg CW (x, y) -> (-x, -y)
			return Vector2(-dir.x, -dir.y)
		3: # 270 deg CW (x, y) -> (y, -x)
			return Vector2(dir.y, -dir.x)
	return dir

static func rotate_side(side: String, steps: int = 0) -> String:
	var s: int = posmod(steps, 4)
	if s == 0:
		return side
	var order := ["N", "E", "S", "W"]
	var idx: int = order.find(side)
	if idx == -1:
		return side
	return order[(idx + s) % 4]

## Returns Array of Dictionary for edge wall segments in anchored rotated space.
## Each element: { "p1": Vector2, "p2": Vector2, "normal": Vector2, "side": String, "cell": Vector2i, "is_internal": bool }
func get_solid_edge_segments(steps: int = 0) -> Array[Dictionary]:
	var anchored: Array[Vector2i] = get_anchored_rotated_cells(steps)
	if anchored.is_empty():
		return []

	var segments: Array[Dictionary] = []
	var cell_set: Dictionary = {}
	for c in anchored:
		cell_set[c] = true

	var max_x: int = anchored[0].x
	for c in anchored:
		max_x = maxi(max_x, c.x)

	for c in anchored:
		_append_cell_edge_segments(c, steps, cell_set, max_x, segments)

	return segments

func _append_cell_edge_segments(c: Vector2i, steps: int, cell_set: Dictionary, max_x: int, segments: Array[Dictionary]) -> void:
	var has_top: bool = cell_set.has(Vector2i(c.x, c.y - 1))
	var has_bot: bool = cell_set.has(Vector2i(c.x, c.y + 1))
	var has_left: bool = cell_set.has(Vector2i(c.x - 1, c.y))
	var has_right: bool = cell_set.has(Vector2i(c.x + 1, c.y))

	var is_funnel: bool = (enclosure_type == EnclosureType.DIRECTIONAL_FUNNEL)
	var is_full: bool = (enclosure_type == EnclosureType.FULL_ENCLOSURE)
	var is_divided: bool = (enclosure_type == EnclosureType.DIVIDED_LANES)

	var n_solid: bool = (is_full or is_divided) and not has_top
	var s_solid: bool = (is_full or is_divided) and not has_bot
	var w_solid: bool = (is_full or is_divided or is_funnel) and not has_left
	var e_solid: bool = (is_full or is_divided or is_funnel) and not has_right
	var is_internal_e: bool = false
	if is_divided and has_right and c.x < max_x:
		e_solid = true
		is_internal_e = true

	var orig_idx: int = _find_orig_cell_index_for_anchored(c, steps)
	if orig_idx >= 0 and orig_idx < cells.size():
		for cs in _get_custom_sides_for_cell(cells[orig_idx]):
			match rotate_side(cs, steps):
				"N": n_solid = true
				"S": s_solid = true
				"W": w_solid = true
				"E": e_solid = true

	_build_edge_dicts(c, n_solid, s_solid, w_solid, e_solid, is_internal_e, segments)

func _build_edge_dicts(c: Vector2i, n_solid: bool, s_solid: bool, w_solid: bool, e_solid: bool, is_internal_e: bool, segments: Array[Dictionary]) -> void:
	var hw: float = 0.5
	var hh: float = 0.5
	var fx: float = float(c.x)
	var fy: float = float(c.y)

	if n_solid:
		segments.append({"p1": Vector2(fx - hw, fy - hh), "p2": Vector2(fx + hw, fy - hh), "normal": Vector2(0, -1), "side": "N", "cell": c, "is_internal": false})
	if s_solid:
		segments.append({"p1": Vector2(fx - hw, fy + hh), "p2": Vector2(fx + hw, fy + hh), "normal": Vector2(0, 1), "side": "S", "cell": c, "is_internal": false})
	if w_solid:
		segments.append({"p1": Vector2(fx - hw, fy - hh), "p2": Vector2(fx - hw, fy + hh), "normal": Vector2(-1, 0), "side": "W", "cell": c, "is_internal": false})
	if e_solid:
		segments.append({"p1": Vector2(fx + hw, fy - hh), "p2": Vector2(fx + hw, fy + hh), "normal": Vector2(1, 0), "side": "E", "cell": c, "is_internal": is_internal_e})

	return segments

func _find_orig_cell_index_for_anchored(anchored_cell: Vector2i, steps: int) -> int:
	var anchored_list: Array[Vector2i] = get_anchored_rotated_cells(steps)
	for i in range(anchored_list.size()):
		if anchored_list[i] == anchored_cell:
			return i
	return -1

func _get_custom_sides_for_cell(cell: Vector2i) -> Array[String]:
	var raw = null
	if custom_wall_edges.has(cell):
		raw = custom_wall_edges[cell]
	else:
		var key_str: String = "%d,%d" % [cell.x, cell.y]
		if custom_wall_edges.has(key_str):
			raw = custom_wall_edges[key_str]
	var res: Array[String] = []
	if raw is Array:
		for item in raw:
			res.append(str(item))
	return res

func _serialize_custom_wall_edges() -> Dictionary:
	var res: Dictionary = {}
	for k in custom_wall_edges:
		var key_str: String = "%d,%d" % [k.x, k.y] if k is Vector2i else str(k)
		var val = custom_wall_edges[k]
		if val is Array:
			res[key_str] = val
	return res

func serialize() -> Dictionary:
	var serialized_cells: Array = []
	for c in cells:
		serialized_cells.append([c.x, c.y])

	var serialized_types: Dictionary = {}
	for k in cell_types:
		var key_str: String = "%d,%d" % [k.x, k.y] if k is Vector2i else str(k)
		serialized_types[key_str] = int(cell_types[k])

	var serialized_dirs: Dictionary = {}
	for k in cell_directions:
		var key_str: String = "%d,%d" % [k.x, k.y] if k is Vector2i else str(k)
		var val = cell_directions[k]
		if val is Vector2i:
			serialized_dirs[key_str] = [val.x, val.y]
		elif val is Vector2:
			serialized_dirs[key_str] = [val.x, val.y]
		else:
			serialized_dirs[key_str] = val

	var serialized_energies: Dictionary = {}
	for k in energy_values:
		var key_str: String = "%d,%d" % [k.x, k.y] if k is Vector2i else str(k)
		serialized_energies[key_str] = int(energy_values[k])

	var serialized_seq: Array = []
	for s in goal_target_sequence:
		serialized_seq.append([s.x, s.y])

	return {
		"module_id": str(module_id),
		"display_name": display_name,
		"tier": tier,
		"cells": serialized_cells,
		"cell_types": serialized_types,
		"cell_directions": serialized_dirs,
		"energy_values": serialized_energies,
		"bumper_durability": bumper_durability,
		"rotation_step": rotation_step,
		"enclosure_type": enclosure_type,
		"custom_wall_edges": _serialize_custom_wall_edges(),
		"goal_type": goal_type,
		"reward_type": reward_type,
		"goal_target_sequence": serialized_seq,
		"goal_target_count": goal_target_count,
		"goal_time_limit": goal_time_limit,
		"reward_energy": reward_energy,
		"reward_ball_count": reward_ball_count,
		"goal_title": goal_title,
		"goal_description": goal_description,
		"reward_description": reward_description,
	}

func deserialize(dict: Dictionary) -> void:
	module_id = StringName(dict.get("module_id", ""))
	display_name = str(dict.get("display_name", ""))
	tier = int(dict.get("tier", 1))
	bumper_durability = int(dict.get("bumper_durability", 0))
	rotation_step = int(dict.get("rotation_step", 0))
	enclosure_type = int(dict.get("enclosure_type", EnclosureType.OPEN_FRAME))
	goal_type = int(dict.get("goal_type", GoalArchetype.NONE))
	reward_type = int(dict.get("reward_type", RewardType.NONE))
	goal_target_count = int(dict.get("goal_target_count", 0))
	goal_time_limit = float(dict.get("goal_time_limit", 0.0))
	reward_energy = int(dict.get("reward_energy", 0))
	reward_ball_count = int(dict.get("reward_ball_count", 0))
	goal_title = str(dict.get("goal_title", ""))
	goal_description = str(dict.get("goal_description", ""))
	reward_description = str(dict.get("reward_description", ""))

	custom_wall_edges.clear()
	var raw_walls = dict.get("custom_wall_edges", {})
	if raw_walls is Dictionary:
		for k in raw_walls:
			var cell_pos: Vector2i = _parse_vector2i_key(k)
			var val = raw_walls[k]
			if val is Array:
				custom_wall_edges[cell_pos] = val

	goal_target_sequence.clear()
	var raw_seq = dict.get("goal_target_sequence", [])
	if raw_seq is Array:
		for s in raw_seq:
			if s is Vector2i:
				goal_target_sequence.append(s)
			elif s is Array and s.size() >= 2:
				goal_target_sequence.append(Vector2i(int(s[0]), int(s[1])))

	cells.clear()
	var raw_cells = dict.get("cells", [])
	for item in raw_cells:
		if item is Vector2i:
			cells.append(item)
		elif item is Array and item.size() >= 2:
			cells.append(Vector2i(int(item[0]), int(item[1])))

	cell_types.clear()
	var raw_types = dict.get("cell_types", {})
	if raw_types is Dictionary:
		for k in raw_types:
			var cell_pos: Vector2i = _parse_vector2i_key(k)
			cell_types[cell_pos] = int(raw_types[k])

	cell_directions.clear()
	var raw_dirs = dict.get("cell_directions", {})
	if raw_dirs is Dictionary:
		for k in raw_dirs:
			var cell_pos: Vector2i = _parse_vector2i_key(k)
			var v = raw_dirs[k]
			if v is Array and v.size() >= 2:
				cell_directions[cell_pos] = Vector2i(int(v[0]), int(v[1]))
			elif v is Vector2i:
				cell_directions[cell_pos] = v
			else:
				cell_directions[cell_pos] = v

	energy_values.clear()
	var raw_energies = dict.get("energy_values", {})
	if raw_energies is Dictionary:
		for k in raw_energies:
			var cell_pos: Vector2i = _parse_vector2i_key(k)
			energy_values[cell_pos] = int(raw_energies[k])

static func from_dictionary(dict: Dictionary) -> Resource:
	var script: GDScript = load("res://resources/polyomino/polyomino_module_data.gd") as GDScript
	var data = script.new()
	data.deserialize(dict)
	return data

static func _parse_vector2i_key(key: Variant) -> Vector2i:
	if key is Vector2i:
		return key
	if key is String:
		var parts := (key as String).split(",")
		if parts.size() == 2:
			return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i.ZERO
