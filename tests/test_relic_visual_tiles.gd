extends "res://tests/test_base.gd"

const RewardCardBuilder = preload("res://scenes/rewards/reward_card_builder.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const DeliberateRelicCatalog = preload("res://resources/polyomino/deliberate_relic_catalog.gd")
const RelicLayoutPreview = preload("res://scenes/rewards/relic_layout_preview.gd")
const RewardDraftPanelScript = preload("res://scenes/rewards/reward_draft_panel.gd")
const MilestoneOption = preload("res://resources/rewards/milestone_option.gd")

func _init() -> void:
	suite_name = "RelicVisualTiles"

func run() -> void:
	test_relic_shop_preview_builder()
	test_relic_shop_description_format()
	test_all_deliberate_relics_preview_and_description()
	test_reward_draft_panel_relic_card_structure()
	cleanup()

func test_relic_shop_preview_builder() -> void:
	begin("RewardCardBuilder.make_relic_shop_preview creates centered polyomino preview")
	var preview_holder: Control = RewardCardBuilder.make_relic_shop_preview(&"corner_slingshot", 38.0)
	autofree(preview_holder)
	assert_true(preview_holder != null, "Preview holder is not null")
	assert_eq(preview_holder.custom_minimum_size.y, 38.0, "Holder height matches requested height")
	assert_eq(preview_holder.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Holder ignores mouse events")

	var preview: RelicLayoutPreview = null
	for child in preview_holder.get_children():
		if child is RelicLayoutPreview:
			preview = child as RelicLayoutPreview
			break

	assert_true(preview != null, "Preview child is RelicLayoutPreview")
	if preview:
		assert_true(preview.get_module_data() != null, "Module data is loaded in preview")
		assert_true(preview.cell_size >= 7.0 and preview.cell_size <= 13.0, "Cell size is clamped reasonably")
		assert_eq(preview.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Preview ignores mouse events")

func test_relic_shop_description_format() -> void:
	begin("PolyominoRelicDatabase.get_relic_shop_description contains kinetic, trigger, and effect")
	var desc: String = PolyominoRelicDatabase.get_relic_shop_description(&"word_bank_gob")
	assert_false(desc.is_empty(), "Shop description is not empty")
	assert_true(desc.contains("3 Rollover Switches"), "Contains kinetic device description")
	assert_true(desc.contains("Spell G-O-B"), "Contains trigger condition")
	assert_true(desc.contains("Release 1 Energize ball"), "Contains temporary ball reward effect")
	assert_true(desc.contains("→"), "Contains arrow connector")

func test_all_deliberate_relics_preview_and_description() -> void:
	begin("All 42 deliberate relics have valid shop preview and formatted descriptions")
	var ids: Array[StringName] = DeliberateRelicCatalog.get_all_ids()
	assert_eq(ids.size(), 42, "Exactly 42 deliberate relics in catalog")

	for id in ids:
		var holder: Control = RewardCardBuilder.make_relic_shop_preview(id, 38.0)
		autofree(holder)
		assert_true(holder != null, "Preview holder exists for %s" % id)
		assert_true(holder.get_child_count() > 0, "Preview child exists for %s" % id)

		var desc: String = PolyominoRelicDatabase.get_relic_shop_description(id)
		assert_false(desc.is_empty(), "Shop description non-empty for %s" % id)
		assert_true(desc.contains("→"), "Description has flow arrow for %s" % id)

func test_reward_draft_panel_relic_card_structure() -> void:
	begin("RewardDraftPanel._make_relic_card includes preview tile and concise reward")
	var panel: Control = RewardDraftPanelScript.new() as Control
	autofree(panel)

	var opt: MilestoneOption = MilestoneOption.new()
	opt.option_type = MilestoneOption.Type.RELIC
	opt.relic_id = &"bumper_vessel_twin"
	opt.rarity = 1

	var card: Control = panel._make_relic_card(opt, 0, 15)
	autofree(card)
	assert_true(card != null, "Relic card instantiated cleanly")

	var found_preview: bool = false
	var found_reward_badge: bool = false
	var found_rich_text: bool = false
	var stack: Array = [card]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is RelicLayoutPreview:
			found_preview = true
		if node is Label and (node as Label).text == "Reward: 1 Rubbery":
			found_reward_badge = true
		if node is RichTextLabel:
			found_rich_text = true
		for c in node.get_children():
			stack.append(c)

	assert_true(found_preview, "Relic card contains RelicLayoutPreview tile")
	assert_true(found_reward_badge, "Offerable relic card contains concise reward badge")
	assert_false(found_rich_text, "Offerable relic card omits verbose description")

