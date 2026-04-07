extends "res://tests/test_base.gd"

## Headless test runner parses scripts before global `class_name` registration; use preload.
const EnergyRoutingScript = preload("res://simulation/energy_routing.gd")

func _init() -> void:
	suite_name = "EnergyRouting"

func run() -> void:
	test_split_main_aligned_all_to_main()
	test_split_sidearm_aligned_all_to_main()
	test_split_defense_aligned_all_to_main()
	test_route_main_alignment()
	test_route_sidearm_alignment()
	test_route_defense_alignment()
	test_route_zero_energy()
	test_route_large_energy()

func test_split_main_aligned_all_to_main() -> void:
	begin("split_main_aligned returns 100% to main")
	var result: Vector3i = EnergyRoutingScript.split_main_aligned(1000)
	assert_eq(result.x, 1000, "main component")
	assert_eq(result.y, 0, "sidearm component")
	assert_eq(result.z, 0, "shield component")

func test_split_sidearm_aligned_all_to_main() -> void:
	begin("split_sidearm_aligned returns 100% to main")
	var result: Vector3i = EnergyRoutingScript.split_sidearm_aligned(1000)
	assert_eq(result.x, 1000, "main component")
	assert_eq(result.y, 0, "sidearm component")
	assert_eq(result.z, 0, "shield component")

func test_split_defense_aligned_all_to_main() -> void:
	begin("split_defense_aligned returns 100% to main")
	var result: Vector3i = EnergyRoutingScript.split_defense_aligned(1000)
	assert_eq(result.x, 1000, "main component")
	assert_eq(result.y, 0, "sidearm component")
	assert_eq(result.z, 0, "shield component")

func test_route_main_alignment() -> void:
	begin("route with MAIN alignment")
	var result: Vector3i = EnergyRoutingScript.route(5000, EnergyRoutingScript.Alignment.MAIN)
	assert_eq(result.x, 5000, "main receives all")
	assert_eq(result.y, 0, "sidearm zero")
	assert_eq(result.z, 0, "shield zero")

func test_route_sidearm_alignment() -> void:
	begin("route with SIDEARM alignment still goes to main")
	var result: Vector3i = EnergyRoutingScript.route(5000, EnergyRoutingScript.Alignment.SIDEARM)
	assert_eq(result.x, 5000, "main receives all")
	assert_eq(result.y, 0, "sidearm zero")
	assert_eq(result.z, 0, "shield zero")

func test_route_defense_alignment() -> void:
	begin("route with DEFENSE alignment still goes to main")
	var result: Vector3i = EnergyRoutingScript.route(5000, EnergyRoutingScript.Alignment.DEFENSE)
	assert_eq(result.x, 5000, "main receives all")
	assert_eq(result.y, 0, "sidearm zero")
	assert_eq(result.z, 0, "shield zero")

func test_route_zero_energy() -> void:
	begin("route with zero energy")
	var result: Vector3i = EnergyRoutingScript.route(0, EnergyRoutingScript.Alignment.MAIN)
	assert_eq(result, Vector3i(0, 0, 0), "zero in = zero out")

func test_route_large_energy() -> void:
	begin("route with large energy value")
	var result: Vector3i = EnergyRoutingScript.route(999999, EnergyRoutingScript.Alignment.MAIN)
	assert_eq(result.x, 999999, "large value preserved")
	assert_eq(result.y, 0, "sidearm zero")
	assert_eq(result.z, 0, "shield zero")
