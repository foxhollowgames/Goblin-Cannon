extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "ConstellationLaser"

func run() -> void:
	test_segment_point_distance_squared_on_segment()
	test_segment_point_distance_squared_off_segment()
	test_binary_split_processor_skips_non_binary()
	test_constellation_laser_applies_to_peg_on_straight_segment()

func test_segment_point_distance_squared_on_segment() -> void:
	begin("Board._segment_point_distance_squared: point on segment -> 0")
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var board := Node2D.new()
	board.set_script(board_script)
	var d: float = board._segment_point_distance_squared(Vector2(0, 0), Vector2(100, 0), Vector2(50, 0))
	assert_approx(d, 0.0, 0.0001, "midpoint on horizontal segment")

func test_segment_point_distance_squared_off_segment() -> void:
	begin("Board._segment_point_distance_squared: perpendicular distance")
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var board := Node2D.new()
	board.set_script(board_script)
	var d: float = board._segment_point_distance_squared(Vector2(0, 0), Vector2(100, 0), Vector2(50, 30))
	assert_approx(d, 900.0, 0.01, "30px above midpoint")

func test_binary_split_processor_skips_non_binary() -> void:
	begin("Board binary split loop skips attackers that are not Binary")
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var src: String = board_script.source_code
	assert_true(src.contains("_ability_key(adef as BallDefinition) != \"Binary\""), "Binary-only guard in split processor")

func test_constellation_laser_applies_to_peg_on_straight_segment() -> void:
	begin("_apply_constellation_laser_hits hits peg intersecting straight segment")
	if GameState:
		GameState.start_run(99)
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var board := Node2D.new()
	board.set_script(board_script)
	board._hit_cooldown = HitCooldown.new()
	var peg_script: GDScript = load("res://scenes/board/peg.gd") as GDScript
	var peg := StaticBody2D.new()
	peg.set_script(peg_script)
	peg.peg_id = 42
	peg.global_position = Vector2(150, 200)
	peg._recovery_ticks_remaining = 0
	board._peg_by_id[42] = peg
	var cdef := BallDefinition.new()
	cdef.ability_name = "Constellation"
	cdef.alignment = Constants.ALIGNMENT_MAIN
	cdef.base_energy = Constants.legacy_display_energy_to_current(20)
	cdef.tier = 1
	cdef.rarity = Constants.RARITY_LEGENDARY
	cdef.city_weights = {0: 100}
	cdef.status_effects = {}
	cdef.shape_type = BallVisuals.ShapeType.PLUS
	var ball_script: GDScript = load("res://scenes/balls/ball.gd") as GDScript
	var ba := RigidBody2D.new()
	ba.set_script(ball_script)
	ba.set_definition(cdef)
	ba.set_ball_id(1)
	ba.global_position = Vector2(100, 200)
	var bb := RigidBody2D.new()
	bb.set_script(ball_script)
	bb.set_definition(cdef.duplicate(true))
	bb.set_ball_id(2)
	bb.global_position = Vector2(200, 200)
	board._active_balls = [ba, bb]
	board._apply_constellation_laser_hits(100)
	var last: int = int(board._constellation_laser_peg_last_tick.get("1|2|42", -999999999))
	assert_eq(last, 100, "laser tick recorded for peg on segment")
