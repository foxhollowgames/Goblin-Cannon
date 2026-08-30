@tool
extends RefCounted
class_name PolyominoRelicDatabase
## Canonical data registry and factory for all polyomino relic items in Campaign 1 (TASK-024).

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")

const CellType = PolyominoModuleData.CellType
const GoalArchetype = PolyominoModuleData.GoalArchetype
const RewardType = PolyominoModuleData.RewardType

const _ALIASES: Dictionary = {
	&"chain_surge_wrench": &"arc_surge_wrench",
}

static var _DEFINITIONS: Dictionary = {}

static func _resolve_id(id: StringName) -> StringName:
	return _ALIASES.get(id, id)

static func _get_defs() -> Dictionary:
	if not _DEFINITIONS.is_empty():
		return _DEFINITIONS
	_build_all_definitions()
	return _DEFINITIONS

static func has_relic_definition(relic_id: StringName) -> bool:
	return _get_defs().has(_resolve_id(relic_id))

static func get_all_relic_ids() -> Array[StringName]:
	var defs := _get_defs()
	var ids: Array[StringName] = []
	for k in defs:
		ids.append(k)
	return ids

static func get_relic_tier(relic_id: StringName) -> int:
	var d = _get_defs().get(_resolve_id(relic_id), null)
	if d != null:
		return int(d.get("tier", 1))
	return 1

static func get_relic_shape_name(relic_id: StringName) -> String:
	var d = _get_defs().get(_resolve_id(relic_id), null)
	if d != null:
		return str(d.get("shape_name", ""))
	return ""

static func get_relic_kinetic_description(relic_id: StringName) -> String:
	var d = _get_defs().get(_resolve_id(relic_id), null)
	if d != null:
		return str(d.get("machinery_desc", ""))
	return ""

static func get_relic_display_name(relic_id: StringName) -> String:
	var d = _get_defs().get(_resolve_id(relic_id), null)
	if d != null:
		return str(d.get("display_name", ""))
	return ""

static func get_relic_goal_title(relic_id: StringName) -> String:
	var g: Dictionary = _get_goal_def(relic_id)
	return str(g.get("title", "Bank Clear"))

static func get_relic_goal_description(relic_id: StringName) -> String:
	var g: Dictionary = _get_goal_def(relic_id)
	return str(g.get("desc", "Hit all components in module."))

static func get_relic_reward_description(relic_id: StringName) -> String:
	var g: Dictionary = _get_goal_def(relic_id)
	return str(g.get("reward_desc", "+100 Energy Surge"))

static func create_module_for_relic(relic_id: StringName) -> PolyominoModuleData:
	var resolved_id: StringName = _resolve_id(relic_id)
	var def = _get_defs().get(resolved_id, null)
	if def == null:
		push_warning("PolyominoRelicDatabase: Unknown relic ID '%s'" % relic_id)
		return null
	var mod := PolyominoModuleData.new()
	mod.module_id = resolved_id
	mod.display_name = str(def.get("display_name", ""))
	mod.tier = int(def.get("tier", 1))
	mod.bumper_durability = int(def.get("bumper_durability", 0))

	var raw_cells: Array = def.get("cells", [])
	var typed_cells: Array[Vector2i] = []
	for c in raw_cells:
		if c is Vector2i:
			typed_cells.append(c)
	mod.cells = typed_cells

	var raw_types: Dictionary = def.get("cell_types", {})
	for k in raw_types:
		var pos: Vector2i = k if k is Vector2i else _parse_vector2i(str(k))
		mod.cell_types[pos] = int(raw_types[k])

	var raw_dirs: Dictionary = def.get("cell_directions", {})
	for k in raw_dirs:
		var pos: Vector2i = k if k is Vector2i else _parse_vector2i(str(k))
		var dir_val = raw_dirs[k]
		if dir_val is Vector2i:
			mod.cell_directions[pos] = dir_val
		elif dir_val is Vector2:
			mod.cell_directions[pos] = Vector2i(int(round(dir_val.x)), int(round(dir_val.y)))

	var raw_energies: Dictionary = def.get("energy_values", {})
	for k in raw_energies:
		var pos: Vector2i = k if k is Vector2i else _parse_vector2i(str(k))
		mod.energy_values[pos] = int(raw_energies[k])

	var g: Dictionary = _get_goal_def(resolved_id)
	if not g.is_empty():
		mod.goal_type = int(g.get("type", GoalArchetype.TARGET_BANK))
		mod.reward_type = int(g.get("reward", RewardType.ENERGY_SURGE))
		mod.goal_title = str(g.get("title", ""))
		mod.goal_description = str(g.get("desc", ""))
		mod.reward_description = str(g.get("reward_desc", ""))
		mod.reward_energy = int(g.get("energy", 0))
		mod.reward_ball_count = int(g.get("balls", 0))
		mod.goal_target_count = int(g.get("target_count", 0))
		mod.goal_time_limit = float(g.get("time_limit", 0.0))
		var seq: Array = g.get("sequence", [])
		var typed_seq: Array[Vector2i] = []
		for s in seq:
			if s is Vector2i:
				typed_seq.append(s)
		mod.goal_target_sequence = typed_seq

	return mod

static func create_item_for_relic(relic_id: StringName) -> JunkBoxItem:
	var mod: PolyominoModuleData = create_module_for_relic(relic_id)
	if mod == null:
		return null
	var item := JunkBoxItem.new(StringName("relic_%s_%d" % [relic_id, Time.get_ticks_usec()]), JunkBoxItem.POLYOMINO_MODULE)
	item.display_name = mod.display_name
	item.module_data = mod
	item.custom_payload = {
		"relic_id": str(_resolve_id(relic_id)),
		"tier": mod.tier,
		"shape_name": get_relic_shape_name(relic_id),
		"machinery_desc": get_relic_kinetic_description(relic_id),
		"goal_title": mod.goal_title,
		"goal_desc": mod.goal_description,
		"reward_desc": mod.reward_description
	}
	return item

## Applies passive/active modifiers to GameState when a relic module is slotted onto the board.
static func apply_relic_effects_to_game_state(relic_id: StringName) -> void:
	if not Engine.has_singleton("GameState") and not ClassDB.class_exists("GameState"):
		pass
	var uid: StringName = _resolve_id(relic_id)
	if not has_relic_definition(uid):
		return
	match uid:
		&"plain_surge":
			GameState.plain_surge_stacks = mini(5, GameState.plain_surge_stacks + 1)
			return
		&"plain_horde":
			GameState.plain_horde_stacks = mini(3, GameState.plain_horde_stacks + 1)
			return
		&"plain_momentum":
			GameState.plain_momentum_stacks = mini(3, GameState.plain_momentum_stacks + 1)
			return
		&"devastating_barrage":
			GameState.cannon_base_damage_bonus += 10
			GameState.chest_devastating_barrage_taken = true
			return
		&"compressed_charge":
			GameState.cannon_charge_reduction += Constants.legacy_internal_energy_to_current(2000)
			GameState.chest_compressed_charge_taken = true
			return
		&"explosion_radius":
			GameState.explosion_radius_bonus += 1
			return
		&"explosion_peg_hit_count":
			GameState.explosion_peg_hit_count_bonus += 1
			return
		&"explosion_impulse":
			GameState.explosion_impulse_bonus += 0.25
			return
		&"chain_arc":
			GameState.chain_arc_bonus += 1
			return
		&"chain_range":
			GameState.chain_range_bonus += 1
			return
		&"max_energize_stacks":
			GameState.max_energize_stacks_per_peg += 1
			return
		&"energize_decays_slower":
			GameState.energize_decay_scale *= 0.85
			return
		&"energized_pegs_repair_faster":
			GameState.energized_peg_repair_scale += 0.2
			return
		&"global_peg_durability":
			GameState.global_peg_durability_bonus += 1
			return
		&"peg_recovery_speed":
			GameState.peg_recovery_speed_scale += 0.15
			return
		&"chest_leech_drain":
			GameState.chest_leech_drain_stacks = mini(Constants.CHEST_PASSIVE_MAX_STACKS, GameState.chest_leech_drain_stacks + 1)
			return
		&"chest_leech_duration":
			GameState.chest_leech_duration_stacks = mini(Constants.CHEST_PASSIVE_MAX_STACKS, GameState.chest_leech_duration_stacks + 1)
			return
		&"chest_phantom_energy":
			GameState.chest_phantom_energy_stacks = mini(Constants.CHEST_PASSIVE_MAX_STACKS, GameState.chest_phantom_energy_stacks + 1)
			return
		&"chest_rubbery_energy":
			GameState.chest_rubbery_energy_stacks = mini(Constants.CHEST_PASSIVE_MAX_STACKS, GameState.chest_rubbery_energy_stacks + 1)
			return
		&"chest_bounce_energy":
			GameState.chest_bounce_energy_stacks = mini(Constants.CHEST_PASSIVE_MAX_STACKS, GameState.chest_bounce_energy_stacks + 1)
			return
		&"chest_split_energy":
			GameState.chest_split_energy_stacks = mini(Constants.CHEST_PASSIVE_MAX_STACKS, GameState.chest_split_energy_stacks + 1)
			return
		&"renewal_pact":
			GameState.peg_recovery_speed_scale += 0.12
			GameState.add_boss_upgrade(uid, 1)
			return

	var tier: int = get_relic_tier(uid)
	if tier == 3:
		GameState.add_boss_upgrade(uid, 1)
	else:
		GameState.add_wall_break_upgrade(uid, 1)

## Reverts passive/active modifiers from GameState when a relic module is unslotted from the board.
static func remove_relic_effects_from_game_state(relic_id: StringName) -> void:
	if not Engine.has_singleton("GameState") and not ClassDB.class_exists("GameState"):
		pass
	var uid: StringName = _resolve_id(relic_id)
	if not has_relic_definition(uid):
		return
	match uid:
		&"plain_surge":
			GameState.plain_surge_stacks = maxi(0, GameState.plain_surge_stacks - 1)
			return
		&"plain_horde":
			GameState.plain_horde_stacks = maxi(0, GameState.plain_horde_stacks - 1)
			return
		&"plain_momentum":
			GameState.plain_momentum_stacks = maxi(0, GameState.plain_momentum_stacks - 1)
			return
		&"devastating_barrage":
			GameState.cannon_base_damage_bonus = maxi(0, GameState.cannon_base_damage_bonus - 10)
			GameState.chest_devastating_barrage_taken = false
			return
		&"compressed_charge":
			GameState.cannon_charge_reduction = maxi(0, GameState.cannon_charge_reduction - Constants.legacy_internal_energy_to_current(2000))
			GameState.chest_compressed_charge_taken = false
			return
		&"explosion_radius":
			GameState.explosion_radius_bonus = maxi(0, GameState.explosion_radius_bonus - 1)
			return
		&"explosion_peg_hit_count":
			GameState.explosion_peg_hit_count_bonus = maxi(0, GameState.explosion_peg_hit_count_bonus - 1)
			return
		&"explosion_impulse":
			GameState.explosion_impulse_bonus = maxf(0.0, GameState.explosion_impulse_bonus - 0.25)
			return
		&"chain_arc":
			GameState.chain_arc_bonus = maxi(0, GameState.chain_arc_bonus - 1)
			return
		&"chain_range":
			GameState.chain_range_bonus = maxi(0, GameState.chain_range_bonus - 1)
			return
		&"max_energize_stacks":
			GameState.max_energize_stacks_per_peg = maxi(3, GameState.max_energize_stacks_per_peg - 1)
			return
		&"energize_decays_slower":
			GameState.energize_decay_scale = minf(1.0, GameState.energize_decay_scale / 0.85)
			return
		&"energized_pegs_repair_faster":
			GameState.energized_peg_repair_scale = maxf(1.0, GameState.energized_peg_repair_scale - 0.2)
			return
		&"global_peg_durability":
			GameState.global_peg_durability_bonus = maxi(0, GameState.global_peg_durability_bonus - 1)
			return
		&"peg_recovery_speed":
			GameState.peg_recovery_speed_scale = maxf(1.0, GameState.peg_recovery_speed_scale - 0.15)
			return
		&"chest_leech_drain":
			GameState.chest_leech_drain_stacks = maxi(0, GameState.chest_leech_drain_stacks - 1)
			return
		&"chest_leech_duration":
			GameState.chest_leech_duration_stacks = maxi(0, GameState.chest_leech_duration_stacks - 1)
			return
		&"chest_phantom_energy":
			GameState.chest_phantom_energy_stacks = maxi(0, GameState.chest_phantom_energy_stacks - 1)
			return
		&"chest_rubbery_energy":
			GameState.chest_rubbery_energy_stacks = maxi(0, GameState.chest_rubbery_energy_stacks - 1)
			return
		&"chest_bounce_energy":
			GameState.chest_bounce_energy_stacks = maxi(0, GameState.chest_bounce_energy_stacks - 1)
			return
		&"chest_split_energy":
			GameState.chest_split_energy_stacks = maxi(0, GameState.chest_split_energy_stacks - 1)
			return
		&"renewal_pact":
			GameState.peg_recovery_speed_scale = maxf(1.0, GameState.peg_recovery_speed_scale - 0.12)
			GameState.remove_boss_upgrade_entry(uid)
			return

	var tier: int = get_relic_tier(uid)
	if tier == 3:
		GameState.remove_boss_upgrade_entry(uid)
	else:
		GameState.remove_wall_break_upgrade_stack(uid, 1)

static func _parse_vector2i(s: String) -> Vector2i:
	var parts := s.split(",")
	if parts.size() == 2:
		return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i.ZERO

static func _get_goal_def(id: StringName) -> Dictionary:
	var defs: Dictionary = {
		&"cascade_reactor": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Reactor Core Ignition", "desc": "Hit all 4 corner boosters + center siphon.", "reward_desc": "Board Supercharge (+3 Energize to all pegs)"},
		&"perpetual_engine": {"type": GoalArchetype.ORBIT_FLOW, "reward": RewardType.MULTIBALL_CASCADE, "title": "Perpetual Loop", "desc": "Complete 3 continuous accelerator loops.", "reward_desc": "Multiball Cascade (4 extra balls)", "target_count": 3, "balls": 4},
		&"storm_of_fragments": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.MULTIBALL_CASCADE, "title": "Fragment Cluster", "desc": "Hit all 3 pop bumpers.", "reward_desc": "Multiball Cascade (5 fragment balls)", "balls": 5},
		&"explosive_contagion": {"type": GoalArchetype.JACKPOT_ACCUMULATOR, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Spore Overload", "desc": "Charge siphons and hit bumper to detonate.", "reward_desc": "Global Board Knock (All pegs hit once)"},
		&"superconductor": {"type": GoalArchetype.HURRY_UP_FRENZY, "reward": RewardType.ENERGY_SURGE, "title": "Superconductor Surge", "desc": "Hit spark rail, then bumper within 4s.", "reward_desc": "+200 Energy Surge to ball", "energy": 200, "time_limit": 4.0},
		&"rubber_storm": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.CONCUSSIVE_OVERDRIVE, "title": "Triangle Ricochet", "desc": "Hit all 3 triangle bumpers.", "reward_desc": "Concussive Overdrive Blast +180 Energy", "energy": 180},
		&"fragment_swarm": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.MULTIBALL_CASCADE, "title": "Swarm Chute", "desc": "Guide ball into the catch funnel.", "reward_desc": "Multiball Cascade (4 swarm balls)", "balls": 4},
		&"overdrive_cascade": {"type": GoalArchetype.ORBIT_FLOW, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Overdrive Orbit", "desc": "Deflect through 3 gates in continuous flow.", "reward_desc": "Board Supercharge (+3 Energize stacks)", "target_count": 3},
		&"goblin_width_tempest": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Tempest Run", "desc": "Hit Accelerator -> Funnel -> Bumper.", "reward_desc": "+180 Energy Surge to ball", "energy": 180},
		&"blood_tithe": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Tithe Gate", "desc": "Sink ball into top catch gate.", "reward_desc": "Global Board Knock (All pegs hit once)"},
		&"crown_ricochet": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Crown Ricochet", "desc": "Hit all 3 crown bumpers.", "reward_desc": "+150 Energy Surge to ball", "energy": 150},
		&"twin_mandate": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Dual Rail Route", "desc": "Hit Left Accelerator -> Right Accelerator.", "reward_desc": "+160 Energy Surge to ball", "energy": 160},
		&"velocity_dividend": {"type": GoalArchetype.JACKPOT_ACCUMULATOR, "reward": RewardType.ENERGY_SURGE, "title": "Vault Dividend", "desc": "Bumpers charge vault, hit booster to collect.", "reward_desc": "+220 Jackpot Energy Surge", "energy": 220},
		&"phase_sovereign": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Phase Alignment", "desc": "Hit ghost booster + all 3 siphons.", "reward_desc": "Board Supercharge (+3 Energize stacks)"},
		&"resonant_well": {"type": GoalArchetype.JACKPOT_ACCUMULATOR, "reward": RewardType.ENERGY_SURGE, "title": "Resonant Well", "desc": "Resonator wheels charge well, siphon collects.", "reward_desc": "+220 Jackpot Energy Surge", "energy": 220},
		&"renewal_pact": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Pact Solenoid", "desc": "Hit all 3 pulse solenoids.", "reward_desc": "Global Board Knock (All pegs hit once)"},
		&"gilded_covenant": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.ENERGY_SURGE, "title": "Gilded Vacuum", "desc": "Sink ball into top vacuum chute.", "reward_desc": "+250 Mega Energy Surge", "energy": 250},
		&"iron_bloom": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Magnetic Matrix", "desc": "Hit all 4 corner magnetic wheels.", "reward_desc": "Global Board Knock (All pegs hit once)"},
		&"echoes_of_wrench": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Wrench Circuit", "desc": "Hit Bumper -> Siphon -> Center Booster.", "reward_desc": "+175 Energy Surge to ball", "energy": 175},
		&"stormgrid_coupling": {"type": GoalArchetype.ORBIT_FLOW, "reward": RewardType.MULTIBALL_CASCADE, "title": "Stormgrid Orbit", "desc": "Pass through rails and boosters 3 times.", "reward_desc": "Multiball Cascade (3 balls)", "target_count": 3, "balls": 3},
		&"leech_singularity": {"type": GoalArchetype.JACKPOT_ACCUMULATOR, "reward": RewardType.ENERGY_SURGE, "title": "Singularity Siphon", "desc": "Siphons charge core, hit rotary core to collect.", "reward_desc": "+200 Energy Surge to ball", "energy": 200},
		&"phantom_resonance": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Spectral Network", "desc": "Hit Tesla resonator + all 3 siphons.", "reward_desc": "Board Supercharge (+3 Energize stacks)"},
		&"supernova_peg": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.CONCUSSIVE_OVERDRIVE, "title": "Supernova Ignition", "desc": "Hit booster + both bumpers.", "reward_desc": "Concussive Overdrive Blast +130 Energy", "energy": 130},
		&"chain_conduction": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Conduction Circuit", "desc": "Hit Rail -> Bumper -> Rail.", "reward_desc": "+120 Energy Surge to ball", "energy": 120},
		&"overcharged_drain": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.ENERGY_SURGE, "title": "Funnel Drain", "desc": "Sink ball into catch funnel.", "reward_desc": "+130 Energy Surge to ball", "energy": 130},
		&"final_arc_detonation": {"type": GoalArchetype.HURRY_UP_FRENZY, "reward": RewardType.CONCUSSIVE_OVERDRIVE, "title": "Arc Hurry-Up", "desc": "Hit rotary core, then bumper in 4s.", "reward_desc": "Concussive Overdrive Blast", "energy": 125, "time_limit": 4.0},
		&"energy_collapse": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Collapse Matrix", "desc": "Hit both siphons + both bumpers.", "reward_desc": "Global Board Knock (All pegs hit once)"},
		&"shrapnel_split": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.MULTIBALL_CASCADE, "title": "Shrapnel Deflector", "desc": "Hit left + right deflector plates.", "reward_desc": "Multiball Cascade (3 split balls)", "balls": 3},
		&"energized_fragments": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Fragment Acceleration", "desc": "Hit Roller 1 -> Roller 2 -> Bumper.", "reward_desc": "+110 Energy Surge to ball", "energy": 110},
		&"arc_twins": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Twin Arc Bridge", "desc": "Hit Left Booster -> Rails -> Right Booster.", "reward_desc": "+125 Energy Surge to ball", "energy": 125},
		&"phase_siphon": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Dual Siphon", "desc": "Hit both siphon nodes.", "reward_desc": "+100 Energy Surge to ball", "energy": 100},
		&"phase_detonation": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.CONCUSSIVE_OVERDRIVE, "title": "Detonation Sequence", "desc": "Hit Rotary Booster -> Rail -> Bumper.", "reward_desc": "Concussive Overdrive Blast", "energy": 115},
		&"spectral_conduit": {"type": GoalArchetype.ORBIT_FLOW, "reward": RewardType.ENERGY_SURGE, "title": "Spectral Orbit", "desc": "Loop through rails and accelerators 2 times.", "reward_desc": "+115 Energy Surge to ball", "energy": 115, "target_count": 2},
		&"impact_burst": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Triple Bumper Bank", "desc": "Hit all 3 kinetic bumpers.", "reward_desc": "Global Board Knock (All pegs hit once)"},
		&"kinetic_charge": {"type": GoalArchetype.JACKPOT_ACCUMULATOR, "reward": RewardType.ENERGY_SURGE, "title": "Kinetic Capacitor", "desc": "Boost wheel charges, siphon collects.", "reward_desc": "+140 Energy Surge to ball", "energy": 140},
		&"static_bounce": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Static Triangle", "desc": "Hit sensor + both bumpers.", "reward_desc": "+105 Energy Surge to ball", "energy": 105},
		&"parasitic_arc": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Parasitic Combo", "desc": "Hit Left Deflector -> Siphon -> Right Deflector.", "reward_desc": "+110 Energy Surge to ball", "energy": 110},
		&"draining_fragments": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.MULTIBALL_CASCADE, "title": "Drain Swarm", "desc": "Hit both siphons + bumper.", "reward_desc": "Multiball Cascade (3 balls)", "balls": 3},
		&"resonant_bounce": {"type": GoalArchetype.HURRY_UP_FRENZY, "reward": RewardType.ENERGY_SURGE, "title": "Resonance Hurry-Up", "desc": "Hit tuning core, then bumper in 4s.", "reward_desc": "+120 Energy Surge to ball", "energy": 120, "time_limit": 4.0},
		&"ricochet_blast": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Ricochet Bank", "desc": "Hit sensor + all 3 bumpers.", "reward_desc": "Global Board Knock (All pegs hit once)"},
		&"blast_launch": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.ENERGY_SURGE, "title": "Launch Spring Eject", "desc": "Sink ball into launch spring chute.", "reward_desc": "+135 Energy Surge to ball", "energy": 135},
		&"arc_surge_wrench": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Dual Solenoids", "desc": "Hit both rotary solenoids.", "reward_desc": "Board Supercharge (+2 Energize stacks)"},
		&"goblin_width_pulse": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.ENERGY_SURGE, "title": "Surge Chute", "desc": "Sink ball into chute funnel.", "reward_desc": "+110 Energy Surge to ball", "energy": 110},
		&"magnet_arc_snare": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Snare Matrix", "desc": "Hit both snare funnels + spark terminal.", "reward_desc": "+120 Energy Surge to ball", "energy": 120},
		&"spark_trampoline": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Trampoline Combo", "desc": "Hit both bumpers + spring plate.", "reward_desc": "+130 Energy Surge to ball", "energy": 130},
		&"hyper_elastic": {"type": GoalArchetype.ORBIT_FLOW, "reward": RewardType.ENERGY_SURGE, "title": "Elastic Track", "desc": "Pass through both boost rollers.", "reward_desc": "+80 Energy Surge to ball", "energy": 80, "target_count": 2},
		&"overdrive_hits": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Overdrive Bank", "desc": "Hit bumper + multiplier.", "reward_desc": "+75 Energy Surge to ball", "energy": 75},
		&"overclock_network": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Overclock Route", "desc": "Hit Rail -> Bumper -> Rail.", "reward_desc": "+70 Energy Surge to ball", "energy": 70},
		&"spreading_rot": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Rot Spores", "desc": "Hit both rot siphons + bumper.", "reward_desc": "Global Board Knock (All pegs hit once)"},
		&"cluster_grenade": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.MULTIBALL_CASCADE, "title": "Cluster Munitions", "desc": "Hit all 3 sub-munition bumpers.", "reward_desc": "Multiball Cascade (3 balls)", "balls": 3},
		&"blast_lift": {"type": GoalArchetype.ORBIT_FLOW, "reward": RewardType.ENERGY_SURGE, "title": "Lift Loop", "desc": "Pass through both concussion chutes.", "reward_desc": "+85 Energy Surge to ball", "energy": 85, "target_count": 2},
		&"fragmentation_tag": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Impact Tag", "desc": "Hit impact sensor + pop bumper.", "reward_desc": "+65 Energy Surge to ball", "energy": 65},
		&"storm_feedback": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Feedback Solenoid", "desc": "Hit solenoid + bumper.", "reward_desc": "+70 Energy Surge to ball", "energy": 70},
		&"overcurrent_surge": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Discharge Core", "desc": "Hit discharge resistor + bumper.", "reward_desc": "+75 Energy Surge to ball", "energy": 75},
		&"fragment_echo": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.MULTIBALL_CASCADE, "title": "Echo Spawner", "desc": "Sink ball into exit funnel.", "reward_desc": "Multiball Cascade (2 echo balls)", "balls": 2},
		&"mass_cascade": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Collision Core", "desc": "Hit collision plate + rotary sensor.", "reward_desc": "Global Board Knock (All pegs hit once)"},
		&"ghost_trail": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Ghost Trail", "desc": "Hit Permeable Rail -> Siphon.", "reward_desc": "+60 Energy Surge to ball", "energy": 60},
		&"phase_instability": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Phase Track", "desc": "Hit Boost Roller -> Rotary Sensor.", "reward_desc": "+65 Energy Surge to ball", "energy": 65},
		&"chest_random_ball": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.MULTIBALL_CASCADE, "title": "Vault Plunder", "desc": "Hit scrap vault core + bumper.", "reward_desc": "Multiball Cascade (2 balls)", "balls": 2},
		&"plain_surge": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Surge Bank", "desc": "Hit kinetic bumper + boost roller.", "reward_desc": "+60 Energy Surge to ball", "energy": 60},
		&"plain_horde": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.MULTIBALL_CASCADE, "title": "Horde Alarm", "desc": "Hit horde sensor + pop bumper.", "reward_desc": "Multiball Cascade (3 balls)", "balls": 3},
		&"plain_momentum": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Momentum Lane", "desc": "Hit Bumper -> Boost Roller.", "reward_desc": "+70 Energy Surge to ball", "energy": 70},
		&"volt_primer": {"type": GoalArchetype.HURRY_UP_FRENZY, "reward": RewardType.ENERGY_SURGE, "title": "Volt Primer", "desc": "Hit discount core, then rail in 4s.", "reward_desc": "+75 Energy Surge to ball", "energy": 75, "time_limit": 4.0},
		&"explosion_radius": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.CONCUSSIVE_OVERDRIVE, "title": "Blast Core", "desc": "Hit bumper + blast expansion core.", "reward_desc": "Concussive Overdrive Blast", "energy": 70},
		&"explosion_peg_hit_count": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Shrapnel Bank", "desc": "Hit bumper + spark deflector.", "reward_desc": "Global Board Knock (All pegs hit once)"},
		&"explosion_impulse": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Wave Launch", "desc": "Hit Wave Accelerator -> Bumper.", "reward_desc": "+60 Energy Surge to ball", "energy": 60},
		&"chain_arc": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Arc Extender", "desc": "Hit arc core + guide rail.", "reward_desc": "Board Supercharge (+2 Energize stacks)"},
		&"chain_range": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Voltage Conduction", "desc": "Hit Voltage Rail -> Rotary Core.", "reward_desc": "+65 Energy Surge to ball", "energy": 65},
		&"max_energize_stacks": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Dual Capacitor", "desc": "Hit capacitor + siphon.", "reward_desc": "Board Supercharge (+2 Energize stacks)"},
		&"energize_decays_slower": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Insulation Flow", "desc": "Hit Insulation Rail -> Siphon.", "reward_desc": "Board Supercharge (+2 Energize stacks)"},
		&"energized_pegs_repair_faster": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Nanite Network", "desc": "Hit nanite tube + siphon.", "reward_desc": "Board Supercharge (+2 Energize stacks)"},
		&"global_peg_durability": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Armor Bank", "desc": "Hit both armor bumpers.", "reward_desc": "Global Board Knock (All pegs hit once)"},
		&"peg_recovery_speed": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Reset Matrix", "desc": "Hit both reset bumpers + spring roller.", "reward_desc": "Global Board Knock (All pegs hit once)"},
		&"devastating_barrage": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Heavy Barrage", "desc": "Hit both heavy bumpers + rotary core.", "reward_desc": "Global Board Knock (All pegs hit once)"},
		&"compressed_charge": {"type": GoalArchetype.JACKPOT_ACCUMULATOR, "reward": RewardType.ENERGY_SURGE, "title": "Charge Capacitor", "desc": "Capacitors charge, siphon collects.", "reward_desc": "+100 Energy Surge to ball", "energy": 100},
		&"chest_leech_drain": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Leech Siphon Bank", "desc": "Hit drain siphon + bumper.", "reward_desc": "+55 Energy Surge to ball", "energy": 55},
		&"chest_leech_duration": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Leech Conduit", "desc": "Hit Leech Siphon -> Guide Rail.", "reward_desc": "+55 Energy Surge to ball", "energy": 55},
		&"chest_phantom_energy": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Spectral Bank", "desc": "Hit spectral siphon + guide rail.", "reward_desc": "+55 Energy Surge to ball", "energy": 55},
		&"chest_rubbery_energy": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Elastic Combo", "desc": "Hit elastic bumper + boost roller.", "reward_desc": "+60 Energy Surge to ball", "energy": 60},
		&"chest_bounce_energy": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Bounce Pair", "desc": "Hit standard bumper + rotary sensor.", "reward_desc": "+50 Energy Surge to ball", "energy": 50},
		&"chest_split_energy": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.MULTIBALL_CASCADE, "title": "Split Chute", "desc": "Hit Fragment Deflector -> Boost Roller.", "reward_desc": "Multiball Cascade (2 balls)", "balls": 2},
	}
	return defs.get(_resolve_id(id), {})

static func _def(id: StringName, name: String, tier: int, shape_name: String, machinery_desc: String, cells: Array[Vector2i], types: Dictionary = {}, dirs: Dictionary = {}, energies: Dictionary = {}) -> void:
	_DEFINITIONS[id] = {
		"display_name": name,
		"tier": tier,
		"shape_name": shape_name,
		"machinery_desc": machinery_desc,
		"cells": cells,
		"cell_types": types,
		"cell_directions": dirs,
		"energy_values": energies,
		"bumper_durability": 0
	}

static func _build_all_definitions() -> void:
	_DEFINITIONS.clear()
	_build_boss_amplifiers()
	_build_wall_break_cross_links()
	_build_single_ball_enhancements()
	_build_treasure_chest_passives()

static func _build_boss_amplifiers() -> void:
	_def(&"cascade_reactor", "Cascade Reactor", 3, "3x3 Solid Block", "4 Corner Boosters + Center Siphon + 4 Corridors", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.ROTARY_BOOSTER, Vector2i(0,2): CellType.ROTARY_BOOSTER, Vector2i(2,2): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.MANA_SIPHON}, {})
	_def(&"perpetual_engine", "Perpetual Engine", 3, "4x3 Pinball Loop", "Top Catch Chute + Boost Ring + Deflector Exit", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.FUNNEL, Vector2i(0,1): CellType.ACCELERATOR, Vector2i(3,1): CellType.ACCELERATOR, Vector2i(1,2): CellType.BUMPER, Vector2i(2,2): CellType.DIRECTIONAL_DEFLECTOR}, {Vector2i(1,0): Vector2i.DOWN, Vector2i(0,1): Vector2i.DOWN, Vector2i(3,1): Vector2i.UP, Vector2i(2,2): Vector2i.DOWN})
	_def(&"storm_of_fragments", "Storm of Fragments", 3, "3x4 Diamond Chamber", "3 Pop Bumpers + Splitter Core + Spark Deflector", [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(0,3), Vector2i(1,3), Vector2i(2,3)], {Vector2i(1,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(0,1): CellType.BUMPER, Vector2i(2,1): CellType.BUMPER, Vector2i(1,3): CellType.BUMPER}, {Vector2i(1,0): Vector2i.UP})
	_def(&"explosive_contagion", "Explosive Contagion", 3, "4x3 Z-Chamber", "3 Pop Bumpers + 2 Spore Siphons + 5 Free Corridors", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(0,0): CellType.BUMPER, Vector2i(2,1): CellType.BUMPER, Vector2i(3,2): CellType.BUMPER, Vector2i(1,0): CellType.MANA_SIPHON, Vector2i(2,2): CellType.MANA_SIPHON}, {})
	_def(&"superconductor", "Superconductor", 3, "4x3 Fortress Chamber", "3 Corner Pop Bumpers + Dual Spark Rails + 6 Playfield Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2), Vector2i(3,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER, Vector2i(3,2): CellType.BUMPER, Vector2i(0,1): CellType.GUIDE_RAIL, Vector2i(1,1): CellType.GUIDE_RAIL}, {})
	_def(&"rubber_storm", "Rubber Storm", 3, "4x3 Pinball Cluster", "3 Pop Bumpers in Triangle + 2 Edge Boosters + 7 Bounce Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.BUMPER, Vector2i(3,0): CellType.BUMPER, Vector2i(2,1): CellType.BUMPER, Vector2i(0,2): CellType.ACCELERATOR, Vector2i(3,2): CellType.ACCELERATOR}, {Vector2i(0,2): Vector2i.UP, Vector2i(3,2): Vector2i.UP})
	_def(&"fragment_swarm", "Fragment Swarm", 3, "3x4 Giant Arch", "Top Catch Funnel + 2 Spark Deflectors + 2 Heavy Bumpers", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1), Vector2i(0,2), Vector2i(2,2), Vector2i(0,3), Vector2i(1,3), Vector2i(2,3), Vector2i(1,2)], {Vector2i(1,0): CellType.FUNNEL, Vector2i(0,1): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(2,1): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(0,3): CellType.BUMPER, Vector2i(2,3): CellType.BUMPER}, {Vector2i(1,0): Vector2i.DOWN, Vector2i(0,1): Vector2i.LEFT, Vector2i(2,1): Vector2i.RIGHT})
	_def(&"overdrive_cascade", "Overdrive Cascade", 3, "4x3 Diamond Rhombus", "Central Overdrive Sensor + 3 Angled Deflector Plates", [Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(0,1): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(2,2): CellType.DIRECTIONAL_DEFLECTOR}, {Vector2i(2,0): Vector2i.UP, Vector2i(0,1): Vector2i.LEFT, Vector2i(2,2): Vector2i.DOWN})
	_def(&"goblin_width_tempest", "Goblin Width Tempest", 3, "3x4 Stepped Chamber", "Wide Catch Funnels + Upward Spring + 2 Corner Bumpers", [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(0,3), Vector2i(1,3), Vector2i(2,3), Vector2i(0,0)], {Vector2i(1,0): CellType.ACCELERATOR, Vector2i(1,1): CellType.FUNNEL, Vector2i(2,1): CellType.FUNNEL, Vector2i(0,3): CellType.BUMPER, Vector2i(2,3): CellType.BUMPER}, {Vector2i(1,0): Vector2i.UP, Vector2i(1,1): Vector2i.DOWN, Vector2i(2,1): Vector2i.LEFT})
	_def(&"blood_tithe", "Blood Tithe", 3, "4x3 Horseshoe Arch", "Top Catch Gate + 3 High-Volume Drain Siphons + 6 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.FUNNEL, Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(3,0): CellType.MANA_SIPHON, Vector2i(0,2): CellType.MANA_SIPHON}, {Vector2i(1,0): Vector2i.DOWN})
	_def(&"crown_ricochet", "Crown Ricochet", 3, "4x3 Crown Chamber", "3 Pop Bumpers in Triangle + 1 Vector Booster + 7 Playfield Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(0,0): CellType.BUMPER, Vector2i(3,0): CellType.BUMPER, Vector2i(1,1): CellType.BUMPER, Vector2i(2,2): CellType.ROTARY_BOOSTER}, {})
	_def(&"twin_mandate", "Twin Mandate", 3, "4x3 Dual Track", "2 Speed Boost Rollers + 2 Energy Siphons + 6 Bounce Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2), Vector2i(0,2)], {Vector2i(0,0): CellType.ACCELERATOR, Vector2i(3,2): CellType.ACCELERATOR, Vector2i(1,0): CellType.MANA_SIPHON, Vector2i(2,1): CellType.MANA_SIPHON}, {Vector2i(0,0): Vector2i.RIGHT, Vector2i(3,2): Vector2i.LEFT})
	_def(&"velocity_dividend", "Velocity Dividend", 3, "3x4 Pinball Vault", "3 Pop Bumpers + 1 Center Booster + 7 Free Travel Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(1,3), Vector2i(2,3)], {Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER, Vector2i(1,2): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"phase_sovereign", "Phase Sovereign", 3, "4x3 Spectral Tunnel", "1 Ghost Sensor + 3 Siphon Nodes + 7 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(3,0): CellType.MANA_SIPHON, Vector2i(1,1): CellType.MANA_SIPHON}, {})
	_def(&"resonant_well", "Resonant Well", 3, "4x3 Resonator Ring", "2 Resonator Wheels + 2 Energize Siphons + 8 Travel Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(2,2): CellType.ROTARY_BOOSTER, Vector2i(0,1): CellType.MANA_SIPHON, Vector2i(3,1): CellType.MANA_SIPHON}, {})
	_def(&"renewal_pact", "Renewal Pact", 3, "4x3 Solenoid Field", "3 Pulse Solenoids + 2 Repair Siphons + 5 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(3,0): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(0,2): CellType.MANA_SIPHON, Vector2i(3,2): CellType.MANA_SIPHON}, {})
	_def(&"gilded_covenant", "Gilded Covenant", 3, "4x3 Vault Chamber", "Top Vacuum Chute + 2 Vault Bumpers + 1 Rotary Coin Emitter", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.FUNNEL, Vector2i(0,0): CellType.BUMPER, Vector2i(3,0): CellType.BUMPER, Vector2i(2,2): CellType.ROTARY_BOOSTER}, {Vector2i(1,0): Vector2i.DOWN})
	_def(&"iron_bloom", "Iron Bloom", 3, "4x3 Solenoid Core", "4 Corner Magnetic Wheels + 2 Deflector Gates + 4 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(3,0): CellType.ROTARY_BOOSTER, Vector2i(0,2): CellType.ROTARY_BOOSTER, Vector2i(3,2): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(2,2): CellType.DIRECTIONAL_DEFLECTOR}, {})
	_def(&"echoes_of_wrench", "Echoes of the Wrench", 3, "4x3 T-Beam Frame", "2 Shock Plates + 2 Repair Siphons + 1 Central Booster", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.BUMPER, Vector2i(3,0): CellType.BUMPER, Vector2i(1,0): CellType.MANA_SIPHON, Vector2i(2,2): CellType.MANA_SIPHON, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"stormgrid_coupling", "Stormgrid Coupling", 3, "4x3 Magnetic Cradle", "2 Rotary Wheels + 1 Center Bumper + 2 Guide Rails + 6 Open Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(2,2): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.BUMPER, Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(0,1): CellType.GUIDE_RAIL}, {})
	_def(&"leech_singularity", "Leech Singularity", 3, "4x3 Arch Siphon", "1 Rotary Core + 3 High-Volume Siphons + 6 Open Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(3,0): CellType.MANA_SIPHON, Vector2i(0,2): CellType.MANA_SIPHON}, {})
	_def(&"phantom_resonance", "Phantom Resonance", 3, "4x3 Spectral Loop", "1 Tesla Resonator + 3 Siphons + 2 Rails + 5 Open Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(3,0): CellType.MANA_SIPHON, Vector2i(1,1): CellType.MANA_SIPHON, Vector2i(0,2): CellType.GUIDE_RAIL, Vector2i(3,2): CellType.GUIDE_RAIL}, {})

static func _build_wall_break_cross_links() -> void:
	_def(&"supernova_peg", "Supernova Peg", 2, "3x3 Box Chamber", "1 Rotary Booster + 2 Pop Bumpers + 4 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.BUMPER, Vector2i(2,2): CellType.BUMPER}, {})
	_def(&"chain_conduction", "Chain Conduction", 2, "4x2 Rail Frame", "2 Pop Bumpers + 2 Lightning Rails + 3 Corridors", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(2,1), Vector2i(3,1)], {Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(1,0): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER, Vector2i(3,0): CellType.GUIDE_RAIL}, {})
	_def(&"overcharged_drain", "Overcharged Drain", 2, "3x3 L-Chamber", "1 Funnel + 2 Siphons + 1 Bumper + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.FUNNEL, Vector2i(0,1): CellType.MANA_SIPHON, Vector2i(0,2): CellType.MANA_SIPHON, Vector2i(2,2): CellType.BUMPER}, {})
	_def(&"final_arc_detonation", "Final Arc Detonation", 2, "3x3 V-Chamber", "2 Bumpers + 1 Rotary Core + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.BUMPER}, {})
	_def(&"energy_collapse", "Energy Collapse", 2, "3x3 Z-Chamber", "2 Siphons + 2 Concussive Bumpers + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(1,0): CellType.MANA_SIPHON, Vector2i(1,1): CellType.BUMPER, Vector2i(2,2): CellType.BUMPER}, {})
	_def(&"shrapnel_split", "Shrapnel Split", 2, "3x3 T-Chamber", "2 Deflectors + 2 Bumpers + 3 Free Corridors", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(2,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(1,0): CellType.BUMPER, Vector2i(1,2): CellType.BUMPER}, {Vector2i(0,0): Vector2i.LEFT, Vector2i(2,0): Vector2i.RIGHT})
	_def(&"energized_fragments", "Energized Fragments", 2, "3x3 Skew Chamber", "2 Energize Rollers + 1 Contact Bumper + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)], {Vector2i(0,0): CellType.ACCELERATOR, Vector2i(1,0): CellType.ACCELERATOR, Vector2i(2,2): CellType.BUMPER}, {})
	_def(&"arc_twins", "Arc Twins", 2, "4x2 Dual Rail", "2 Rotary Boosters + 2 Guide Rails + 3 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(3,1)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.GUIDE_RAIL, Vector2i(2,0): CellType.GUIDE_RAIL, Vector2i(3,0): CellType.ROTARY_BOOSTER}, {})
	_def(&"phase_siphon", "Phase Siphon", 2, "3x3 V-Chamber", "2 Siphon Nodes + 1 Bumper + 3 Open Travel Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(1,1): CellType.MANA_SIPHON, Vector2i(2,0): CellType.BUMPER}, {})
	_def(&"phase_detonation", "Phase Detonation", 2, "3x3 Hook Chamber", "1 Rotary Booster + 1 Rail + 2 Bumpers + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.GUIDE_RAIL, Vector2i(2,0): CellType.BUMPER, Vector2i(2,2): CellType.BUMPER}, {})
	_def(&"spectral_conduit", "Spectral Conduit", 2, "3x3 Stepped Rail", "2 Rails + 2 Accelerators + 3 Travel Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(1,0): CellType.ACCELERATOR, Vector2i(1,1): CellType.GUIDE_RAIL, Vector2i(2,2): CellType.ACCELERATOR}, {})
	_def(&"impact_burst", "Impact Burst", 2, "3x3 T-Chamber", "3 Heavy Kinetic Bumpers + 1 Rotary Sensor + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.BUMPER, Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.BUMPER, Vector2i(1,2): CellType.BUMPER}, {})
	_def(&"kinetic_charge", "Kinetic Charge", 2, "3x3 Skew Chamber", "1 Boost Wheel + 1 Siphon + 1 Rotary Core + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)], {Vector2i(0,0): CellType.ACCELERATOR, Vector2i(1,0): CellType.MANA_SIPHON, Vector2i(2,2): CellType.ROTARY_BOOSTER}, {})
	_def(&"static_bounce", "Static Bounce", 2, "3x3 L-Chamber", "1 Rotary Sensor + 2 Pop Bumpers + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(0,1): CellType.BUMPER, Vector2i(1,2): CellType.BUMPER}, {})
	_def(&"parasitic_arc", "Parasitic Arc", 2, "3x3 V-Chamber", "2 Spark Deflectors + 1 Drain Siphon + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(1,1): CellType.MANA_SIPHON, Vector2i(2,0): CellType.DIRECTIONAL_DEFLECTOR}, {Vector2i(0,0): Vector2i.LEFT, Vector2i(2,0): Vector2i.RIGHT})
	_def(&"draining_fragments", "Draining Fragments", 2, "3x3 Skew Chamber", "2 Fragment Siphons + 1 Contact Bumper + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)], {Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(1,0): CellType.MANA_SIPHON, Vector2i(2,2): CellType.BUMPER}, {})
	_def(&"resonant_bounce", "Resonant Bounce", 2, "3x3 Straight Chamber", "2 Bumpers + 1 Resonance Tuning Core + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.BUMPER}, {})
	_def(&"ricochet_blast", "Ricochet Blast", 2, "3x3 L-Chamber", "1 Rotary Sensor + 3 Concussive Bumpers + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(0,1): CellType.BUMPER, Vector2i(0,2): CellType.BUMPER, Vector2i(2,2): CellType.BUMPER}, {})
	_def(&"blast_launch", "Blast Launch", 2, "3x3 V-Chamber", "2 Deflectors + 1 Upward Launch Spring + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(1,1): CellType.ACCELERATOR, Vector2i(2,0): CellType.DIRECTIONAL_DEFLECTOR}, {Vector2i(0,0): Vector2i.UP, Vector2i(1,1): Vector2i.UP, Vector2i(2,0): Vector2i.UP})
	_def(&"arc_surge_wrench", "Arc Surge Wrench", 2, "3x3 Straight Chamber", "2 Rotary Solenoids + 1 Wire Harness + 3 Travel Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.GUIDE_RAIL, Vector2i(2,0): CellType.ROTARY_BOOSTER}, {})
	_def(&"goblin_width_pulse", "Goblin Surge Chute", 2, "3x3 Skew Chamber", "1 Rotary Sensor + 2 Chute Funnels + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.FUNNEL, Vector2i(2,2): CellType.FUNNEL}, {})
	_def(&"magnet_arc_snare", "Magnet Arc Snare", 2, "3x3 V-Chamber", "2 Snare Funnels + 1 Spark Terminal + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.FUNNEL, Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.FUNNEL}, {})
	_def(&"spark_trampoline", "Spark Trampoline", 2, "3x3 Trampoline Chamber", "2 Bumpers + 1 Charged Spring Plate + 3 Travel Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(1,0): CellType.ACCELERATOR, Vector2i(2,0): CellType.BUMPER}, {Vector2i(1,0): Vector2i.UP})

static func _build_single_ball_enhancements() -> void:
	_def(&"hyper_elastic", "Hyper Elastic", 1, "2x3 Vertical Track", "2 Upward Boost Rollers + 3 Free Travel Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.ACCELERATOR, Vector2i(0,2): CellType.ACCELERATOR}, {Vector2i(0,0): Vector2i.UP, Vector2i(0,2): Vector2i.UP})
	_def(&"overdrive_hits", "Overdrive Hits", 1, "2x2 Box Chamber", "1 Pop Bumper + 1 Overdrive Multiplier + 2 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"overclock_network", "Overclock Network", 1, "3x2 V-Mesh", "2 Grid Rails + 1 Bumper + 2 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(2,1)], {Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(1,1): CellType.BUMPER, Vector2i(2,0): CellType.GUIDE_RAIL}, {})
	_def(&"spreading_rot", "Spreading Rot", 1, "2x3 L-Shape", "2 Rot Siphons + 1 Bumper + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)], {Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(0,1): CellType.MANA_SIPHON, Vector2i(1,2): CellType.BUMPER}, {})
	_def(&"cluster_grenade", "Cluster Grenade", 1, "3x2 Chevron", "3 Sub-Munition Pop Bumpers + 2 Travel Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER, Vector2i(1,0): CellType.BUMPER}, {})
	_def(&"blast_lift", "Blast Lift", 1, "2x3 Vertical Track", "2 Upward Concussion Chutes + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.ACCELERATOR, Vector2i(0,2): CellType.ACCELERATOR}, {Vector2i(0,0): Vector2i.UP, Vector2i(0,2): Vector2i.UP})
	_def(&"fragmentation_tag", "Fragmentation Tag", 1, "2x2 Box Chamber", "1 Impact Sensor + 1 Pop Bumper + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"storm_feedback", "Storm Feedback", 1, "3x2 Horizontal Bar", "1 Feedback Solenoid + 1 Bumper + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.BUMPER}, {})
	_def(&"overcurrent_surge", "Overcurrent Surge", 1, "2x2 Box Chamber", "1 Discharge Resistor + 1 Bumper + 2 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"fragment_echo", "Fragment Echo", 1, "3x2 Horizontal Bar", "1 Exit Funnel + 1 Top Spawner + 3 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.FUNNEL, Vector2i(2,0): CellType.ROTARY_BOOSTER}, {})
	_def(&"mass_cascade", "Mass Cascade", 1, "2x2 Box Chamber", "1 Collision Plate + 1 Rotary Sensor + 2 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"ghost_trail", "Ghost Trail", 1, "2x3 Vertical Track", "1 Permeable Rail + 1 Siphon + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(0,2): CellType.MANA_SIPHON}, {})
	_def(&"phase_instability", "Phase Instability", 1, "3x2 Horizontal Track", "1 Boost Roller + 1 Rotary Sensor + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.ACCELERATOR, Vector2i(2,0): CellType.ROTARY_BOOSTER}, {})
	_def(&"chest_random_ball", "Plunderer's Cut", 1, "2x2 Box Chamber", "1 Scrap Vault Core + 1 Bumper + 2 Open Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.BUMPER}, {})
	_def(&"plain_surge", "Plain Surge", 1, "3x2 Horizontal Bar", "1 Kinetic Bumper + 1 Boost Roller + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.ACCELERATOR}, {})
	_def(&"plain_horde", "Plain Horde", 1, "2x2 Box Chamber", "1 Horde Sensor + 1 Pop Bumper + 2 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"plain_momentum", "Plain Momentum", 1, "2x3 Vertical Bar", "1 Overdrive Bumper + 1 Boost Roller + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.BUMPER, Vector2i(0,2): CellType.ACCELERATOR}, {})
	_def(&"volt_primer", "Volt Primer", 1, "3x2 Horizontal Bar", "1 Cannon Discount Core + 1 Wire Rail + 3 Open Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.GUIDE_RAIL}, {})

static func _build_treasure_chest_passives() -> void:
	_def(&"explosion_radius", "Bigger Blasts", 1, "2x2 Box Chamber", "1 Blast Expansion Core + 1 Pop Bumper + 2 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"explosion_peg_hit_count", "More Explosion Hits", 1, "3x2 Horizontal Bar", "1 Shrapnel Bumper + 1 Spark Deflector + 3 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.DIRECTIONAL_DEFLECTOR}, {Vector2i(2,0): Vector2i.RIGHT})
	_def(&"explosion_impulse", "Stronger Blast Push", 1, "2x3 Vertical Bar", "1 Wave Accelerator + 1 Pop Bumper + 3 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.ACCELERATOR, Vector2i(0,2): CellType.BUMPER}, {Vector2i(0,0): Vector2i.UP})
	_def(&"chain_arc", "+1 Chain Jump", 1, "2x2 Box Chamber", "1 Arc Extender Core + 1 Guide Rail + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.GUIDE_RAIL}, {})
	_def(&"chain_range", "Longer Chains", 1, "3x2 Horizontal Bar", "1 Voltage Rail + 1 Rotary Core + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(2,0): CellType.ROTARY_BOOSTER}, {})
	_def(&"max_energize_stacks", "Deeper Energize", 1, "2x2 Box Chamber", "1 Dual Capacitor + 1 Siphon + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.MANA_SIPHON}, {})
	_def(&"energize_decays_slower", "Slower Energize Fade", 1, "2x3 Vertical Bar", "1 Insulation Rail + 1 Siphon + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(0,2): CellType.MANA_SIPHON}, {})
	_def(&"energized_pegs_repair_faster", "Fast Heal (Energized)", 1, "2x2 Box Chamber", "1 Nanite Tube + 1 Siphon + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.MANA_SIPHON}, {})
	_def(&"global_peg_durability", "Tough Pegs", 1, "3x2 Chevron", "2 Armor Plating Bumpers + 3 Free Travel Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER}, {})
	_def(&"peg_recovery_speed", "Faster Peg Recovery", 1, "3x2 Chevron", "2 Reset Bumpers + 1 Spring Roller + 2 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER, Vector2i(1,0): CellType.ACCELERATOR}, {})
	_def(&"devastating_barrage", "Devastating Barrage", 1, "2x3 L-Chamber", "2 Heavy Shell Bumpers + 1 Rotary Core + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)], {Vector2i(0,0): CellType.BUMPER, Vector2i(0,1): CellType.ROTARY_BOOSTER, Vector2i(1,2): CellType.BUMPER}, {})
	_def(&"compressed_charge", "Compressed Charge", 1, "2x3 L-Chamber", "2 Rotary Capacitors + 1 Siphon + 2 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(0,1): CellType.MANA_SIPHON, Vector2i(1,2): CellType.ROTARY_BOOSTER}, {})
	_def(&"chest_leech_drain", "Leech Drain Up", 1, "2x2 Box Chamber", "1 Drain Siphon + 1 Pop Bumper + 2 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(1,1): CellType.BUMPER}, {})
	_def(&"chest_leech_duration", "Longer Leech", 1, "2x3 Vertical Bar", "1 Leech Siphon + 1 Guide Rail + 3 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(0,2): CellType.GUIDE_RAIL}, {})
	_def(&"chest_phantom_energy", "Phantom Energy", 1, "2x2 Box Chamber", "1 Spectral Siphon + 1 Guide Rail + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(1,1): CellType.GUIDE_RAIL}, {})
	_def(&"chest_rubbery_energy", "Rubbery Energy", 1, "3x2 Horizontal Bar", "1 Elastic Bumper + 1 Boost Roller + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.ACCELERATOR}, {})
	_def(&"chest_bounce_energy", "Plain Energy", 1, "2x2 Box Chamber", "1 Standard Bumper + 1 Rotary Sensor + 2 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"chest_split_energy", "Split Energy", 1, "2x3 Vertical Bar", "1 Fragment Deflector + 1 Boost Roller + 3 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(0,2): CellType.ACCELERATOR}, {Vector2i(0,0): Vector2i.DOWN, Vector2i(0,2): Vector2i.DOWN})

