extends "res://tests/test_base.gd"
## Checks completion names in factories, saved items, and visible banners.

const DB = preload("res://resources/polyomino/polyomino_relic_database.gd")
const Item = preload("res://resources/inventory/junk_box_item.gd")
const Names = preload("res://resources/polyomino/relic_names.gd")
const ModuleNode = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const OLD_NAMES: Dictionary = { ## String relic ID -> old goal title.
	"crown_ricochet": "Crown Ricochet",
	"ghost_trail": "Ghost Trail",
	"word_bank_bam": "B-A-M Word Bank",
	"funneled_spinner_dual": "Pulse Spinner",
}

func _init() -> void:
	suite_name = "RelicGoalNames"

## Checks migrated names and preserved custom goal titles.
func run() -> void:
	_test_titles()
	_test_fallbacks()

func _test_titles() -> void:
	begin("Factories and saved items show the new completion names")
	for id: String in OLD_NAMES:
		var item: Resource = DB.create_item_for_relic(StringName(id))
		var expected: String = DB.get_relic_display_name(StringName(id))
		assert_eq(item.module_data.goal_title, expected)
		assert_eq(DB.get_relic_goal_title(StringName(id)), expected)
		var saved: Dictionary = item.serialize() ## String field -> saved value.
		saved["module_data"]["goal_title"] = OLD_NAMES[id]
		var restored: Resource = Item.deserialize(saved)
		assert_eq(restored.module_data.goal_title, expected)
		assert_eq(restored.module_data.serialize(), item.module_data.serialize())
		_check_banner(restored.module_data, expected)
		saved["module_data"]["goal_title"] = "Custom Goal"
		assert_eq(Item.deserialize(saved).module_data.goal_title, "Custom Goal")

func _check_banner(module: Resource, expected: String) -> void:
	var node: Node2D = ModuleNode.new()
	node.module_data = module
	Engine.get_main_loop().root.add_child(node)
	node._trigger_goal_completion(null)
	assert_eq(node._floating_banner_text, expected.to_upper())
	node.free()

func _test_fallbacks() -> void:
	begin("Unrelated goal text remains unchanged")
	for id: String in OLD_NAMES:
		assert_eq(Names.resolve_goal_title(StringName(id), ""), "")
		assert_eq(Names.resolve_goal_title(&"unknown", OLD_NAMES[id]), OLD_NAMES[id])
		var current: String = Names.resolve(StringName(id), "")
		assert_eq(Names.resolve_goal_title(StringName(id), current), current)
	var item: Resource = DB.create_item_for_relic(&"bumper_vessel_twin")
	assert_eq(Item.deserialize(item.serialize()).module_data.goal_title, item.module_data.goal_title)
