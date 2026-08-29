extends "res://tests/test_base.gd"

const HitCooldown = preload("res://simulation/hit_cooldown.gd")

func _init() -> void:
	suite_name = "HitCooldown"

func run() -> void:
	test_no_prior_hit_always_ok()
	test_within_cooldown_blocked()
	test_after_cooldown_ok()
	test_at_exact_cooldown_boundary()
	test_independent_ball_peg_pairs()
	test_clear_resets_all()
	test_multiple_records_overwrites()

func test_no_prior_hit_always_ok() -> void:
	begin("no prior hit — cooldown_ok returns true")
	var hc := HitCooldown.new()
	assert_true(hc.cooldown_ok(1, 1, 0, 3), "first hit should be ok")
	assert_true(hc.cooldown_ok(1, 1, 100, 3), "first hit at any tick should be ok")

func test_within_cooldown_blocked() -> void:
	begin("within cooldown — blocked")
	var hc := HitCooldown.new()
	hc.record_hit(1, 1, 10)
	assert_false(hc.cooldown_ok(1, 1, 10, 3), "same tick = blocked")
	assert_false(hc.cooldown_ok(1, 1, 11, 3), "1 tick later = blocked")
	assert_false(hc.cooldown_ok(1, 1, 12, 3), "2 ticks later = blocked")

func test_after_cooldown_ok() -> void:
	begin("after cooldown expires — ok")
	var hc := HitCooldown.new()
	hc.record_hit(1, 1, 10)
	assert_true(hc.cooldown_ok(1, 1, 13, 3), "exactly at cooldown boundary")
	assert_true(hc.cooldown_ok(1, 1, 20, 3), "well past cooldown")

func test_at_exact_cooldown_boundary() -> void:
	begin("at exact cooldown boundary (current - last == cooldown)")
	var hc := HitCooldown.new()
	hc.record_hit(5, 10, 100)
	assert_true(hc.cooldown_ok(5, 10, 105, 5), "exactly 5 ticks later with cooldown 5")
	assert_false(hc.cooldown_ok(5, 10, 104, 5), "4 ticks later with cooldown 5")

func test_independent_ball_peg_pairs() -> void:
	begin("different ball/peg pairs are independent")
	var hc := HitCooldown.new()
	hc.record_hit(1, 1, 10)
	assert_false(hc.cooldown_ok(1, 1, 11, 3), "same pair blocked")
	assert_true(hc.cooldown_ok(1, 2, 11, 3), "different peg ok")
	assert_true(hc.cooldown_ok(2, 1, 11, 3), "different ball ok")
	assert_true(hc.cooldown_ok(2, 2, 11, 3), "different both ok")

func test_clear_resets_all() -> void:
	begin("clear resets all cooldowns")
	var hc := HitCooldown.new()
	hc.record_hit(1, 1, 10)
	hc.record_hit(2, 2, 10)
	hc.clear()
	assert_true(hc.cooldown_ok(1, 1, 10, 3), "pair 1,1 ok after clear")
	assert_true(hc.cooldown_ok(2, 2, 10, 3), "pair 2,2 ok after clear")

func test_multiple_records_overwrites() -> void:
	begin("recording same pair again overwrites last_hit")
	var hc := HitCooldown.new()
	hc.record_hit(1, 1, 10)
	assert_false(hc.cooldown_ok(1, 1, 12, 3), "blocked from first record")
	hc.record_hit(1, 1, 20)
	assert_false(hc.cooldown_ok(1, 1, 22, 3), "blocked from second record")
	assert_true(hc.cooldown_ok(1, 1, 23, 3), "ok past second record's cooldown")
