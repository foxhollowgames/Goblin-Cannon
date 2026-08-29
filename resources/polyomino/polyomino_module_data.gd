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
	ROTARY_BOOSTER = 5
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
		else:
			serialized_dirs[key_str] = val

	return {
		"module_id": str(module_id),
		"display_name": display_name,
		"tier": tier,
		"cells": serialized_cells,
		"cell_types": serialized_types,
		"cell_directions": serialized_dirs,
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
