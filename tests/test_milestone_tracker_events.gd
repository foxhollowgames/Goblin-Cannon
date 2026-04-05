extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "MilestoneTrackerEvents"

func run() -> void:
	test_register_milestone_emits_sequentially()
	test_reset_clears_count()

func _make_tracker() -> Node:
	var mt: Node = Node.new()
	mt.set_script(load("res://scenes/milestone/milestone_tracker.gd") as GDScript)
	return mt

func test_register_milestone_emits_sequentially() -> void:
	begin("register_milestone_reward emits milestone_reached with increasing index")
	var mt: Node = _make_tracker()
	var indices: Array = []
	var totals: Array = []
	if mt.has_signal("milestone_reached"):
		mt.milestone_reached.connect(func(i: int, total_disp: int) -> void:
			indices.append(i)
			totals.append(total_disp)
		)
	if mt.has_method("register_milestone_reward"):
		mt.register_milestone_reward()
		mt.register_milestone_reward()
	assert_eq(indices.size(), 2, "two signals")
	assert_eq(indices[0], 0, "first index")
	assert_eq(indices[1], 1, "second index")
	assert_eq(totals[0], 0, "total display arg unused")
	assert_eq(totals[1], 0, "total display arg unused")

func test_reset_clears_count() -> void:
	begin("set_thresholds_from_city resets milestone count")
	var mt: Node = _make_tracker()
	if mt.has_method("register_milestone_reward"):
		mt.register_milestone_reward()
	if mt.has_method("set_thresholds_from_city"):
		var empty: Array[int] = []
		mt.set_thresholds_from_city(empty)
	var captured: Array = [-1]
	if mt.has_signal("milestone_reached"):
		mt.milestone_reached.connect(func(i: int, _t: int) -> void: captured[0] = i)
	if mt.has_method("register_milestone_reward"):
		mt.register_milestone_reward()
	assert_eq(captured[0], 0, "after reset, next reward is index 0")
