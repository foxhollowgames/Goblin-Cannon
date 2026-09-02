extends "res://tests/test_base.gd"

const ComicVignettePanelScript = preload("res://scenes/ui/comic_vignette_panel.gd")

func _init() -> void:
	suite_name = "ComicVignettePanel"

func run() -> void:
	test_vignette_trigger_and_visibility()
	test_wall_degradation_ratio()
	test_goblin_mood_states()
	test_vignette_dismissal()

func test_vignette_trigger_and_visibility() -> void:
	begin("ComicVignettePanel triggers on cannon firing and becomes visible")
	var panel: Control = ComicVignettePanelScript.new()
	panel._ready()

	assert_false(panel.visible, "starts hidden")

	var triggered: Array = [false]
	panel.vignette_triggered.connect(func(_dmg, _hp): triggered[0] = true)

	panel.trigger_firing_vignette(150, 80, 200)

	assert_true(panel.visible, "visible after trigger")
	assert_true(panel.is_active, "is_active is true")
	assert_true(triggered[0], "vignette_triggered signal emitted")
	assert_eq(panel.current_damage, 150, "damage recorded as 150")

	panel.free()

func test_wall_degradation_ratio() -> void:
	begin("Degradation ratio accurately reflects remaining wall HP")
	var panel: Control = ComicVignettePanelScript.new()
	panel.trigger_firing_vignette(50, 100, 200)

	assert_eq(panel.get_wall_degradation_ratio(), 0.5, "50% degraded at 100/200 HP")

	panel.free()

func test_goblin_mood_states() -> void:
	begin("Goblin mood updates based on wall degradation severity")
	var panel: Control = ComicVignettePanelScript.new()

	panel.trigger_firing_vignette(10, 190, 200)
	assert_eq(panel.get_goblin_mood_state(), &"focused", "<20% degraded = focused")

	panel.trigger_firing_vignette(50, 100, 200)
	assert_eq(panel.get_goblin_mood_state(), &"cheering", "50% degraded = cheering")

	panel.trigger_firing_vignette(50, 20, 200)
	assert_eq(panel.get_goblin_mood_state(), &"ecstatic", ">=80% degraded = ecstatic")

	panel.free()

func test_vignette_dismissal() -> void:
	begin("Dismissing vignette hides panel and emits vignette_dismissed")
	var panel: Control = ComicVignettePanelScript.new()
	panel.trigger_firing_vignette(100, 50, 200)

	var dismissed: Array = [false]
	panel.vignette_dismissed.connect(func(): dismissed[0] = true)

	panel.dismiss_vignette()

	assert_false(panel.visible, "hidden after dismiss")
	assert_false(panel.is_active, "is_active is false")
	assert_true(dismissed[0], "vignette_dismissed signal emitted")

	panel.free()
