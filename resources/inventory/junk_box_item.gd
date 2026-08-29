@tool
extends Resource
class_name JunkBoxItem
## Individual item instance in the Junk Box backpack inventory.

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")

enum ItemType {
	POLYOMINO_MODULE = 0,
	PEG = 1,
	BALL = 2,
	MISC = 3
}

const POLYOMINO_MODULE: int = 0
const PEG: int = 1
const BALL: int = 2
const MISC: int = 3

@export var instance_id: StringName = &""
@export var item_type: int = ItemType.POLYOMINO_MODULE
@export var display_name: String = ""
@export var module_data: PolyominoModuleData = null
@export var custom_payload: Dictionary = {}
@export var grid_position: Vector2i = Vector2i.ZERO
@export var rotation_step: int = 0

func _init(p_instance_id: StringName = &"", p_item_type: int = ItemType.POLYOMINO_MODULE) -> void:
	if p_instance_id != &"":
		instance_id = p_instance_id
	else:
		instance_id = StringName("item_%d_%d" % [Time.get_ticks_usec(), randi() % 1000000])
	item_type = p_item_type

## Returns the item's local cell footprint rotated by rotation_step and anchored at (0, 0).
func get_local_cells() -> Array[Vector2i]:
	if module_data != null and not module_data.cells.is_empty():
		return module_data.get_anchored_rotated_cells(rotation_step)
	return [Vector2i.ZERO]

## Returns absolute grid cells occupied by this item based on grid_position and rotation_step.
func get_occupied_cells() -> Array[Vector2i]:
	var local_cells: Array[Vector2i] = get_local_cells()
	var occupied: Array[Vector2i] = []
	for c in local_cells:
		occupied.append(c + grid_position)
	return occupied

## Rotates the item 90 degrees clockwise.
func rotate_clockwise() -> void:
	rotation_step = (rotation_step + 1) % 4

func serialize() -> Dictionary:
	return {
		"instance_id": str(instance_id),
		"item_type": item_type,
		"display_name": display_name,
		"grid_position": [grid_position.x, grid_position.y],
		"rotation_step": rotation_step,
		"module_data": module_data.serialize() if module_data != null else {},
		"custom_payload": custom_payload.duplicate(true),
	}

static func deserialize(dict: Dictionary) -> Resource:
	var script: GDScript = load("res://resources/inventory/junk_box_item.gd") as GDScript
	var item = script.new(StringName(dict.get("instance_id", "")))
	item.item_type = int(dict.get("item_type", ItemType.POLYOMINO_MODULE))
	item.display_name = str(dict.get("display_name", ""))

	var pos_raw = dict.get("grid_position", [0, 0])
	if pos_raw is Array and pos_raw.size() >= 2:
		item.grid_position = Vector2i(int(pos_raw[0]), int(pos_raw[1]))
	elif pos_raw is Vector2i:
		item.grid_position = pos_raw
	else:
		item.grid_position = Vector2i.ZERO

	item.rotation_step = int(dict.get("rotation_step", 0))

	var mod_dict = dict.get("module_data", {})
	if mod_dict is Dictionary and not mod_dict.is_empty():
		var mod := PolyominoModuleData.new()
		mod.deserialize(mod_dict)
		item.module_data = mod
	else:
		item.module_data = null

	var payload = dict.get("custom_payload", {})
	if payload is Dictionary:
		item.custom_payload = payload.duplicate(true)

	return item
