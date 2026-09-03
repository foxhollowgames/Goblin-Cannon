extends "res://tests/test_base.gd"

const ScrollingTerrainScript = preload("res://scenes/combat/scrolling_terrain.gd")
const BattlefieldViewScript = preload("res://scenes/combat/battlefield_view.gd")

func _init() -> void:
	suite_name = "CannonScrollingTerrain"

func run() -> void:
	test_scrolling_terrain_initial_stationary_state()
	test_scrolling_terrain_speed_and_wrapping()
	test_scrolling_terrain_advancing_tweens()
	test_battlefield_view_terrain_integration()
	test_battlefield_view_transition_signals()
	cleanup()

func test_scrolling_terrain_initial_stationary_state() -> void:
	begin("scrolling_terrain_initial_stationary_state")
	var terrain: Node2D = ScrollingTerrainScript.new() as Node2D
	autofree(terrain)
	assert_not_null_val(terrain, "ScrollingTerrain instance created")
	assert_eq(terrain.scroll_speed, 0.0, "Terrain is completely stationary (speed 0) during regular combat")
	assert_false(terrain.is_advancing, "Terrain is not advancing initially")
	assert_eq(ScrollingTerrainScript.TERRAIN_WIDTH, 320.0, "Terrain width matches battlefield panel width")
	assert_eq(ScrollingTerrainScript.TERRAIN_HEIGHT, 720.0, "Terrain height matches battlefield panel height")

func test_scrolling_terrain_speed_and_wrapping() -> void:
	begin("scrolling_terrain_speed_and_wrapping")
	var terrain: Node2D = ScrollingTerrainScript.new() as Node2D
	autofree(terrain)
	terrain.set_scroll_speed(100.0)
	assert_eq(terrain.get_scroll_speed(), 100.0, "Scroll speed setter updates speed")

	terrain._process(0.5)
	assert_approx(terrain._scroll_offset_y, 50.0, 0.01, "Scroll offset accumulates based on speed and delta")

	# Advance by large delta to verify seamless modulo wrapping
	terrain._process(10.0)
	assert_lt(terrain._scroll_offset_y, ScrollingTerrainScript.TILE_REPEAT_Y, "Scroll offset wraps cleanly within repeat cycle")
	assert_gte(terrain._scroll_offset_y, 0.0, "Scroll offset remains non-negative")

func test_scrolling_terrain_advancing_tweens() -> void:
	begin("scrolling_terrain_advancing_tweens")
	var terrain: Node2D = ScrollingTerrainScript.new() as Node2D
	autofree(terrain)
	var advance_started_emitted: Array = [false]
	terrain.advance_started.connect(func(): advance_started_emitted[0] = true)

	terrain.start_advancing(0.1, 250.0)
	assert_true(terrain.is_advancing, "is_advancing becomes true on start_advancing")
	assert_true(advance_started_emitted[0], "advance_started signal emitted")

	terrain.stop_advancing(0.05)
	assert_not_null_val(terrain._speed_tween, "Speed tween active during deceleration")

func test_battlefield_view_terrain_integration() -> void:
	begin("battlefield_view_terrain_integration")
	var bf: Node2D = BattlefieldViewScript.new() as Node2D
	autofree(bf)
	bf._ready()
	var terrain: Node2D = bf.get_scrolling_terrain()
	assert_not_null_val(terrain, "BattlefieldView creates and exposes ScrollingTerrain")
	assert_eq(terrain.scroll_speed, 0.0, "Terrain in BattlefieldView starts stationary")

	# Test wall destroyed transition triggers terrain advance
	bf.play_wall_destroyed_transition()
	assert_true(terrain.is_advancing, "Terrain starts advancing on wall destroyed transition")
	assert_not_null_val(bf._roll_tween, "Cannon roll tween created on wall destroyed transition")
	assert_true(bf._roll_tween.is_valid(), "Cannon roll tween is valid on wall destroyed transition")

	# Test next wall intro stops terrain
	bf.play_next_wall_intro()
	assert_not_null_val(bf._roll_tween, "Roll tween active on next wall intro")
	assert_true(bf._roll_tween.is_valid(), "Roll tween is valid on next wall intro")

func test_battlefield_view_transition_signals() -> void:
	begin("battlefield_view_transition_signals")
	var bf: Node2D = BattlefieldViewScript.new() as Node2D
	autofree(bf)
	assert_true(bf.has_signal("wall_break_transition_finished"), "BattlefieldView has wall_break_transition_finished signal")
	assert_true(bf.has_signal("next_wall_intro_finished"), "BattlefieldView has next_wall_intro_finished signal")

func assert_not_null_val(val: Variant, msg: String) -> void:
	if val != null:
		passed += 1
	else:
		failed += 1
		errors.append("%s: value was null" % msg)
