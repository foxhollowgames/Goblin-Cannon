extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "VolatileGas"

func run() -> void:
	test_gas_claim_once_per_cloud()
	test_clear_buffs_on_score()

func test_gas_claim_once_per_cloud() -> void:
	begin("try_claim_gas_cloud stacks per distinct cloud id")
	var b: Node = RigidBody2D.new()
	b.set_script(load("res://scenes/balls/ball.gd"))
	b.try_claim_gas_cloud(1, true)
	b.try_claim_gas_cloud(1, true)
	assert_eq(b.get_gas_damage_stack_count(), 1, "duplicate id ignored")
	b.try_claim_gas_cloud(2, false)
	assert_eq(b.get_gas_damage_stack_count(), 1, "still one damage")
	assert_eq(b.get_gas_energy_stack_count(), 1, "one energy stack")

func test_clear_buffs_on_score() -> void:
	begin("clear_gas_buffs_on_score resets stacks")
	var b: Node = RigidBody2D.new()
	b.set_script(load("res://scenes/balls/ball.gd"))
	b.try_claim_gas_cloud(10, true)
	b.try_claim_gas_cloud(11, false)
	b.clear_gas_buffs_on_score()
	assert_eq(b.get_gas_damage_stack_count(), 0, "damage cleared")
	assert_eq(b.get_gas_energy_stack_count(), 0, "energy cleared")
