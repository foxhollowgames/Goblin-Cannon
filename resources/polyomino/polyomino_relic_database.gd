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
static var _MULTI_PEG_DEFINITIONS: Dictionary = {}

static func _resolve_id(id: StringName) -> StringName:
	return _ALIASES.get(id, id)

static func _get_defs() -> Dictionary:
	if not _DEFINITIONS.is_empty():
		return _DEFINITIONS
	_build_all_definitions()
	return _DEFINITIONS

static func _get_def(id: StringName) -> Dictionary:
	var defs := _get_defs()
	var res_id: StringName = _resolve_id(id)
	if defs.has(res_id):
		return defs[res_id]
	if _MULTI_PEG_DEFINITIONS.has(res_id):
		return _MULTI_PEG_DEFINITIONS[res_id]
	return {}

static func has_relic_definition(relic_id: StringName) -> bool:
	var res_id: StringName = _resolve_id(relic_id)
	return _get_defs().has(res_id) or _MULTI_PEG_DEFINITIONS.has(res_id)

static func get_all_relic_ids() -> Array[StringName]:
	var defs := _get_defs()
	var ids: Array[StringName] = []
	for k in defs:
		ids.append(k)
	return ids

static func get_relic_tier(relic_id: StringName) -> int:
	var d = _get_def(relic_id)
	if not d.is_empty():
		return int(d.get("tier", 1))
	return 1

static func get_relic_shape_name(relic_id: StringName) -> String:
	var d = _get_def(relic_id)
	if not d.is_empty():
		return str(d.get("shape_name", ""))
	return ""

static func get_relic_kinetic_description(relic_id: StringName) -> String:
	var d = _get_def(relic_id)
	if not d.is_empty():
		return str(d.get("machinery_desc", ""))
	return ""

static func get_relic_display_name(relic_id: StringName) -> String:
	var d = _get_def(relic_id)
	if not d.is_empty():
		return str(d.get("display_name", ""))
	return ""

static func get_relic_goal_title(relic_id: StringName) -> String:
	var g: Dictionary = _get_goal_def(relic_id)
	return str(g.get("title", "Bank Clear"))

static func get_relic_goal_description(relic_id: StringName) -> String:
	var g: Dictionary = _get_goal_def(relic_id)
	return str(g.get("desc", "Hit all components in module."))

static func get_relic_activation_requirement(relic_id: StringName) -> String:
	var g: Dictionary = _get_goal_def(relic_id)
	if g.has("activation_req"):
		return str(g["activation_req"])
	return get_relic_goal_description(relic_id)

static func get_relic_reward_description(relic_id: StringName) -> String:
	var g: Dictionary = _get_goal_def(relic_id)
	return str(g.get("reward_desc", "+100 Energy Surge"))

static func create_module_for_relic(relic_id: StringName) -> PolyominoModuleData:
	var resolved_id: StringName = _resolve_id(relic_id)
	var def = _get_def(resolved_id)
	if def.is_empty():
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

	mod.enclosure_type = int(def.get("enclosure_type", PolyominoModuleData.EnclosureType.OPEN_FRAME))
	mod.layout_mode = int(def.get("layout_mode", PolyominoModuleData.MachineryLayoutMode.PER_CELL))
	mod.unified_component_type = int(def.get("unified_component_type", PolyominoModuleData.CellType.EMPTY))
	var raw_walls: Dictionary = def.get("custom_wall_edges", {})
	for k in raw_walls:
		var pos: Vector2i = k if k is Vector2i else _parse_vector2i(str(k))
		mod.custom_wall_edges[pos] = raw_walls[k]

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
		mod.activation_requirement = get_relic_activation_requirement(resolved_id)
		mod.required_widget_type = int(g.get("required_widget", CellType.EMPTY))
		mod.activation_threshold = int(g.get("threshold", g.get("target_count", 0)))
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
	var item := JunkBoxItem.new(StringName("relic_%s_%d_%d" % [relic_id, Time.get_ticks_usec(), randi() % 1000000]), JunkBoxItem.POLYOMINO_MODULE)
	item.display_name = mod.display_name
	item.module_data = mod
	item.custom_payload = {
		"relic_id": str(_resolve_id(relic_id)),
		"tier": mod.tier,
		"shape_name": get_relic_shape_name(relic_id),
		"machinery_desc": get_relic_kinetic_description(relic_id),
		"goal_title": mod.goal_title,
		"goal_desc": mod.goal_description,
		"activation_requirement": mod.activation_requirement,
		"reward_desc": mod.reward_description
	}
	return item

## Applies board slotting registry to GameState when a relic module is slotted onto the board.
static func apply_relic_effects_to_game_state(relic_id: StringName) -> void:
	if not Engine.has_singleton("GameState") and not ClassDB.class_exists("GameState"):
		pass
	var uid: StringName = _resolve_id(relic_id)
	if not has_relic_definition(uid):
		return

	var tier: int = get_relic_tier(uid)
	if tier == 3:
		GameState.add_boss_upgrade(uid, 1)
	else:
		GameState.add_wall_break_upgrade(uid, 1)

## Reverts board slotting registry from GameState when a relic module is unslotted from the board.
static func remove_relic_effects_from_game_state(relic_id: StringName) -> void:
	if not Engine.has_singleton("GameState") and not ClassDB.class_exists("GameState"):
		pass
	var uid: StringName = _resolve_id(relic_id)
	if not has_relic_definition(uid):
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
		&"cascade_reactor": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Reactor Core Ignition", "desc": "Hit all 4 corner boosters + center bumper.", "activation_req": "Hit all 4 corner boosters and center bumper.", "reward_desc": "Board Supercharge (+3 Energize to all pegs)"},
		&"perpetual_engine": {"type": GoalArchetype.ORBIT_FLOW, "reward": RewardType.MULTIBALL_CASCADE, "title": "Perpetual Loop", "desc": "Complete 3 continuous accelerator loops.", "activation_req": "Complete 3 continuous accelerator loops.", "reward_desc": "Multiball Cascade (4 extra balls)", "target_count": 3, "balls": 4, "required_widget": CellType.ACCELERATOR, "threshold": 3},
		&"storm_of_fragments": {"type": GoalArchetype.SUPER_JETS, "reward": RewardType.MULTIBALL_CASCADE, "title": "Fragment Cluster", "desc": "Hit all 3 pop bumpers.", "activation_req": "Hit all 3 pop bumpers.", "reward_desc": "Multiball Cascade (5 fragment balls)", "balls": 5, "required_widget": CellType.POP_BUMPER, "threshold": 3},
		&"explosive_contagion": {"type": GoalArchetype.TACTICAL_REBOUND, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Spore Overload", "desc": "Deflect across slingshots 3 times.", "activation_req": "Deflect across slingshots 3 times.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.SLINGSHOT, "threshold": 3},
		&"superconductor": {"type": GoalArchetype.HURRY_UP_FRENZY, "reward": RewardType.ENERGY_SURGE, "title": "Superconductor Surge", "desc": "Hit drop target, then target again within 4s.", "activation_req": "Knock down drop target within 4s.", "reward_desc": "+200 Energy Surge to ball", "energy": 200, "time_limit": 4.0, "required_widget": CellType.DROP_TARGET, "threshold": 3},
		&"rubber_storm": {"type": GoalArchetype.SUPER_JETS, "reward": RewardType.CONCUSSIVE_OVERDRIVE, "title": "Triangle Ricochet", "desc": "Hit all 3 triangle pop bumpers.", "activation_req": "Hit all 3 triangle pop bumpers.", "reward_desc": "Concussive Overdrive Blast +180 Energy", "energy": 180, "required_widget": CellType.POP_BUMPER, "threshold": 3},
		&"fragment_swarm": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.MULTIBALL_CASCADE, "title": "Swarm Chute", "desc": "Sink ball into catch scoop funnel.", "activation_req": "Sink ball into catch scoop.", "reward_desc": "Multiball Cascade (4 swarm balls)", "balls": 4, "required_widget": CellType.SCOOP_SINKHOLE, "threshold": 1},
		&"overdrive_cascade": {"type": GoalArchetype.ORBIT_FLOW, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Overdrive Orbit", "desc": "Complete 2 consecutive orbit loops.", "activation_req": "Complete 2 orbit loops.", "reward_desc": "Board Supercharge (+3 Energize stacks)", "target_count": 2, "required_widget": CellType.ORBIT_LOOP, "threshold": 2},
		&"goblin_width_tempest": {"type": GoalArchetype.LAUNCH_RAMP, "reward": RewardType.ENERGY_SURGE, "title": "Tempest Run", "desc": "Launch ball through vertical up kicker.", "activation_req": "Enter vertical up kicker.", "reward_desc": "+180 Energy Surge to ball", "energy": 180, "required_widget": CellType.VERTICAL_UP_KICKER, "threshold": 1},
		&"blood_tithe": {"type": GoalArchetype.BASH_DEMOLITION, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Tithe Gate", "desc": "Strike the blood altar bash toy 3 times.", "activation_req": "Strike bash toy 3 times.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.BASH_TOY, "threshold": 3},
		&"crown_ricochet": {"type": GoalArchetype.SUPER_JETS, "reward": RewardType.ENERGY_SURGE, "title": "Crown Ricochet", "desc": "Hit all 3 crown pop bumpers.", "activation_req": "Hit all 3 crown pop bumpers.", "reward_desc": "+150 Energy Surge to ball", "energy": 150, "required_widget": CellType.POP_BUMPER, "threshold": 3},
		&"twin_mandate": {"type": GoalArchetype.ORBIT_FLOW, "reward": RewardType.ENERGY_SURGE, "title": "Dual Rail Route", "desc": "Traverse both twin orbit loops.", "activation_req": "Traverse both twin orbit loops.", "reward_desc": "+160 Energy Surge to ball", "energy": 160, "target_count": 2, "required_widget": CellType.ORBIT_LOOP, "threshold": 2},
		&"velocity_dividend": {"type": GoalArchetype.BASH_DEMOLITION, "reward": RewardType.ENERGY_SURGE, "title": "Vault Dividend", "desc": "Smash central vault bash toy 3 times.", "activation_req": "Smash vault bash toy 3 times.", "reward_desc": "+220 Jackpot Energy Surge", "energy": 220, "required_widget": CellType.BASH_TOY, "threshold": 3},
		&"phase_sovereign": {"type": GoalArchetype.DIVERTER_SWITCH, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Phase Alignment", "desc": "Trip the mechanical diverter gate.", "activation_req": "Trip mechanical diverter gate.", "reward_desc": "Board Supercharge (+3 Energize stacks)", "required_widget": CellType.MECHANICAL_DIVERTER, "threshold": 1},
		&"resonant_well": {"type": GoalArchetype.SPINNER_RPM, "reward": RewardType.ENERGY_SURGE, "title": "Resonant Well", "desc": "Rev spinners to complete 20 revolutions.", "activation_req": "Rev spinners 20 revolutions.", "reward_desc": "+220 Jackpot Energy Surge", "energy": 220, "required_widget": CellType.SPINNER, "threshold": 20, "target_count": 20},
		&"renewal_pact": {"type": GoalArchetype.TACTICAL_REBOUND, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Pact Solenoid", "desc": "Deflect across slingshots 3 times.", "activation_req": "Deflect off slingshots 3 times.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.SLINGSHOT, "threshold": 3},
		&"gilded_covenant": {"type": GoalArchetype.BASH_DEMOLITION, "reward": RewardType.ENERGY_SURGE, "title": "Gilded Vacuum", "desc": "Strike the gilded reliquary bash toy 3 times.", "activation_req": "Strike bash toy 3 times.", "reward_desc": "+250 Mega Energy Surge", "energy": 250, "required_widget": CellType.BASH_TOY, "threshold": 3},
		&"iron_bloom": {"type": GoalArchetype.BASH_DEMOLITION, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Magnetic Matrix", "desc": "Strike all 4 corner iron bloom bash targets.", "activation_req": "Strike 4 corner bash targets.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.BASH_TOY, "threshold": 4},
		&"echoes_of_wrench": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Wrench Circuit", "desc": "Knock down both drop targets.", "activation_req": "Knock down both drop targets.", "reward_desc": "+175 Energy Surge to ball", "energy": 175, "required_widget": CellType.DROP_TARGET, "threshold": 2},
		&"stormgrid_coupling": {"type": GoalArchetype.BASH_DEMOLITION, "reward": RewardType.MULTIBALL_CASCADE, "title": "Stormgrid Orbit", "desc": "Strike the central storm core bash toy 3 times.", "activation_req": "Strike storm bash toy 3 times.", "reward_desc": "Multiball Cascade (3 balls)", "balls": 3, "required_widget": CellType.BASH_TOY, "threshold": 3},
		&"leech_singularity": {"type": GoalArchetype.BASH_DEMOLITION, "reward": RewardType.ENERGY_SURGE, "title": "Singularity Siphon", "desc": "Strike captive ball into siphon 2 times.", "activation_req": "Strike captive ball 2 times.", "reward_desc": "+200 Energy Surge to ball", "energy": 200, "required_widget": CellType.CAPTIVE_BALL, "threshold": 2},
		&"phantom_resonance": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Spectral Network", "desc": "Traverse guide track through spectral circuit.", "activation_req": "Traverse spectral guide track.", "reward_desc": "Board Supercharge (+3 Energize stacks)", "required_widget": CellType.GUIDE_TRACK, "threshold": 1},
		&"supernova_peg": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.CONCUSSIVE_OVERDRIVE, "title": "Supernova Ignition", "desc": "Knock down both drop targets.", "activation_req": "Knock down both drop targets.", "reward_desc": "Concussive Overdrive Blast +130 Energy", "energy": 130, "required_widget": CellType.DROP_TARGET, "threshold": 2},
		&"chain_conduction": {"type": GoalArchetype.SUPER_JETS, "reward": RewardType.ENERGY_SURGE, "title": "Conduction Circuit", "desc": "Hit both conduction pop bumpers.", "activation_req": "Hit both pop bumpers.", "reward_desc": "+120 Energy Surge to ball", "energy": 120, "required_widget": CellType.POP_BUMPER, "threshold": 2},
		&"overcharged_drain": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.ENERGY_SURGE, "title": "Funnel Drain", "desc": "Sink ball into catch scoop funnel.", "activation_req": "Sink ball into catch scoop.", "reward_desc": "+130 Energy Surge to ball", "energy": 130, "required_widget": CellType.SCOOP_SINKHOLE, "threshold": 1},
		&"final_arc_detonation": {"type": GoalArchetype.LAUNCH_RAMP, "reward": RewardType.CONCUSSIVE_OVERDRIVE, "title": "Arc Hurry-Up", "desc": "Enter vertical up kicker.", "activation_req": "Enter vertical up kicker.", "reward_desc": "Concussive Overdrive Blast", "energy": 125, "required_widget": CellType.VERTICAL_UP_KICKER, "threshold": 1},
		&"energy_collapse": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Collapse Matrix", "desc": "Knock down both drop targets in the bank.", "activation_req": "Knock down both drop targets.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.DROP_TARGET, "threshold": 2},
		&"shrapnel_split": {"type": GoalArchetype.DIVERTER_SWITCH, "reward": RewardType.MULTIBALL_CASCADE, "title": "Shrapnel Deflector", "desc": "Trip mechanical diverter gate.", "activation_req": "Trip mechanical diverter gate.", "reward_desc": "Multiball Cascade (3 split balls)", "balls": 3, "required_widget": CellType.MECHANICAL_DIVERTER, "threshold": 1},
		&"energized_fragments": {"type": GoalArchetype.SPINNER_RPM, "reward": RewardType.ENERGY_SURGE, "title": "Fragment Acceleration", "desc": "Rev spinners to complete 15 revolutions.", "activation_req": "Rev spinners 15 revolutions.", "reward_desc": "+110 Energy Surge to ball", "energy": 110, "required_widget": CellType.SPINNER, "threshold": 15, "target_count": 15},
		&"arc_twins": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Twin Arc Bridge", "desc": "Traverse both twin guide tracks.", "activation_req": "Traverse both guide tracks.", "reward_desc": "+125 Energy Surge to ball", "energy": 125, "required_widget": CellType.GUIDE_TRACK, "threshold": 2},
		&"phase_siphon": {"type": GoalArchetype.ROLLOVER_SPELL, "reward": RewardType.ENERGY_SURGE, "title": "Dual Siphon", "desc": "Roll over phase sensor switch.", "activation_req": "Roll over phase switch.", "reward_desc": "+100 Energy Surge to ball", "energy": 100, "required_widget": CellType.ROLLOVER_SWITCH, "threshold": 1},
		&"phase_detonation": {"type": GoalArchetype.ORBIT_FLOW, "reward": RewardType.CONCUSSIVE_OVERDRIVE, "title": "Detonation Sequence", "desc": "Complete 1 orbit loop traversal.", "activation_req": "Complete 1 orbit loop.", "reward_desc": "Concussive Overdrive Blast", "energy": 115, "target_count": 1, "required_widget": CellType.ORBIT_LOOP, "threshold": 1},
		&"spectral_conduit": {"type": GoalArchetype.ORBIT_FLOW, "reward": RewardType.ENERGY_SURGE, "title": "Spectral Orbit", "desc": "Complete 2 conduit orbit loops.", "activation_req": "Complete 2 orbit loops.", "reward_desc": "+115 Energy Surge to ball", "energy": 115, "target_count": 2, "required_widget": CellType.ORBIT_LOOP, "threshold": 2},
		&"impact_burst": {"type": GoalArchetype.SUPER_JETS, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Triple Bumper Bank", "desc": "Hit all 3 impact pop bumpers.", "activation_req": "Hit all 3 pop bumpers.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.POP_BUMPER, "threshold": 3},
		&"kinetic_charge": {"type": GoalArchetype.SPINNER_RPM, "reward": RewardType.ENERGY_SURGE, "title": "Kinetic Capacitor", "desc": "Rev spinner to complete 10 revolutions.", "activation_req": "Rev spinner 10 revolutions.", "reward_desc": "+140 Energy Surge to ball", "energy": 140, "required_widget": CellType.SPINNER, "threshold": 10, "target_count": 10},
		&"static_bounce": {"type": GoalArchetype.ROLLOVER_SPELL, "reward": RewardType.ENERGY_SURGE, "title": "Static Triangle", "desc": "Roll over static switch.", "activation_req": "Roll over static switch.", "reward_desc": "+105 Energy Surge to ball", "energy": 105, "required_widget": CellType.ROLLOVER_SWITCH, "threshold": 1},
		&"parasitic_arc": {"type": GoalArchetype.DIVERTER_SWITCH, "reward": RewardType.ENERGY_SURGE, "title": "Parasitic Combo", "desc": "Trip mechanical diverter gate.", "activation_req": "Trip diverter gate.", "reward_desc": "+110 Energy Surge to ball", "energy": 110, "required_widget": CellType.MECHANICAL_DIVERTER, "threshold": 1},
		&"draining_fragments": {"type": GoalArchetype.TACTICAL_REBOUND, "reward": RewardType.MULTIBALL_CASCADE, "title": "Drain Swarm", "desc": "Deflect off corner slingshot.", "activation_req": "Deflect off slingshot.", "reward_desc": "Multiball Cascade (3 balls)", "balls": 3, "required_widget": CellType.SLINGSHOT, "threshold": 1},
		&"resonant_bounce": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Resonance Hurry-Up", "desc": "Knock down both resonant drop targets.", "activation_req": "Knock down both drop targets.", "reward_desc": "+120 Energy Surge to ball", "energy": 120, "required_widget": CellType.DROP_TARGET, "threshold": 2},
		&"ricochet_blast": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Ricochet Bank", "desc": "Knock down all 3 drop targets in the bank.", "activation_req": "Knock down all 3 drop targets.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.DROP_TARGET, "threshold": 3},
		&"blast_launch": {"type": GoalArchetype.LAUNCH_RAMP, "reward": RewardType.ENERGY_SURGE, "title": "Launch Spring Eject", "desc": "Enter vertical up kicker launch pot.", "activation_req": "Enter vertical up kicker.", "reward_desc": "+135 Energy Surge to ball", "energy": 135, "required_widget": CellType.VERTICAL_UP_KICKER, "threshold": 1},
		&"arc_surge_wrench": {"type": GoalArchetype.TACTICAL_REBOUND, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Dual Solenoids", "desc": "Deflect off slingshot.", "activation_req": "Deflect off slingshot.", "reward_desc": "Board Supercharge (+2 Energize stacks)", "required_widget": CellType.SLINGSHOT, "threshold": 1},
		&"goblin_width_pulse": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.ENERGY_SURGE, "title": "Surge Chute", "desc": "Sink ball into surge scoop.", "activation_req": "Sink ball into scoop.", "reward_desc": "+110 Energy Surge to ball", "energy": 110, "required_widget": CellType.SCOOP_SINKHOLE, "threshold": 1},
		&"magnet_arc_snare": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.ENERGY_SURGE, "title": "Snare Matrix", "desc": "Lock ball into snare chamber.", "activation_req": "Lock ball in snare lock.", "reward_desc": "+120 Energy Surge to ball", "energy": 120, "required_widget": CellType.BALL_LOCK, "threshold": 1},
		&"spark_trampoline": {"type": GoalArchetype.BASH_DEMOLITION, "reward": RewardType.ENERGY_SURGE, "title": "Trampoline Combo", "desc": "Strike captive ball 2 times.", "activation_req": "Strike captive ball 2 times.", "reward_desc": "+130 Energy Surge to ball", "energy": 130, "required_widget": CellType.CAPTIVE_BALL, "threshold": 2},
		&"hyper_elastic": {"type": GoalArchetype.ORBIT_FLOW, "reward": RewardType.ENERGY_SURGE, "title": "Elastic Track", "desc": "Pass through spinners to complete loops.", "activation_req": "Complete 2 spinner passes.", "reward_desc": "+80 Energy Surge to ball", "energy": 80, "target_count": 2, "required_widget": CellType.SPINNER, "threshold": 2},
		&"overdrive_hits": {"type": GoalArchetype.SUPER_JETS, "reward": RewardType.ENERGY_SURGE, "title": "Overdrive Bumper", "desc": "Hit pop bumper.", "activation_req": "Hit pop bumper.", "reward_desc": "+75 Energy Surge to ball", "energy": 75, "required_widget": CellType.POP_BUMPER, "threshold": 1},
		&"overclock_network": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Overclock Route", "desc": "Traverse guide track to bumper.", "activation_req": "Traverse guide track.", "reward_desc": "+70 Energy Surge to ball", "energy": 70, "required_widget": CellType.GUIDE_TRACK, "threshold": 1},
		&"spreading_rot": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Rot Spores", "desc": "Knock down rot drop target.", "activation_req": "Knock down drop target.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.DROP_TARGET, "threshold": 1},
		&"cluster_grenade": {"type": GoalArchetype.SUPER_JETS, "reward": RewardType.MULTIBALL_CASCADE, "title": "Cluster Munitions", "desc": "Hit all 3 cluster pop bumpers.", "activation_req": "Hit all 3 pop bumpers.", "reward_desc": "Multiball Cascade (3 balls)", "balls": 3, "required_widget": CellType.POP_BUMPER, "threshold": 3},
		&"blast_lift": {"type": GoalArchetype.LAUNCH_RAMP, "reward": RewardType.ENERGY_SURGE, "title": "Lift Loop", "desc": "Enter vertical up kicker.", "activation_req": "Enter vertical up kicker.", "reward_desc": "+85 Energy Surge to ball", "energy": 85, "required_widget": CellType.VERTICAL_UP_KICKER, "threshold": 1},
		&"fragmentation_tag": {"type": GoalArchetype.SUPER_JETS, "reward": RewardType.ENERGY_SURGE, "title": "Impact Tag", "desc": "Hit impact pop bumper.", "activation_req": "Hit pop bumper.", "reward_desc": "+65 Energy Surge to ball", "energy": 65, "required_widget": CellType.POP_BUMPER, "threshold": 1},
		&"storm_feedback": {"type": GoalArchetype.TACTICAL_REBOUND, "reward": RewardType.ENERGY_SURGE, "title": "Feedback Solenoid", "desc": "Deflect off slingshot kicker.", "activation_req": "Deflect off slingshot.", "reward_desc": "+70 Energy Surge to ball", "energy": 70, "required_widget": CellType.SLINGSHOT, "threshold": 1},
		&"overcurrent_surge": {"type": GoalArchetype.ROLLOVER_SPELL, "reward": RewardType.ENERGY_SURGE, "title": "Discharge Core", "desc": "Roll over discharge switch.", "activation_req": "Roll over switch.", "reward_desc": "+75 Energy Surge to ball", "energy": 75, "required_widget": CellType.ROLLOVER_SWITCH, "threshold": 1},
		&"fragment_echo": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.MULTIBALL_CASCADE, "title": "Echo Spawner", "desc": "Sink ball into echo scoop.", "activation_req": "Sink ball into scoop.", "reward_desc": "Multiball Cascade (2 echo balls)", "balls": 2, "required_widget": CellType.SCOOP_SINKHOLE, "threshold": 1},
		&"mass_cascade": {"type": GoalArchetype.BASH_DEMOLITION, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Collision Core", "desc": "Strike mass captive ball.", "activation_req": "Strike captive ball.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.CAPTIVE_BALL, "threshold": 1},
		&"ghost_trail": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Ghost Trail", "desc": "Traverse ghost guide track.", "activation_req": "Traverse guide track.", "reward_desc": "+60 Energy Surge to ball", "energy": 60, "required_widget": CellType.GUIDE_TRACK, "threshold": 1},
		&"phase_instability": {"type": GoalArchetype.ORBIT_FLOW, "reward": RewardType.ENERGY_SURGE, "title": "Phase Track", "desc": "Complete 1 orbit loop traversal.", "activation_req": "Complete 1 orbit loop.", "reward_desc": "+65 Energy Surge to ball", "energy": 65, "target_count": 1, "required_widget": CellType.ORBIT_LOOP, "threshold": 1},
		&"chest_random_ball": {"type": GoalArchetype.BASH_DEMOLITION, "reward": RewardType.MULTIBALL_CASCADE, "title": "Vault Plunder", "desc": "Strike vault captive ball.", "activation_req": "Strike captive ball.", "reward_desc": "Multiball Cascade (2 balls)", "balls": 2, "required_widget": CellType.CAPTIVE_BALL, "threshold": 1},
		&"plain_surge": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.ENERGY_SURGE, "title": "Surge Bank", "desc": "Hit kinetic bumper + boost roller.", "activation_req": "Hit all components in module.", "reward_desc": "+60 Energy Surge to ball", "energy": 60, "threshold": 2},
		&"plain_horde": {"type": GoalArchetype.SUPER_JETS, "reward": RewardType.MULTIBALL_CASCADE, "title": "Horde Alarm", "desc": "Hit horde pop bumper.", "activation_req": "Hit pop bumper.", "reward_desc": "Multiball Cascade (3 balls)", "balls": 3, "required_widget": CellType.POP_BUMPER, "threshold": 1},
		&"plain_momentum": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Momentum Lane", "desc": "Hit Bumper -> Boost Roller.", "activation_req": "Traverse sequence route.", "reward_desc": "+70 Energy Surge to ball", "energy": 70, "threshold": 2},
		&"volt_primer": {"type": GoalArchetype.ROLLOVER_SPELL, "reward": RewardType.ENERGY_SURGE, "title": "Volt Primer", "desc": "Roll over primer switch.", "activation_req": "Roll over switch.", "reward_desc": "+75 Energy Surge to ball", "energy": 75, "required_widget": CellType.ROLLOVER_SWITCH, "threshold": 1},
		&"explosion_radius": {"type": GoalArchetype.TACTICAL_REBOUND, "reward": RewardType.CONCUSSIVE_OVERDRIVE, "title": "Blast Core", "desc": "Deflect off slingshot.", "activation_req": "Deflect off slingshot.", "reward_desc": "Concussive Overdrive Blast", "energy": 70, "required_widget": CellType.SLINGSHOT, "threshold": 1},
		&"explosion_peg_hit_count": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Shrapnel Bank", "desc": "Lock ball into shrapnel chamber.", "activation_req": "Lock ball in chamber.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.BALL_LOCK, "threshold": 1},
		&"explosion_impulse": {"type": GoalArchetype.LAUNCH_RAMP, "reward": RewardType.ENERGY_SURGE, "title": "Wave Launch", "desc": "Enter vertical up kicker.", "activation_req": "Enter vertical up kicker.", "reward_desc": "+60 Energy Surge to ball", "energy": 60, "required_widget": CellType.VERTICAL_UP_KICKER, "threshold": 1},
		&"chain_arc": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Arc Extender", "desc": "Traverse arc guide track.", "activation_req": "Traverse guide track.", "reward_desc": "Board Supercharge (+2 Energize stacks)", "required_widget": CellType.GUIDE_TRACK, "threshold": 1},
		&"chain_range": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Voltage Conduction", "desc": "Traverse voltage guide track.", "activation_req": "Traverse guide track.", "reward_desc": "+65 Energy Surge to ball", "energy": 65, "required_widget": CellType.GUIDE_TRACK, "threshold": 1},
		&"max_energize_stacks": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Dual Capacitor", "desc": "Sink ball into capacitor scoop.", "activation_req": "Sink ball into scoop.", "reward_desc": "Board Supercharge (+2 Energize stacks)", "required_widget": CellType.SCOOP_SINKHOLE, "threshold": 1},
		&"energize_decays_slower": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Insulation Flow", "desc": "Traverse insulation guide track.", "activation_req": "Traverse guide track.", "reward_desc": "Board Supercharge (+2 Energize stacks)", "required_widget": CellType.GUIDE_TRACK, "threshold": 1},
		&"energized_pegs_repair_faster": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.BOARD_SUPERCHARGE, "title": "Nanite Network", "desc": "Traverse nanite guide track.", "activation_req": "Traverse guide track.", "reward_desc": "Board Supercharge (+2 Energize stacks)", "required_widget": CellType.GUIDE_TRACK, "threshold": 1},
		&"global_peg_durability": {"type": GoalArchetype.SUPER_JETS, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Armor Bank", "desc": "Hit both armor pop bumpers.", "activation_req": "Hit both pop bumpers.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.POP_BUMPER, "threshold": 2},
		&"peg_recovery_speed": {"type": GoalArchetype.TACTICAL_REBOUND, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Reset Matrix", "desc": "Deflect off slingshot.", "activation_req": "Deflect off slingshot.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.SLINGSHOT, "threshold": 1},
		&"devastating_barrage": {"type": GoalArchetype.TARGET_BANK, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Heavy Barrage", "desc": "Knock down both heavy drop targets.", "activation_req": "Knock down both drop targets.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.DROP_TARGET, "threshold": 2},
		&"compressed_charge": {"type": GoalArchetype.JACKPOT_ACCUMULATOR, "reward": RewardType.ENERGY_SURGE, "title": "Charge Capacitor", "desc": "Ball locks charge, booster collects.", "activation_req": "Charge locks and collect.", "reward_desc": "+100 Energy Surge to ball", "energy": 100},
		&"chest_leech_drain": {"type": GoalArchetype.TACTICAL_REBOUND, "reward": RewardType.ENERGY_SURGE, "title": "Leech Bumper Bank", "desc": "Deflect off drain slingshot.", "activation_req": "Deflect off slingshot.", "reward_desc": "+55 Energy Surge to ball", "energy": 55, "required_widget": CellType.SLINGSHOT, "threshold": 1},
		&"chest_leech_duration": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Leech Conduit", "desc": "Traverse leech guide track.", "activation_req": "Traverse guide track.", "reward_desc": "+55 Energy Surge to ball", "energy": 55, "required_widget": CellType.GUIDE_TRACK, "threshold": 1},
		&"chest_phantom_energy": {"type": GoalArchetype.SEQUENCE_ROUTE, "reward": RewardType.ENERGY_SURGE, "title": "Spectral Bank", "desc": "Traverse spectral guide track.", "activation_req": "Traverse guide track.", "reward_desc": "+55 Energy Surge to ball", "energy": 55, "required_widget": CellType.GUIDE_TRACK, "threshold": 1},
		&"chest_rubbery_energy": {"type": GoalArchetype.SPINNER_RPM, "reward": RewardType.ENERGY_SURGE, "title": "Elastic Combo", "desc": "Rev rubbery spinner to complete 8 revolutions.", "activation_req": "Rev spinner 8 revolutions.", "reward_desc": "+60 Energy Surge to ball", "energy": 60, "required_widget": CellType.SPINNER, "threshold": 8, "target_count": 8},
		&"chest_bounce_energy": {"type": GoalArchetype.SUPER_JETS, "reward": RewardType.ENERGY_SURGE, "title": "Bounce Pair", "desc": "Hit bounce pop bumper.", "activation_req": "Hit pop bumper.", "reward_desc": "+50 Energy Surge to ball", "energy": 50, "required_widget": CellType.POP_BUMPER, "threshold": 1},
		&"chest_split_energy": {"type": GoalArchetype.DIVERTER_SWITCH, "reward": RewardType.MULTIBALL_CASCADE, "title": "Split Chute", "desc": "Trip split diverter gate.", "activation_req": "Trip diverter gate.", "reward_desc": "Multiball Cascade (2 balls)", "balls": 2, "required_widget": CellType.MECHANICAL_DIVERTER, "threshold": 1},
		&"mega_pop_bumper": {"type": GoalArchetype.SUPER_JETS, "reward": RewardType.ENERGY_SURGE, "title": "Mega Bumper Overcharge", "desc": "Hit mega pop bumper 3 times.", "activation_req": "Hit mega pop bumper 3 times.", "reward_desc": "+100 Energy Surge to ball", "energy": 100, "required_widget": CellType.POP_BUMPER, "threshold": 3},
		&"abyssal_maw": {"type": GoalArchetype.SINKHOLE_LOCK, "reward": RewardType.MULTIBALL_CASCADE, "title": "Abyssal Eruption", "desc": "Capture balls in the abyssal maw.", "activation_req": "Sink ball into abyssal maw.", "reward_desc": "Multiball Cascade (3 balls)", "balls": 3, "required_widget": CellType.SCOOP_SINKHOLE, "threshold": 1},
		&"golem_effigy": {"type": GoalArchetype.BASH_DEMOLITION, "reward": RewardType.GLOBAL_BOARD_KNOCK, "title": "Golem Demolition", "desc": "Shatter the golem effigy.", "activation_req": "Strike golem effigy 5 times.", "reward_desc": "Global Board Knock (All pegs hit once)", "required_widget": CellType.BASH_TOY, "threshold": 5},
		&"corner_slingshot": {"type": GoalArchetype.TACTICAL_REBOUND, "reward": RewardType.ENERGY_SURGE, "title": "Corner Rebound", "desc": "Rebound from corner slingshot 2 times.", "activation_req": "Rebound from slingshot 2 times.", "reward_desc": "+75 Energy Surge to ball", "energy": 75, "required_widget": CellType.SLINGSHOT, "threshold": 2},
	}
	return defs.get(_resolve_id(id), {})

static func _def(id: StringName, name: String, tier: int, shape_name: String, machinery_desc: String, cells: Array[Vector2i], types: Dictionary = {}, dirs: Dictionary = {}, energies: Dictionary = {}, enclosure: int = PolyominoModuleData.EnclosureType.OPEN_FRAME, walls: Dictionary = {}, layout_mode: int = PolyominoModuleData.MachineryLayoutMode.PER_CELL, unified_type: int = CellType.EMPTY) -> void:
	_DEFINITIONS[id] = {
		"display_name": name,
		"tier": tier,
		"shape_name": shape_name,
		"machinery_desc": machinery_desc,
		"cells": cells,
		"cell_types": types,
		"cell_directions": dirs,
		"energy_values": energies,
		"bumper_durability": 0,
		"enclosure_type": enclosure,
		"custom_wall_edges": walls,
		"layout_mode": layout_mode,
		"unified_component_type": unified_type
	}

static func _def_multi(id: StringName, name: String, tier: int, shape_name: String, machinery_desc: String, cells: Array[Vector2i], types: Dictionary = {}, dirs: Dictionary = {}, energies: Dictionary = {}, enclosure: int = PolyominoModuleData.EnclosureType.OPEN_FRAME, walls: Dictionary = {}, layout_mode: int = PolyominoModuleData.MachineryLayoutMode.UNIFIED, unified_type: int = CellType.EMPTY) -> void:
	_MULTI_PEG_DEFINITIONS[id] = {
		"display_name": name,
		"tier": tier,
		"shape_name": shape_name,
		"machinery_desc": machinery_desc,
		"cells": cells,
		"cell_types": types,
		"cell_directions": dirs,
		"energy_values": energies,
		"bumper_durability": 0,
		"enclosure_type": enclosure,
		"custom_wall_edges": walls,
		"layout_mode": layout_mode,
		"unified_component_type": unified_type
	}

static func _build_all_definitions() -> void:
	_DEFINITIONS.clear()
	_MULTI_PEG_DEFINITIONS.clear()
	_build_boss_amplifiers()
	_build_wall_break_cross_links()
	_build_single_ball_enhancements()
	_build_treasure_chest_passives()
	_build_multi_peg_machinery()

static func _build_multi_peg_machinery() -> void:
	_def_multi(&"mega_pop_bumper", "Mega Pop Bumper", 2, "2x2 Square Block", "Unified 4-Peg Mega Bumper Core (+20 Energy, 650 Impulse)", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {}, {}, {}, PolyominoModuleData.EnclosureType.OPEN_FRAME, {}, PolyominoModuleData.MachineryLayoutMode.UNIFIED, CellType.POP_BUMPER)
	_def_multi(&"abyssal_maw", "Abyssal Maw", 2, "2x2 Square Well", "Unified 4-Peg Vortex Sinkhole (Multi-Ball Eject Volley)", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {}, {}, {}, PolyominoModuleData.EnclosureType.OPEN_FRAME, {}, PolyominoModuleData.MachineryLayoutMode.UNIFIED, CellType.SCOOP_SINKHOLE)
	_def_multi(&"golem_effigy", "Golem Effigy", 3, "2x2 Boss Statue", "Unified 4-Peg Heavy Bash Toy (8 Hits, 40 Shatter Bonus)", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {}, {}, {}, PolyominoModuleData.EnclosureType.OPEN_FRAME, {}, PolyominoModuleData.MachineryLayoutMode.UNIFIED, CellType.BASH_TOY)
	_def_multi(&"corner_slingshot", "Corner Slingshot", 1, "3-Peg Corner L", "Unified Diagonal Corner Slingshot Kicker", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1)], {}, {}, {}, PolyominoModuleData.EnclosureType.OPEN_FRAME, {}, PolyominoModuleData.MachineryLayoutMode.UNIFIED, CellType.SLINGSHOT)

static func _build_boss_amplifiers() -> void:
	_def(&"cascade_reactor", "Cascade Reactor", 3, "3x3 Solid Block", "4 Corner Boosters + Center Bumper + Rollover Switches", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.ROLLOVER_SWITCH, Vector2i(0,2): CellType.ROLLOVER_SWITCH, Vector2i(2,2): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.POP_BUMPER}, {})
	_def(&"perpetual_engine", "Perpetual Engine", 3, "4x3 Pinball Loop", "Top Ball Lock + Accelerator Ring + Deflector Exit", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.BALL_LOCK, Vector2i(0,1): CellType.ACCELERATOR, Vector2i(3,1): CellType.ACCELERATOR, Vector2i(1,2): CellType.BUMPER, Vector2i(2,2): CellType.DIRECTIONAL_DEFLECTOR}, {Vector2i(1,0): Vector2i.DOWN, Vector2i(0,1): Vector2i.DOWN, Vector2i(3,1): Vector2i.UP, Vector2i(2,2): Vector2i.DOWN}, {}, PolyominoModuleData.EnclosureType.DIRECTIONAL_FUNNEL)
	_def(&"storm_of_fragments", "Storm of Fragments", 3, "3x4 Diamond Chamber", "3 Pop Bumpers + Splitter Core + Spark Deflector", [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(0,3), Vector2i(1,3), Vector2i(2,3)], {Vector2i(1,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(0,1): CellType.POP_BUMPER, Vector2i(2,1): CellType.POP_BUMPER, Vector2i(1,3): CellType.POP_BUMPER}, {Vector2i(1,0): Vector2i.UP})
	_def(&"explosive_contagion", "Explosive Contagion", 3, "4x3 Z-Chamber", "3 Slingshots + 2 Pop Bumpers + 5 Free Corridors", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(0,0): CellType.SLINGSHOT, Vector2i(2,1): CellType.SLINGSHOT, Vector2i(3,2): CellType.SLINGSHOT, Vector2i(1,0): CellType.POP_BUMPER, Vector2i(2,2): CellType.POP_BUMPER}, {})
	_def(&"superconductor", "Superconductor", 3, "4x3 Fortress Chamber", "3 Drop Targets + Dual Spark Rails + 6 Playfield Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2), Vector2i(3,1)], {Vector2i(0,0): CellType.DROP_TARGET, Vector2i(2,0): CellType.DROP_TARGET, Vector2i(3,2): CellType.DROP_TARGET, Vector2i(0,1): CellType.GUIDE_RAIL, Vector2i(1,1): CellType.GUIDE_RAIL}, {}, {}, PolyominoModuleData.EnclosureType.FULL_ENCLOSURE)
	_def(&"rubber_storm", "Rubber Storm", 3, "4x3 Pinball Cluster", "3 Pop Bumpers + 2 Edge Boosters + 7 Bounce Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.POP_BUMPER, Vector2i(3,0): CellType.POP_BUMPER, Vector2i(2,1): CellType.POP_BUMPER, Vector2i(0,2): CellType.ACCELERATOR, Vector2i(3,2): CellType.ACCELERATOR}, {Vector2i(0,2): Vector2i.UP, Vector2i(3,2): Vector2i.UP})
	_def(&"fragment_swarm", "Fragment Swarm", 3, "3x4 Giant Arch", "Scoop Sinkhole + 2 Spark Deflectors + 2 Heavy Bumpers", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1), Vector2i(0,2), Vector2i(2,2), Vector2i(0,3), Vector2i(1,3), Vector2i(2,3), Vector2i(1,2)], {Vector2i(1,0): CellType.SCOOP_SINKHOLE, Vector2i(0,1): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(2,1): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(0,3): CellType.BUMPER, Vector2i(2,3): CellType.BUMPER}, {Vector2i(1,0): Vector2i.DOWN, Vector2i(0,1): Vector2i.LEFT, Vector2i(2,1): Vector2i.RIGHT}, {}, PolyominoModuleData.EnclosureType.DIRECTIONAL_FUNNEL)
	_def(&"overdrive_cascade", "Overdrive Cascade", 3, "4x3 Diamond Rhombus", "Central Orbit Loop + 3 Angled Deflector Plates", [Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(1,1): CellType.ORBIT_LOOP, Vector2i(2,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(0,1): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(2,2): CellType.DIRECTIONAL_DEFLECTOR}, {Vector2i(2,0): Vector2i.UP, Vector2i(0,1): Vector2i.LEFT, Vector2i(2,2): Vector2i.DOWN})
	_def(&"goblin_width_tempest", "Goblin Width Tempest", 3, "3x4 Stepped Chamber", "Vertical Up Kicker + Upward Spring + 2 Corner Bumpers", [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(0,3), Vector2i(1,3), Vector2i(2,3), Vector2i(0,0)], {Vector2i(1,0): CellType.VERTICAL_UP_KICKER, Vector2i(1,1): CellType.FUNNEL, Vector2i(2,1): CellType.FUNNEL, Vector2i(0,3): CellType.BUMPER, Vector2i(2,3): CellType.BUMPER}, {Vector2i(1,0): Vector2i.UP, Vector2i(1,1): Vector2i.DOWN, Vector2i(2,1): Vector2i.LEFT})
	_def(&"blood_tithe", "Blood Tithe", 3, "4x3 Horseshoe Arch", "Central Bash Toy + 3 Pop Bumpers", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.BASH_TOY, Vector2i(0,0): CellType.POP_BUMPER, Vector2i(3,0): CellType.POP_BUMPER, Vector2i(0,2): CellType.POP_BUMPER}, {Vector2i(1,0): Vector2i.DOWN}, {}, PolyominoModuleData.EnclosureType.DIRECTIONAL_FUNNEL)
	_def(&"crown_ricochet", "Crown Ricochet", 3, "4x3 Crown Chamber", "3 Pop Bumpers + 1 Vector Booster + 7 Playfield Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(3,0): CellType.POP_BUMPER, Vector2i(1,1): CellType.POP_BUMPER, Vector2i(2,2): CellType.ROTARY_BOOSTER}, {})
	_def(&"twin_mandate", "Twin Mandate", 3, "4x3 Dual Track", "2 Orbit Loops + 2 Pop Bumpers + 6 Bounce Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2), Vector2i(0,2)], {Vector2i(0,0): CellType.ORBIT_LOOP, Vector2i(3,2): CellType.ORBIT_LOOP, Vector2i(1,0): CellType.POP_BUMPER, Vector2i(2,1): CellType.POP_BUMPER}, {Vector2i(0,0): Vector2i.RIGHT, Vector2i(3,2): Vector2i.LEFT}, {}, PolyominoModuleData.EnclosureType.DIVIDED_LANES)
	_def(&"velocity_dividend", "Velocity Dividend", 3, "3x4 Pinball Vault", "Central Bash Toy + 3 Solenoid Bumpers + 7 Free Travel Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(1,3), Vector2i(2,3)], {Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER, Vector2i(1,2): CellType.BUMPER, Vector2i(1,1): CellType.BASH_TOY}, {})
	_def(&"phase_sovereign", "Phase Sovereign", 3, "4x3 Spectral Tunnel", "1 Mechanical Diverter + 3 Pop Bumpers + 7 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.MECHANICAL_DIVERTER, Vector2i(0,0): CellType.POP_BUMPER, Vector2i(3,0): CellType.POP_BUMPER, Vector2i(1,1): CellType.POP_BUMPER}, {})
	_def(&"resonant_well", "Resonant Well", 3, "4x3 Resonator Ring", "2 Spinners + 2 Pop Bumpers + 8 Travel Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.SPINNER, Vector2i(2,2): CellType.SPINNER, Vector2i(0,1): CellType.POP_BUMPER, Vector2i(3,1): CellType.POP_BUMPER}, {})
	_def(&"renewal_pact", "Renewal Pact", 3, "4x3 Solenoid Field", "3 Slingshots + 2 Pop Bumpers + 5 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(0,0): CellType.SLINGSHOT, Vector2i(3,0): CellType.SLINGSHOT, Vector2i(1,1): CellType.SLINGSHOT, Vector2i(0,2): CellType.POP_BUMPER, Vector2i(3,2): CellType.POP_BUMPER}, {})
	_def(&"gilded_covenant", "Gilded Covenant", 3, "4x3 Vault Chamber", "Central Bash Toy + 2 Vault Bumpers + 1 Top Funnel", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.FUNNEL, Vector2i(0,0): CellType.BUMPER, Vector2i(3,0): CellType.BUMPER, Vector2i(2,2): CellType.BASH_TOY}, {Vector2i(1,0): Vector2i.DOWN})
	_def(&"iron_bloom", "Iron Bloom", 3, "4x3 Solenoid Core", "4 Bash Toy Corner Targets + 2 Deflector Gates + 4 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(0,0): CellType.BASH_TOY, Vector2i(3,0): CellType.BASH_TOY, Vector2i(0,2): CellType.BASH_TOY, Vector2i(3,2): CellType.BASH_TOY, Vector2i(1,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(2,2): CellType.DIRECTIONAL_DEFLECTOR}, {})
	_def(&"echoes_of_wrench", "Echoes of the Wrench", 3, "4x3 T-Beam Frame", "2 Drop Targets + 2 Pop Bumpers + 1 Central Booster", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.DROP_TARGET, Vector2i(3,0): CellType.DROP_TARGET, Vector2i(1,0): CellType.POP_BUMPER, Vector2i(2,2): CellType.POP_BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"stormgrid_coupling", "Stormgrid Coupling", 3, "4x3 Magnetic Cradle", "1 Central Bash Toy + 1 Center Bumper + 2 Guide Tracks", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.BASH_TOY, Vector2i(2,2): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.BUMPER, Vector2i(0,0): CellType.GUIDE_TRACK, Vector2i(0,1): CellType.GUIDE_TRACK}, {})
	_def(&"leech_singularity", "Leech Singularity", 3, "4x3 Arch Siphon", "1 Captive Ball + 3 Pop Bumpers + 6 Open Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.CAPTIVE_BALL, Vector2i(0,0): CellType.POP_BUMPER, Vector2i(3,0): CellType.POP_BUMPER, Vector2i(0,2): CellType.POP_BUMPER}, {})
	_def(&"phantom_resonance", "Phantom Resonance", 3, "4x3 Spectral Loop", "1 Guide Track Core + 3 Pop Bumpers + 2 Rails + 5 Open Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(3,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)], {Vector2i(1,0): CellType.GUIDE_TRACK, Vector2i(0,0): CellType.POP_BUMPER, Vector2i(3,0): CellType.POP_BUMPER, Vector2i(1,1): CellType.POP_BUMPER, Vector2i(0,2): CellType.GUIDE_RAIL, Vector2i(3,2): CellType.GUIDE_RAIL}, {})

static func _build_wall_break_cross_links() -> void:
	_def(&"supernova_peg", "Supernova Peg", 2, "3x3 Box Chamber", "1 Rotary Booster + 2 Drop Targets + 4 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.DROP_TARGET, Vector2i(2,2): CellType.DROP_TARGET}, {})
	_def(&"chain_conduction", "Chain Conduction", 2, "4x2 Rail Frame", "2 Pop Bumpers + 2 Guide Tracks + 3 Corridors", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(2,1), Vector2i(3,1)], {Vector2i(0,0): CellType.GUIDE_TRACK, Vector2i(1,0): CellType.POP_BUMPER, Vector2i(2,0): CellType.POP_BUMPER, Vector2i(3,0): CellType.GUIDE_TRACK}, {})
	_def(&"overcharged_drain", "Overcharged Drain", 2, "3x3 L-Chamber", "1 Scoop Sinkhole + 2 Pop Bumpers + 1 Bumper", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.SCOOP_SINKHOLE, Vector2i(0,1): CellType.POP_BUMPER, Vector2i(0,2): CellType.POP_BUMPER, Vector2i(2,2): CellType.BUMPER}, {})
	_def(&"final_arc_detonation", "Final Arc Detonation", 2, "3x3 V-Chamber", "2 Bumpers + 1 Vertical Up Kicker + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.VERTICAL_UP_KICKER, Vector2i(2,0): CellType.BUMPER}, {})
	_def(&"energy_collapse", "Energy Collapse", 2, "3x3 Z-Chamber", "2 Pop Bumpers + 2 Drop Targets + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(1,0): CellType.POP_BUMPER, Vector2i(1,1): CellType.DROP_TARGET, Vector2i(2,2): CellType.DROP_TARGET}, {})
	_def(&"shrapnel_split", "Shrapnel Split", 2, "3x3 T-Chamber", "2 Mechanical Diverters + 2 Bumpers + 3 Corridors", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.MECHANICAL_DIVERTER, Vector2i(2,0): CellType.MECHANICAL_DIVERTER, Vector2i(1,0): CellType.BUMPER, Vector2i(1,2): CellType.BUMPER}, {Vector2i(0,0): Vector2i.LEFT, Vector2i(2,0): Vector2i.RIGHT})
	_def(&"energized_fragments", "Energized Fragments", 2, "3x3 Skew Chamber", "2 Spinners + 1 Contact Bumper + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)], {Vector2i(0,0): CellType.SPINNER, Vector2i(1,0): CellType.SPINNER, Vector2i(2,2): CellType.BUMPER}, {})
	_def(&"arc_twins", "Arc Twins", 2, "4x2 Dual Rail", "2 Rotary Boosters + 2 Guide Tracks + 3 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(0,1), Vector2i(1,1), Vector2i(3,1)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.GUIDE_TRACK, Vector2i(2,0): CellType.GUIDE_TRACK, Vector2i(3,0): CellType.ROTARY_BOOSTER}, {})
	_def(&"phase_siphon", "Phase Siphon", 2, "3x3 V-Chamber", "2 Pop Bumpers + 1 Rollover Switch + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(1,1): CellType.POP_BUMPER, Vector2i(2,0): CellType.ROLLOVER_SWITCH}, {})
	_def(&"phase_detonation", "Phase Detonation", 2, "3x3 Hook Chamber", "1 Orbit Loop + 1 Rail + 2 Bumpers + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.ORBIT_LOOP, Vector2i(1,0): CellType.GUIDE_RAIL, Vector2i(2,0): CellType.BUMPER, Vector2i(2,2): CellType.BUMPER}, {})
	_def(&"spectral_conduit", "Spectral Conduit", 2, "3x3 Stepped Rail", "2 Guide Rails + 2 Orbit Loops + 3 Travel Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(1,0): CellType.ORBIT_LOOP, Vector2i(1,1): CellType.GUIDE_RAIL, Vector2i(2,2): CellType.ORBIT_LOOP}, {})
	_def(&"impact_burst", "Impact Burst", 2, "3x3 T-Chamber", "3 Pop Bumpers + 1 Rotary Sensor + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.POP_BUMPER, Vector2i(1,2): CellType.POP_BUMPER}, {})
	_def(&"kinetic_charge", "Kinetic Charge", 2, "3x3 Skew Chamber", "1 Spinner + 1 Pop Bumper + 1 Rotary Core + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)], {Vector2i(0,0): CellType.SPINNER, Vector2i(1,0): CellType.POP_BUMPER, Vector2i(2,2): CellType.ROTARY_BOOSTER}, {})
	_def(&"static_bounce", "Static Bounce", 2, "3x3 L-Chamber", "1 Rollover Switch + 2 Pop Bumpers + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2)], {Vector2i(0,0): CellType.ROLLOVER_SWITCH, Vector2i(0,1): CellType.POP_BUMPER, Vector2i(1,2): CellType.POP_BUMPER}, {})
	_def(&"parasitic_arc", "Parasitic Arc", 2, "3x3 V-Chamber", "2 Mechanical Diverters + 1 Pop Bumper", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.MECHANICAL_DIVERTER, Vector2i(1,1): CellType.POP_BUMPER, Vector2i(2,0): CellType.MECHANICAL_DIVERTER}, {Vector2i(0,0): Vector2i.LEFT, Vector2i(2,0): Vector2i.RIGHT})
	_def(&"draining_fragments", "Draining Fragments", 2, "3x3 Skew Chamber", "2 Pop Bumpers + 1 Slingshot + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(1,0): CellType.POP_BUMPER, Vector2i(2,2): CellType.SLINGSHOT}, {})
	_def(&"resonant_bounce", "Resonant Bounce", 2, "3x3 Straight Chamber", "2 Drop Targets + 1 Tuning Core + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], {Vector2i(0,0): CellType.DROP_TARGET, Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.DROP_TARGET}, {})
	_def(&"ricochet_blast", "Ricochet Blast", 2, "3x3 L-Chamber", "1 Rotary Sensor + 3 Drop Targets + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(0,1): CellType.DROP_TARGET, Vector2i(0,2): CellType.DROP_TARGET, Vector2i(2,2): CellType.DROP_TARGET}, {})
	_def(&"blast_launch", "Blast Launch", 2, "3x3 V-Chamber", "2 Deflectors + 1 Vertical Up Kicker + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(1,1): CellType.VERTICAL_UP_KICKER, Vector2i(2,0): CellType.DIRECTIONAL_DEFLECTOR}, {Vector2i(0,0): Vector2i.UP, Vector2i(1,1): Vector2i.UP, Vector2i(2,0): Vector2i.UP})
	_def(&"arc_surge_wrench", "Arc Surge Wrench", 2, "3x3 Straight Chamber", "2 Slingshots + 1 Wire Harness + 3 Travel Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], {Vector2i(0,0): CellType.SLINGSHOT, Vector2i(1,0): CellType.GUIDE_RAIL, Vector2i(2,0): CellType.SLINGSHOT}, {})
	_def(&"goblin_width_pulse", "Goblin Surge Chute", 2, "3x3 Skew Chamber", "1 Rotary Sensor + 2 Scoop Sinkholes + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.SCOOP_SINKHOLE, Vector2i(2,2): CellType.SCOOP_SINKHOLE}, {})
	_def(&"magnet_arc_snare", "Magnet Arc Snare", 2, "3x3 V-Chamber", "2 Ball Locks + 1 Spark Terminal + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(2,2)], {Vector2i(0,0): CellType.BALL_LOCK, Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.BALL_LOCK}, {})
	_def(&"spark_trampoline", "Spark Trampoline", 2, "3x3 Trampoline Chamber", "2 Captive Balls + 1 Charged Spring Plate", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], {Vector2i(0,0): CellType.CAPTIVE_BALL, Vector2i(1,0): CellType.ACCELERATOR, Vector2i(2,0): CellType.CAPTIVE_BALL}, {Vector2i(1,0): Vector2i.UP})

static func _build_single_ball_enhancements() -> void:
	_def(&"hyper_elastic", "Hyper Elastic", 1, "2x3 Vertical Track", "2 Spinners + 3 Free Travel Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.SPINNER, Vector2i(0,2): CellType.SPINNER}, {Vector2i(0,0): Vector2i.UP, Vector2i(0,2): Vector2i.UP})
	_def(&"overdrive_hits", "Overdrive Hits", 1, "2x2 Box Chamber", "1 Pop Bumper + 1 Overdrive Multiplier", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"overclock_network", "Overclock Network", 1, "3x2 V-Mesh", "2 Guide Tracks + 1 Bumper + 2 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(2,1)], {Vector2i(0,0): CellType.GUIDE_TRACK, Vector2i(1,1): CellType.BUMPER, Vector2i(2,0): CellType.GUIDE_TRACK}, {})
	_def(&"spreading_rot", "Spreading Rot", 1, "2x3 L-Shape", "2 Pop Bumpers + 1 Drop Target + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(0,1): CellType.POP_BUMPER, Vector2i(1,2): CellType.DROP_TARGET}, {})
	_def(&"cluster_grenade", "Cluster Grenade", 1, "3x2 Chevron", "3 Pop Bumpers + 2 Travel Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(2,0): CellType.POP_BUMPER, Vector2i(1,0): CellType.POP_BUMPER}, {})
	_def(&"blast_lift", "Blast Lift", 1, "2x3 Vertical Track", "2 Vertical Up Kickers + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.VERTICAL_UP_KICKER, Vector2i(0,2): CellType.VERTICAL_UP_KICKER}, {Vector2i(0,0): Vector2i.UP, Vector2i(0,2): Vector2i.UP})
	_def(&"fragmentation_tag", "Fragmentation Tag", 1, "2x2 Box Chamber", "1 Pop Bumper + 1 Rotary Sensor + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"storm_feedback", "Storm Feedback", 1, "3x2 Horizontal Bar", "1 Slingshot + 1 Bumper + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.SLINGSHOT, Vector2i(2,0): CellType.BUMPER}, {})
	_def(&"overcurrent_surge", "Overcurrent Surge", 1, "2x2 Box Chamber", "1 Rollover Switch + 1 Bumper + 2 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.ROLLOVER_SWITCH, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"fragment_echo", "Fragment Echo", 1, "3x2 Horizontal Bar", "1 Scoop Sinkhole + 1 Top Spawner + 3 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.SCOOP_SINKHOLE, Vector2i(2,0): CellType.ROTARY_BOOSTER}, {})
	_def(&"mass_cascade", "Mass Cascade", 1, "2x2 Box Chamber", "1 Captive Ball + 1 Rotary Sensor + 2 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.CAPTIVE_BALL, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"ghost_trail", "Ghost Trail", 1, "2x3 Vertical Track", "1 Guide Track + 1 Pop Bumper + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.GUIDE_TRACK, Vector2i(0,2): CellType.POP_BUMPER}, {})
	_def(&"phase_instability", "Phase Instability", 1, "3x2 Horizontal Track", "1 Orbit Loop + 1 Rotary Sensor + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.ORBIT_LOOP, Vector2i(2,0): CellType.ROTARY_BOOSTER}, {})
	_def(&"chest_random_ball", "Plunderer's Cut", 1, "2x2 Box Chamber", "1 Captive Ball + 1 Bumper + 2 Open Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.CAPTIVE_BALL, Vector2i(1,1): CellType.BUMPER}, {})
	_def(&"plain_surge", "Plain Surge", 1, "3x2 Horizontal Bar", "1 Mechanical Diverter + 1 Boost Roller", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.MECHANICAL_DIVERTER, Vector2i(2,0): CellType.ACCELERATOR}, {})
	_def(&"plain_horde", "Plain Horde", 1, "2x2 Box Chamber", "1 Pop Bumper + 1 Rotary Sensor + 2 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"plain_momentum", "Plain Momentum", 1, "2x3 Vertical Bar", "1 Orbit Loop + 1 Boost Roller + 3 Open Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.ORBIT_LOOP, Vector2i(0,2): CellType.ACCELERATOR}, {})
	_def(&"volt_primer", "Volt Primer", 1, "3x2 Horizontal Bar", "1 Rollover Switch + 1 Wire Rail + 3 Open Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.ROLLOVER_SWITCH, Vector2i(2,0): CellType.GUIDE_RAIL}, {})

static func _build_treasure_chest_passives() -> void:
	_def(&"explosion_radius", "Bigger Blasts", 1, "2x2 Box Chamber", "1 Slingshot + 1 Pop Bumper + 2 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.SLINGSHOT, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"explosion_peg_hit_count", "More Explosion Hits", 1, "3x2 Horizontal Bar", "1 Ball Lock + 1 Spark Deflector + 3 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.BALL_LOCK, Vector2i(2,0): CellType.DIRECTIONAL_DEFLECTOR}, {Vector2i(2,0): Vector2i.RIGHT})
	_def(&"explosion_impulse", "Stronger Blast Push", 1, "2x3 Vertical Bar", "1 Vertical Up Kicker + 1 Pop Bumper + 3 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.VERTICAL_UP_KICKER, Vector2i(0,2): CellType.BUMPER}, {Vector2i(0,0): Vector2i.UP})
	_def(&"chain_arc", "+1 Chain Jump", 1, "2x2 Box Chamber", "1 Guide Track + 1 Guide Rail + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.GUIDE_TRACK, Vector2i(1,1): CellType.GUIDE_RAIL}, {})
	_def(&"chain_range", "Longer Chains", 1, "3x2 Horizontal Bar", "1 Guide Track + 1 Rotary Core + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.GUIDE_TRACK, Vector2i(2,0): CellType.ROTARY_BOOSTER}, {})
	_def(&"max_energize_stacks", "Deeper Energize", 1, "2x2 Box Chamber", "1 Scoop Sinkhole + 1 Pop Bumper + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.SCOOP_SINKHOLE, Vector2i(1,1): CellType.POP_BUMPER}, {})
	_def(&"energize_decays_slower", "Slower Energize Fade", 1, "2x3 Vertical Bar", "1 Guide Track + 1 Pop Bumper + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.GUIDE_TRACK, Vector2i(0,2): CellType.POP_BUMPER}, {})
	_def(&"energized_pegs_repair_faster", "Fast Heal (Energized)", 1, "2x2 Box Chamber", "1 Guide Track + 1 Pop Bumper + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.GUIDE_TRACK, Vector2i(1,1): CellType.POP_BUMPER}, {})
	_def(&"global_peg_durability", "Tough Pegs", 1, "3x2 Chevron", "2 Pop Bumpers + 3 Free Travel Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(2,0): CellType.POP_BUMPER}, {})
	_def(&"peg_recovery_speed", "Faster Peg Recovery", 1, "3x2 Chevron", "2 Slingshots + 1 Spring Roller + 2 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.SLINGSHOT, Vector2i(2,0): CellType.SLINGSHOT, Vector2i(1,0): CellType.ACCELERATOR}, {})
	_def(&"devastating_barrage", "Devastating Barrage", 1, "2x3 L-Chamber", "2 Drop Targets + 1 Rotary Core + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)], {Vector2i(0,0): CellType.DROP_TARGET, Vector2i(0,1): CellType.ROTARY_BOOSTER, Vector2i(1,2): CellType.DROP_TARGET}, {})
	_def(&"compressed_charge", "Compressed Charge", 1, "2x3 L-Chamber", "2 Ball Locks + 1 Rotary Booster + 2 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)], {Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(0,1): CellType.BALL_LOCK, Vector2i(1,2): CellType.BALL_LOCK}, {})
	_def(&"chest_leech_drain", "Leech Drain Up", 1, "2x2 Box Chamber", "1 Slingshot + 1 Pop Bumper + 2 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(1,1): CellType.SLINGSHOT}, {})
	_def(&"chest_leech_duration", "Longer Leech", 1, "2x3 Vertical Bar", "1 Pop Bumper + 1 Guide Track + 3 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(0,2): CellType.GUIDE_TRACK}, {})
	_def(&"chest_phantom_energy", "Phantom Energy", 1, "2x2 Box Chamber", "1 Pop Bumper + 1 Guide Track + 2 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(1,1): CellType.GUIDE_TRACK}, {})
	_def(&"chest_rubbery_energy", "Rubbery Energy", 1, "3x2 Horizontal Bar", "1 Spinner + 1 Boost Roller + 3 Free Cells", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)], {Vector2i(0,0): CellType.SPINNER, Vector2i(2,0): CellType.ACCELERATOR}, {})
	_def(&"chest_bounce_energy", "Plain Energy", 1, "2x2 Box Chamber", "1 Pop Bumper + 1 Rotary Sensor + 2 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], {Vector2i(0,0): CellType.POP_BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER}, {})
	_def(&"chest_split_energy", "Split Energy", 1, "2x3 Vertical Bar", "1 Mechanical Diverter + 1 Boost Roller + 3 Free Spaces", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], {Vector2i(0,0): CellType.MECHANICAL_DIVERTER, Vector2i(0,2): CellType.ACCELERATOR}, {Vector2i(0,0): Vector2i.DOWN, Vector2i(0,2): Vector2i.DOWN})

