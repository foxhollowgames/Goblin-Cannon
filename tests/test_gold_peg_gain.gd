extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "GoldPegGain"

func run() -> void:
	test_gold_peg_signal_emitted()
	test_gilded_covenant_bonus_gold()
	test_stash_gold_release_emits_gold_gained()
	test_center_panel_gold_arrival_increments_gamestate()
	test_gold_vfx_particle_count()

func _attach_holder() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree")
	var holder := Node.new()
	tree.root.add_child(holder)
	return holder

func test_gold_peg_signal_emitted() -> void:
	begin("Gold peg hit emits gold_gained signal with amount 1")
	GameState.start_run(12345)
	var holder: Node = _attach_holder()
	var board: Node = Node2D.new()
	board.set_script(load("res://scenes/board/board.gd"))
	holder.add_child(board)

	var received_amount: int = 0
	var received_pos: Vector2 = Vector2.ZERO
	board.gold_gained.connect(func(amount: int, pos: Vector2) -> void:
		received_amount = amount
		received_pos = pos
	)

	var peg: Node = StaticBody2D.new()
	peg.set_script(load("res://scenes/board/peg.gd"))
	peg.peg_id = 1
	peg.position = Vector2(100, 100)
	peg.peg_extra_kind = "gold"
	board.add_child(peg)
	board._peg_by_id[1] = peg

	var ball: Node = RigidBody2D.new()
	ball.set_script(load("res://scenes/balls/ball.gd"))
	ball.position = Vector2(100, 100)
	board.add_child(ball)
	board._active_balls.append(ball)

	# Simulate hit on gold peg
	board._ball_colliding_pegs_this_tick[ball.get_ball_id()] = [peg]
	board.run_ball_steps(1)

	assert_eq(received_amount, 1, "Gold peg hit should emit gold_gained with amount 1")
	assert_eq(received_pos, peg.global_position, "Position should match peg position")
	holder.queue_free()

func test_gilded_covenant_bonus_gold() -> void:
	begin("Gilded Covenant upgrade adds +1 gold per gold peg hit")
	GameState.start_run(54321)
	GameState.boss_upgrades_held.append(&"gilded_covenant")
	var holder: Node = _attach_holder()
	var board: Node = Node2D.new()
	board.set_script(load("res://scenes/board/board.gd"))
	holder.add_child(board)

	var received_amount: int = 0
	board.gold_gained.connect(func(amount: int, _pos: Vector2) -> void:
		received_amount = amount
	)

	var peg: Node = StaticBody2D.new()
	peg.set_script(load("res://scenes/board/peg.gd"))
	peg.peg_id = 2
	peg.position = Vector2(200, 200)
	peg.peg_extra_kind = "lucky_gold"
	board.add_child(peg)
	board._peg_by_id[2] = peg

	var ball: Node = RigidBody2D.new()
	ball.set_script(load("res://scenes/balls/ball.gd"))
	ball.position = Vector2(200, 200)
	board.add_child(ball)
	board._active_balls.append(ball)

	board._ball_colliding_pegs_this_tick[ball.get_ball_id()] = [peg]
	board.run_ball_steps(1)

	assert_eq(received_amount, 2, "Gilded covenant should grant 2 gold on lucky_gold peg hit")
	holder.queue_free()

func test_stash_gold_release_emits_gold_gained() -> void:
	begin("Peg releasing stash gold emits gold_gained on parent board")
	GameState.start_run(99999)
	var holder: Node = _attach_holder()
	var board: Node = Node2D.new()
	board.set_script(load("res://scenes/board/board.gd"))
	holder.add_child(board)

	var received_amount: int = 0
	board.gold_gained.connect(func(amount: int, _pos: Vector2) -> void:
		received_amount = amount
	)

	var peg: Node = StaticBody2D.new()
	peg.set_script(load("res://scenes/board/peg.gd"))
	peg.peg_id = 3
	peg.stash_gold_amount = 5
	board.add_child(peg)

	peg.call("_release_stash_gold_if_any")
	assert_eq(received_amount, 5, "Stash gold release should emit gold_gained with stash amount")
	assert_eq(int(peg.stash_gold_amount), 0, "Stash amount should be reset to 0")
	holder.queue_free()

func test_center_panel_gold_arrival_increments_gamestate() -> void:
	begin("Center panel _on_gold_arrived increments GameState.run_gold and updates label")
	GameState.start_run(11111)
	var initial_gold: int = GameState.run_gold
	var holder: Node = _attach_holder()

	var left_panel: Control = Control.new()
	left_panel.name = "LeftPanel"
	var run_gold_label: Label = Label.new()
	run_gold_label.name = "RunGold"
	left_panel.add_child(run_gold_label)
	holder.add_child(left_panel)

	var center_panel: Control = Control.new()
	center_panel.name = "CenterPanel"
	center_panel.set_script(load("res://scenes/main/center_panel_ui.gd"))
	holder.add_child(center_panel)

	center_panel.call("_on_gold_arrived", 3, Vector2(100, 100))
	assert_eq(GameState.run_gold, initial_gold + 3, "GameState.run_gold should increment by 3")
	assert_eq(run_gold_label.text, "Gold: %d" % (initial_gold + 3), "RunGold label text should show updated gold")
	holder.queue_free()

func test_gold_vfx_particle_count() -> void:
	begin("energy_flow_vfx respects explicit particle count (1 gold = 1 particle, 5 gold = 5 particles)")
	var holder: Node = _attach_holder()
	var vfx_scene: PackedScene = load("res://scenes/ui/energy_flow_vfx.tscn") as PackedScene

	# Test 1 particle for 1 gold (round particle)
	var vfx1: Control = vfx_scene.instantiate() as Control
	vfx1.setup(Vector2(50, 50), Vector2(100, 100), Color.YELLOW, 1, true)
	holder.add_child(vfx1)
	assert_eq(vfx1.call("_get_particle_count"), 1, "1 gold should request 1 particle")
	vfx1.call("_spawn_particles")
	var particles1: Array = vfx1.get("_particles")
	assert_eq(particles1.size(), 1, "1 gold should spawn exactly 1 flying particle")
	assert_true(particles1[0] is Control and not (particles1[0] is ColorRect), "Round particle should be custom Control, not square ColorRect")
	vfx1.queue_free()

	# Test 5 particles for 5 gold (round particles)
	var vfx5: Control = vfx_scene.instantiate() as Control
	vfx5.setup(Vector2(50, 50), Vector2(100, 100), Color.YELLOW, 5, true)
	holder.add_child(vfx5)
	assert_eq(vfx5.call("_get_particle_count"), 5, "5 gold should request 5 particles")
	vfx5.call("_spawn_particles")
	var particles5: Array = vfx5.get("_particles")
	assert_eq(particles5.size(), 5, "5 gold should spawn exactly 5 flying particles")
	assert_true(particles5[0] is Control and not (particles5[0] is ColorRect), "5 gold particles should be round Controls")
	vfx5.queue_free()

	holder.queue_free()
