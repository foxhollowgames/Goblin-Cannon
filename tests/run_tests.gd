extends SceneTree
## Test runner. Execute from project root:
##   godot --headless -s tests/run_tests.gd
##
## Discovers test scripts in res://tests/test_*.gd, instantiates each,
## calls run(), and reports pass/fail counts. Exits with code 1 on any failure.

## Register test scripts here. Add new test files to this array.
const TEST_SCRIPTS: Array[String] = [
	"res://tests/test_monsters_also_die_palette.gd",
	"res://tests/test_script_parse_smoke.gd",
	"res://tests/test_energy_routing.gd",
	"res://tests/test_hit_cooldown.gd",
	"res://tests/test_kingdom_board_events.gd",
	"res://tests/test_milestone_curve.gd",
	"res://tests/test_milestone_tracker_events.gd",
	"res://tests/test_combat_manager.gd",
	"res://tests/test_main_cannon.gd",
	"res://tests/test_game_state.gd",
	"res://tests/test_reward_generation.gd",
	"res://tests/test_milestone_shop_data.gd",
	"res://tests/test_reward_handler.gd",
	"res://tests/test_shop_ball_prices.gd",
	"res://tests/test_energy_router.gd",
	"res://tests/test_test_scenario.gd",
	"res://tests/test_city_progression.gd",
	"res://tests/test_magnet_peg.gd",
	"res://tests/test_lucky_gold_peg.gd",
	"res://tests/test_volatile_gas.gd",
	"res://tests/test_phantom_trail.gd",
	"res://tests/test_ball_visuals.gd",
	"res://tests/test_constellation_laser.gd",
	"res://tests/test_binary_ball.gd",
	"res://tests/test_bloom_ball.gd",
	"res://tests/test_sticky_slime_event.gd",
	"res://tests/test_black_hole_event.gd",
	"res://tests/test_energize_event_pegs.gd",
	"res://tests/test_keyword_database.gd",
	"res://tests/test_junk_box_inventory.gd",
	"res://tests/test_polyomino_drag_drop.gd",
	"res://tests/test_polyomino_machinery.gd",
	"res://tests/test_hopper_steering.gd",
	"res://tests/test_hopper_ball_cascade.gd",
	"res://tests/test_hopper_top_bar_debug_menu.gd",
	"res://tests/test_live_board_ghost_placement.gd",
	"res://tests/test_junk_box_ui_and_board_transfer.gd",
	"res://tests/test_polyomino_relic_shapes.gd",
	"res://tests/test_slotted_relic_effects.gd",
	"res://tests/test_relic_board_triggers.gd",
	"res://tests/test_peg_grid_alignment.gd",
	"res://tests/test_relic_audio_levels.gd",
	"res://tests/test_audio_pitch_randomizer.gd",
	"res://tests/test_relic_selection_preview.gd",
	"res://tests/test_board_relic_repositioning.gd",
	"res://tests/test_relic_pinball_goals.gd",
	"res://tests/test_ui_buttons_audit.gd",
	"res://tests/test_tooltip_text_refinement.gd",
	"res://tests/test_relic_enclosures.gd",
	"res://tests/test_wall_siege.gd",
	"res://tests/test_wall_health_scaling.gd",
	"res://tests/test_pinball_machinery.gd",
	"res://tests/test_junk_box_sidebar_display.gd",
	"res://tests/test_story_campaign_architecture.gd",
	"res://tests/test_character_progression_mechanics.gd",
	"res://tests/test_tetromino_module_fusion.gd",
	"res://tests/test_build_archetypes_and_synergies.gd",
	"res://tests/test_comic_vignette_panel.gd",
	"res://tests/test_circular_cannon_widget.gd",
	"res://tests/test_cannon_sprite_visuals.gd",
	"res://tests/test_cannon_scrolling_terrain.gd",
	"res://tests/test_corner_cannon_terrain.gd",
	"res://tests/test_pause_game_comic_overlays.gd",
	"res://tests/test_asset_pack_sprites.gd",
	"res://tests/test_top_gold_counter_ui.gd",
	"res://tests/test_junk_box_dynamic_scroll.gd",
	"res://scripts/capture_ui_screenshot.gd",
	"res://tests/test_pinball_components.gd",
	"res://tests/test_relic_widget_distribution.gd",
	"res://tests/test_on_board_relic_tooltips.gd",
	"res://tests/test_keyword_flyout_tooltip.gd",
	"res://tests/test_relic_junk_box_return.gd",
	"res://tests/test_relic_machinery_rotation.gd",
	"res://tests/test_relic_pinball_activation.gd",
	"res://tests/test_junk_box_relic_display_and_tooltips.gd",
	"res://tests/test_ui_wireframe_and_screen_layout.gd",
	"res://tests/test_junk_box_manual_placement.gd",
	"res://tests/test_file_lengths.gd",
]

func _initialize() -> void:
	# Watchdog timer: automatically force exit if tests exceed 30 seconds
	create_timer(30.0).timeout.connect(func() -> void:
		printerr("ERROR: Test suite timed out after 30 seconds!")
		quit(1)
	)
	call_deferred("_run_all_tests")

func _run_all_tests() -> void:
	var _mp = load("res://autoloads/monster_palette.gd")
	var _mc = load("res://scenes/board/machinery/polyomino_machinery_component.gd")

	var total_passed: int = 0
	var total_failed: int = 0
	var all_errors: Array[String] = []

	print("\n========================================\n  GOBLIN CANNON — TEST SUITE\n========================================\n")

	for path in TEST_SCRIPTS:
		var result: Dictionary = _execute_test_file(path)
		total_passed += int(result.get("passed", 0))
		total_failed += int(result.get("failed", 0))
		var errs: Array = result.get("errors", [])
		for e in errs:
			all_errors.append(str(e))

	print("\n----------------------------------------\n  Total: %d passed, %d failed\n----------------------------------------" % [total_passed, total_failed])
	if total_failed > 0:
		print("\nFailures:")
		for e in all_errors:
			print("  • %s" % e)
		print("")

	quit(0 if total_failed == 0 else 1)

func _execute_test_file(path: String) -> Dictionary:
	var res := {"passed": 0, "failed": 0, "errors": []}
	var script: GDScript = load(path) as GDScript
	if not script or not script.can_instantiate():
		print("  [FAIL] Could not load or parse: %s" % path)
		res["failed"] = 1
		res["errors"].append("%s > Failed to parse or instantiate" % path.get_file())
		return res

	var test_instance = script.new()
	if not test_instance or not test_instance.has_method("run"):
		print("  [SKIP] No run() method: %s" % path)
		return res

	test_instance.run()
	if test_instance.has_method("cleanup"):
		test_instance.cleanup()

	var passed: int = test_instance.passed
	var failed: int = test_instance.failed
	var suite: String = test_instance.suite_name if "suite_name" in test_instance else path.get_file()
	var errors: Array = test_instance.errors if "errors" in test_instance else []

	res["passed"] = passed
	res["failed"] = failed
	var status: String = "PASS" if failed == 0 else "FAIL"
	print("  [%s] %s  (%d passed, %d failed)" % [status, suite, passed, failed])
	for e in errors:
		res["errors"].append("%s > %s" % [suite, e])

	return res

