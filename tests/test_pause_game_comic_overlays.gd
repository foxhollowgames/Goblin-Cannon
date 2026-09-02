extends "res://tests/test_base.gd"

const FullscreenComicTakeoverScript = preload("res://scenes/ui/fullscreen_comic_takeover.gd")
const ComicVignettePanelScript = preload("res://scenes/ui/comic_vignette_panel.gd")
const CircularCannonWidgetScript = preload("res://scenes/ui/circular_cannon_widget.gd")

func _init() -> void:
	suite_name = "PauseGameComicOverlays"

func run() -> void:
	test_fullscreen_comic_takeover_pauses_and_unpauses_game_state()
	test_bottom_right_cannon_animation_does_not_pause_game_state()
	test_circular_cannon_widget_does_not_pause_game_state()

func test_fullscreen_comic_takeover_pauses_and_unpauses_game_state() -> void:
	begin("Fullscreen comic takeover pauses and unpauses game state")
	var takeover: CanvasLayer = FullscreenComicTakeoverScript.new()
	autofree(takeover)

	GameState.paused = false
	assert_false(GameState.paused, "Game should not be paused initially")

	takeover.play_takeover("TEST TAKEOVER")
	assert_true(takeover.is_playing, "Takeover active")
	assert_true(GameState.paused, "Game state enters paused state on comic overlay trigger")

	takeover.dismiss_takeover()
	assert_false(takeover.is_playing, "Takeover dismissed")
	assert_false(GameState.paused, "Game state unpauses after comic overlay dismissal")

func test_bottom_right_cannon_animation_does_not_pause_game_state() -> void:
	begin("Bottom-right comic vignette panel animation does not pause game state")
	var vignette: Control = ComicVignettePanelScript.new()
	autofree(vignette)

	GameState.paused = false
	assert_false(GameState.paused, "Game should not be paused initially")

	vignette.trigger_firing_vignette(100, 50, 200)
	assert_true(vignette.is_active, "Vignette active")
	assert_false(GameState.paused, "Bottom-right cannon animation MUST NOT pause game state")

	vignette.dismiss_vignette()
	assert_false(GameState.paused, "Game state remains unpaused after vignette dismissal")

func test_circular_cannon_widget_does_not_pause_game_state() -> void:
	begin("Bottom-right circular cannon widget animation does not pause game state")
	var widget: Control = CircularCannonWidgetScript.new()
	autofree(widget)

	GameState.paused = false
	assert_false(GameState.paused, "Game should not be paused initially")

	widget.trigger_firing_anim()
	assert_false(GameState.paused, "Circular cannon firing animation does not pause game state")
