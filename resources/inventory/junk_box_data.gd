@tool
extends Resource
class_name JunkBoxData
## Core data and state container for the Junk Box backpack inventory.
## Supports fixed columns with endless vertical expansion (rows >= 0).

const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")

signal inventory_changed
signal item_added(item: JunkBoxItem)
signal item_removed(item: JunkBoxItem)
signal item_moved(item: JunkBoxItem)

const DEFAULT_COLUMNS: int = 8
const DEFAULT_MIN_ROWS: int = 12

@export var grid_columns: int = DEFAULT_COLUMNS
## Dictionary of instance_id (StringName) -> JunkBoxItem
var items: Dictionary = {}
## Dictionary of cell (Vector2i) -> instance_id (StringName)
var occupied_cells: Dictionary = {}

## Returns true if the item can be legally placed at target_pos with specified rotation.
## If rotation is -1, item's current rotation_step is used.
## ignore_instance_id allows checking moves/rotations without colliding with cells occupied by that instance.
func can_place_item(item: JunkBoxItem, target_pos: Vector2i, rotation: int = -1, ignore_instance_id: StringName = &"") -> bool:
	if item == null:
		return false
	if target_pos.y < 0:
		return false

	var rot: int = item.rotation_step if rotation < 0 else posmod(rotation, 4)
	var local_cells: Array[Vector2i] = []
	if item.module_data != null and not item.module_data.cells.is_empty():
		local_cells = item.module_data.get_anchored_rotated_cells(rot)
	else:
		local_cells = [Vector2i.ZERO]

	for c in local_cells:
		var grid_pos := target_pos + c
		if grid_pos.x < 0 or grid_pos.x >= grid_columns:
			return false
		if grid_pos.y < 0:
			return false
		if occupied_cells.has(grid_pos):
			var occ_id: StringName = occupied_cells[grid_pos]
			if ignore_instance_id == &"" or occ_id != ignore_instance_id:
				return false

	return true

## Places an item at target_pos. Updates occupied_cells, registers in items, and emits signals.
func place_item(item: JunkBoxItem, target_pos: Vector2i, rotation: int = -1) -> bool:
	if item == null:
		return false
	if not can_place_item(item, target_pos, rotation, item.instance_id):
		return false

	# Clear previous occupied cells if item is already registered in this inventory
	if items.has(item.instance_id):
		for cell in item.get_occupied_cells():
			if occupied_cells.get(cell) == item.instance_id:
				occupied_cells.erase(cell)

	item.grid_position = target_pos
	if rotation >= 0:
		item.rotation_step = posmod(rotation, 4)

	items[item.instance_id] = item
	for cell in item.get_occupied_cells():
		occupied_cells[cell] = item.instance_id

	item_added.emit(item)
	inventory_changed.emit()
	return true

## Removes an item by instance_id. Clears occupied cells, unregisters from items, and returns the removed item.
func remove_item(instance_id: StringName) -> JunkBoxItem:
	if not items.has(instance_id):
		return null
	var item: JunkBoxItem = items[instance_id]
	for cell in item.get_occupied_cells():
		if occupied_cells.get(cell) == instance_id:
			occupied_cells.erase(cell)
	items.erase(instance_id)
	item_removed.emit(item)
	inventory_changed.emit()
	return item

## Moves an already placed item to a new position and optional new rotation without self-collision.
func move_item(instance_id: StringName, new_pos: Vector2i, new_rotation: int = -1) -> bool:
	if not items.has(instance_id):
		return false
	var item: JunkBoxItem = items[instance_id]
	if not can_place_item(item, new_pos, new_rotation, instance_id):
		return false

	# Remove old cells from grid
	for cell in item.get_occupied_cells():
		if occupied_cells.get(cell) == instance_id:
			occupied_cells.erase(cell)

	item.grid_position = new_pos
	if new_rotation >= 0:
		item.rotation_step = posmod(new_rotation, 4)

	# Register new cells on grid
	for cell in item.get_occupied_cells():
		occupied_cells[cell] = instance_id

	item_moved.emit(item)
	inventory_changed.emit()
	return true

## Returns the item occupying grid_cell, or null.
func get_item_at(grid_cell: Vector2i) -> JunkBoxItem:
	if occupied_cells.has(grid_cell):
		var id: StringName = occupied_cells[grid_cell]
		return items.get(id, null)
	return null

## Returns the maximum row (y index) among all occupied cells, or DEFAULT_MIN_ROWS - 1.
func get_max_row() -> int:
	var max_y: int = DEFAULT_MIN_ROWS - 1
	for cell in occupied_cells:
		if cell.y > max_y:
			max_y = cell.y
	return max_y

## Returns the maximum row (y index) strictly among all occupied cells, or -1 if empty.
func get_max_occupied_row() -> int:
	if occupied_cells.is_empty():
		return -1
	var max_y: int = 0
	for cell in occupied_cells:
		if cell.y > max_y:
			max_y = cell.y
	return max_y

## Finds the first valid (x, y) slot for placing the item scanning y from 0 upwards and x from 0 to grid_columns - 1.
func find_first_available_slot(item: JunkBoxItem, rotation: int = -1) -> Vector2i:
	if item == null:
		return Vector2i(-1, -1)
	var max_scan_y: int = get_max_row() + 10
	var y: int = 0
	while y <= max_scan_y:
		for x in range(grid_columns):
			var slot := Vector2i(x, y)
			if can_place_item(item, slot, rotation, item.instance_id):
				return slot
		y += 1
		if y > max_scan_y:
			max_scan_y += 10
	return Vector2i(-1, -1)

## Automatically finds a slot and places the item.
func add_item_auto(item: JunkBoxItem) -> bool:
	if item == null:
		return false
	var slot := find_first_available_slot(item)
	if slot.x < 0 or slot.y < 0:
		return false
	return place_item(item, slot)

## Sorts items by tier / size descending and compactly repacks them starting at y=0.
func auto_pack() -> void:
	if items.is_empty():
		return

	var item_list: Array[JunkBoxItem] = []
	for it in items.values():
		if it is JunkBoxItem:
			item_list.append(it)

	# Sort descending: Tier (highest first), then cell count (largest first), then instance_id
	item_list.sort_custom(func(a: JunkBoxItem, b: JunkBoxItem) -> bool:
		var tier_a: int = a.module_data.tier if a.module_data != null else 0
		var tier_b: int = b.module_data.tier if b.module_data != null else 0
		if tier_a != tier_b:
			return tier_a > tier_b
		var size_a: int = a.module_data.get_cell_count() if a.module_data != null else 1
		var size_b: int = b.module_data.get_cell_count() if b.module_data != null else 1
		if size_a != size_b:
			return size_a > size_b
		return str(a.instance_id) < str(b.instance_id)
	)

	occupied_cells.clear()

	for item in item_list:
		var slot := find_first_available_slot(item)
		if slot.x >= 0 and slot.y >= 0:
			item.grid_position = slot
			for cell in item.get_occupied_cells():
				occupied_cells[cell] = item.instance_id

	inventory_changed.emit()

func serialize() -> Dictionary:
	var serialized_items: Array = []
	for item in items.values():
		if item is JunkBoxItem:
			serialized_items.append(item.serialize())
	return {
		"grid_columns": grid_columns,
		"items": serialized_items,
	}

func deserialize(dict: Dictionary) -> void:
	items.clear()
	occupied_cells.clear()
	grid_columns = int(dict.get("grid_columns", DEFAULT_COLUMNS))
	var raw_items = dict.get("items", [])
	if raw_items is Array:
		for item_dict in raw_items:
			if item_dict is Dictionary:
				var item: JunkBoxItem = JunkBoxItem.deserialize(item_dict)
				if item != null:
					items[item.instance_id] = item
					for cell in item.get_occupied_cells():
						occupied_cells[cell] = item.instance_id
	inventory_changed.emit()

func clear() -> void:
	items.clear()
	occupied_cells.clear()
	inventory_changed.emit()

func get_all_items() -> Array[JunkBoxItem]:
	var result: Array[JunkBoxItem] = []
	for it in items.values():
		if it is JunkBoxItem:
			result.append(it)
	return result

func get_item_count() -> int:
	return items.size()

func has_item(instance_id: StringName) -> bool:
	return items.has(instance_id)
