class_name EnergyRouting
extends RefCounted
## Pure functions for energy routing. Internal = display × 100.
## All energy routes to the main cannon regardless of ball alignment.

enum Alignment { MAIN, SIDEARM, DEFENSE }

static func split_main_aligned(internal: int) -> Vector3i:
	return Vector3i(internal, 0, 0)

static func split_sidearm_aligned(internal: int) -> Vector3i:
	return Vector3i(internal, 0, 0)

static func split_defense_aligned(internal: int) -> Vector3i:
	return Vector3i(internal, 0, 0)

static func route(internal_energy: int, _alignment: Alignment) -> Vector3i:
	return Vector3i(internal_energy, 0, 0)
