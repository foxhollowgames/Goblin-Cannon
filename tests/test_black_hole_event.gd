extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "BlackHoleEvent"

func run() -> void:
	test_constants_black_hole_delay()
	test_board_reason_black_hole_is_4()
	test_black_hole_scripts_load()

func test_constants_black_hole_delay() -> void:
	begin("BLACK_HOLE_RESPAWN_DELAY_SEC is 5 seconds")
	assert_approx(Constants.BLACK_HOLE_RESPAWN_DELAY_SEC, 5.0, 0.001, "delay")

func test_board_reason_black_hole_is_4() -> void:
	begin("board.gd REASON_BLACK_HOLE is 4 (game_coordinator exit branch)")
	var script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var m: Dictionary = script.get_script_constant_map()
	assert_eq(int(m.get("REASON_BLACK_HOLE", -99)), 4, "REASON_BLACK_HOLE")

func test_black_hole_scripts_load() -> void:
	begin("black hole scripts parse")
	var paths: Array[String] = [
		"res://scenes/board/black_hole_controller.gd",
		"res://scenes/board/black_hole_preview.gd",
		"res://scenes/board/black_hole_visual.gd",
	]
	for p in paths:
		var s: GDScript = load(p) as GDScript
		assert_true(s != null, "load %s" % p)
