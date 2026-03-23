extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "GameState"

func run() -> void:
	test_start_run_resets_values()
	test_start_run_sets_seed()
	test_record_ball_ability()
	test_record_ball_ability_no_duplicates()
	test_record_ball_ability_ignores_empty()
	test_has_ball_ability()
	test_wall_break_upgrade_stacking()
	test_has_wall_break_upgrade()
	test_run_flow_state_fighting()
	test_run_flow_state_reward_paused()
	test_start_run_clears_upgrades()
	test_explosion_radius_bonus_resets()
	test_chain_arc_bonus_resets()
	test_peg_durability_bonus_resets()

func test_start_run_resets_values() -> void:
	begin("start_run resets all run-scoped values")
	GameState.cannon_charge_reduction = 999
	GameState.cannon_base_damage_bonus = 50
	GameState.main_charge_bonus = 0.5
	GameState.hopper_width_scale = 2.0
	GameState.start_run(42)
	assert_eq(GameState.cannon_charge_reduction, 0, "cannon_charge_reduction reset")
	assert_eq(GameState.cannon_base_damage_bonus, 0, "cannon_base_damage_bonus reset")
	assert_approx(GameState.main_charge_bonus, 0.0, 0.001, "main_charge_bonus reset")
	assert_approx(GameState.hopper_width_scale, 1.0, 0.001, "hopper_width_scale reset")

func test_start_run_sets_seed() -> void:
	begin("start_run sets run_seed")
	GameState.start_run(12345)
	assert_eq(GameState.run_seed, 12345, "seed = 12345")

func test_record_ball_ability() -> void:
	begin("record_ball_ability_in_run adds ability name")
	GameState.start_run(1)
	GameState.record_ball_ability_in_run("Bounce")
	assert_true(GameState.has_ball_ability_in_run("Bounce"), "Bounce recorded")

func test_record_ball_ability_no_duplicates() -> void:
	begin("record_ball_ability_in_run does not duplicate")
	GameState.start_run(1)
	GameState.record_ball_ability_in_run("Split")
	GameState.record_ball_ability_in_run("Split")
	assert_eq(GameState.ball_ability_names_in_run.size(), 1, "only one entry")

func test_record_ball_ability_ignores_empty() -> void:
	begin("record_ball_ability_in_run ignores empty string")
	GameState.start_run(1)
	GameState.record_ball_ability_in_run("")
	assert_eq(GameState.ball_ability_names_in_run.size(), 0, "nothing recorded for empty")

func test_has_ball_ability() -> void:
	begin("has_ball_ability_in_run checks presence")
	GameState.start_run(1)
	assert_false(GameState.has_ball_ability_in_run("Phantom"), "not yet recorded")
	GameState.record_ball_ability_in_run("Phantom")
	assert_true(GameState.has_ball_ability_in_run("Phantom"), "now recorded")

func test_wall_break_upgrade_stacking() -> void:
	begin("add_wall_break_upgrade stacks correctly")
	GameState.start_run(1)
	GameState.add_wall_break_upgrade(&"impact_burst", 1)
	assert_eq(GameState.get_wall_break_upgrade_stacks(&"impact_burst"), 1, "first stack")
	GameState.add_wall_break_upgrade(&"impact_burst", 1)
	assert_eq(GameState.get_wall_break_upgrade_stacks(&"impact_burst"), 2, "second stack")

func test_has_wall_break_upgrade() -> void:
	begin("has_wall_break_upgrade checks > 0 stacks")
	GameState.start_run(1)
	assert_false(GameState.has_wall_break_upgrade(&"blast_lift"), "no stacks = false")
	GameState.add_wall_break_upgrade(&"blast_lift", 1)
	assert_true(GameState.has_wall_break_upgrade(&"blast_lift"), "1 stack = true")

func test_run_flow_state_fighting() -> void:
	begin("set_run_flow_state FIGHTING restores sim_speed and paused")
	GameState.start_run(1)
	GameState.set_run_flow_state(GameState.RunFlowState.REWARD_PAUSED)
	assert_true(GameState.paused, "paused after REWARD_PAUSED")
	GameState.set_run_flow_state(GameState.RunFlowState.FIGHTING)
	assert_false(GameState.paused, "unpaused after FIGHTING")
	assert_approx(GameState.sim_speed, 1.0, 0.001, "sim_speed = 1.0")

func test_run_flow_state_reward_paused() -> void:
	begin("set_run_flow_state REWARD_PAUSED sets paused")
	GameState.start_run(1)
	GameState.set_run_flow_state(GameState.RunFlowState.REWARD_PAUSED)
	assert_true(GameState.paused, "paused = true")

func test_start_run_clears_upgrades() -> void:
	begin("start_run clears applied_wall_break_upgrades")
	GameState.add_wall_break_upgrade(&"test_upgrade", 3)
	GameState.start_run(1)
	assert_eq(GameState.get_wall_break_upgrade_stacks(&"test_upgrade"), 0, "cleared after start_run")

func test_explosion_radius_bonus_resets() -> void:
	begin("explosion_radius_bonus resets on start_run")
	GameState.explosion_radius_bonus = 5
	GameState.start_run(1)
	assert_eq(GameState.explosion_radius_bonus, 0, "reset to 0")

func test_chain_arc_bonus_resets() -> void:
	begin("chain_arc_bonus resets on start_run")
	GameState.chain_arc_bonus = 3
	GameState.start_run(1)
	assert_eq(GameState.chain_arc_bonus, 0, "reset to 0")

func test_peg_durability_bonus_resets() -> void:
	begin("global_peg_durability_bonus resets on start_run")
	GameState.global_peg_durability_bonus = 2
	GameState.start_run(1)
	assert_eq(GameState.global_peg_durability_bonus, 0, "reset to 0")
