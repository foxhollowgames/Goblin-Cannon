extends "res://tests/test_base.gd"

func _init() -> void:
	suite_name = "EnergyRouter"

func run() -> void:
	test_route_energy_emits_all_to_main()
	test_route_energy_zero()
	test_route_energy_ignores_alignment()

func _make_router() -> Node:
	var script: GDScript = load("res://scenes/energy/energy_router.gd")
	var er := Node.new()
	er.set_script(script)
	return er

func test_route_energy_emits_all_to_main() -> void:
	begin("route_energy emits all energy as main, zero sidearm/shield")
	var er := _make_router()
	var received: Array = []
	er.energy_allocated.connect(func(m: int, s: int, sh: int): received.append(Vector3i(m, s, sh)))
	er.route_energy(5000, 0)
	assert_eq(received.size(), 1, "signal emitted once")
	assert_eq(received[0].x, 5000, "main = 5000")
	assert_eq(received[0].y, 0, "sidearm = 0")
	assert_eq(received[0].z, 0, "shield = 0")

func test_route_energy_zero() -> void:
	begin("route_energy with zero energy")
	var er := _make_router()
	var received: Array = []
	er.energy_allocated.connect(func(m: int, s: int, sh: int): received.append(Vector3i(m, s, sh)))
	er.route_energy(0, 0)
	assert_eq(received[0], Vector3i(0, 0, 0), "zero in = zero out")

func test_route_energy_ignores_alignment() -> void:
	begin("route_energy ignores alignment parameter")
	var er := _make_router()
	var results: Array = []
	er.energy_allocated.connect(func(m: int, s: int, sh: int): results.append(Vector3i(m, s, sh)))
	er.route_energy(1000, Constants.ALIGNMENT_MAIN)
	er.route_energy(1000, Constants.ALIGNMENT_SIDEARM)
	er.route_energy(1000, Constants.ALIGNMENT_DEFENSE)
	assert_eq(results.size(), 3, "three emissions")
	for r in results:
		assert_eq(r.x, 1000, "main always 1000")
		assert_eq(r.y, 0, "sidearm always 0")
		assert_eq(r.z, 0, "shield always 0")
