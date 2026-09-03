extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "WallHealthScaling"

func run() -> void:
	test_wall_hp_exponential_scaling()
	test_gold_breach_reward_scaling()
	test_no_arithmetic_overflow()

func test_wall_hp_exponential_scaling() -> void:
	begin("Wall HP scales exponentially across wall indices")
	var city: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[0]) as CityDefinition
	var hp0: int = city.get_wall_hp_max_for_index(0)
	var hp1: int = city.get_wall_hp_max_for_index(1)
	var hp2: int = city.get_wall_hp_max_for_index(2)
	assert_eq(hp0, city.wall_hp_max, "wall 0 HP equals base wall HP")
	assert_eq(hp1, int(roundf(float(hp0) * 1.35)), "wall 1 HP scales by 1.35x")
	assert_gt(hp2, hp1, "wall 2 HP is greater than wall 1 HP")

func test_gold_breach_reward_scaling() -> void:
	begin("Breach gold rewards scale exponentially across wall indices")
	var city: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[0]) as CityDefinition
	var g0: int = city.get_wall_breach_gold_reward(0)
	var g1: int = city.get_wall_breach_gold_reward(1)
	var g2: int = city.get_wall_breach_gold_reward(2)
	assert_eq(g0, Constants.BASE_WALL_BREACH_GOLD, "wall 0 gold equals base gold")
	assert_eq(g1, int(roundf(float(g0) * 1.25)), "wall 1 gold scales by 1.25x")
	assert_gt(g2, g1, "wall 2 gold is greater than wall 1 gold")

func test_no_arithmetic_overflow() -> void:
	begin("High wall indices calculate valid HP without overflow")
	var city: CityDefinition = load(Constants.CITY_DEFINITION_PATHS[0]) as CityDefinition
	var hp10: int = city.get_wall_hp_max_for_index(10)
	assert_gt(hp10, 0, "wall 10 HP is positive and non-zero")
	assert_gt(hp10, city.wall_hp_max, "wall 10 HP is significantly scaled")
