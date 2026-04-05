extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "EnergizeEventPegs"

func run() -> void:
	test_constants_blocks_event_kinds()
	test_treasure_chest_no_energize_stack()
	test_plain_peg_still_gets_energize_stack()
	test_overclock_skips_event_pegs()

func test_constants_blocks_event_kinds() -> void:
	begin("Constants.peg_extra_kind_blocks_energize matches event pegs")
	assert_true(Constants.peg_extra_kind_blocks_energize("treasure_chest"), "chest")
	assert_true(Constants.peg_extra_kind_blocks_energize("sticky_slime"), "sticky")
	assert_true(Constants.peg_extra_kind_blocks_energize("milestone_event"), "milestone")
	assert_true(Constants.peg_extra_kind_blocks_energize("buffet_table"), "buffet")
	assert_false(Constants.peg_extra_kind_blocks_energize(""), "plain peg")
	assert_false(Constants.peg_extra_kind_blocks_energize("gold"), "gold peg")

func test_treasure_chest_no_energize_stack() -> void:
	begin("apply_hit(..., add_energized true) does not stack energize on treasure chest")
	if GameState:
		GameState.start_run(77)
	var peg_script: GDScript = load("res://scenes/board/peg.gd") as GDScript
	var holder := Node.new()
	var peg := StaticBody2D.new()
	peg.set_script(peg_script)
	peg.peg_extra_kind = "treasure_chest"
	holder.add_child(peg)
	peg.apply_hit(true, 0, true)
	assert_eq(peg.get_energized_durability(), 0, "no energized durability on chest")
	holder.queue_free()

func test_plain_peg_still_gets_energize_stack() -> void:
	begin("apply_hit(..., add_energized true) still adds energize on normal peg")
	if GameState:
		GameState.start_run(78)
	var peg_script: GDScript = load("res://scenes/board/peg.gd") as GDScript
	var pc: PegConfig = PegConfig.new()
	pc.durability = 3
	var holder := Node.new()
	var peg := StaticBody2D.new()
	peg.set_script(peg_script)
	peg.peg_config = pc
	peg.peg_extra_kind = ""
	holder.add_child(peg)
	peg.apply_hit(true, 0, true)
	assert_gt(peg.get_energized_durability(), 0, "plain peg gains energized HP")
	holder.queue_free()

func test_overclock_skips_event_pegs() -> void:
	begin("add_overclock_durability does nothing on treasure_chest")
	if GameState:
		GameState.start_run(79)
	var peg_script: GDScript = load("res://scenes/board/peg.gd") as GDScript
	var holder := Node.new()
	var peg := StaticBody2D.new()
	peg.set_script(peg_script)
	peg.peg_extra_kind = "treasure_chest"
	holder.add_child(peg)
	peg.add_overclock_durability(5)
	assert_eq(peg.get_energized_durability(), 0, "overclock blocked on chest")
	holder.queue_free()
