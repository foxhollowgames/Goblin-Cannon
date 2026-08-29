extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const BoardScript = preload("res://scenes/board/board.gd")
const PolyominoModuleNodeScript = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const PinballBumperScript = preload("res://scenes/board/machinery/pinball_bumper.gd")
const SpeedBoostWheelScript = preload("res://scenes/board/machinery/speed_boost_wheel.gd")
const ManaSiphonScript = preload("res://scenes/board/machinery/mana_siphon.gd")
const DirectionalDeflectorScript = preload("res://scenes/board/machinery/directional_deflector.gd")
const BallScript = preload("res://scenes/balls/ball.gd")

func _init() -> void:
	suite_name = "PolyominoMachinery"

func run() -> void:
	test_pinball_bumper_physics_and_energy()
	test_speed_boost_wheel_acceleration_and_direction()
	test_mana_siphon_permeability_and_energy()
	test_directional_deflector_funneling()
	test_compound_module_assembly_and_scaling()
	test_compound_module_rotation_and_vectors()
	test_board_machinery_collision_and_lifecycle()

func _create_mock_ball(pos: Vector2 = Vector2.ZERO, vel: Vector2 = Vector2.ZERO, start_energy: int = 10) -> RigidBody2D:
	var ball := RigidBody2D.new()
	ball.set_script(BallScript)
	ball._ready()
	ball.position = pos
	ball.linear_velocity = vel
	ball.set_total_energy_display(start_energy)
	return ball

func test_pinball_bumper_physics_and_energy() -> void:
	begin("Pinball Bumper outward impulse, bonus energy, and cooldown")
	var bumper: PinballBumper = PinballBumperScript.new()
	bumper.position = Vector2(100, 100)

	var ball := _create_mock_ball(Vector2(100, 80), Vector2(0, 50), 10)

	# Ball approaching from above: diff is (0, -20) -> outward impulse is (0, -380)
	var res1: Dictionary = bumper.trigger_activation(ball, 10)
	assert_true(res1.get("activated", false), "bumper activates on ball contact")
	assert_eq(res1.get("energy_granted", 0), 5, "bumper grants +5 bonus energy")
	assert_eq(ball.get_total_energy(), 15, "ball energy increased from 10 to 15")

	var impulse: Vector2 = res1.get("impulse_applied", Vector2.ZERO)
	assert_true(impulse.y < -100.0, "impulse pushes ball upward away from bumper")

	# Cooldown test: same ball in next tick (11) must be rejected (< 3 ticks)
	var res2: Dictionary = bumper.trigger_activation(ball, 11)
	assert_false(res2.get("activated", false), "cooldown blocks repeat activation within 3 ticks")

	# Tick 13 (diff = 3 ticks) must activate again
	var res3: Dictionary = bumper.trigger_activation(ball, 13)
	assert_true(res3.get("activated", false), "bumper activates again after cooldown expires")

	ball.free()
	bumper.free()

func test_speed_boost_wheel_acceleration_and_direction() -> void:
	begin("Speed Boost Wheel vector acceleration and rotation reorientation")
	var wheel: SpeedBoostWheel = SpeedBoostWheelScript.new()
	wheel.position = Vector2(200, 200)
	wheel.direction = Vector2.RIGHT # Accelerate to the right (1, 0)
	wheel.base_energy = 4

	var ball := _create_mock_ball(Vector2(200, 200), Vector2(0, 100), 20)

	var res: Dictionary = wheel.trigger_activation(ball, 100)
	assert_true(res.get("activated", false), "speed wheel activates on contact")
	assert_eq(res.get("energy_granted", 0), 4, "speed wheel grants +4 bonus energy")
	assert_eq(ball.get_total_energy(), 24, "ball total energy updated to 24")

	# Ball should now be accelerated heavily to the right
	assert_gte(ball.linear_velocity.x, 400.0, "ball linear_velocity.x accelerated to >= 400")

	ball.free()
	wheel.free()

func test_mana_siphon_permeability_and_energy() -> void:
	begin("Mana Siphon permeable pass-through and bonus energy without deflection")
	var siphon: ManaSiphon = ManaSiphonScript.new()
	siphon.position = Vector2(300, 300)
	siphon.base_energy = 8

	assert_true(siphon.is_permeable, "mana siphon is marked permeable")

	var initial_vel := Vector2(120, 250)
	var ball := _create_mock_ball(Vector2(300, 300), initial_vel, 15)

	var res: Dictionary = siphon.trigger_activation(ball, 50)
	assert_true(res.get("activated", false), "mana siphon activates on ball pass")
	assert_eq(res.get("energy_granted", 0), 8, "mana siphon grants +8 energy")
	assert_eq(ball.get_total_energy(), 23, "ball total energy updated to 23")

	# Trajectory must NOT be deflected
	assert_eq(res.get("impulse_applied", Vector2.ONE), Vector2.ZERO, "impulse applied is Vector2.ZERO")
	assert_eq(ball.linear_velocity, initial_vel, "ball velocity is completely unchanged")

	ball.free()
	siphon.free()

func test_directional_deflector_funneling() -> void:
	begin("Directional Deflector funneling and ball velocity redirection")
	var deflector: DirectionalDeflector = DirectionalDeflectorScript.new()
	deflector.position = Vector2(150, 250)
	deflector.direction = Vector2(1, 1).normalized() # Down-Right diagonal
	deflector.base_energy = 2

	var ball := _create_mock_ball(Vector2(150, 250), Vector2(-100, 150), 10)

	var res: Dictionary = deflector.trigger_activation(ball, 75)
	assert_true(res.get("activated", false), "deflector activates on contact")
	assert_eq(res.get("energy_granted", 0), 2, "deflector grants +2 energy")

	# Ball should be steered into the down-right direction (positive x and positive y)
	assert_gt(ball.linear_velocity.x, 0.0, "steered velocity x > 0")
	assert_gt(ball.linear_velocity.y, 0.0, "steered velocity y > 0")

	ball.free()
	deflector.free()

func test_compound_module_assembly_and_scaling() -> void:
	begin("Compound PolyominoModuleNode multi-cell assembly and spatial layout")
	var mod_data := PolyominoModuleData.new()
	mod_data.module_id = &"synergy_t_module"
	mod_data.tier = 2
	# 4 cells: (0,0)=BUMPER, (1,0)=ACCELERATOR, (2,0)=MANA_SIPHON, (1,1)=DIRECTIONAL_DEFLECTOR
	mod_data.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)]
	mod_data.set_cell_type_at(Vector2i(0, 0), PolyominoModuleData.CellType.BUMPER)
	mod_data.set_cell_type_at(Vector2i(1, 0), PolyominoModuleData.CellType.ACCELERATOR)
	mod_data.set_cell_type_at(Vector2i(2, 0), PolyominoModuleData.CellType.MANA_SIPHON)
	mod_data.set_cell_type_at(Vector2i(1, 1), PolyominoModuleData.CellType.DIRECTIONAL_DEFLECTOR)

	var item := JunkBoxItem.new(&"item_t", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data

	var module_node := PolyominoModuleNodeScript.new()
	module_node.setup_module(item, Vector2i(3, 2), 0)

	var all_comps: Array[PolyominoMachineryComponent] = module_node.get_all_components()
	assert_eq(all_comps.size(), 4, "compound module created 4 internal machinery components")

	var c0: PolyominoMachineryComponent = module_node.get_component_at_local_cell(Vector2i(0, 0))
	assert_true(c0 != null, "component at (0,0) exists")
	assert_true(c0 is PinballBumperScript, "component at (0,0) is PinballBumper")
	assert_eq(c0.position, Vector2(0, 0), "c0 at origin (0,0)")

	var c1: PolyominoMachineryComponent = module_node.get_component_at_local_cell(Vector2i(1, 0))
	assert_true(c1 != null, "component at (1,0) exists")
	assert_true(c1 is SpeedBoostWheelScript, "component at (1,0) is SpeedBoostWheel")
	assert_eq(c1.position, Vector2(module_node.CELL_WIDTH, 0), "c1 scaled by CELL_WIDTH")

	var c2: PolyominoMachineryComponent = module_node.get_component_at_local_cell(Vector2i(2, 0))
	assert_true(c2 != null, "component at (2,0) exists")
	assert_true(c2 is ManaSiphonScript, "component at (2,0) is ManaSiphon")

	var c3: PolyominoMachineryComponent = module_node.get_component_at_local_cell(Vector2i(1, 1))
	assert_true(c3 != null, "component at (1,1) exists")
	assert_true(c3 is DirectionalDeflectorScript, "component at (1,1) is DirectionalDeflector")
	assert_eq(c3.position, Vector2(module_node.CELL_WIDTH, module_node.CELL_HEIGHT), "c3 scaled by width & height")

	module_node.free()

func test_compound_module_rotation_and_vectors() -> void:
	begin("Compound module 90° CW rotation and vector reorientation")
	var mod_data := PolyominoModuleData.new()
	mod_data.module_id = &"rot_test_bar"
	mod_data.cells = [Vector2i(0, 0), Vector2i(1, 0)]
	mod_data.set_cell_type_at(Vector2i(0, 0), PolyominoModuleData.CellType.ACCELERATOR)
	mod_data.set_cell_direction_at(Vector2i(0, 0), Vector2.RIGHT) # (1, 0)
	mod_data.set_cell_type_at(Vector2i(1, 0), PolyominoModuleData.CellType.BUMPER)

	var item := JunkBoxItem.new(&"item_rot", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data

	# Rotate 90° CW (step 1)
	var module_node := PolyominoModuleNodeScript.new()
	module_node.setup_module(item, Vector2i(2, 2), 1)

	# 90° CW rotation transforms (1, 0) -> down vector in 2D (0, 1)
	var comp0: PolyominoMachineryComponent = module_node.get_all_components()[0]
	assert_eq(comp0.direction, Vector2.DOWN, "accelerator direction rotated 90° CW from RIGHT to DOWN")

	module_node.free()

func test_board_machinery_collision_and_lifecycle() -> void:
	begin("Board module placement, collision interaction during sim step, and unslotting")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)

	var mod_data := PolyominoModuleData.new()
	mod_data.module_id = &"board_bumper_test"
	mod_data.cells = [Vector2i(0, 0)]
	mod_data.set_cell_type_at(Vector2i(0, 0), PolyominoModuleData.CellType.BUMPER)
	mod_data.set_cell_energy_value(Vector2i(0, 0), 7)

	var item := JunkBoxItem.new(&"bumper_item_1", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod_data

	# Place at grid cell (4, 3)
	assert_true(board.place_module(item, Vector2i(4, 3), 0), "placed module on board")

	var cell_world_pos: Vector2 = board.board_cell_to_world(Vector2i(4, 3))
	var ball := _create_mock_ball(cell_world_pos + Vector2(0, -10), Vector2(0, 40), 10)
	board._active_balls.append(ball)

	# Run simulation step
	board.run_ball_steps(200)

	# Ball should have collided with bumper at (4,3)
	assert_eq(ball.get_total_energy(), 17, "ball gained +7 energy from board bumper interaction")

	# Unslot module from board
	var unslotted: Resource = board.unslot_module(&"bumper_item_1")
	assert_eq(unslotted, item, "unslot returns item")
	assert_eq(board.get_all_placed_modules().size(), 0, "no placed modules remaining")

	ball.free()
	board.free()
