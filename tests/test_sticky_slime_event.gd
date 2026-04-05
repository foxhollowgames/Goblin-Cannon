extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "StickySlimeEvent"

func run() -> void:
	test_sticky_slime_rescue_hits_consume()
	test_pick_normal_peg_ids_filters_special_pegs()

func test_sticky_slime_rescue_hits_consume() -> void:
	begin("Peg.consume_sticky_slime_ball_hit matches Constants.STICKY_SLIME_RESCUE_HITS")
	if GameState:
		GameState.start_run(1)
	var peg_script: GDScript = load("res://scenes/board/peg.gd") as GDScript
	var peg := StaticBody2D.new()
	peg.set_script(peg_script)
	if peg.has_method("configure_sticky_slime_overlay"):
		peg.configure_sticky_slime_overlay("")
	var n: int = Constants.STICKY_SLIME_RESCUE_HITS
	assert_eq(peg.get_sticky_rescue_hits_remaining(), n, "initial rescue hits")
	var broke_at: int = -1
	for i in range(n + 2):
		if peg.has_method("consume_sticky_slime_ball_hit") and peg.consume_sticky_slime_ball_hit():
			broke_at = i
			break
	assert_eq(broke_at, n - 1, "break should occur on Nth distinct ball hit (0-based index n-1)")

func test_pick_normal_peg_ids_filters_special_pegs() -> void:
	begin("Board.pick_random_normal_peg_ids_for_sticky_event only uses plain pegs")
	if GameState:
		GameState.start_run(2)
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var board := Node2D.new()
	board.set_script(board_script)
	var peg_script: GDScript = load("res://scenes/board/peg.gd") as GDScript
	var p0 := StaticBody2D.new()
	p0.set_script(peg_script)
	p0.peg_id = 1
	p0.peg_extra_kind = ""
	board._peg_by_id[1] = p0
	var p1 := StaticBody2D.new()
	p1.set_script(peg_script)
	p1.peg_id = 2
	p1.peg_extra_kind = "bomb"
	board._peg_by_id[2] = p1
	var ids: Array[int] = board.pick_random_normal_peg_ids_for_sticky_event(5)
	assert_eq(ids.size(), 1, "only one normal peg")
	assert_eq(ids[0], 1, "plain peg id")
