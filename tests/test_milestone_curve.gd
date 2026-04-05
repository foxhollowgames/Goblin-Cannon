extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "MilestoneCurve"

func run() -> void:
	test_linear_thresholds()
	test_exponential_thresholds()
	test_negative_level_returns_zero()
	test_next_threshold_index()
	test_crossed_indices_none()
	test_crossed_indices_some()
	test_crossed_indices_all()
	test_exponential_growth_increases()

func test_linear_thresholds() -> void:
	begin("linear thresholds for levels 0-2")
	assert_eq(MilestoneCurve.threshold_for_level(0), 2000, "level 0 = 2k")
	assert_eq(MilestoneCurve.threshold_for_level(1), 4000, "level 1 = 4k")
	assert_eq(MilestoneCurve.threshold_for_level(2), 6000, "level 2 = 6k")

func test_exponential_thresholds() -> void:
	begin("exponential thresholds for levels 3+")
	# Level 3: 6000 * 2^1 = 12000
	assert_eq(MilestoneCurve.threshold_for_level(3), 12000, "level 3 = 12k (2^1)")
	# Level 4: 6000 * 2^2 = 24000
	assert_eq(MilestoneCurve.threshold_for_level(4), 24000, "level 4 = 24k (2^2)")
	# Level 5: 6000 * 2^3 = 48000
	assert_eq(MilestoneCurve.threshold_for_level(5), 48000, "level 5 = 48k (2^3)")

func test_negative_level_returns_zero() -> void:
	begin("negative level returns 0")
	assert_eq(MilestoneCurve.threshold_for_level(-1), 0, "level -1 = 0")
	assert_eq(MilestoneCurve.threshold_for_level(-100), 0, "level -100 = 0")

func test_next_threshold_index() -> void:
	begin("next_threshold_index finds first crossed threshold")
	var thresholds: Array = [100, 200, 300]
	assert_eq(MilestoneCurve.next_threshold_index(50, thresholds), -1, "below all")
	assert_eq(MilestoneCurve.next_threshold_index(100, thresholds), 0, "at first")
	assert_eq(MilestoneCurve.next_threshold_index(250, thresholds), 0, "above first returns first match")
	assert_eq(MilestoneCurve.next_threshold_index(500, thresholds), 0, "above all still returns first match")

func test_crossed_indices_none() -> void:
	begin("crossed_indices returns empty when below all thresholds")
	var thresholds: Array = [100, 200, 300]
	var result: Array = MilestoneCurve.crossed_indices(50, thresholds)
	assert_empty(result, "nothing crossed at 50")

func test_crossed_indices_some() -> void:
	begin("crossed_indices returns partially crossed")
	var thresholds: Array = [100, 200, 300]
	var result: Array = MilestoneCurve.crossed_indices(250, thresholds)
	assert_eq(result.size(), 2, "two thresholds crossed at 250")
	assert_in(0, result, "index 0 crossed")
	assert_in(1, result, "index 1 crossed")

func test_crossed_indices_all() -> void:
	begin("crossed_indices returns all when above all thresholds")
	var thresholds: Array = [100, 200, 300]
	var result: Array = MilestoneCurve.crossed_indices(500, thresholds)
	assert_eq(result.size(), 3, "all three crossed at 500")

func test_exponential_growth_increases() -> void:
	begin("each exponential level is larger than the previous")
	var prev: int = MilestoneCurve.threshold_for_level(5)
	for level in range(6, 15):
		var curr: int = MilestoneCurve.threshold_for_level(level)
		assert_gt(curr, prev, "level %d > level %d" % [level, level - 1])
		prev = curr
