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
	test_volt_primer_lowers_threshold()
	test_volt_primer_resets_on_fire()

func _ensure_clean_game_state() -> void:
	if GameState:
		GameState.start_run(12345)

func _make_cannon() -> Node:
	var script: GDScript = load("res://scenes/systems/main_cannon/main_cannon.gd")
	var mc := Node.new()
	mc.set_script(script)
	return autofree(mc) as Node

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
	begin("base charge threshold is 10000 (100 display)")
	_ensure_clean_game_state()
	var mc := _make_cannon()
	assert_eq(mc.get_charge_threshold(), Constants.main_cannon_charge_internal(), "BASE = 100 display internal")

func test_charge_threshold_with_reduction() -> void:
	begin("cannon_charge_reduction lowers threshold")
	_ensure_clean_game_state()
	GameState.cannon_charge_reduction = 250
	var mc := _make_cannon()
	assert_eq(mc.get_charge_threshold(), Constants.main_cannon_charge_internal() - 250, "base - reduction")
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
	assert_false(mc.try_fire(), "below 10000 threshold")

func test_try_fire_at_threshold() -> void:
	begin("try_fire returns true at threshold")
	_ensure_clean_game_state()
	var mc := _make_cannon()
	mc.add_energy(Constants.main_cannon_charge_internal())
	assert_true(mc.try_fire(), "at threshold, fires")

func test_try_fire_deducts_energy() -> void:
	begin("try_fire deducts threshold cost from current energy")
	_ensure_clean_game_state()
	var mc := _make_cannon()
	var base: int = Constants.main_cannon_charge_internal()
	mc.add_energy(base + 1000)
	mc.try_fire()
	assert_eq(mc.get_current_energy(), 1000, "leftover after one shot")

func test_fired_signal_with_damage() -> void:
	begin("main_fired signal emitted with damage value")
	_ensure_clean_game_state()
	var mc := _make_cannon()
	var captured := [-1]
	mc.main_fired.connect(func(dmg: int): captured[0] = dmg)
	mc.add_energy(Constants.main_cannon_charge_internal())
	mc.try_fire()
	assert_eq(captured[0], 10, "base damage = 10")

func test_damage_includes_bonus() -> void:
	begin("damage includes cannon_base_damage_bonus")
	_ensure_clean_game_state()
	GameState.cannon_base_damage_bonus = 15
	var mc := _make_cannon()
	var captured := [-1]
	mc.main_fired.connect(func(dmg: int): captured[0] = dmg)
	mc.add_energy(Constants.main_cannon_charge_internal())
	mc.try_fire()
	assert_eq(captured[0], 25, "10 + 15 bonus = 25")
	GameState.cannon_base_damage_bonus = 0

func test_sim_tick_fires_when_ready() -> void:
	begin("sim_tick auto-fires when energy >= threshold")
	_ensure_clean_game_state()
	var mc := _make_cannon()
	var fired := [false]
	mc.main_fired.connect(func(_d: int): fired[0] = true)
	mc.add_energy(Constants.main_cannon_charge_internal())
	mc.sim_tick(0)
	assert_true(fired[0], "fired when ready")
	assert_lt(mc.get_current_energy(), Constants.main_cannon_charge_internal(), "energy consumed")

func test_volt_primer_lowers_threshold() -> void:
	begin("Volt Primer discount lowers charge threshold")
	_ensure_clean_game_state()
	GameState.add_wall_break_upgrade(&"volt_primer", 1)
	GameState.apply_volt_primer_on_energize()
	var mc := _make_cannon()
	var base: int = Constants.main_cannon_charge_internal()
	var disc: int = Constants.main_cannon_volt_primer_discount_internal()
	assert_eq(mc.get_charge_threshold(), base - disc, "threshold reduced by 5 display units")

func test_volt_primer_resets_on_fire() -> void:
	begin("Volt Primer clears after main cannon fires")
	_ensure_clean_game_state()
	GameState.add_wall_break_upgrade(&"volt_primer", 1)
	GameState.apply_volt_primer_on_energize()
	var mc := _make_cannon()
	mc.add_energy(Constants.main_cannon_charge_internal())
	mc.try_fire()
	assert_eq(GameState.main_cannon_volt_primer_discount, 0, "primer cleared")
	assert_eq(mc.get_charge_threshold(), Constants.main_cannon_charge_internal(), "threshold back to base")
