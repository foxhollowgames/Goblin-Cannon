class_name EnergyRouting
extends RefCounted
## Pure functions for energy routing (§1.7). Internal = display × 100.
## No RNG; no node dependencies. Used by EnergyRouter node.

enum Alignment { MAIN, SIDEARM, DEFENSE }

# Main-aligned: 100% main cannon only. Sidearm/Defense: unchanged splits.
const SPLIT_SIDEARM: int = 15
const SPLIT_SHIELD: int = 15
const SPLIT_SIDEARM_ALIGNED_MAIN: int = 20
const SPLIT_SIDEARM_ALIGNED_SIDEARM: int = 80
const SPLIT_DEFENSE_ALIGNED_MAIN: int = 20
const SPLIT_DEFENSE_ALIGNED_SHIELD: int = 80

## Returns (main, sidearm, shield) in internal units. Main cannon balls: 100% main.
static func split_main_aligned(internal: int) -> Vector3i:
	return Vector3i(internal, 0, 0)

static func split_sidearm_aligned(internal: int) -> Vector3i:
	var main: int = (internal * SPLIT_SIDEARM_ALIGNED_MAIN) / 100
	var sidearm: int = (internal * SPLIT_SIDEARM_ALIGNED_SIDEARM) / 100
	var shield: int = internal - main - sidearm
	return Vector3i(main, sidearm, shield)

static func split_defense_aligned(internal: int) -> Vector3i:
	var main: int = (internal * SPLIT_DEFENSE_ALIGNED_MAIN) / 100
	var shield: int = (internal * SPLIT_DEFENSE_ALIGNED_SHIELD) / 100
	var sidearm: int = internal - main - shield
	return Vector3i(main, sidearm, shield)

static func route(internal_energy: int, alignment: Alignment) -> Vector3i:
	match alignment:
		Alignment.MAIN: return split_main_aligned(internal_energy)
		Alignment.SIDEARM: return split_sidearm_aligned(internal_energy)
		Alignment.DEFENSE: return split_defense_aligned(internal_energy)
	return split_main_aligned(internal_energy)
