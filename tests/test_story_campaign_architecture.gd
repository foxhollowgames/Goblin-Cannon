extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "StoryCampaignArchitecture"

func run() -> void:
	test_campaign_initialization_and_archetypes()
	test_campaign_run_progression_and_mcguffins()
	test_run_unlock_boundaries()
	test_run_six_convergence_trigger()
	test_campaign_save_load_serialization()

func test_campaign_initialization_and_archetypes() -> void:
	begin("Campaign initialization maps run index to correct character archetype")
	assert_eq(GameState.get_character_archetype_for_run(1), &"goblin", "run 1 = goblin")
	assert_eq(GameState.get_character_archetype_for_run(2), &"necromancer", "run 2 = necromancer")
	assert_eq(GameState.get_character_archetype_for_run(3), &"beastmancer", "run 3 = beastmancer")
	assert_eq(GameState.get_character_archetype_for_run(4), &"mechanic", "run 4 = mechanic")
	assert_eq(GameState.get_character_archetype_for_run(5), &"astromancer", "run 5 = astromancer")
	assert_eq(GameState.get_character_archetype_for_run(6), &"goblin_convergence", "run 6 = goblin_convergence")

func test_campaign_run_progression_and_mcguffins() -> void:
	begin("Completing a run unlocks McGuffin and advances highest unlocked run")
	GameState.start_run(100)
	GameState.start_campaign_run(1)

	assert_eq(GameState.campaign_run_index, 1, "run 1 started")
	assert_eq(GameState.character_archetype, &"goblin", "archetype is goblin")

	GameState.complete_campaign_run()
	assert_true(GameState.has_mcguffin(&"mcguffin_run_1"), "mcguffin_run_1 awarded")
	assert_eq(GameState.highest_unlocked_campaign_run, 2, "run 2 unlocked")
	assert_true(GameState.is_run_unlocked(2), "run 2 is now unlocked")

func test_run_unlock_boundaries() -> void:
	begin("Locked runs cannot be started until unlocked")
	GameState.start_run(200)
	GameState.highest_unlocked_campaign_run = 1

	assert_true(GameState.is_run_unlocked(1), "run 1 unlocked initially")
	assert_false(GameState.is_run_unlocked(2), "run 2 locked initially")
	assert_false(GameState.is_run_unlocked(6), "run 6 locked initially")

func test_run_six_convergence_trigger() -> void:
	begin("Starting run 6 triggers the convergence event")
	GameState.start_run(300)
	GameState.highest_unlocked_campaign_run = 6

	var convergence_result: Array = [false]
	GameState.convergence_event_triggered.connect(func(): convergence_result[0] = true)

	GameState.start_campaign_run(6)
	assert_eq(GameState.campaign_run_index, 6, "run 6 active")
	assert_true(GameState.convergence_active, "convergence_active set to true")
	assert_true(convergence_result[0], "convergence_event_triggered signal emitted")

func test_campaign_save_load_serialization() -> void:
	begin("Campaign progress saves and restores cleanly from serialized Dictionary")
	GameState.start_run(400)
	GameState.start_campaign_run(3)
	GameState.complete_campaign_run()

	var save_data: Dictionary = GameState.save_campaign_progress()
	assert_eq(int(save_data.get("campaign_run_index")), 3, "save data contains run index 3")
	assert_eq(int(save_data.get("highest_unlocked_campaign_run")), 4, "save data contains highest unlocked 4")

	GameState.start_run(500)
	GameState.load_campaign_progress(save_data)

	assert_eq(GameState.campaign_run_index, 3, "restored run index 3")
	assert_eq(GameState.highest_unlocked_campaign_run, 4, "restored highest unlocked 4")
	assert_true(GameState.has_mcguffin(&"mcguffin_run_3"), "restored mcguffin_run_3")
