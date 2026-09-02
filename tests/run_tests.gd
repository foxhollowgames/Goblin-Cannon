extends SceneTree
## Ensures `class_name MonsterPalette` is registered before any script references it (headless order).
const _monster_palette_script = preload("res://autoloads/monster_palette.gd")
const _machinery_component_script = preload("res://scenes/board/machinery/polyomino_machinery_component.gd")
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
	var total_passed: int = 0
	var total_failed: int = 0
	var all_errors: Array[String] = []

	print("")
	print("========================================")
	print("  GOBLIN CANNON — TEST SUITE")
	print("========================================")
	print("")

	for path in TEST_SCRIPTS:
		var script: GDScript = load(path) as GDScript
		if not script or not script.can_instantiate():
			print("  [FAIL] Could not load or parse: %s" % path)
			total_failed += 1
			all_errors.append("%s > Failed to parse or instantiate" % path.get_file())
			continue

		var test_instance = script.new()
		if not test_instance or not test_instance.has_method("run"):
			print("  [SKIP] No run() method: %s" % path)
			continue

		test_instance.run()
		if test_instance.has_method("cleanup"):
			test_instance.cleanup()

		var passed: int = test_instance.passed
		var failed: int = test_instance.failed
		var suite: String = test_instance.suite_name if "suite_name" in test_instance else path.get_file()
		var errors: Array = test_instance.errors if "errors" in test_instance else []

		total_passed += passed
		total_failed += failed

		var status: String = "PASS" if failed == 0 else "FAIL"
		print("  [%s] %s  (%d passed, %d failed)" % [status, suite, passed, failed])
		for e in errors:
			all_errors.append("%s > %s" % [suite, e])

	print("")
	print("----------------------------------------")
	print("  Total: %d passed, %d failed" % [total_passed, total_failed])
	print("----------------------------------------")

	if total_failed > 0:
		print("")
		print("Failures:")
		for e in all_errors:
			print("  • %s" % e)
		print("")

	quit(0 if total_failed == 0 else 1)
