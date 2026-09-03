extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "AssetPackSprites"

func run() -> void:
	test_wall_visual_textures()
	test_vfx_spritesheet_textures()
	test_ui_pack_textures()
	test_comic_vignette_goblin_textures()
	test_goblin_grab_arm_texture()
	cleanup()

func test_wall_visual_textures() -> void:
	begin("wall_visual_textures")
	var WallVisualScript = load("res://scenes/combat/wall_visual.gd")
	assert_not_null_val(WallVisualScript, "WallVisual script loads")
	var wall: Node2D = WallVisualScript.new() as Node2D
	autofree(wall)
	assert_not_null_val(wall, "WallVisual instance created")
	assert_not_null_val(WallVisualScript.WALL_TILE_TEXTURE, "Wall stone tile texture preloaded")
	assert_not_null_val(WallVisualScript.WALL_CAP_TEXTURE, "Wall cap battlement texture preloaded")

func test_vfx_spritesheet_textures() -> void:
	begin("vfx_spritesheet_textures")
	var ImpactVFXScript = load("res://scenes/combat/wall_impact_vfx.gd")
	assert_not_null_val(ImpactVFXScript, "WallImpactVFX script loads")
	assert_not_null_val(ImpactVFXScript.IMPACT_VFX_TEXTURE, "Wall impact VFX spritesheet loaded")

	var MuzzleBlastVFXScript = load("res://scenes/combat/muzzle_blast_vfx.gd")
	assert_not_null_val(MuzzleBlastVFXScript, "MuzzleBlastVFX script loads")
	assert_not_null_val(MuzzleBlastVFXScript.BLAST_VFX_TEXTURE, "Muzzle blast VFX spritesheet loaded")

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
	var panel_tex: Texture2D = load("res://assets/Kenney Game Assets All-in-1 3.4.0/UI assets/UI Pack - Adventure/PNG/Default/panel_grey_green.png") as Texture2D
	assert_not_null_val(panel_tex, "Kenney UI green panel texture preloaded")
	var border_tex: Texture2D = load("res://assets/Kenney Game Assets All-in-1 3.4.0/UI assets/UI Pack - Adventure/PNG/Default/progress_green.png") as Texture2D
	assert_not_null_val(border_tex, "Kenney UI progress green texture preloaded")

func test_comic_vignette_goblin_textures() -> void:
	begin("comic_vignette_goblin_textures")
	var CVPanelScript = load("res://scenes/ui/comic_vignette_panel.gd")
	assert_not_null_val(CVPanelScript, "ComicVignettePanel script loads")
	assert_not_null_val(CVPanelScript.TEXTURE_FOCUSED, "Focused goblin texture preloaded")
	assert_not_null_val(CVPanelScript.TEXTURE_DETERMINED, "Determined goblin texture preloaded")
	assert_not_null_val(CVPanelScript.TEXTURE_CHEERING, "Cheering goblin texture preloaded")
	assert_not_null_val(CVPanelScript.TEXTURE_ECSTATIC, "Ecstatic goblin texture preloaded")

	var panel = CVPanelScript.new()
	autofree(panel)
	assert_not_null_val(panel, "ComicVignettePanel instance created")
	assert_eq_val(panel.get_goblin_texture_for_mood(&"focused"), CVPanelScript.TEXTURE_FOCUSED, "Focused mood returns focused texture")
	assert_eq_val(panel.get_goblin_texture_for_mood(&"ecstatic"), CVPanelScript.TEXTURE_ECSTATIC, "Ecstatic mood returns ecstatic texture")

func test_goblin_grab_arm_texture() -> void:
	begin("goblin_grab_arm_texture")
	var GrabScript = load("res://scenes/board/goblin_grab_effect.gd")
	assert_not_null_val(GrabScript, "GoblinGrabEffect script loads")
	assert_not_null_val(GrabScript.GOBLIN_HAND_TEXTURE, "Goblin hand texture preloaded")
	var grab = GrabScript.new()
	autofree(grab)
	assert_not_null_val(grab, "GoblinGrabEffect instance created")

func assert_eq_val(actual: Variant, expected: Variant, msg: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		errors.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])

func assert_not_null_val(val: Variant, msg: String) -> void:
	if val != null:
		passed += 1
	else:
		failed += 1
		errors.append("%s: value was null" % msg)

