extends "res://tests/test_base.gd"
const DB = preload("res://resources/polyomino/polyomino_relic_database.gd")
const Item = preload("res://resources/inventory/junk_box_item.gd")
const Names = preload("res://resources/polyomino/relic_names.gd")

func _init() -> void:
	suite_name = "RelicNames"

## Run all tests
func run() -> void:
	_test_names()
	_test_saved_names()
	_test_coverage()
	_test_fallbacks()
	_test_reward_words()
	_test_title_widths()

func _test_names() -> void:
	begin("Catalog names are distinct and consistent")
	var seen: Dictionary = {} ## title -> bool
	for id: String in Names.NAMES:
		var item: Resource = DB.create_item_for_relic(StringName(id))
		assert_eq(item.display_name, Names.NAMES[id])
		assert_eq(item.module_data.display_name, item.display_name)
		assert_eq(item.display_name.split(" ", false).size(), 2)
		assert_false(seen.has(item.display_name))
		seen[item.display_name] = true

func _test_saved_names() -> void:
	begin("Old saved names resolve without changing relic identity")
	for id: String in Names.NAMES:
		var item: Resource = DB.create_item_for_relic(StringName(id))
		var saved: Dictionary = item.serialize()
		saved["display_name"] = "Old title"
		saved["module_data"]["display_name"] = "Old title"
		var restored: Resource = Item.deserialize(saved)
		assert_eq(restored.display_name, Names.NAMES[id])
		assert_eq(restored.module_data.display_name, Names.NAMES[id])
		assert_eq(restored.module_data.module_id, item.module_data.module_id)
		assert_eq(restored.module_data.cells, item.module_data.cells)
		assert_eq(restored.module_data.reward_description, item.module_data.reward_description)

func _test_coverage() -> void:
	begin("Every catalog ID has a two-word name")
	assert_eq(Names.NAMES.size(), DB.get_all_relic_ids().size())
	for id: StringName in DB.get_all_relic_ids():
		assert_true(Names.NAMES.has(str(id)), str(id))

func _test_fallbacks() -> void:
	begin("Aliases and unknown names retain identity")
	assert_eq(Names.resolve(&"chain_surge_wrench", "old"), Names.resolve(&"arc_surge_wrench", "old"))
	assert_eq(Names.resolve(&"unknown", "Custom Device"), "Custom Device")
	var item: Resource = Item.new(&"custom", Item.POLYOMINO_MODULE)
	item.display_name = "Custom Device"
	assert_eq(Item.deserialize(item.serialize()).display_name, "Custom Device")
	item.custom_payload = {"relic_id": "bumper_vessel_twin"}
	assert_eq(Item.deserialize(item.serialize()).display_name, "Bouncy Bumpers")
	item.custom_payload["is_debug_showcase"] = true
	assert_eq(Item.deserialize(item.serialize()).display_name, "Custom Device")
	item.item_type = Item.PEG
	item.custom_payload.erase("is_debug_showcase")
	assert_eq(Item.deserialize(item.serialize()).display_name, "Custom Device")

func _test_reward_words() -> void:
	begin("Each reward word represents one ball type and count")
	var expected: Dictionary = {"Iron": ["Plain", 3], "Teeming": ["Plain", 6], "Swarming": ["Plain", 12], "Bouncy": ["Rubbery", 1], "Springy": ["Rubbery", 4], "Irrepressible": ["Rubbery", 10], "Charged": ["Energize", 1], "Surging": ["Energize", 3], "Explosive": ["Explosive", 1], "Cataclysmic": ["Explosive", 3], "Crackling": ["Chain Lightning", 1], "Thundering": ["Chain Lightning", 3], "Splitting": ["Split", 1], "Splintering": ["Split", 2], "Shattering": ["Split", 4], "Binary": ["Binary", 1]} ## adjective -> type and count
	for id: StringName in DB.get_offerable_relic_ids():
		var item: Resource = DB.create_item_for_relic(id)
		var word: String = item.display_name.get_slice(" ", 0)
		assert_true(expected.has(word), word)
		if not expected.has(word):
			continue
		assert_eq(item.module_data.relic_ball_reward.ball_type, expected[word][0])
		assert_eq(item.module_data.relic_ball_reward.count, expected[word][1])

func _test_title_widths() -> void:
	begin("Each word fits the existing Merchant and reward title widths")
	var font: Font = ThemeDB.fallback_font
	for id: String in Names.NAMES:
		var title: String = Names.NAMES[id]
		for word: String in title.split(" ", false):
			assert_true(font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x <= 136.0, title)
			assert_true(font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x <= 180.0, title)
