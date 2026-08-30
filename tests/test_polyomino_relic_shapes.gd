class_name TestPolyominoRelicShapes
extends RefCounted
## Unit tests for TASK-024 polyomino relic shapes, tiers, rotations, and data definitions.

const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")

var suite_name: String = "PolyominoRelicShapes"
var passed: int = 0
var failed: int = 0
var errors: Array[String] = []

func _assert(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		errors.append(message)

func run() -> void:
	test_database_completeness()
	test_relic_tiers_and_cell_counts()
	test_relic_empty_cells_present()
	test_relic_rotation_anchoring()
	test_relic_bounding_boxes()
	test_relic_cell_types_and_machinery()
	test_relic_serialization()
	test_junk_box_item_creation_and_insertion()

func test_database_completeness() -> void:
	var ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	_assert(ids.size() == 81, "Expected exactly 81 relic definitions in database, got %d" % ids.size())

	for id in ids:
		_assert(PolyominoRelicDatabase.has_relic_definition(id), "Database must acknowledge definition for '%s'" % str(id))
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(id)
		_assert(mod != null, "create_module_for_relic must return valid module for '%s'" % str(id))
		if mod != null:
			_assert(mod.module_id == id, "Module ID '%s' should match relic ID '%s'" % [str(mod.module_id), str(id)])
			_assert(not mod.display_name.is_empty(), "Relic '%s' must have a display name" % str(id))
			_assert(mod.cells.size() > 0, "Relic '%s' must have at least one cell" % str(id))

	# Test alias resolution
	_assert(PolyominoRelicDatabase.has_relic_definition(&"chain_surge_wrench"), "Alias chain_surge_wrench must be recognized")
	var alias_mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(&"chain_surge_wrench")
	_assert(alias_mod != null and alias_mod.module_id == &"arc_surge_wrench", "Alias must resolve to canonical arc_surge_wrench module")

func test_relic_tiers_and_cell_counts() -> void:
	var ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	for id in ids:
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(id)
		if mod == null:
			continue
		var tier: int = mod.tier
		var count: int = mod.get_cell_count()

		match tier:
			1:
				_assert(count >= 4 and count <= 6, "Tier 1 relic '%s' cell count (%d) must be between 4 and 6" % [str(id), count])
			2:
				_assert(count >= 6 and count <= 9, "Tier 2 relic '%s' cell count (%d) must be between 6 and 9" % [str(id), count])
			3:
				_assert(count >= 9 and count <= 14, "Tier 3 relic '%s' cell count (%d) must be between 9 and 14" % [str(id), count])
			_:
				_assert(false, "Relic '%s' has unexpected tier %d" % [str(id), tier])

func test_relic_empty_cells_present() -> void:
	var ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	for id in ids:
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(id)
		if mod == null:
			continue
		var empty_cells: Array[Vector2i] = mod.get_empty_cells()
		var machine_cells: Array[Vector2i] = mod.get_occupied_machine_cells()
		_assert(empty_cells.size() >= 1, "Relic '%s' must have at least 1 empty playfield cell, got %d" % [str(id), empty_cells.size()])
		_assert(machine_cells.size() >= 1, "Relic '%s' must have at least 1 machine cell, got %d" % [str(id), machine_cells.size()])
		_assert(empty_cells.size() + machine_cells.size() == mod.get_cell_count(), "Empty + machine cells count must equal total cells for '%s'" % str(id))

func test_relic_rotation_anchoring() -> void:
	var ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	for id in ids:
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(id)
		if mod == null:
			continue

		for rot in range(4):
			var anchored: Array[Vector2i] = mod.get_anchored_rotated_cells(rot)
			_assert(anchored.size() == mod.cells.size(), "Rotated cells count must equal original for '%s' rot %d" % [str(id), rot])

			var has_min_x_zero: bool = false
			var has_min_y_zero: bool = false
			var all_non_negative: bool = true

			for c in anchored:
				if c.x < 0 or c.y < 0:
					all_non_negative = false
				if c.x == 0:
					has_min_x_zero = true
				if c.y == 0:
					has_min_y_zero = true

			_assert(all_non_negative, "Rotated cell coordinates for '%s' rot %d must be non-negative" % [str(id), rot])
			_assert(has_min_x_zero, "Rotated cell coordinates for '%s' rot %d must have min_x == 0" % [str(id), rot])
			_assert(has_min_y_zero, "Rotated cell coordinates for '%s' rot %d must have min_y == 0" % [str(id), rot])

func test_relic_bounding_boxes() -> void:
	var ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	for id in ids:
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(id)
		if mod == null:
			continue
		var bb: Rect2i = mod.get_bounding_box()
		_assert(bb.size.x >= 1 and bb.size.y >= 1, "Bounding box size must be >= 1 for '%s'" % str(id))

		if mod.tier == 3:
			_assert(bb.size.x <= 4 and bb.size.y <= 4, "Tier 3 boss relic '%s' bounding box must fit within 4x4 (got %dx%d)" % [str(id), bb.size.x, bb.size.y])

func test_relic_cell_types_and_machinery() -> void:
	var ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	for id in ids:
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(id)
		if mod == null:
			continue

		for cell in mod.cells:
			var t: int = mod.get_cell_type_at(cell)
			_assert(t >= 0 and t <= 7, "Cell type (%d) at (%d,%d) in '%s' must be valid CellType enum" % [t, cell.x, cell.y, str(id)])
			var energy: int = mod.get_cell_energy_value(cell)
			_assert(energy >= 0, "Energy value at (%d,%d) in '%s' must be >= 0" % [cell.x, cell.y, str(id)])

func test_relic_serialization() -> void:
	var ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	for id in ids:
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(id)
		if mod == null:
			continue
		var dict: Dictionary = mod.serialize()
		var restored := PolyominoModuleData.new()
		restored.deserialize(dict)

		_assert(restored.module_id == mod.module_id, "Serialized module_id mismatch for '%s'" % str(id))
		_assert(restored.tier == mod.tier, "Serialized tier mismatch for '%s'" % str(id))
		_assert(restored.cells.size() == mod.cells.size(), "Serialized cells size mismatch for '%s'" % str(id))

func test_junk_box_item_creation_and_insertion() -> void:
	var jbox := JunkBoxData.new()
	var ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()

	# Create JunkBoxItem for each relic and test auto-fit
	for i in range(mini(ids.size(), 10)):
		var id: StringName = ids[i]
		var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(id)
		_assert(item != null, "create_item_for_relic must return non-null for '%s'" % str(id))
		if item != null:
			_assert(item.item_type == JunkBoxItem.POLYOMINO_MODULE, "Item type should be POLYOMINO_MODULE for '%s'" % str(id))
			_assert(item.custom_payload.get("relic_id", "") == str(id), "Custom payload should hold relic_id for '%s'" % str(id))
			var placed: bool = jbox.add_item_auto(item)
			_assert(placed, "add_item_auto should place relic '%s' into JunkBoxData" % str(id))

	_assert(jbox.get_item_count() == mini(ids.size(), 10), "JunkBox should contain placed test relics")
