extends "res://tests/test_base.gd"

const BoardEventPreviewScript: GDScript = preload("res://scenes/board/board_event_preview.gd")
const BuffetTablePreviewScript: GDScript = preload("res://scenes/board/buffet_table_preview.gd")
const BuffetTableBreakScript: GDScript = preload("res://scenes/board/buffet_table_break_effect.gd")
const TreasureChestPreviewScript: GDScript = preload("res://scenes/board/treasure_chest_preview.gd")
const TreasureChestBreakScript: GDScript = preload("res://scenes/board/treasure_chest_break_effect.gd")
const StickySlimePreviewScript: GDScript = preload("res://scenes/board/sticky_slime_preview.gd")
const BlackHolePreviewScript: GDScript = preload("res://scenes/board/black_hole_preview.gd")
const CoinBurstVFXScript: GDScript = preload("res://scenes/board/coin_burst_vfx.gd")

func _init() -> void:
	suite_name = "InterventionVisualEffects"

func run() -> void:
	test_board_event_preview_textures()
	test_buffet_table_preview_and_break_textures()
	test_treasure_chest_preview_and_break_textures()
	test_sticky_slime_and_black_hole_previews()
	test_peg_kind_drawing_assets()
	test_coin_burst_vfx_instantiation()

func test_board_event_preview_textures() -> void:
	begin("BoardEventPreview loads item sprite and animated aura spritesheet")
	assert_true(BoardEventPreviewScript.ITEM_TEXTURE != null, "Merchant item texture is loaded")
	assert_true(BoardEventPreviewScript.AURA_VFX_TEXTURE != null, "Merchant aura VFX spritesheet is loaded")
	var preview: Node2D = BoardEventPreviewScript.new() as Node2D
	preview._ready()
	preview.free()

func test_buffet_table_preview_and_break_textures() -> void:
	begin("Buffet table preview and break effect load food and steam spritesheets")
	assert_true(BuffetTablePreviewScript.FOOD_TEXTURE != null, "Buffet table food texture is loaded")
	assert_true(BuffetTablePreviewScript.STEAM_VFX_TEXTURE != null, "Buffet table steam VFX spritesheet is loaded")
	assert_true(BuffetTableBreakScript.FOOD_BURST_TEXTURE != null, "Buffet break effect food burst texture is loaded")
	assert_true(BuffetTableBreakScript.STEAM_BURST_VFX != null, "Buffet break effect steam burst VFX is loaded")
	var preview: Node2D = BuffetTablePreviewScript.new() as Node2D
	preview.free()
	var break_fx: Node2D = BuffetTableBreakScript.new() as Node2D
	break_fx.free()

func test_treasure_chest_preview_and_break_textures() -> void:
	begin("Treasure chest preview and break effect load chest sprite and sparkle burst VFX")
	assert_true(TreasureChestPreviewScript.CHEST_TEXTURE != null, "Chest preview texture is loaded")
	assert_true(TreasureChestPreviewScript.SPARKLE_VFX_TEXTURE != null, "Chest sparkle VFX spritesheet is loaded")
	assert_true(TreasureChestBreakScript.SPARKLE_BURST_VFX != null, "Chest break sparkle burst VFX is loaded")
	var preview: Node2D = TreasureChestPreviewScript.new() as Node2D
	preview.free()
	var break_fx: Node2D = TreasureChestBreakScript.new() as Node2D
	break_fx.free()

func test_sticky_slime_and_black_hole_previews() -> void:
	begin("Sticky slime loads splat and bubble assets, and black hole loads vortex spritesheet")
	assert_true(StickySlimePreviewScript.SPLAT_TEXTURE != null, "Sticky slime splat texture is loaded")
	assert_true(StickySlimePreviewScript.BUBBLES_VFX_TEXTURE != null, "Sticky slime bubbles VFX is loaded")
	assert_true(BlackHolePreviewScript.VORTEX_VFX_TEXTURE != null, "Black hole vortex VFX is loaded")
	var slime: Node2D = StickySlimePreviewScript.new() as Node2D
	slime.free()
	var hole: Node2D = BlackHolePreviewScript.new() as Node2D
	hole.free()

func test_peg_kind_drawing_assets() -> void:
	begin("PegKindDrawing preloads chest, bag, food, and splat sprite textures")
	assert_true(PegKindDrawing.CHEST_TEXTURE != null, "PegKindDrawing chest texture is loaded")
	assert_true(PegKindDrawing.BAG_TEXTURE != null, "PegKindDrawing bag texture is loaded")
	assert_true(PegKindDrawing.FOOD_TEXTURE != null, "PegKindDrawing food texture is loaded")
	assert_true(PegKindDrawing.SPLAT_TEXTURE != null, "PegKindDrawing splat texture is loaded")

func test_coin_burst_vfx_instantiation() -> void:
	begin("CoinBurstVFX loads textures, sets up coins, and cleans up cleanly")
	assert_true(CoinBurstVFXScript.COIN_TEXTURE != null, "Coin burst coin texture is loaded")
	assert_true(CoinBurstVFXScript.COINS_VFX_TEXTURE != null, "Coin burst spritesheet VFX is loaded")
	var vfx: Node2D = CoinBurstVFXScript.new() as Node2D
	vfx.setup(Vector2(200.0, 300.0))
	var coins: Array = vfx.get("_coins") as Array
	assert_true(coins != null and coins.size() == 14, "Coin burst initializes 14 coin dictionaries")
	vfx.free()
