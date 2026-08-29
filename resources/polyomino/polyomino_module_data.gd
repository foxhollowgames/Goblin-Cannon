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
	}

func deserialize(dict: Dictionary) -> void:
	module_id = StringName(dict.get("module_id", ""))
	display_name = str(dict.get("display_name", ""))
	tier = int(dict.get("tier", 1))
	bumper_durability = int(dict.get("bumper_durability", 0))
	rotation_step = int(dict.get("rotation_step", 0))

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
