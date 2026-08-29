extends "res://tests/test_base.gd"

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")
const BoardScript = preload("res://scenes/board/board.gd")
const PolyominoModuleNodeScript = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const PegScript = preload("res://scenes/board/peg.gd")
const BallScript = preload("res://scenes/balls/ball.gd")

func _init() -> void:
	suite_name = "LiveBoardGhostPlacement"

func run() -> void:
	test_module_placement_ghost_state_when_balls_overlap()
	test_module_transition_to_active_solid_state_when_balls_leave()
	test_module_placement_immediate_solid_when_no_balls()
	test_peg_placement_ghost_state_when_balls_overlap()
	test_peg_transition_to_active_when_ball_clears()
	test_moving_component_does_not_trap_balls()
	test_signals_emitted_during_ghost_transitions()
	test_unslotting_ghost_and_solid_components()

func _create_mock_ball(pos: Vector2 = Vector2.ZERO, vel: Vector2 = Vector2.ZERO) -> RigidBody2D:
	var ball := RigidBody2D.new()
	ball.set_script(BallScript)
	ball._ready()
	ball.position = pos
	ball.linear_velocity = vel
	return ball

func test_module_placement_ghost_state_when_balls_overlap() -> void:
	begin("Polyomino module enters ghost state (50% opacity, non-colliding) when overlapping active ball")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	# Add active ball at grid cell (2, 2) world coordinates
	var ball_pos: Vector2 = board.board_cell_to_world(Vector2i(2, 2))
	var ball := _create_mock_ball(ball_pos)
	board._active_balls.append(ball)

	# Create a 2x2 box module placed at (2, 2)
	var mod := PolyominoModuleData.new()
	mod.module_id = &"box_2x2"
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	mod.cell_types[Vector2i(0, 0)] = PolyominoModuleData.CellType.BUMPER

	var item := JunkBoxItem.new(&"mod_ghost_1", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod

	# Place module overlapping the ball
	var placed: bool = board.place_module(item, Vector2i(2, 2))
	assert_true(placed, "place_module returns true")
	assert_true(board.is_module_in_ghost_state(&"mod_ghost_1"), "module registered in ghost state")
	assert_eq(board.get_ghost_modules().size(), 1, "1 module in ghost state")

	var mod_node: PolyominoModuleNode = board._placed_module_nodes.get(&"mod_ghost_1") as PolyominoModuleNode
	assert_true(mod_node != null, "module visual node exists")
	assert_true(mod_node.is_ghost_state_active(), "module node is_ghost is true")
	assert_eq(mod_node.modulate.a, 0.5, "module node renders at 50% opacity (alpha = 0.5)")

	# Ghost state components do not deflect balls or activate
	var col_res: Dictionary = mod_node.check_ball_collision(ball, 10)
	assert_false(col_res.get("activated", false), "ghost module does not activate or deflect ball")

	ball.free()
	board.free()

func test_module_transition_to_active_solid_state_when_balls_leave() -> void:
	begin("Polyomino module transitions to 100% opacity and active solid state when balls leave")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	# Active ball initially at cell (3, 2)
	var ball_pos: Vector2 = board.board_cell_to_world(Vector2i(3, 2))
	var ball := _create_mock_ball(ball_pos)
	board._active_balls.append(ball)

	var mod := PolyominoModuleData.new()
	mod.module_id = &"bar_1x2"
	mod.cells = [Vector2i(0, 0), Vector2i(1, 0)]
	mod.cell_types[Vector2i(0, 0)] = PolyominoModuleData.CellType.BUMPER
	mod.cell_types[Vector2i(1, 0)] = PolyominoModuleData.CellType.BUMPER

	var item := JunkBoxItem.new(&"mod_transition_1", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod

	board.place_module(item, Vector2i(2, 2))
	assert_true(board.is_module_in_ghost_state(&"mod_transition_1"), "module starts in ghost state")

	var mod_node: PolyominoModuleNode = board._placed_module_nodes.get(&"mod_transition_1") as PolyominoModuleNode
	assert_eq(mod_node.modulate.a, 0.5, "starts at 50% opacity")

	# Move the ball away to cell (8, 8)
	ball.position = board.board_cell_to_world(Vector2i(8, 8))
	assert_true(board.is_module_area_clear_of_balls(item), "module area is now clear of balls")

	# Process ghost states
	board._process_ghost_states(15)
	assert_false(board.is_module_in_ghost_state(&"mod_transition_1"), "module is no longer in ghost state")
	assert_eq(board.get_ghost_modules().size(), 0, "0 ghost modules remaining")
	assert_false(mod_node.is_ghost_state_active(), "module node is solid")
	assert_eq(mod_node.modulate.a, 1.0, "module node becomes 100% opaque")

	# Once solid, ball collision activates normally
	var bumper = mod_node.get_component_at_local_cell(Vector2i(0, 0))
	assert_true(bumper != null, "bumper component found")
	ball.position = mod_node.position + bumper.position
	var col_res: Dictionary = mod_node.check_ball_collision(ball, 20)
	assert_true(col_res.get("activated", false), "solid module machinery activates on contact")

	ball.free()
	board.free()

func test_module_placement_immediate_solid_when_no_balls() -> void:
	begin("Polyomino module placed on empty area immediately enters 100% solid state")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0), Vector2i(0, 1)]

	var item := JunkBoxItem.new(&"mod_solid_1", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod

	board.place_module(item, Vector2i(4, 4))
	assert_false(board.is_module_in_ghost_state(&"mod_solid_1"), "module placed without ball overlap is solid")

	var mod_node: PolyominoModuleNode = board._placed_module_nodes.get(&"mod_solid_1") as PolyominoModuleNode
	assert_false(mod_node.is_ghost_state_active(), "mod_node is not ghost")
	assert_eq(mod_node.modulate.a, 1.0, "mod_node is 100% opaque")

	board.free()

func test_peg_placement_ghost_state_when_balls_overlap() -> void:
	begin("Peg placed overlapping active ball enters ghost state (50% opacity, disabled collider)")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	var peg_pos: Vector2 = board.board_cell_to_world(Vector2i(5, 5))
	var ball := _create_mock_ball(peg_pos)
	board._active_balls.append(ball)

	var peg: Node = board.place_peg_at_cell(Vector2i(5, 5))
	assert_true(peg != null, "peg created")
	assert_true(peg.has_method("is_ghost_placement_active"), "peg has ghost placement check")
	assert_true(peg.is_ghost_placement_active(), "peg starts in ghost placement state")
	assert_eq(peg.modulate.a, 0.5, "peg opacity is 50%")
	assert_eq(peg.collision_layer, 0, "peg physics collision layer is disabled (0)")

	# Ghost peg ignores damage hits
	var init_dur: int = peg.get_durability() if peg.has_method("get_durability") else 3
	if peg.has_method("apply_hit"):
		peg.apply_hit(true, 1, false)
		assert_eq(peg.get_durability(), init_dur, "ghost peg ignores apply_hit damage")

	ball.free()
	board.free()

func test_peg_transition_to_active_when_ball_clears() -> void:
	begin("Peg transitions to solid (100% opacity, enabled collider) when overlapping ball moves away")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	var peg_pos: Vector2 = board.board_cell_to_world(Vector2i(6, 4))
	var ball := _create_mock_ball(peg_pos)
	board._active_balls.append(ball)

	var peg: Node = board.place_peg_at_cell(Vector2i(6, 4))
	assert_true(peg.is_ghost_placement_active(), "peg in ghost state")

	# Ball moves away
	ball.position = Vector2(0, 0)
	assert_true(board.is_peg_area_clear_of_balls(peg), "peg area is clear")

	board._process_ghost_states(30)
	assert_false(peg.is_ghost_placement_active(), "peg is solid")
	assert_eq(peg.modulate.a, 1.0, "peg is 100% opaque")
	assert_eq(peg.collision_layer, 1, "peg physics collision layer is enabled (1)")

	# Once solid, peg takes hit damage normally
	var dur_before: int = peg.get_durability()
	peg.apply_hit(true, 1, false)
	assert_eq(peg.get_durability(), dur_before - 1, "solid peg takes damage from apply_hit")

	ball.free()
	board.free()

func test_moving_component_does_not_trap_balls() -> void:
	begin("Moving module or peg over moving ball allows ball to continue without physics traps")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	# Ball moving with velocity through cell (3, 3)
	var ball_pos: Vector2 = board.board_cell_to_world(Vector2i(3, 3))
	var ball := _create_mock_ball(ball_pos, Vector2(100, 200))
	board._active_balls.append(ball)

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0)]
	var item := JunkBoxItem.new(&"trap_test_mod", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod

	# Live-place directly on top of the moving ball
	board.place_module(item, Vector2i(3, 3))
	assert_true(board.is_module_in_ghost_state(&"trap_test_mod"), "entered ghost state")

	# Ball velocity is not zeroed or trapped
	assert_eq(ball.linear_velocity, Vector2(100, 200), "ball velocity remains untouched")

	# Ball moves past the module cell
	ball.position += Vector2(100.0, 100.0)
	board._process_ghost_states(40)
	assert_false(board.is_module_in_ghost_state(&"trap_test_mod"), "module solidifies after ball moves past")

	ball.free()
	board.free()

func test_signals_emitted_during_ghost_transitions() -> void:
	begin("Ghost state changes and solidifying transitions emit signals")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	var ghost_signals: Array = []
	var solid_signals: Array = []

	board.ghost_state_changed.connect(func(comp, is_ghost): ghost_signals.append([comp, is_ghost]))
	board.module_solidified.connect(func(mod_item): solid_signals.append(mod_item))

	var ball_pos: Vector2 = board.board_cell_to_world(Vector2i(1, 1))
	var ball := _create_mock_ball(ball_pos)
	board._active_balls.append(ball)

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0)]
	var item := JunkBoxItem.new(&"sig_mod", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod

	# 1. Place with overlap -> ghost_state_changed(item, true)
	board.place_module(item, Vector2i(1, 1))
	assert_eq(ghost_signals.size(), 1, "ghost_state_changed emitted")
	assert_eq(ghost_signals[0][1], true, "is_ghost = true")
	assert_eq(solid_signals.size(), 0, "no solid signal yet")

	# 2. Clear ball and process -> ghost_state_changed(item, false) + module_solidified(item)
	ball.position = Vector2(900, 900)
	board._process_ghost_states(50)
	assert_eq(ghost_signals.size(), 2, "ghost_state_changed emitted for solid state")
	assert_eq(ghost_signals[1][1], false, "is_ghost = false")
	assert_eq(solid_signals.size(), 1, "module_solidified emitted")
	assert_eq(solid_signals[0], item, "emitted correct item")

	ball.free()
	board.free()

func test_unslotting_ghost_and_solid_components() -> void:
	begin("Unslotting components cleans up ghost tracking dictionaries")
	var board: Node2D = Node2D.new()
	board.set_script(BoardScript)
	board._ready()

	var ball_pos: Vector2 = board.board_cell_to_world(Vector2i(2, 2))
	var ball := _create_mock_ball(ball_pos)
	board._active_balls.append(ball)

	var mod := PolyominoModuleData.new()
	mod.cells = [Vector2i(0, 0)]
	var item := JunkBoxItem.new(&"unslot_ghost_mod", JunkBoxItem.POLYOMINO_MODULE)
	item.module_data = mod

	board.place_module(item, Vector2i(2, 2))
	assert_true(board.is_module_in_ghost_state(&"unslot_ghost_mod"), "module in ghost")

	var unslotted: Resource = board.unslot_module(&"unslot_ghost_mod")
	assert_eq(unslotted, item, "unslotted correctly")
	assert_false(board.is_module_in_ghost_state(&"unslot_ghost_mod"), "erased from ghost tracking")
	assert_eq(board.get_ghost_modules().size(), 0, "0 ghost modules")

	# Peg unslot
	var ball2_pos: Vector2 = board.board_cell_to_world(Vector2i(1, 2))
	var ball2 := _create_mock_ball(ball2_pos)
	board._active_balls.append(ball2)

	var peg: Node = board.place_peg_at_cell(Vector2i(1, 2))
	assert_true(board.is_peg_in_ghost_state(peg.peg_id), "peg in ghost")
	var unslotted_peg: Node = board.unslot_peg_at_cell(Vector2i(1, 2))
	assert_eq(unslotted_peg, peg, "unslotted peg correctly")
	assert_false(board.is_peg_in_ghost_state(peg.peg_id), "erased peg from ghost tracking")

	unslotted_peg.free()
	ball.free()
	ball2.free()
	board.free()
