extends "res://tests/test_base.gd"
## Regression checks for reachable ports and truthful device completion.

const Data = preload("res://resources/polyomino/polyomino_module_data.gd")
const Database = preload("res://resources/polyomino/polyomino_relic_database.gd")
const Module = preload("res://scenes/board/machinery/polyomino_module_node.gd")
const Placement = preload("res://resources/polyomino/relic_flow_placement.gd")
const Gate = preload("res://scenes/board/machinery/wire_gate.gd")

class TestBall extends Node2D:
	var linear_velocity: Vector2 = Vector2.DOWN * 80.0
	var energy: int = 0
	func get_ball_id() -> int: return get_instance_id()
	func add_peg_energy(value: int) -> void: energy += value

func _init() -> void:
	suite_name = "RelicFlowContract"

func run() -> void:
	GameState.start_run(93)
	test_rotated_openings()
	test_custom_opening_round_trip()
	test_roster_geometry()
	test_blocked_neighbor()
	test_orbit_ports()
	test_partial_reservoir()
	test_spinner_speed_reward()
	test_route_contact_is_not_completion()
	cleanup()

func test_rotated_openings() -> void:
	begin("Lane openings rotate with the device and never overlap walls")
	var data: Resource = Database.create_module_for_relic(&"word_bank_gob")
	for steps: int in range(4):
		var ports: Array[Dictionary] = data.get_flow_ports(steps)
		assert_eq(ports.size(), 6, "Three entrances and three exits")
		for port: Dictionary in ports:
			var midpoint: Vector2 = (port.p1 + port.p2) * 0.5
			for wall: Dictionary in data.get_solid_edge_segments(steps):
				assert_gt(midpoint.distance_to(Geometry2D.get_closest_point_to_segment(midpoint, wall.p1, wall.p2)), 0.2)
			var expected: Vector2 = Data.get_rotated_direction(Vector2.UP if port.kind == "entry" else Vector2.DOWN, steps)
			assert_eq(port.normal, expected)

func test_custom_opening_round_trip() -> void:
	begin("Explicit wall removal survives saving and rotation")
	var data: Resource = Data.new()
	data.cells.assign([Vector2i.ZERO])
	data.enclosure_type = Data.EnclosureType.FULL_ENCLOSURE
	data.custom_wall_edges[Vector2i.ZERO] = ["N", "-N", "-S"]
	var copy: Resource = Data.new()
	copy.deserialize(data.serialize())
	assert_eq(copy.get_solid_edge_segments().size(), 2)
	assert_eq(copy.get_flow_ports(1).size(), 2)

func test_roster_geometry() -> void:
	begin("All catalog components exist in their footprint; passage families expose ports")
	for id: StringName in Database.get_all_relic_ids():
		var data: Resource = Database.create_module_for_relic(id)
		for cell: Vector2i in data.cell_types:
			assert_true(data.cells.has(cell), "%s reserves component %s" % [id, cell])
		if data.enclosure_type in [2, 3] or data.unified_component_type == Data.CellType.WIRE_GATE:
			assert_true(data.get_flow_ports().size() >= 2, "%s exposes ports" % id)
		for cell: Vector2i in data.goal_target_sequence:
			assert_true(data.cells.has(cell), "%s reserves its track" % id)

func test_blocked_neighbor() -> void:
	begin("Placement detects another device sealing a mouth")
	var item: Resource = Database.create_item_for_relic(&"word_bank_gob")
	var other: Resource = Database.create_item_for_relic(&"word_bank_gob")
	other.grid_position = Vector2i(0, -2)
	other.module_data.enclosure_type = Data.EnclosureType.FULL_ENCLOSURE
	assert_false(Placement.ports_clear(item, Vector2i.ZERO, 0, {&"other": other}))
	other.module_data.enclosure_type = Data.EnclosureType.DIVIDED_LANES
	assert_true(Placement.ports_clear(item, Vector2i.ZERO, 0, {&"other": other}))

func test_partial_reservoir() -> void:
	begin("Partial release conserves the ball and earns no full reward")
	var gate: Node = autofree(Gate.new())
	var ball: Node = autofree(TestBall.new())
	var releases: Array = []
	gate.cascade_released.connect(func(_gate: Node, balls: Array) -> void: releases.append(balls))
	gate.trigger_activation(ball, 1)
	for tick: int in range(Gate.PARTIAL_RELEASE_TICKS): gate._physics_process(1.0 / 60.0)
	assert_true(gate.retained_balls.is_empty())
	assert_eq(releases.size(), 0)
	assert_gt(ball.linear_velocity.y, 0.0)

func test_spinner_speed_reward() -> void:
	begin("Spinner bonus requires speed and respects cooldown")
	var node: Node = autofree(Module.new())
	node.setup_module(Database.create_item_for_relic(&"funneled_spinner_chute"), Vector2i.ZERO)
	var spinner: Node = node.get_all_components()[0]
	var ball: Node = autofree(TestBall.new())
	var rewards: Array = []
	node.goal_completed.connect(func(_m, _g, _r, _b, _d): rewards.append(1))
	spinner.trigger_activation(ball, 1)
	assert_eq(rewards.size(), 0)
	spinner.trigger_activation(ball, 20)
	assert_eq(rewards.size(), 1)
	spinner.trigger_activation(ball, 40)
	assert_eq(rewards.size(), 1)

func test_route_contact_is_not_completion() -> void:
	begin("A track entry cannot award a completed route")
	var node: Node = autofree(Module.new())
	node.setup_module(Database.create_item_for_relic(&"track_u_turn"), Vector2i.ZERO)
	var track: Node = node.get_unified_component()
	var ball: Node = autofree(TestBall.new())
	var rewards: Array = []
	node.goal_completed.connect(func(_m, _g, _r, _b, _d): rewards.append(1))
	track.trigger_activation(ball, 1)
	assert_eq(rewards.size(), 0)
	assert_false(track.check_ball_contact(track.position + track.points[3], 8.0, Vector2.ZERO))

func test_orbit_ports() -> void:
	begin("Both orbit mouths match runtime routes and reject adjacent walls")
	for id: StringName in [&"apex_orbit_loop", &"cyclone_orbit_loop", &"grand_orbit_circuit"]:
		for steps: int in range(4):
			var item: Resource = Database.create_item_for_relic(id)
			var node: Node = autofree(Module.new())
			node.setup_module(item, Vector2i.ZERO, steps)
			var orbit: Node = node.get_unified_component()
			var ports: Array[Dictionary] = item.module_data.get_flow_ports(steps)
			assert_eq(ports.size(), 2)
			for index: int in range(ports.size()):
				var port: Dictionary = ports[index]
				var expected: Vector2 = orbit.port_a_dir if index == 0 else orbit.port_b_dir
				assert_true(port.normal.is_equal_approx(expected), "%s rotation %d port direction" % [id, steps])
				var other: Resource = Database.create_item_for_relic(&"word_bank_gob")
				other.module_data.cells.assign([Vector2i.ZERO])
				other.module_data.enclosure_type = Data.EnclosureType.FULL_ENCLOSURE
				other.grid_position = port.cell + Vector2i(signf(port.normal.x), signf(port.normal.y))
				assert_false(Placement.ports_clear(item, Vector2i.ZERO, steps, {&"wall": other}), "%s rotation %d rejects blocked mouth" % [id, steps])
