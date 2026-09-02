extends RefCounted
class_name BuildSynergyDatabase
## Database and calculation engine for Build Archetypes and Synergy Linkages (TASK-008).

const ARCHETYPES: Array[StringName] = [
	&"pyro_explosion",
	&"cryo_shatter",
	&"chain_voltage",
	&"swarm_cascade"
]

const SYNERGY_MATRIX: Dictionary = {
	"pyro_explosion": {
		"preferred_balls": [&"flame_ball", &"volatile_ball"],
		"preferred_pegs": [&"volatile_gas", &"stash_peg"],
		"synergy_bonus": 1.35
	},
	"cryo_shatter": {
		"preferred_balls": [&"frost_ball", &"sticky_slime"],
		"preferred_pegs": [&"ice_peg", &"shield_peg"],
		"synergy_bonus": 1.30
	},
	"chain_voltage": {
		"preferred_balls": [&"lightning_ball", &"binary_ball"],
		"preferred_pegs": [&"energize_peg", &"booster_peg"],
		"synergy_bonus": 1.40
	},
	"swarm_cascade": {
		"preferred_balls": [&"split_ball", &"bloom_ball"],
		"preferred_pegs": [&"magnet_peg", &"lucky_gold_peg"],
		"synergy_bonus": 1.25
	}
}

static func get_all_archetypes() -> Array[StringName]:
	return ARCHETYPES

static func get_synergy_multiplier(archetype: StringName, ball_type: StringName, peg_type: StringName) -> float:
	if not SYNERGY_MATRIX.has(str(archetype)):
		return 1.0
	var data: Dictionary = SYNERGY_MATRIX[str(archetype)]
	var pref_balls: Array = data.get("preferred_balls", [])
	var pref_pegs: Array = data.get("preferred_pegs", [])
	var base_bonus: float = float(data.get("synergy_bonus", 1.0))

	var matches: int = 0
	if ball_type in pref_balls:
		matches += 1
	if peg_type in pref_pegs:
		matches += 1

	if matches == 2:
		return base_bonus
	elif matches == 1:
		return 1.0 + (base_bonus - 1.0) * 0.5
	return 1.0

static func get_archetype_description(archetype: StringName) -> String:
	match archetype:
		&"pyro_explosion": return "High-Density Pyro Explosion: Flame balls, explosive pegs, and burn duration multipliers."
		&"cryo_shatter": return "Cryo Shatter & Shield Fortification: Frost balls, brittle bonuses, and defense conversions."
		&"chain_voltage": return "Chain Reaction Voltage: Lightning balls, rapid bounce pegs, and high-frequency sidearm triggers."
		&"swarm_cascade": return "Swarm Split & Leech Cascade: Split balls, leech pegs, and persistent energy siphons."
		_: return "Standard Build Strategy."
