extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "AssetPackSprites"

func run() -> void:
	test_wall_visual_textures()
	test_vfx_spritesheet_textures()
	test_ui_pack_textures()
	cleanup()

func test_wall_visual_textures() -> void:
	begin("wall_visual_textures")
	var WallVisualScript = load("res://scenes/combat/wall_visual.gd")
	assert_not_null_val(WallVisualScript, "WallVisual script loads")
	var wall: Node2D = WallVisualScript.new() as Node2D
	autofree(wall)
	assert_not_null_val(wall, "WallVisual instance created")

	if ResourceLoader.exists(WallVisualScript.WALL_TILE_PATH):
		assert_not_null_val(WallVisualScript.WALL_TILE_TEXTURE, "Wall stone tile texture loaded")
	else:
		assert_true(WallVisualScript.WALL_TILE_TEXTURE == null, "Wall stone tile texture gracefully falls back to null when missing")

	if ResourceLoader.exists(WallVisualScript.WALL_CAP_PATH):
		assert_not_null_val(WallVisualScript.WALL_CAP_TEXTURE, "Wall cap battlement texture loaded")
	else:
		assert_true(WallVisualScript.WALL_CAP_TEXTURE == null, "Wall cap battlement texture gracefully falls back to null when missing")

func test_vfx_spritesheet_textures() -> void:
	begin("vfx_spritesheet_textures")
	var ImpactVFXScript = load("res://scenes/combat/wall_impact_vfx.gd")
	assert_not_null_val(ImpactVFXScript, "WallImpactVFX script loads")
	if ResourceLoader.exists(ImpactVFXScript.IMPACT_VFX_PATH):
		assert_not_null_val(ImpactVFXScript.IMPACT_VFX_TEXTURE, "Wall impact VFX spritesheet loaded")
	else:
		assert_true(ImpactVFXScript.IMPACT_VFX_TEXTURE == null, "Wall impact VFX gracefully falls back to null when missing")

	var MuzzleBlastVFXScript = load("res://scenes/combat/muzzle_blast_vfx.gd")
	assert_not_null_val(MuzzleBlastVFXScript, "MuzzleBlastVFX script loads")
	if ResourceLoader.exists(MuzzleBlastVFXScript.BLAST_VFX_PATH):
		assert_not_null_val(MuzzleBlastVFXScript.BLAST_VFX_TEXTURE, "Muzzle blast VFX spritesheet loaded")
	else:
		assert_true(MuzzleBlastVFXScript.BLAST_VFX_TEXTURE == null, "Muzzle blast VFX gracefully falls back to null when missing")

	var impact: Node2D = ImpactVFXScript.new() as Node2D
	autofree(impact)
	impact.setup(Vector2(160, 36))
	assert_not_null_val(impact, "WallImpactVFX instance created")

	var blast: Node2D = MuzzleBlastVFXScript.new() as Node2D
	autofree(blast)
	blast.setup(Vector2(160, 640))
	assert_not_null_val(blast, "MuzzleBlastVFX instance created")

func test_ui_pack_textures() -> void:
	begin("ui_pack_textures")
	var panel_path: String = "res://assets/Kenney Game Assets All-in-1 3.4.0/UI assets/UI Pack - Adventure/PNG/Default/panel_grey_green.png"
	var border_path: String = "res://assets/Kenney Game Assets All-in-1 3.4.0/UI assets/UI Pack - Adventure/PNG/Default/progress_green.png"
	if ResourceLoader.exists(panel_path):
		var panel_tex: Texture2D = load(panel_path) as Texture2D
		assert_not_null_val(panel_tex, "Kenney UI green panel texture loaded")
	else:
		assert_true(true, "Kenney UI green panel optional asset skipped when not present")
	if ResourceLoader.exists(border_path):
		var border_tex: Texture2D = load(border_path) as Texture2D
		assert_not_null_val(border_tex, "Kenney UI progress green texture loaded")
	else:
		assert_true(true, "Kenney UI progress green optional asset skipped when not present")

func assert_not_null_val(val: Variant, msg: String) -> void:
	if val != null:
		passed += 1
	else:
		failed += 1
		errors.append("%s: value was null" % msg)
