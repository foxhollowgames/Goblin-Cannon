extends "res://tests/test_base.gd"

const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const RelicLayoutPreview = preload("res://scenes/rewards/relic_layout_preview.gd")
const MajorUpgradeDefinition = preload("res://resources/rewards/major_upgrade_definition.gd")

func _init() -> void:
	suite_name = "RelicSelectionPreview"

func run() -> void:
	test_preview_control_instantiation_and_properties()
	test_all_database_relics_generate_valid_previews()
	test_kinetic_glyph_types_and_directions()
	test_draft_card_construction_with_preview()
	test_draft_card_fallback_without_relic_def()

func test_preview_control_instantiation_and_properties() -> void:
	begin("RelicLayoutPreview control instantiation and properties")
	var preview: RelicLayoutPreview = RelicLayoutPreview.new()
	assert_true(preview != null, "RelicLayoutPreview instantiates successfully")
	assert_eq(preview.mouse_filter, Control.MOUSE_FILTER_PASS, "mouse_filter is MOUSE_FILTER_PASS")
	assert_eq(preview.custom_minimum_size.y, RelicLayoutPreview.DEFAULT_PREVIEW_HEIGHT, "default height is set")
	assert_eq(preview.get_cell_count(), 0, "initial cell count is 0")

	var success: bool = preview.setup_for_relic(&"cascade_reactor")
	assert_true(success, "setup_for_relic returns true for valid relic ID")
	assert_eq(preview.relic_id, &"cascade_reactor", "relic_id matches")
	assert_eq(preview.get_cell_count(), 9, "cascade_reactor has 9 cells")
	assert_true(preview.get_module_data() != null, "get_module_data returns valid data")

	var bounds: Rect2 = preview.get_preview_bounds()
	assert_gt(bounds.size.x, 0.0, "preview bounds width is positive")
	assert_gt(bounds.size.y, 0.0, "preview bounds height is positive")

	preview.clear()
	assert_eq(preview.get_cell_count(), 0, "cell count resets to 0 after clear")
	assert_true(preview.get_module_data() == null, "module_data is null after clear")

	preview.free()

func test_all_database_relics_generate_valid_previews() -> void:
	begin("Every campaign relic in PolyominoRelicDatabase generates a valid preview")
	var all_ids: Array[StringName] = PolyominoRelicDatabase.get_all_relic_ids()
	assert_eq(all_ids.size(), 81, "exactly 81 relic definitions exist")

	var preview: RelicLayoutPreview = RelicLayoutPreview.new()
	preview.size = Vector2(180, 80)

	for id in all_ids:
		var ok: bool = preview.setup_for_relic(id)
		assert_true(ok, "setup_for_relic succeeds for '%s'" % str(id))
		var mod: PolyominoModuleData = preview.get_module_data()
		assert_true(mod != null, "module_data is not null for '%s'" % str(id))
		if mod != null:
			assert_gt(mod.cells.size(), 0, "relic '%s' has at least one cell" % str(id))
			assert_eq(preview.get_cell_count(), mod.cells.size(), "cell count matches for '%s'" % str(id))
			var tier: int = mod.tier
			assert_true(tier >= 1 and tier <= 3, "tier is valid (1..3) for '%s'" % str(id))
			var bounds: Rect2 = preview.get_preview_bounds()
			assert_gt(bounds.size.x, 0.0, "bounds width > 0 for '%s'" % str(id))
			assert_gt(bounds.size.y, 0.0, "bounds height > 0 for '%s'" % str(id))

	preview.free()

func test_kinetic_glyph_types_and_directions() -> void:
	begin("Kinetic glyph types and directional flow definitions")
	var preview: RelicLayoutPreview = RelicLayoutPreview.new()

	# Test Bumper component relic
	preview.setup_for_relic(&"supernova_peg")
	var mod_bumper: PolyominoModuleData = preview.get_module_data()
	assert_true(mod_bumper != null, "supernova_peg module exists")
	var has_bumper: bool = false
	for c in mod_bumper.cells:
		if mod_bumper.get_cell_type_at(c) == PolyominoModuleData.CellType.BUMPER:
			has_bumper = true
	assert_true(has_bumper, "supernova_peg contains bumper cell")

	# Test Accelerator component relic with directional vector
	preview.setup_for_relic(&"hyper_elastic")
	var mod_accel: PolyominoModuleData = preview.get_module_data()
	assert_true(mod_accel != null, "hyper_elastic module exists")
	var has_accel: bool = false
	for c in mod_accel.cells:
		if mod_accel.get_cell_type_at(c) == PolyominoModuleData.CellType.ACCELERATOR:
			has_accel = true
			var dir: Vector2 = mod_accel.get_cell_direction_at(c)
			assert_eq(dir, Vector2.UP, "hyper_elastic accelerator direction is UP")
	assert_true(has_accel, "hyper_elastic contains accelerator cell")

	# Test Funnel component relic
	preview.setup_for_relic(&"perpetual_engine")
	var mod_funnel: PolyominoModuleData = preview.get_module_data()
	assert_true(mod_funnel != null, "perpetual_engine module exists")
	var has_funnel: bool = false
	for c in mod_funnel.cells:
		if mod_funnel.get_cell_type_at(c) == PolyominoModuleData.CellType.FUNNEL:
			has_funnel = true
			var f_dir: Vector2 = mod_funnel.get_cell_direction_at(c)
			assert_eq(f_dir, Vector2.DOWN, "perpetual_engine funnel direction is DOWN")
	assert_true(has_funnel, "perpetual_engine contains funnel cell")

	# Test Rotary Booster component relic
	preview.setup_for_relic(&"storm_of_fragments")
	var mod_booster: PolyominoModuleData = preview.get_module_data()
	assert_true(mod_booster != null, "storm_of_fragments module exists")
	var has_booster: bool = false
	for c in mod_booster.cells:
		if mod_booster.get_cell_type_at(c) == PolyominoModuleData.CellType.ROTARY_BOOSTER:
			has_booster = true
	assert_true(has_booster, "storm_of_fragments contains rotary booster cell")

	# Test Mana Siphon component relic
	preview.setup_for_relic(&"blood_tithe")
	var mod_siphon: PolyominoModuleData = preview.get_module_data()
	assert_true(mod_siphon != null, "blood_tithe module exists")
	var has_siphon: bool = false
	for c in mod_siphon.cells:
		if mod_siphon.get_cell_type_at(c) == PolyominoModuleData.CellType.MANA_SIPHON:
			has_siphon = true
	assert_true(has_siphon, "blood_tithe contains mana siphon cell")

	# Test Directional Deflector component relic
	preview.setup_for_relic(&"shrapnel_split")
	var mod_deflector: PolyominoModuleData = preview.get_module_data()
	assert_true(mod_deflector != null, "shrapnel_split module exists")
	var has_deflector: bool = false
	for c in mod_deflector.cells:
		if mod_deflector.get_cell_type_at(c) == PolyominoModuleData.CellType.DIRECTIONAL_DEFLECTOR:
			has_deflector = true
	assert_true(has_deflector, "shrapnel_split contains directional deflector cell")

	preview.free()

func test_draft_card_construction_with_preview() -> void:
	begin("Major upgrade draft card constructs cleanly with preview attached")
	var panel_scene: PackedScene = load("res://scenes/rewards/major_upgrade_draft_panel.tscn") as PackedScene
	assert_true(panel_scene != null, "major_upgrade_draft_panel.tscn loads")

	var panel: Control = panel_scene.instantiate() as Control
	assert_true(panel != null, "panel instantiates")

	var upgrade: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	upgrade.display_name = "Supernova Peg"
	upgrade.description = "Supernova: Triggers a large explosion."
	upgrade.upgrade_id = &"supernova_peg"

	var card: Control = panel._make_card(upgrade, 0)
	assert_true(card != null, "card created successfully")

	# Inspect card hierarchy
	var vbox: VBoxContainer = null
	for child in card.get_children():
		if child is VBoxContainer:
			vbox = child
			break

	assert_true(vbox != null, "card contains VBoxContainer")
	if vbox != null:
		var title_node: Node = null
		var preview_node: RelicLayoutPreview = null
		var desc_node: RichTextLabel = null

		for child in vbox.get_children():
			if child is Label and child.text == "Supernova Peg":
				title_node = child
			elif child is RelicLayoutPreview:
				preview_node = child
			elif child is RichTextLabel:
				desc_node = child

		assert_true(title_node != null, "title label exists in card")
		assert_true(preview_node != null, "RelicLayoutPreview exists in card")
		assert_true(desc_node != null, "description label exists in card")

		if title_node != null and preview_node != null and desc_node != null:
			var title_idx: int = title_node.get_index()
			var preview_idx: int = preview_node.get_index()
			var desc_idx: int = desc_node.get_index()
			assert_gt(preview_idx, title_idx, "preview is placed after title label")
			assert_lt(preview_idx, desc_idx, "preview is placed before description label")
			assert_eq(preview_node.relic_id, &"supernova_peg", "preview relic_id matches upgrade_id")

	card.free()
	panel.free()

func test_draft_card_fallback_without_relic_def() -> void:
	begin("Draft card without relic definition falls back cleanly")
	var panel_scene: PackedScene = load("res://scenes/rewards/major_upgrade_draft_panel.tscn") as PackedScene
	var panel: Control = panel_scene.instantiate() as Control

	var non_relic_upgrade: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	non_relic_upgrade.display_name = "Generic Upgrade"
	non_relic_upgrade.description = "Generic effect description."
	non_relic_upgrade.upgrade_id = &"non_existent_relic_123"

	var card: Control = panel._make_card(non_relic_upgrade, 0)
	assert_true(card != null, "card created with non-relic upgrade")

	var vbox: VBoxContainer = null
	for child in card.get_children():
		if child is VBoxContainer:
			vbox = child
			break

	assert_true(vbox != null, "card contains VBoxContainer")
	if vbox != null:
		var has_preview: bool = false
		for child in vbox.get_children():
			if child is RelicLayoutPreview:
				has_preview = true
		assert_false(has_preview, "non-relic upgrade card does not instantiate RelicLayoutPreview")

	card.free()
	panel.free()
