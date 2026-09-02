extends "res://tests/test_base.gd"

const CircularCannonWidgetScript = preload("res://scenes/ui/circular_cannon_widget.gd")
const FullscreenComicTakeoverScript = preload("res://scenes/ui/fullscreen_comic_takeover.gd")

func _init() -> void:
	suite_name = "CircularCannonWidgetAndTakeover"

func run() -> void:
	test_circular_widget_energy_ratio()
	test_circular_widget_ready_signal()
	test_fullscreen_takeover_flow()

func test_circular_widget_energy_ratio() -> void:
	begin("CircularCannonWidget calculates liquid energy ratio accurately")
	var widget: Control = CircularCannonWidgetScript.new()
	widget._ready()

	assert_eq(widget.liquid_ratio, 0.0, "starts at 0.0")

	widget.set_energy(5000, 10000)
	assert_eq(widget.liquid_ratio, 0.5, "50% liquid ratio at 5000/10000")

	widget.set_energy(10000, 10000)
	assert_eq(widget.liquid_ratio, 1.0, "100% liquid ratio at 10000/10000")

	widget.free()

func test_circular_widget_ready_signal() -> void:
	begin("CircularCannonWidget emits cannon_ready_to_fire when full")
	var widget: Control = CircularCannonWidgetScript.new()
	widget.set_energy(0, 100)

	var ready_emitted: Array = [false]
	widget.cannon_ready_to_fire.connect(func(): ready_emitted[0] = true)

	widget.set_energy(100, 100)
	assert_true(ready_emitted[0], "cannon_ready_to_fire emitted on 100% energy")

	widget.free()

func test_fullscreen_takeover_flow() -> void:
	begin("FullscreenComicTakeover starts hidden and plays takeover sequence")
	var takeover: CanvasLayer = FullscreenComicTakeoverScript.new()
	takeover._ready()

	assert_false(takeover.visible, "starts hidden")

	var started: Array = [false]
	takeover.takeover_started.connect(func(): started[0] = true)

	takeover.play_takeover("WALL BROKEN")

	assert_true(takeover.visible, "visible during takeover")
	assert_true(takeover.is_playing, "is_playing is true")
	assert_true(started[0], "takeover_started signal emitted")

	takeover.dismiss_takeover()
	assert_false(takeover.visible, "hidden after dismiss")
	assert_false(takeover.is_playing, "is_playing is false")

	takeover.free()
