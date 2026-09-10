extends "res://tests/test_base.gd"

const BallScene: PackedScene = preload("res://scenes/balls/ball.tscn")
const HopperScript: GDScript = preload("res://scenes/hopper/hopper.gd")

func _init() -> void:
	suite_name = "BallEnergyReset"

func run() -> void:
	test_ball_base_energy_initialization()
	test_ball_accumulated_energy_reset()
	test_multi_cycle_energy_reset_does_not_compound()
	test_hopper_return_ball_resets_energy()
	test_board_spawn_ball_resets_energy()
	test_gas_buffs_cleared_on_reset()

func test_ball_base_energy_initialization() -> void:
	begin("Ball initializes with default base energy (3) and updates when BallDefinition is assigned")
	var ball: RigidBody2D = BallScene.instantiate() as RigidBody2D
	ball._ready()
	assert_eq(ball.get_total_energy(), 3, "Default ball energy is 3")
	assert_eq(ball.get_base_energy(), 3, "Default base energy is 3")
	
	var def: BallDefinition = BallDefinition.new()
	def.base_energy = 5
	ball.set_definition(def)
	assert_eq(ball.get_total_energy(), 5, "Ball energy matches definition base energy")
	assert_eq(ball.get_base_energy(), 5, "Ball base energy is 5")
	ball.free()

func test_ball_accumulated_energy_reset() -> void:
	begin("Ball accumulated peg energy resets cleanly to base energy")
	var ball: RigidBody2D = BallScene.instantiate() as RigidBody2D
	ball._ready()
	var def: BallDefinition = BallDefinition.new()
	def.base_energy = 5
	ball.set_definition(def)
	
	ball.add_peg_energy(10)
	assert_eq(ball.get_total_energy(), 15, "Energy should accumulate to 15 after peg hits")
	
	ball.reset_energy_to_base()
	assert_eq(ball.get_total_energy(), 5, "Energy should reset back to base value 5")
	ball.free()

func test_multi_cycle_energy_reset_does_not_compound() -> void:
	begin("Multiple board run cycles do not compound energy")
	var ball: RigidBody2D = BallScene.instantiate() as RigidBody2D
	ball._ready()
	var def: BallDefinition = BallDefinition.new()
	def.base_energy = 5
	ball.set_definition(def)
	
	for cycle: int in 4:
		ball.add_peg_energy(20)
		assert_eq(ball.get_total_energy(), 25, "Cycle %d: energy during run is 25" % cycle)
		ball.reset_energy_to_base()
		assert_eq(ball.get_total_energy(), 5, "Cycle %d: energy resets to base 5" % cycle)
	ball.free()

func test_hopper_return_ball_resets_energy() -> void:
	begin("Hopper return_ball resets ball energy to base energy")
	var parent_node: Node2D = Node2D.new()
	var container: Node2D = Node2D.new()
	container.name = "BallsContainer"
	parent_node.add_child(container)
	
	var hopper: Node2D = Node2D.new()
	hopper.set_script(HopperScript)
	parent_node.add_child(hopper)
	hopper._ready()
	
	var ball: RigidBody2D = BallScene.instantiate() as RigidBody2D
	ball._ready()
	var def: BallDefinition = BallDefinition.new()
	def.base_energy = 4
	ball.set_definition(def)
	ball.add_peg_energy(18)
	assert_eq(ball.get_total_energy(), 22, "Energy before hopper return is 22")
	
	hopper.return_ball(ball)
	assert_eq(ball.get_total_energy(), 4, "Energy after hopper return must be base energy 4")
	
	parent_node.free()

func test_board_spawn_ball_resets_energy() -> void:
	begin("Board spawn_ball_at_start resets ball energy to base energy")
	var board_script: GDScript = load("res://scenes/board/board.gd") as GDScript
	var board: Node2D = Node2D.new()
	board.set_script(board_script)
	var balls_container: Node2D = Node2D.new()
	balls_container.name = "BallsContainer"
	board.add_child(balls_container)
	board._ready()
	
	var ball: RigidBody2D = BallScene.instantiate() as RigidBody2D
	ball._ready()
	var def: BallDefinition = BallDefinition.new()
	def.base_energy = 6
	ball.set_definition(def)
	ball.add_peg_energy(14)
	assert_eq(ball.get_total_energy(), 20, "Energy before spawn is 20")
	
	board.spawn_ball_at_start(ball)
	assert_eq(ball.get_total_energy(), 6, "Energy after spawn_ball_at_start must be base energy 6")
	
	board.free()

func test_gas_buffs_cleared_on_reset() -> void:
	begin("Volatile gas damage and energy stacks clear when energy resets")
	var ball: RigidBody2D = BallScene.instantiate() as RigidBody2D
	ball._ready()
	
	ball.try_claim_gas_cloud(1, true)
	ball.try_claim_gas_cloud(2, false)
	assert_eq(ball.get_gas_damage_stack_count(), 1, "Gas damage stack is 1")
	assert_eq(ball.get_gas_energy_stack_count(), 1, "Gas energy stack is 1")
	
	ball.reset_energy_to_base()
	assert_eq(ball.get_gas_damage_stack_count(), 0, "Gas damage stack cleared on reset")
	assert_eq(ball.get_gas_energy_stack_count(), 0, "Gas energy stack cleared on reset")
	ball.free()
