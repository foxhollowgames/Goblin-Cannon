extends "res://tests/test_base.gd"

const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const PolyominoFusionSystemScript = preload("res://resources/polyomino/polyomino_fusion_system.gd")

func _init() -> void:
	suite_name = "TetrominoModuleFusion"

func run() -> void:
	test_same_tier_fusion_eligibility()
	test_recipe_blueprint_fusion()
	test_tier_upgraded_fusion_output()

func test_same_tier_fusion_eligibility() -> void:
	begin("Two modules of identical tier are eligible for fusion")
	var mod_a := PolyominoModuleData.new()
	mod_a.module_id = &"mod_a"
	mod_a.tier = 1
	mod_a.cells = [Vector2i(0, 0)]

	var item_a := JunkBoxItem.new(&"mod_a", JunkBoxItem.POLYOMINO_MODULE)
	item_a.module_data = mod_a

	var mod_b := PolyominoModuleData.new()
	mod_b.module_id = &"mod_b"
	mod_b.tier = 1
	mod_b.cells = [Vector2i(0, 1)]

	var item_b := JunkBoxItem.new(&"mod_b", JunkBoxItem.POLYOMINO_MODULE)
	item_b.module_data = mod_b

	assert_true(PolyominoFusionSystemScript.can_fuse(item_a, item_b), "same tier items can fuse")

func test_recipe_blueprint_fusion() -> void:
	begin("Bumper + Accelerator fuses into Lightning Dynamo recipe blueprint")
	var mod_a := PolyominoModuleData.new()
	mod_a.module_id = &"item_bumper"
	mod_a.tier = 1
	mod_a.cells = [Vector2i(0, 0)]

	var item_a := JunkBoxItem.new(&"item_bumper", JunkBoxItem.POLYOMINO_MODULE)
	item_a.module_data = mod_a

	var mod_b := PolyominoModuleData.new()
	mod_b.module_id = &"item_accelerator"
	mod_b.tier = 2
	mod_b.cells = [Vector2i(1, 0)]

	var item_b := JunkBoxItem.new(&"item_accelerator", JunkBoxItem.POLYOMINO_MODULE)
	item_b.module_data = mod_b

	assert_true(PolyominoFusionSystemScript.can_fuse(item_a, item_b), "recipe blueprint allows different tier fusion")

	var fused: JunkBoxItem = PolyominoFusionSystemScript.fuse_modules(item_a, item_b)
	assert_true(fused != null, "fused item is created")
	assert_eq(fused.module_data.module_id, &"item_lightning_dynamo", "recipe output is item_lightning_dynamo")

func test_tier_upgraded_fusion_output() -> void:
	begin("Fusing two tier 1 modules produces a tier 2 combined module")
	var mod_a := PolyominoModuleData.new()
	mod_a.module_id = &"item_basic"
	mod_a.tier = 1
	mod_a.cells = [Vector2i(0, 0)]

	var item_a := JunkBoxItem.new(&"item_basic", JunkBoxItem.POLYOMINO_MODULE)
	item_a.module_data = mod_a

	var mod_b := PolyominoModuleData.new()
	mod_b.module_id = &"item_basic"
	mod_b.tier = 1
	mod_b.cells = [Vector2i(1, 0)]

	var item_b := JunkBoxItem.new(&"item_basic", JunkBoxItem.POLYOMINO_MODULE)
	item_b.module_data = mod_b

	var fused: JunkBoxItem = PolyominoFusionSystemScript.fuse_modules(item_a, item_b)
	assert_true(fused != null, "fused item created")
	assert_eq(fused.module_data.tier, 2, "fused module tier is 2")
	assert_eq(fused.module_data.cells.size(), 2, "fused module combines cell geometries")
