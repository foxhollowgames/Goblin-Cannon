extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "LuckyGoldPeg"

func run() -> void:
	test_lucky_gold_stash_is_always_one_or_five()
	test_lucky_gold_five_rolls_more_often_than_plain_stash()

func test_lucky_gold_stash_is_always_one_or_five() -> void:
	begin("lucky gold stash rolls only 1 or 5")
	if GameState:
		GameState.start_run(777001)
	var peg_script: GDScript = load("res://scenes/board/peg.gd") as GDScript
	for i in range(120):
		var peg: Node = StaticBody2D.new()
		peg.set_script(peg_script)
		peg.peg_id = i
		peg.position = Vector2(10.0 + float(i), 20.0)
		peg.peg_extra_kind = "lucky_gold"
		peg.refresh_stash_gold_for_current_kind()
		var a: int = int(peg.stash_gold_amount)
		assert_true(a == 1 or a == 5, "stash amount should be 1 or 5, got %d" % a)
		peg.free()

func test_lucky_gold_five_rolls_more_often_than_plain_stash() -> void:
	begin("lucky gold 5-stash rate exceeds plain peg stash rate (same seed space)")
	if GameState:
		GameState.start_run(424242)
	var peg_script: GDScript = load("res://scenes/board/peg.gd") as GDScript
	var plain_fives: int = 0
	var lucky_fives: int = 0
	var n: int = 600
	for i in range(n):
		var p_plain: Node = StaticBody2D.new()
		p_plain.set_script(peg_script)
		p_plain.peg_id = i
		p_plain.position = Vector2(50.0 + float(i), 100.0)
		p_plain.peg_extra_kind = ""
		p_plain.refresh_stash_gold_for_current_kind()
		if int(p_plain.stash_gold_amount) == 5:
			plain_fives += 1
		p_plain.free()
	for j in range(n):
		var p_lucky: Node = StaticBody2D.new()
		p_lucky.set_script(peg_script)
		p_lucky.peg_id = j
		p_lucky.position = Vector2(50.0 + float(j), 100.0)
		p_lucky.peg_extra_kind = "lucky_gold"
		p_lucky.refresh_stash_gold_for_current_kind()
		if int(p_lucky.stash_gold_amount) == 5:
			lucky_fives += 1
		p_lucky.free()
	assert_gt(lucky_fives, plain_fives, "lucky gold should produce more 5-gold stashes than plain pegs")
