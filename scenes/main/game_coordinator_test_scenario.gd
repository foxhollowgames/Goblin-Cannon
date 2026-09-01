class_name GameCoordinatorTestScenario
extends RefCounted
## Static helper class for applying TestScenario autoload overrides for GameCoordinator.

const LEGACY_PEG_UPGRADE_ID_TO_KIND: Dictionary = {
	"add_bomb_peg": "bomb",
	"add_trampoline_peg": "trampoline",
	"add_goblin_reset_node": "goblin_reset",
	"add_eternal_peg": "eternal",
	"add_extreme_bouncer_peg": "extreme_bouncer",
	"add_magnet_peg": "magnet",
	"add_splitter_peg": "splitter",
	"add_gold_peg": "gold",
	"add_lucky_gold_peg": "lucky_gold",
	"add_gravity_well_peg": "gravity_well",
	"add_phase_peg": "phase",
	"add_wrench_peg": "wrench",
}

#region Public API
## Applies TestScenario starting stats, upgrades, and peg counts to GameState.
static func apply_test_scenario() -> void:
	if not TestScenario or not TestScenario.enabled:
		return
	if TestScenario.starting_city_id >= 0:
		GameState.current_city_id = TestScenario.starting_city_id
	for stat_key in TestScenario.starting_stats:
		var value = TestScenario.starting_stats[stat_key]
		match stat_key:
			"cannon_damage":
				GameState.cannon_base_damage_bonus += int(value)
			"cannon_energy":
				GameState.cannon_charge_reduction += Constants.legacy_internal_energy_to_current(int(value))
			"main_charge":
				GameState.main_charge_bonus += float(value)
			"door_interval":
				GameState.conduit_wave_interval_scale = maxf(0.5, GameState.conduit_wave_interval_scale - float(value))
			"door_duration":
				GameState.conduit_open_duration_scale += float(value)
			"plain_surge":
				GameState.plain_surge_stacks = mini(5, GameState.plain_surge_stacks + int(value))
			"plain_horde":
				GameState.plain_horde_stacks = mini(3, GameState.plain_horde_stacks + int(value))
			"plain_momentum":
				GameState.plain_momentum_stacks = mini(3, GameState.plain_momentum_stacks + int(value))
	for entry in TestScenario.starting_upgrades:
		if entry is String:
			var s_uid: String = entry as String
			if LEGACY_PEG_UPGRADE_ID_TO_KIND.has(s_uid):
				add_peg_stacks(str(LEGACY_PEG_UPGRADE_ID_TO_KIND[s_uid]), 1)
			else:
				GameState.add_wall_break_upgrade(StringName(entry), 1)
		elif entry is Dictionary:
			var uid: String = entry.get("id", "")
			var stacks: int = entry.get("stacks", 1)
			if not uid.is_empty():
				if LEGACY_PEG_UPGRADE_ID_TO_KIND.has(uid):
					add_peg_stacks(str(LEGACY_PEG_UPGRADE_ID_TO_KIND[uid]), stacks)
				else:
					GameState.add_wall_break_upgrade(StringName(uid), stacks)
	if TestScenario.starting_peg_counts.has("bomb"):
		GameState.bomb_peg_count += int(TestScenario.starting_peg_counts["bomb"])
	if TestScenario.starting_peg_counts.has("trampoline"):
		GameState.trampoline_peg_count += int(TestScenario.starting_peg_counts["trampoline"])
	if TestScenario.starting_peg_counts.has("goblin_reset"):
		GameState.goblin_reset_node_count += int(TestScenario.starting_peg_counts["goblin_reset"])
	var summary: String = TestScenario.get_summary()
	if not summary.is_empty():
		print("[TestScenario] ACTIVE — %s" % summary)

## Increments starting peg counts for a specific peg kind.
static func add_peg_stacks(kind: String, stacks: int) -> void:
	for _i in stacks:
		match kind:
			"bomb":
				GameState.bomb_peg_count += 1
			"trampoline":
				GameState.trampoline_peg_count += 1
			"goblin_reset":
				GameState.goblin_reset_node_count += 1
			"eternal":
				GameState.eternal_peg_count += 1
			"extreme_bouncer":
				GameState.extreme_bouncer_peg_count += 1
			"magnet":
				GameState.magnet_peg_count += 1
			"splitter":
				GameState.splitter_peg_count += 1
			"gold":
				GameState.gold_peg_count += 1
			"lucky_gold":
				GameState.lucky_gold_peg_count += 1
			"gravity_well":
				GameState.gravity_well_peg_count += 1
			"phase":
				GameState.phase_peg_count += 1
			"wrench":
				GameState.wrench_peg_count += 1
			_:
				pass
#endregion

