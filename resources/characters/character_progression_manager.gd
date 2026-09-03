extends RefCounted
class_name CharacterProgressionManager
## Manager for Character Bespoke Progression Mechanics across all 6 campaign archetypes.

static func get_perks_for_archetype(archetype: StringName) -> Dictionary:
	match archetype:
		&"goblin":
			return {
				"volatile_explosion_bonus": 0.15,
				"stash_peg_multiplier": 1.5,
				"wall_damage_mod": 1.0,
				"peg_energy_bonus": 0,
				"ball_revive_chance": 0.0,
				"booster_speed_mod": 1.0,
				"constellation_damage_mod": 1.0
			}
		&"necromancer":
			return {
				"volatile_explosion_bonus": 0.0,
				"stash_peg_multiplier": 1.0,
				"wall_damage_mod": 1.10,
				"peg_energy_bonus": 2,
				"ball_revive_chance": 0.15,
				"booster_speed_mod": 1.0,
				"constellation_damage_mod": 1.0
			}
		&"beastmancer":
			return {
				"volatile_explosion_bonus": 0.0,
				"stash_peg_multiplier": 1.2,
				"wall_damage_mod": 1.25,
				"peg_energy_bonus": 1,
				"ball_revive_chance": 0.0,
				"booster_speed_mod": 1.10,
				"constellation_damage_mod": 1.0
			}
		&"mechanic":
			return {
				"volatile_explosion_bonus": 0.05,
				"stash_peg_multiplier": 1.0,
				"wall_damage_mod": 1.05,
				"peg_energy_bonus": 0,
				"ball_revive_chance": 0.05,
				"booster_speed_mod": 1.30,
				"constellation_damage_mod": 1.05
			}
		&"astromancer":
			return {
				"volatile_explosion_bonus": 0.0,
				"stash_peg_multiplier": 1.1,
				"wall_damage_mod": 1.15,
				"peg_energy_bonus": 1,
				"ball_revive_chance": 0.0,
				"booster_speed_mod": 1.0,
				"constellation_damage_mod": 1.35
			}
		&"goblin_convergence":
			return {
				"volatile_explosion_bonus": 0.20,
				"stash_peg_multiplier": 1.8,
				"wall_damage_mod": 1.40,
				"peg_energy_bonus": 3,
				"ball_revive_chance": 0.20,
				"booster_speed_mod": 1.35,
				"constellation_damage_mod": 1.40
			}
		_:
			return get_perks_for_archetype(&"goblin")

static func compute_wall_damage_modifier(archetype: StringName) -> float:
	var perks: Dictionary = get_perks_for_archetype(archetype)
	return float(perks.get("wall_damage_mod", 1.0))

static func compute_peg_energy_bonus(archetype: StringName, base_energy: int) -> int:
	var perks: Dictionary = get_perks_for_archetype(archetype)
	var flat_bonus: int = int(perks.get("peg_energy_bonus", 0))
	return base_energy + flat_bonus

static func compute_ball_revive_chance(archetype: StringName) -> float:
	var perks: Dictionary = get_perks_for_archetype(archetype)
	return float(perks.get("ball_revive_chance", 0.0))

static func compute_booster_speed_multiplier(archetype: StringName) -> float:
	var perks: Dictionary = get_perks_for_archetype(archetype)
	return float(perks.get("booster_speed_mod", 1.0))

static func is_perk_active(archetype: StringName, perk_name: StringName) -> bool:
	var perks: Dictionary = get_perks_for_archetype(archetype)
	if perks.has(str(perk_name)):
		var val = perks[str(perk_name)]
		if val is bool:
			return val
		if val is float or val is int:
			return float(val) > 0.0
	return false
