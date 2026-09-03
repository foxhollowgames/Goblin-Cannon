extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "WallSiege"

func run() -> void:
	test_siege_timer_initialization()
	test_wall_destruction_auto_progression()
	test_defender_pushback_on_timeout()
	test_defender_pushback_at_wall_zero()

func test_siege_timer_initialization() -> void:
	begin("Siege timer initializes to 120 seconds during combat")
	var cm := _make_combat_manager()
	var city: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[0]) as CityDefinition
	cm.init_from_city(city)
	assert_eq(cm.get_timer_seconds_remaining(), 120.0, "timer starts at 120 seconds")
	assert_false(cm.is_time_expired(), "timer not expired initially")

func test_wall_destruction_auto_progression() -> void:
	begin("Wall destruction auto-advances combat state to next wall")
	var cm := _make_combat_manager()
	var city: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[0]) as CityDefinition
	cm.init_from_city(city)
	assert_eq(cm.get_current_wall_index(), 0, "starts at wall index 0")
	cm._on_main_fired(cm.get_wall_hp())
	assert_eq(cm.get_wall_hp(), 0, "wall HP depleted to 0")
	cm.advance_to_next_wall()
	assert_eq(cm.get_current_wall_index(), 1, "advanced to wall index 1")
	assert_gt(cm.get_wall_hp(), 0, "new wall has HP restored")

func test_defender_pushback_on_timeout() -> void:
	begin("Timer expiration triggers defender pushback to previous wall")
	var cm := _make_combat_manager()
	var city: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[0]) as CityDefinition
	cm.init_from_city(city)
	cm.advance_to_next_wall()
	assert_eq(cm.get_current_wall_index(), 1, "current wall index is 1")
	cm.apply_defender_pushback()
	assert_eq(cm.get_current_wall_index(), 0, "pushed back to wall index 0")
	assert_eq(cm.get_wall_hp(), cm.get_wall_hp_max(), "wall HP restored to 100%")

func test_defender_pushback_at_wall_zero() -> void:
	begin("Defender pushback at wall zero resets wall HP to max")
	var cm := _make_combat_manager()
	var city: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[0]) as CityDefinition
	cm.init_from_city(city)
	assert_eq(cm.get_current_wall_index(), 0, "current wall index is 0")
	cm._on_main_fired(50)
	assert_lt(cm.get_wall_hp(), cm.get_wall_hp_max(), "wall HP reduced")
	cm.apply_defender_pushback()
	assert_eq(cm.get_current_wall_index(), 0, "remains at wall index 0")
	assert_eq(cm.get_wall_hp(), cm.get_wall_hp_max(), "wall HP reset to 100%")

func _make_combat_manager() -> Node:
	var script: GDScript = load("res://scenes/main/combat_manager.gd")
	var cm := Node.new()
	cm.set_script(script)
	return cm
