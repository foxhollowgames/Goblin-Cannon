extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "MainCannon"

func run() -> void:
	_ensure_clean_game_state()
	test_add_energy_increases_current()
	test_energy_changed_signal()
	test_get_charge_threshold_base()
	test_charge_threshold_with_reduction()
	test_charge_threshold_minimum_1()
	test_try_fire_below_threshold()
	test_try_fire_at_threshold()
	test_try_fire_deducts_energy()
	test_fired_signal_with_damage()
	test_damage_includes_bonus()
	test_sim_tick_fires_when_ready()

func _ensure_clean_game_state() -> void:
	if GameState:
		GameState.start_run(12345)

func _make_cannon() -> Node:
	var script: GDScript = load("res://scenes/systems/main_cannon/main_cannon.gd")
	var mc := Node.new()
	mc.set_script(script)
	return mc

func test_add_energy_increases_current() -> void:
	begin("add_energy increases current energy")
	var mc := _make_cannon()
	assert_eq(mc.get_current_energy(), 0, "starts at 0")
	mc.add_energy(1000)
	assert_eq(mc.get_current_energy(), 1000, "after adding 1000")
	mc.add_energy(500)
	assert_eq(mc.get_current_energy(), 1500, "after adding 500 more")

func test_energy_changed_signal() -> void:
	begin("main_energy_changed signal emitted on add_energy")
	var mc := _make_cannon()
	var captured := [-1]
	mc.main_energy_changed.connect(func(v: int): captured[0] = v)
	mc.add_energy(100)
	assert_eq(captured[0], 100, "signal carries new current value")

func test_get_charge_threshold_base() -> void:
	begin("base charge threshold is 80000")
	_ensure_clean_game_state()
	var mc := _make_cannon()
	assert_eq(mc.get_charge_threshold(), 80000, "BASE = 80000 with no reduction")

func test_charge_threshold_with_reduction() -> void:
	begin("cannon_charge_reduction lowers threshold")
	_ensure_clean_game_state()
	GameState.cannon_charge_reduction = 2000
	var mc := _make_cannon()
	assert_eq(mc.get_charge_threshold(), 78000, "80000 - 2000 = 78000")
	GameState.cannon_charge_reduction = 0

func test_charge_threshold_minimum_1() -> void:
	begin("threshold never goes below 1")
	_ensure_clean_game_state()
	GameState.cannon_charge_reduction = 999999
	var mc := _make_cannon()
	assert_eq(mc.get_charge_threshold(), 1, "clamped to 1")
	GameState.cannon_charge_reduction = 0

func test_try_fire_below_threshold() -> void:
	begin("try_fire returns false below threshold")
	_ensure_clean_game_state()
	var mc := _make_cannon()
	mc.add_energy(1000)
	assert_false(mc.try_fire(), "below 80000 threshold")

func test_try_fire_at_threshold() -> void:
	begin("try_fire returns true at threshold")
	_ensure_clean_game_state()
	var mc := _make_cannon()
	mc.add_energy(80000)
	assert_true(mc.try_fire(), "at threshold, fires")

func test_try_fire_deducts_energy() -> void:
	begin("try_fire deducts threshold cost from current energy")
	_ensure_clean_game_state()
	var mc := _make_cannon()
	mc.add_energy(90000)
	mc.try_fire()
	assert_eq(mc.get_current_energy(), 10000, "90000 - 80000 = 10000")

func test_fired_signal_with_damage() -> void:
	begin("main_fired signal emitted with damage value")
	_ensure_clean_game_state()
	var mc := _make_cannon()
	var captured := [-1]
	mc.main_fired.connect(func(dmg: int): captured[0] = dmg)
	mc.add_energy(80000)
	mc.try_fire()
	assert_eq(captured[0], 10, "base damage = 10")

func test_damage_includes_bonus() -> void:
	begin("damage includes cannon_base_damage_bonus")
	_ensure_clean_game_state()
	GameState.cannon_base_damage_bonus = 15
	var mc := _make_cannon()
	var captured := [-1]
	mc.main_fired.connect(func(dmg: int): captured[0] = dmg)
	mc.add_energy(80000)
	mc.try_fire()
	assert_eq(captured[0], 25, "10 + 15 bonus = 25")
	GameState.cannon_base_damage_bonus = 0

func test_sim_tick_fires_when_ready() -> void:
	begin("sim_tick auto-fires when energy >= threshold")
	_ensure_clean_game_state()
	var mc := _make_cannon()
	var count := [0]
	mc.main_fired.connect(func(_d: int): count[0] += 1)
	mc.add_energy(80000)
	mc.sim_tick(0)
	assert_eq(count[0], 1, "sim_tick triggered fire")
	assert_lt(mc.get_current_energy(), 80000, "energy consumed")
