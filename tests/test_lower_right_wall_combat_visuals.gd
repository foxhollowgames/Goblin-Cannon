extends "res://tests/test_base.gd"

const WallVisualScript: GDScript = preload("res://scenes/combat/wall_visual.gd")
const CannonShotScript: GDScript = preload("res://scenes/combat/cannon_shot_vfx.gd")
const WallImpactScript: GDScript = preload("res://scenes/combat/wall_impact_vfx.gd")
const BattlefieldViewScript: GDScript = preload("res://scenes/combat/battlefield_view.gd")

func _init() -> void:
	suite_name = "LowerRightWallCombatVisuals"

func run() -> void:
	test_wall_visual_textures_and_hit_reaction()
	test_cannonball_projectile_texture_and_setup()
	test_wall_impact_vfx_setup_and_particles()
	test_battlefield_view_horizontal_alignment()
	test_battlefield_view_fire_spawns_projectile()

func test_wall_visual_textures_and_hit_reaction() -> void:
	begin("WallVisual preloads textures and triggers hit reaction")
	assert_true(WallVisualScript.CASTLE_WALL_TEXTURE != null, "Castle wall sprite texture is loaded")
	assert_true(WallVisualScript.WALL_TILE_TEXTURE != null, "Stone wall tile texture is loaded")
	assert_true(WallVisualScript.WALL_CAP_TEXTURE != null, "Wall cap texture is loaded")
	
	var wall: Node2D = WallVisualScript.new() as Node2D
	wall.trigger_hit_reaction()
	assert_eq(wall.get("_flash_alpha"), 1.0, "Hit reaction sets flash alpha to 1.0")
	wall.free()

func test_cannonball_projectile_texture_and_setup() -> void:
	begin("CannonShotVFX loads cannonball sprite and configures start and end coordinates")
	assert_true(CannonShotScript.CANNON_BALL_TEXTURE != null, "Cannonball sprite texture is loaded")
	
	var shot: Node2D = CannonShotScript.new() as Node2D
	var impact_called: Array[bool] = [false]
	var impact_cb: Callable = func(_pos: Vector2) -> void:
		impact_called[0] = true
	
	var start_pos: Vector2 = Vector2(72.0, 628.0)
	var end_pos: Vector2 = Vector2(265.0, 628.0)
	shot.setup(start_pos, end_pos, impact_cb)
	
	assert_eq(shot.position, start_pos, "Projectile start position is muzzle coordinate")
	assert_eq(shot.get("_end_pos"), end_pos, "Projectile end position is wall coordinate")
	shot.free()

func test_wall_impact_vfx_setup_and_particles() -> void:
	begin("WallImpactVFX initializes spritesheet particles and debris scattering")
	assert_true(WallImpactScript.IMPACT_VFX_TEXTURE != null, "Impact VFX spritesheet is loaded")
	assert_true(WallImpactScript.DEBRIS_TEXTURE != null, "Impact debris texture is loaded")
	
	var impact: Node2D = WallImpactScript.new() as Node2D
	var impact_pos: Vector2 = Vector2(265.0, 628.0)
	impact.setup(impact_pos)
	
	assert_eq(impact.position, impact_pos, "Impact VFX position matches wall coordinate")
	var particles: Array = impact.get("_particles") as Array
	var debris: Array = impact.get("_debris") as Array
	assert_true(particles != null and particles.size() > 0, "Impact particles array is initialized")
	assert_true(debris != null and debris.size() > 0, "Impact debris array is initialized")
	impact.free()

func test_battlefield_view_horizontal_alignment() -> void:
	begin("BattlefieldView coordinates align vertically at y=628.0 for horizontal combat")
	assert_approx(BattlefieldViewScript.CANNON_MUZZLE_POS.y, 628.0, 0.01, "Cannon muzzle vertical position is 628.0")
	assert_approx(BattlefieldViewScript.WALL_IMPACT_POS.y, 628.0, 0.01, "Wall impact vertical position is 628.0")
	assert_true(BattlefieldViewScript.WALL_IMPACT_POS.x > BattlefieldViewScript.CANNON_MUZZLE_POS.x, "Wall is opposite cannon on the right side")

func test_battlefield_view_fire_spawns_projectile() -> void:
	begin("BattlefieldView fire_cannon_shot spawns projectile and blast nodes in VFXContainer")
	var bf: Node2D = BattlefieldViewScript.new() as Node2D
	bf._ready()
	
	bf.fire_cannon_shot()
	var vfx_cont: Node2D = bf.get("_vfx_container") as Node2D
	assert_true(vfx_cont != null, "VFXContainer node exists")
	assert_true(vfx_cont.get_child_count() > 0, "VFXContainer contains projectile shot and blast")
	bf.free()
