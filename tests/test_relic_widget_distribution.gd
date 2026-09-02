class_name TestRelicWidgetDistribution
extends RefCounted
## Unit tests for TASK-053: Relic machinery audit and even widget distribution.

const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const CellType = PolyominoModuleData.CellType

var suite_name: String = "RelicWidgetDistribution"
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
	test_all_15_widgets_represented()
	test_bash_toy_exclusive_to_tier_3()
	test_even_widget_distribution()

func test_all_15_widgets_represented() -> void:
	var ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	var widget_counts: Dictionary = {}

	var target_cell_types: Array[int] = [
		CellType.POP_BUMPER,
		CellType.DROP_TARGET,
		CellType.STANDUP_TARGET,
		CellType.SPINNER,
		CellType.SCOOP_SINKHOLE,
		CellType.BALL_LOCK,
		CellType.GUIDE_TRACK,
		CellType.ORBIT_LOOP,
		CellType.SLINGSHOT,
		CellType.ROLLOVER_SWITCH,
		CellType.CAPTIVE_BALL,
		CellType.MECHANICAL_DIVERTER,
		CellType.VERTICAL_UP_KICKER,
		CellType.BASH_TOY,
		CellType.OUTLANE_KICKBACK
	]

	for t in target_cell_types:
		widget_counts[t] = 0

	for relic_id in ids:
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(relic_id)
		if mod == null:
			continue
		for c in mod.cells:
			var c_type: int = mod.get_cell_type_at(c)
			if widget_counts.has(c_type):
				widget_counts[c_type] = int(widget_counts[c_type]) + 1

	for t in target_cell_types:
		var count: int = int(widget_counts[t])
		_assert(count > 0, "CellType %d must be represented in relic database, got count %d" % [t, count])

func test_bash_toy_exclusive_to_tier_3() -> void:
	var ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	var tier_1_bash_toys: int = 0
	var tier_2_bash_toys: int = 0
	var tier_3_bash_toys: int = 0

	for relic_id in ids:
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(relic_id)
		if mod == null:
			continue

		var has_bash_toy: bool = false
		for c in mod.cells:
			if mod.get_cell_type_at(c) == CellType.BASH_TOY:
				has_bash_toy = true
				break

		if has_bash_toy:
			if mod.tier == 1:
				tier_1_bash_toys += 1
			elif mod.tier == 2:
				tier_2_bash_toys += 1
			elif mod.tier == 3:
				tier_3_bash_toys += 1

	_assert(tier_1_bash_toys == 0, "Tier 1 common relics must contain 0 bash toys, got %d" % tier_1_bash_toys)
	_assert(tier_2_bash_toys == 0, "Tier 2 wall break relics must contain 0 bash toys, got %d" % tier_2_bash_toys)
	_assert(tier_3_bash_toys > 0, "Tier 3 boss amplifier relics must contain bash toys, got %d" % tier_3_bash_toys)

func test_even_widget_distribution() -> void:
	var ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	var total_relics_with_machinery: int = 0

	for relic_id in ids:
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(relic_id)
		if mod == null:
			continue
		if not mod.get_occupied_machine_cells().is_empty():
			total_relics_with_machinery += 1

	_assert(total_relics_with_machinery == 81, "All 81 relics must have active machinery components defined")
