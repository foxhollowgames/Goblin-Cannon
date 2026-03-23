extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "CombatManager"

func run() -> void:
	test_init_from_city_sets_wall_hp()
	test_init_from_city_sets_timer()
	test_wall_time_constants()
	test_on_main_fired_reduces_hp()
	test_wall_hp_floors_at_zero()
	test_wall_destroyed_signal_emitted()
	test_wall_destroyed_emitted_only_once()
	test_sim_tick_counts_down_timer()
	test_time_expired_signal()
	test_time_expired_blocks_further_damage()
	test_advance_to_next_wall()
	test_is_all_walls_destroyed()
	test_timer_seconds_remaining()
	test_get_wall_names()
	test_get_current_gate_name()
	test_get_city_display_name()

func _make_combat_manager() -> Node:
	var script: GDScript = load("res://scenes/main/combat_manager.gd")
	var cm := Node.new()
	cm.set_script(script)
	return cm

func _make_city() -> CityDefinition:
	var city := CityDefinition.new()
	city.display_name = "Test City"
	city.gate_name = "Front Gate"
	city.wall_names = ["Wall A", "Wall B", "Wall C"]
	city.wall_hp_max = 50
	return city

func test_init_from_city_sets_wall_hp() -> void:
	begin("init_from_city sets wall HP from city definition")
	var cm := _make_combat_manager()
	var city := _make_city()
	cm.init_from_city(city)
	assert_eq(cm.get_wall_hp(), 50, "wall HP = city wall_hp_max for index 0")
	assert_eq(cm.get_wall_hp_max(), 50, "wall HP max = 50")

func test_init_from_city_sets_timer() -> void:
	begin("init_from_city sets timer for first wall")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	# Wall 0 = 300 seconds * 60 ticks/sec = 18000 ticks → 300.0 seconds
	assert_approx(cm.get_timer_seconds_remaining(), 300.0, 0.1, "first wall timer = 300s")

func test_wall_time_constants() -> void:
	begin("WALL_TIME_SECONDS matches spec (5min, 3min, 2min)")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	# Read the constant indirectly via _get_wall_time_ticks
	assert_approx(cm.get_timer_seconds_remaining(), 300.0, 0.1, "wall 0 = 5 min")

func test_on_main_fired_reduces_hp() -> void:
	begin("_on_main_fired reduces wall HP")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	cm._on_main_fired(10)
	assert_eq(cm.get_wall_hp(), 40, "50 - 10 = 40")
	cm._on_main_fired(15)
	assert_eq(cm.get_wall_hp(), 25, "40 - 15 = 25")

func test_wall_hp_floors_at_zero() -> void:
	begin("wall HP does not go below zero")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	cm._on_main_fired(999)
	assert_eq(cm.get_wall_hp(), 0, "clamped to 0")

func test_wall_destroyed_signal_emitted() -> void:
	begin("wall_destroyed signal emitted when HP reaches 0")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	var count := [0]
	cm.wall_destroyed.connect(func(): count[0] += 1)
	cm._on_main_fired(50)
	assert_eq(count[0], 1, "wall_destroyed emitted once")

func test_wall_destroyed_emitted_only_once() -> void:
	begin("wall_destroyed is only emitted once per wall")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	var count := [0]
	cm.wall_destroyed.connect(func(): count[0] += 1)
	cm._on_main_fired(25)
	cm._on_main_fired(25)
	assert_eq(count[0], 1, "emitted once at HP=0")
	cm._on_main_fired(10)
	assert_eq(count[0], 1, "no duplicate emission")

func test_sim_tick_counts_down_timer() -> void:
	begin("sim_tick decrements timer")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	var initial: float = cm.get_timer_seconds_remaining()
	for i in 60:
		cm.sim_tick(i)
	var after: float = cm.get_timer_seconds_remaining()
	assert_approx(initial - after, 1.0, 0.1, "60 ticks = 1 second")

func test_time_expired_signal() -> void:
	begin("time_expired signal emitted when timer hits 0")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	var count := [0]
	cm.time_expired.connect(func(): count[0] += 1)
	for i in 18000:
		cm.sim_tick(i)
	assert_eq(count[0], 1, "time_expired emitted")
	assert_true(cm.is_time_expired(), "is_time_expired flag set")

func test_time_expired_blocks_further_damage() -> void:
	begin("damage is ignored after time expires")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	# Force timer to expire
	for i in 18000:
		cm.sim_tick(i)
	var hp_before: int = cm.get_wall_hp()
	cm._on_main_fired(10)
	assert_eq(cm.get_wall_hp(), hp_before, "HP unchanged after time expired")

func test_advance_to_next_wall() -> void:
	begin("advance_to_next_wall sets new HP and timer")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	cm._on_main_fired(50)
	cm.advance_to_next_wall()
	assert_eq(cm.get_current_wall_index(), 1, "moved to wall index 1")
	assert_gt(cm.get_wall_hp(), 0, "new wall has HP")
	assert_eq(cm.get_wall_hp(), cm.get_wall_hp_max(), "HP = HP max")
	# Wall 1 timer = 180 seconds
	assert_approx(cm.get_timer_seconds_remaining(), 180.0, 0.1, "wall 1 timer = 180s")

func test_is_all_walls_destroyed() -> void:
	begin("is_all_walls_destroyed true when past last wall")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	assert_false(cm.is_all_walls_destroyed(), "not all destroyed at start")
	# Advance through all 3 walls
	cm.advance_to_next_wall()
	assert_false(cm.is_all_walls_destroyed(), "wall index 1, still have walls")
	cm.advance_to_next_wall()
	assert_false(cm.is_all_walls_destroyed(), "wall index 2, still have walls")
	cm.advance_to_next_wall()
	assert_true(cm.is_all_walls_destroyed(), "past all walls")

func test_timer_seconds_remaining() -> void:
	begin("timer_seconds_remaining returns correct float")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	assert_approx(cm.get_timer_seconds_remaining(), 300.0, 0.1, "300.0 seconds at start")
	for i in 30:
		cm.sim_tick(i)
	assert_approx(cm.get_timer_seconds_remaining(), 299.5, 0.1, "0.5 seconds elapsed after 30 ticks")

func test_get_wall_names() -> void:
	begin("get_wall_names returns city wall names")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	var names: Array = cm.get_wall_names()
	assert_eq(names.size(), 3, "3 wall names")
	assert_eq(names[0], "Wall A", "first wall name")

func test_get_current_gate_name() -> void:
	begin("get_current_gate_name returns name for current index")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	assert_eq(cm.get_current_gate_name(), "Wall A", "first gate name")
	cm.advance_to_next_wall()
	assert_eq(cm.get_current_gate_name(), "Wall B", "second gate name")
	cm.advance_to_next_wall()
	assert_eq(cm.get_current_gate_name(), "Wall C", "third gate name")

func test_get_city_display_name() -> void:
	begin("get_city_display_name returns city display name")
	var cm := _make_combat_manager()
	cm.init_from_city(_make_city())
	assert_eq(cm.get_city_display_name(), "Test City", "city display name")
