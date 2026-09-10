extends "res://tests/test_base.gd"

const RelicTierVisuals = preload("res://scenes/ui/relic_tier_visuals.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoModuleNode = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const RelicLayoutPreview = preload("res://scenes/rewards/relic_layout_preview.gd")
const MajorUpgradeDefinition = preload("res://resources/rewards/major_upgrade_definition.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")

func _init() -> void:
	suite_name = "RelicTierVisualStyling"

func run() -> void:
	test_tier_colors_and_styles()
	test_all_database_relics_map_to_valid_tier_styles()
	test_relic_layout_preview_tier_styling()
	test_draft_card_tier_styling_and_marker()
	test_draft_card_hover_restores_tier_border()
	test_polyomino_module_node_and_junk_box_tier_propagation()

func test_tier_colors_and_styles() -> void:
	begin("RelicTierVisuals defines distinct colors and styles for tiers 1 through 5")

	var colors: Array[Color] = []
	for t in range(1, 6):
		var col: Color = RelicTierVisuals.get_tier_color(t)
		assert_true(col.a > 0.0, "Tier %d has positive alpha" % t)
		var style: Dictionary = RelicTierVisuals.get_tier_style(t)
		assert_true(not style.is_empty(), "Tier %d returns non-empty style dictionary" % t)
		assert_true(style.has("accent_color"), "Tier %d has accent_color" % t)
		assert_true(style.has("highlight_color"), "Tier %d has highlight_color" % t)
		assert_true(style.has("border_width"), "Tier %d has border_width" % t)
		assert_true(style.has("ink_border_width"), "Tier %d has ink_border_width" % t)
		assert_true(style.has("corner_accent_type"), "Tier %d has corner_accent_type" % t)
		assert_true(style.has("badge_shape"), "Tier %d has badge_shape" % t)
		assert_gt(float(style["border_width"]), 0.0, "Tier %d border_width is positive" % t)
		colors.append(col)

	# Assert tiers 1, 2, 3 have distinct colors
	assert_neq(colors[0], colors[1], "Tier 1 and Tier 2 colors are distinct")
	assert_neq(colors[1], colors[2], "Tier 2 and Tier 3 colors are distinct")
	assert_neq(colors[0], colors[2], "Tier 1 and Tier 3 colors are distinct")

	# Assert corner accent progression
	assert_eq(String(RelicTierVisuals.get_tier_style(1)["corner_accent_type"]), "none", "Tier 1 has no corner accents")
	assert_eq(String(RelicTierVisuals.get_tier_style(2)["corner_accent_type"]), "bracket", "Tier 2 has bracket corner accents")
	assert_eq(String(RelicTierVisuals.get_tier_style(3)["corner_accent_type"]), "diamond", "Tier 3 has diamond corner accents")

func test_all_database_relics_map_to_valid_tier_styles() -> void:
	begin("All relics in PolyominoRelicDatabase map to valid tier styles")

	var all_ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	assert_gt(all_ids.size(), 0, "Relic database contains items")

	for id in all_ids:
		var tier: int = PolyominoRelicDatabase.get_relic_tier(id)
		assert_true(tier >= 1 and tier <= 5, "Relic '%s' has tier between 1 and 5 (%d)" % [id, tier])
		var style: Dictionary = RelicTierVisuals.get_tier_style(tier)
		assert_true(not style.is_empty(), "Relic '%s' tier %d maps to valid style" % [id, tier])
		var mod: PolyominoModuleData = PolyominoRelicDatabase.create_module_for_relic(id)
		assert_true(mod != null, "Module created for '%s'" % id)
		if mod != null:
			assert_eq(mod.tier, tier, "Module tier matches database tier for '%s'" % id)

func test_relic_layout_preview_tier_styling() -> void:
	begin("RelicLayoutPreview updates accent_color from RelicTierVisuals")

	var preview: RelicLayoutPreview = RelicLayoutPreview.new()
	preview.size = Vector2(180, 80)

	# Test with Tier 1 relic
	var t1_success: bool = preview.setup_for_relic(&"overdrive_hits")
	assert_true(t1_success, "Setup succeeded for overdrive_hits (Tier 1)")
	var expected_t1_col: Color = RelicTierVisuals.get_tier_color(1)
	assert_eq(preview.accent_color, expected_t1_col, "Preview accent color matches Tier 1 color")

	# Test with Tier 3 boss relic
	var t3_success: bool = preview.setup_for_relic(&"cascade_reactor")
	assert_true(t3_success, "Setup succeeded for cascade_reactor (Tier 3)")
	var expected_t3_col: Color = RelicTierVisuals.get_tier_color(3)
	assert_eq(preview.accent_color, expected_t3_col, "Preview accent color matches Tier 3 color")

	preview.free()

func test_draft_card_tier_styling_and_marker() -> void:
	begin("MajorUpgradeDraftPanel styles draft cards with tier borders and markers")

	var panel_scene: PackedScene = load("res://scenes/rewards/major_upgrade_draft_panel.tscn") as PackedScene
	assert_true(panel_scene != null, "Draft panel scene loaded")
	var panel: Control = panel_scene.instantiate() as Control
	assert_true(panel != null, "Draft panel instantiated")

	var relic_upgrade: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	relic_upgrade.upgrade_id = &"cascade_reactor"
	relic_upgrade.display_name = "Cascade Reactor"
	relic_upgrade.description = "Test description."

	var card: Control = panel._make_card(relic_upgrade, 0)
	assert_true(card != null, "Draft card created")

	# Verify panel stylebox border color matches Tier 3 accent color
	var style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
	assert_true(style != null, "Card has StyleBoxFlat panel style")
	if style != null:
		var expected_col: Color = RelicTierVisuals.get_tier_color(3)
		assert_eq(style.border_color, expected_col, "Card border matches Tier 3 accent color")

	# Verify card hierarchy contains rarity shape marker
	var vbox: VBoxContainer = null
	for child in card.get_children():
		if child is VBoxContainer:
			vbox = child
			break

	assert_true(vbox != null, "Card contains VBoxContainer")
	if vbox != null:
		var has_marker: bool = false
		for child in vbox.get_children():
			if child is CenterContainer and child.get_child_count() > 0:
				var sub = child.get_child(0)
				if sub is RarityShapeMarker:
					has_marker = true
					assert_eq(sub.shape_color, style.border_color, "Marker shape color matches card border")
					break
		assert_true(has_marker, "Card contains RarityShapeMarker for relic upgrade")

	card.free()
	panel.free()

func test_draft_card_hover_restores_tier_border() -> void:
	begin("Draft card mouse_exited restores relic tier border color")

	var panel_scene: PackedScene = load("res://scenes/rewards/major_upgrade_draft_panel.tscn") as PackedScene
	var panel: Control = panel_scene.instantiate() as Control

	var relic_upgrade: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	relic_upgrade.upgrade_id = &"cascade_reactor"
	relic_upgrade.display_name = "Cascade Reactor"

	var card: Control = panel._make_card(relic_upgrade, 0)
	var style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
	var expected_col: Color = RelicTierVisuals.get_tier_color(3)
	assert_eq(style.border_color, expected_col, "Initial border color matches Tier 3")

	card.mouse_entered.emit()
	assert_eq(style.border_color, Color(1.0, 0.85, 0.35, 1.0), "Hover sets gold border highlight")

	card.mouse_exited.emit()
	assert_eq(style.border_color, expected_col, "Mouse exit restores Tier 3 border color")

	card.free()
	panel.free()

func test_polyomino_module_node_and_junk_box_tier_propagation() -> void:
	begin("PolyominoModuleNode and JunkBoxItem propagate tier color on setup")

	var t1_item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"overdrive_hits")
	assert_true(t1_item != null, "Created JunkBoxItem for overdrive_hits")
	assert_eq(t1_item.module_data.tier, 1, "overdrive_hits is Tier 1")

	var node1: PolyominoModuleNode = PolyominoModuleNode.new()
	node1.setup_module(t1_item, Vector2i(2, 2), 0)
	assert_eq(node1._accent_color, RelicTierVisuals.get_tier_color(1), "PolyominoModuleNode has Tier 1 accent color")
	node1.free()

	var t3_item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(&"cascade_reactor")
	assert_true(t3_item != null, "Created JunkBoxItem for cascade_reactor")
	assert_eq(t3_item.module_data.tier, 3, "cascade_reactor is Tier 3")

	var node3: PolyominoModuleNode = PolyominoModuleNode.new()
	node3.setup_module(t3_item, Vector2i(4, 4), 0)
	assert_eq(node3._accent_color, RelicTierVisuals.get_tier_color(3), "PolyominoModuleNode has Tier 3 accent color")
	node3.free()
