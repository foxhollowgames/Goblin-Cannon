extends "res://tests/test_base.gd"

const BuildSynergyDatabaseScript = preload("res://resources/synergies/build_synergy_database.gd")

func _init() -> void:
	suite_name = "BuildArchetypesAndSynergies"

func run() -> void:
	test_archetype_registration()
	test_synergy_multiplier_calculations()
	test_archetype_descriptions()

func test_archetype_registration() -> void:
	begin("All 4 core build archetypes are registered")
	var archs: Array[StringName] = BuildSynergyDatabaseScript.get_all_archetypes()
	assert_eq(archs.size(), 4, "4 archetypes registered")
	assert_true(&"pyro_explosion" in archs, "pyro_explosion present")
	assert_true(&"cryo_shatter" in archs, "cryo_shatter present")
	assert_true(&"chain_voltage" in archs, "chain_voltage present")
	assert_true(&"swarm_cascade" in archs, "swarm_cascade present")

func test_synergy_multiplier_calculations() -> void:
	begin("Synergy multiplier scales with matching ball and peg combinations")
	var full_bonus: float = BuildSynergyDatabaseScript.get_synergy_multiplier(&"pyro_explosion", &"flame_ball", &"volatile_gas")
	var partial_bonus: float = BuildSynergyDatabaseScript.get_synergy_multiplier(&"pyro_explosion", &"flame_ball", &"unknown_peg")
	var no_bonus: float = BuildSynergyDatabaseScript.get_synergy_multiplier(&"pyro_explosion", &"unknown_ball", &"unknown_peg")

	assert_gt(full_bonus, partial_bonus, "full match > partial match")
	assert_gt(partial_bonus, no_bonus, "partial match > no match")
	assert_eq(no_bonus, 1.0, "no match multiplier is 1.0")

func test_archetype_descriptions() -> void:
	begin("Archetype descriptions return descriptive text")
	var desc: String = BuildSynergyDatabaseScript.get_archetype_description(&"chain_voltage")
	assert_false(desc.is_empty(), "description string is non-empty")
	assert_true(desc.contains("Chain Reaction Voltage"), "description mentions archetype name")
