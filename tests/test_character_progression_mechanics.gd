extends "res://tests/test_base.gd"

const CharacterProgressionManagerScript = preload("res://resources/characters/character_progression_manager.gd")

func _init() -> void:
	suite_name = "CharacterProgressionMechanics"

func run() -> void:
	test_goblin_archetype_perks()
	test_necromancer_archetype_perks()
	test_beastmancer_archetype_perks()
	test_mechanic_archetype_perks()
	test_astromancer_archetype_perks()
	test_convergence_goblin_synergy_perks()

func test_goblin_archetype_perks() -> void:
	begin("Goblin archetype provides explosive volatile and stash peg bonus")
	var perks: Dictionary = CharacterProgressionManagerScript.get_perks_for_archetype(&"goblin")
	assert_gt(float(perks.get("volatile_explosion_bonus", 0.0)), 0.0, "goblin has volatile explosion bonus")
	assert_gt(float(perks.get("stash_peg_multiplier", 0.0)), 1.0, "goblin has stash peg multiplier")

func test_necromancer_archetype_perks() -> void:
	begin("Necromancer archetype provides peg energy bonus and ball revive chance")
	var bonus_energy: int = CharacterProgressionManagerScript.compute_peg_energy_bonus(&"necromancer", 10)
	var revive_chance: float = CharacterProgressionManagerScript.compute_ball_revive_chance(&"necromancer")
	assert_eq(bonus_energy, 12, "necromancer grants +2 peg energy")
	assert_gt(revive_chance, 0.10, "necromancer has >10% ball revive chance")

func test_beastmancer_archetype_perks() -> void:
	begin("Beastmancer archetype provides wall damage and booster speed bonuses")
	var wall_mod: float = CharacterProgressionManagerScript.compute_wall_damage_modifier(&"beastmancer")
	var booster_mod: float = CharacterProgressionManagerScript.compute_booster_speed_multiplier(&"beastmancer")
	assert_gt(wall_mod, 1.20, "beastmancer has >1.20 wall damage modifier")
	assert_gt(booster_mod, 1.0, "beastmancer has booster speed boost")

func test_mechanic_archetype_perks() -> void:
	begin("Mechanic archetype provides high booster speed multiplier")
	var booster_mod: float = CharacterProgressionManagerScript.compute_booster_speed_multiplier(&"mechanic")
	assert_gt(booster_mod, 1.25, "mechanic has >=1.30 booster speed multiplier")

func test_astromancer_archetype_perks() -> void:
	begin("Astromancer archetype provides high constellation damage modifier")
	var perks: Dictionary = CharacterProgressionManagerScript.get_perks_for_archetype(&"astromancer")
	assert_gt(float(perks.get("constellation_damage_mod", 0.0)), 1.30, "astromancer has >1.30 constellation damage mod")

func test_convergence_goblin_synergy_perks() -> void:
	begin("Convergence Goblin archetype combines highest values across all 5 character perks")
	var perks: Dictionary = CharacterProgressionManagerScript.get_perks_for_archetype(&"goblin_convergence")
	assert_gt(float(perks.get("wall_damage_mod", 0.0)), 1.35, "convergence goblin has maximum wall damage mod")
	assert_gt(float(perks.get("stash_peg_multiplier", 0.0)), 1.5, "convergence goblin has maximum stash peg multiplier")
	assert_gt(float(perks.get("ball_revive_chance", 0.0)), 0.15, "convergence goblin has maximum ball revive chance")
