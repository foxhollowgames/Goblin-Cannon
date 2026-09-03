extends "res://tests/test_base.gd"

const ScrollingTerrainScript = preload("res://scenes/combat/scrolling_terrain.gd")
const BattlefieldViewScript = preload("res://scenes/combat/battlefield_view.gd")

func _init() -> void:
	suite_name = "CannonScrollingTerrain"

func run() -> void:
	test_scrolling_terrain_initial_stationary_state()
	test_scrolling_terrain_speed_and_wrapping()
	test_scrolling_terrain_negative_wrapping()
	test_scrolling_terrain_advancing_tweens()
	test_scrolling_terrain_recoil_rumble()
	test_battlefield_view_terrain_integration()
	test_battlefield_view_transition_signals_emission()
	test_battlefield_view_local_cannon_positioning()
	cleanup()

func _add_to_tree(node: Node) -> Node:
	autofree(node)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(node)
	return node

func test_scrolling_terrain_initial_stationary_state() -> void:
	begin("scrolling_terrain_initial_stationary_state")
	var terrain: Node2D = _add_to_tree(ScrollingTerrainScript.new()) as Node2D
	assert_not_null_val(terrain, "ScrollingTerrain instance created")
	assert_eq(terrain.scroll_speed, 0.0, "Terrain is completely stationary (speed 0) during regular combat")
	assert_false(terrain.is_advancing, "Terrain is not advancing initially")
	assert_eq(ScrollingTerrainScript.TERRAIN_WIDTH, 320.0, "Terrain width matches battlefield panel width")
	assert_eq(ScrollingTerrainScript.TERRAIN_HEIGHT, 720.0, "Terrain height matches battlefield panel height")

func test_scrolling_terrain_speed_and_wrapping() -> void:
	begin("scrolling_terrain_speed_and_wrapping")
	var terrain: Node2D = _add_to_tree(ScrollingTerrainScript.new()) as Node2D
	terrain.set_scroll_speed(100.0)
	assert_eq(terrain.get_scroll_speed(), 100.0, "Scroll speed setter updates speed")

	terrain._process(0.5)
	assert_approx(terrain._scroll_offset_y, 50.0, 0.01, "Scroll offset accumulates based on speed and delta")

	terrain._process(10.0)
	assert_lt(terrain._scroll_offset_y, ScrollingTerrainScript.TILE_REPEAT_Y, "Scroll offset wraps cleanly within repeat cycle")
	assert_gte(terrain._scroll_offset_y, 0.0, "Scroll offset remains non-negative")

func test_scrolling_terrain_negative_wrapping() -> void:
	begin("scrolling_terrain_negative_wrapping")
	var terrain: Node2D = _add_to_tree(ScrollingTerrainScript.new()) as Node2D
	terrain.set_scroll_speed(-80.0)
	terrain._process(1.0)
	assert_lt(terrain._scroll_offset_y, ScrollingTerrainScript.TILE_REPEAT_Y, "Negative scroll wraps within upper boundary")
	assert_gte(terrain._scroll_offset_y, 0.0, "Negative scroll wraps to non-negative range")

func test_scrolling_terrain_advancing_tweens() -> void:
	begin("scrolling_terrain_advancing_tweens")
	var terrain: Node2D = _add_to_tree(ScrollingTerrainScript.new()) as Node2D
	var started_emitted: Array = [false]
	var stopped_emitted: Array = [false]
	terrain.advance_started.connect(func(): started_emitted[0] = true)
	terrain.advance_stopped.connect(func(): stopped_emitted[0] = true)

	terrain.start_advancing(0.1, 250.0)
	assert_true(terrain.is_advancing, "is_advancing becomes true on start_advancing")
	assert_true(started_emitted[0], "advance_started signal emitted")

	terrain.stop_advancing(0.05)
	assert_not_null_val(terrain._speed_tween, "Speed tween active during deceleration")
	terrain._speed_tween.custom_step(0.1)
	assert_true(stopped_emitted[0], "advance_stopped emitted after tween step completion")
	assert_false(terrain.is_advancing, "is_advancing resets to false on stop")
	assert_eq(terrain.scroll_speed, 0.0, "scroll_speed decelerates to 0.0")

func test_scrolling_terrain_recoil_rumble() -> void:
	begin("scrolling_terrain_recoil_rumble")
	var terrain: Node2D = _add_to_tree(ScrollingTerrainScript.new()) as Node2D
	terrain.trigger_recoil_rumble(4.0)
	assert_not_null_val(terrain._rumble_tween, "Rumble tween created")
	assert_eq(terrain._rumble_offset.y, 4.0, "Rumble offset initially set to intensity")
	terrain._rumble_tween.custom_step(0.3)
	assert_eq(terrain._rumble_offset, Vector2.ZERO, "Rumble offset returns to zero after completion")

func test_battlefield_view_terrain_integration() -> void:
	begin("battlefield_view_terrain_integration")
	var bf: Node2D = _add_to_tree(BattlefieldViewScript.new()) as Node2D
	bf._ready()
	var terrain: Node2D = bf.get_scrolling_terrain()
	assert_not_null_val(terrain, "BattlefieldView creates and exposes ScrollingTerrain")
	assert_eq(terrain.scroll_speed, 0.0, "Terrain in BattlefieldView starts stationary")

	bf.play_wall_destroyed_transition()
	assert_true(terrain.is_advancing, "Terrain starts advancing on wall destroyed transition")
	assert_not_null_val(bf._roll_tween, "Cannon roll tween created on wall destroyed transition")
	assert_true(bf._roll_tween.is_valid(), "Cannon roll tween is valid on wall destroyed transition")

	bf.play_next_wall_intro()
	assert_not_null_val(bf._roll_tween, "Roll tween active on next wall intro")
	assert_true(bf._roll_tween.is_valid(), "Roll tween is valid on next wall intro")

func test_battlefield_view_transition_signals_emission() -> void:
	begin("battlefield_view_transition_signals_emission")
	var bf: Node2D = _add_to_tree(BattlefieldViewScript.new()) as Node2D
	bf._ready()
	var break_finished: Array = [false]
	var intro_finished: Array = [false]
	bf.wall_break_transition_finished.connect(func(): break_finished[0] = true)
	bf.next_wall_intro_finished.connect(func(): intro_finished[0] = true)

	bf.play_wall_destroyed_transition()
	bf._roll_tween.custom_step(3.0)
	assert_true(break_finished[0], "wall_break_transition_finished signal emitted after roll completion")
	assert_approx(bf._cannon_roll_offset_y, -BattlefieldViewScript.CANNON_ROLL_DISTANCE, 0.01, "Cannon roll offset reached full forward distance")

	bf.play_next_wall_intro()
	bf._roll_tween.custom_step(3.0)
	assert_true(intro_finished[0], "next_wall_intro_finished signal emitted after return completion")
	assert_approx(bf._cannon_roll_offset_y, 0.0, 0.01, "Cannon roll offset returned to 0.0")

func test_battlefield_view_local_cannon_positioning() -> void:
	begin("battlefield_view_local_cannon_positioning")
	var bf: Node2D = _add_to_tree(BattlefieldViewScript.new()) as Node2D
	var cannon_node: Node2D = Node2D.new()
	bf.add_child(cannon_node)
	bf._cannon_visual = cannon_node
	bf._cannon_overlay_local_pos = Vector2(50, 628)
	bf._cannon_roll_offset_y = -100.0
	bf._process(0.016)
	assert_eq(cannon_node.position.y, 528.0, "Local cannon visual position reflects roll offset when not reparented")

func assert_not_null_val(val: Variant, msg: String) -> void:
	if val != null:
		passed += 1
	else:
		failed += 1
		errors.append("%s: value was null" % msg)
