@tool
extends RefCounted
class_name PolyominoRelicDatabase
## Canonical data registry and factory for all polyomino relic items in Campaign 1 (TASK-024).

const PolyominoModuleData = preload("res://resources/polyomino/polyomino_module_data.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")

const CellType = PolyominoModuleData.CellType

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
		"machinery_desc": get_relic_kinetic_description(relic_id)
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
	# Tier 3 (5 to 9 Cells — 3×3 Bounding Box)
	_def(&"cascade_reactor", "Cascade Reactor", 3, "3x3 Solid Block", "4 Corner Tesla Coils + Central Energy Siphon + 4 Bounce Rails",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.ROTARY_BOOSTER, Vector2i(0,2): CellType.ROTARY_BOOSTER, Vector2i(2,2): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.MANA_SIPHON, Vector2i(1,0): CellType.BUMPER, Vector2i(0,1): CellType.BUMPER, Vector2i(2,1): CellType.BUMPER, Vector2i(1,2): CellType.BUMPER})

	_def(&"perpetual_engine", "Perpetual Engine", 3, "3x3 Hollow Ring", "Top Catch Chute + Circular Boost Ring + Bottom Emitter",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)],
		{Vector2i(1,0): CellType.FUNNEL, Vector2i(0,0): CellType.ACCELERATOR, Vector2i(2,0): CellType.ACCELERATOR, Vector2i(0,1): CellType.ACCELERATOR, Vector2i(2,1): CellType.ACCELERATOR, Vector2i(0,2): CellType.ACCELERATOR, Vector2i(2,2): CellType.ACCELERATOR, Vector2i(1,2): CellType.DIRECTIONAL_DEFLECTOR},
		{Vector2i(1,0): Vector2i.DOWN, Vector2i(0,0): Vector2i.DOWN, Vector2i(2,0): Vector2i.DOWN, Vector2i(0,1): Vector2i.DOWN, Vector2i(2,1): Vector2i.UP, Vector2i(0,2): Vector2i.RIGHT, Vector2i(2,2): Vector2i.LEFT, Vector2i(1,2): Vector2i.DOWN})

	_def(&"storm_of_fragments", "Storm of Fragments", 3, "3x3 5-Cell Cross", "Central Splitter Core + 4 Spark Deflector Nodes",
		[Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(1,2)],
		{Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(0,1): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(2,1): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(1,2): CellType.DIRECTIONAL_DEFLECTOR},
		{Vector2i(1,0): Vector2i.UP, Vector2i(0,1): Vector2i.LEFT, Vector2i(2,1): Vector2i.RIGHT, Vector2i(1,2): Vector2i.DOWN})

	_def(&"explosive_contagion", "Explosive Contagion", 3, "3x3 Giant Z-Ramp", "3 Concussive Vents + 3 Spore Dispersal Chambers",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1), Vector2i(1,2), Vector2i(2,2)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.BUMPER, Vector2i(2,2): CellType.BUMPER, Vector2i(1,0): CellType.MANA_SIPHON, Vector2i(2,1): CellType.MANA_SIPHON, Vector2i(1,2): CellType.MANA_SIPHON})

	_def(&"superconductor", "Superconductor", 3, "3x3 Corner Fortress", "Dual Spark Rails + 2 Corner Pinball Bumpers",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER, Vector2i(0,2): CellType.BUMPER, Vector2i(1,0): CellType.GUIDE_RAIL, Vector2i(0,1): CellType.GUIDE_RAIL, Vector2i(1,1): CellType.ACCELERATOR, Vector2i(1,2): CellType.ACCELERATOR})

	_def(&"rubber_storm", "Rubber Storm", 3, "3x3 Pinball Chamber", "4 Corner High-Tension Bumpers + 4 Edge Accelerator Rollers",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER, Vector2i(0,2): CellType.BUMPER, Vector2i(2,2): CellType.BUMPER, Vector2i(1,0): CellType.ACCELERATOR, Vector2i(0,1): CellType.ACCELERATOR, Vector2i(2,1): CellType.ACCELERATOR, Vector2i(1,2): CellType.ACCELERATOR})

	_def(&"fragment_swarm", "Fragment Swarm", 3, "3x3 Giant Archway", "Top Ball Catch Funnel + 3 Fragment Diverter Chutes",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1), Vector2i(0,2), Vector2i(2,2)],
		{Vector2i(1,0): CellType.FUNNEL, Vector2i(0,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(2,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(0,1): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(2,1): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(0,2): CellType.BUMPER, Vector2i(2,2): CellType.BUMPER},
		{Vector2i(1,0): Vector2i.DOWN, Vector2i(0,0): Vector2i.LEFT, Vector2i(2,0): Vector2i.RIGHT, Vector2i(0,1): Vector2i.LEFT, Vector2i(2,1): Vector2i.RIGHT})

	_def(&"overdrive_cascade", "Overdrive Cascade", 3, "3x3 Diamond Rhombus", "Central Overdrive Sensor + 4 Angled Deflector Plates",
		[Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(1,2)],
		{Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(0,1): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(2,1): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(1,2): CellType.DIRECTIONAL_DEFLECTOR},
		{Vector2i(1,0): Vector2i.UP, Vector2i(0,1): Vector2i.LEFT, Vector2i(2,1): Vector2i.RIGHT, Vector2i(1,2): Vector2i.DOWN})

	_def(&"goblin_width_tempest", "Goblin Width Tempest", 3, "3x3 Stepped Pyramid", "Wide Return Funnel + Upward Launch Spring",
		[Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(2,2)],
		{Vector2i(1,0): CellType.ACCELERATOR, Vector2i(1,1): CellType.FUNNEL, Vector2i(0,1): CellType.FUNNEL, Vector2i(2,1): CellType.FUNNEL, Vector2i(0,2): CellType.BUMPER, Vector2i(2,2): CellType.BUMPER},
		{Vector2i(1,0): Vector2i.UP, Vector2i(1,1): Vector2i.DOWN, Vector2i(0,1): Vector2i.RIGHT, Vector2i(2,1): Vector2i.LEFT})

	_def(&"blood_tithe", "Blood Tithe", 3, "3x3 Horseshoe Arch", "Dual High-Volume Drain Siphons + Catch Gate",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)],
		{Vector2i(1,0): CellType.FUNNEL, Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(2,0): CellType.MANA_SIPHON, Vector2i(0,1): CellType.MANA_SIPHON, Vector2i(2,1): CellType.MANA_SIPHON})

	_def(&"crown_ricochet", "Crown Ricochet", 3, "3x3 Corner Fortress", "2 Heavy Pinball Bumpers + 1 Vector Boost Ramp",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER, Vector2i(0,2): CellType.BUMPER, Vector2i(1,0): CellType.ACCELERATOR, Vector2i(0,1): CellType.ACCELERATOR, Vector2i(1,1): CellType.ROTARY_BOOSTER})

	_def(&"twin_mandate", "Twin Mandate", 3, "3x3 Diagonal Bar", "3 Fragment Speed Rollers + 2 Energy Siphons",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)],
		{Vector2i(0,0): CellType.ACCELERATOR, Vector2i(1,1): CellType.ACCELERATOR, Vector2i(2,2): CellType.ACCELERATOR, Vector2i(1,0): CellType.MANA_SIPHON, Vector2i(2,1): CellType.MANA_SIPHON})

	_def(&"velocity_dividend", "Velocity Dividend", 3, "3x3 Plus Core", "High-Speed Impact Gate + 4 Shock Absorbers",
		[Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(1,2)],
		{Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.BUMPER, Vector2i(0,1): CellType.BUMPER, Vector2i(2,1): CellType.BUMPER, Vector2i(1,2): CellType.BUMPER})

	_def(&"phase_sovereign", "Phase Sovereign", 3, "3x3 Spectral Tunnel", "Permeable Siphon Rails + Ghost Sensor",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1), Vector2i(0,2), Vector2i(2,2)],
		{Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(2,0): CellType.MANA_SIPHON, Vector2i(0,1): CellType.MANA_SIPHON, Vector2i(2,1): CellType.MANA_SIPHON, Vector2i(0,2): CellType.GUIDE_RAIL, Vector2i(2,2): CellType.GUIDE_RAIL})

	_def(&"resonant_well", "Resonant Well", 3, "3x3 Hollow Ring", "Resonator Ring + Energize Amplifiers",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)],
		{Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.GUIDE_RAIL, Vector2i(0,1): CellType.MANA_SIPHON, Vector2i(2,1): CellType.MANA_SIPHON, Vector2i(0,2): CellType.GUIDE_RAIL, Vector2i(1,2): CellType.ROTARY_BOOSTER, Vector2i(2,2): CellType.GUIDE_RAIL})

	_def(&"renewal_pact", "Renewal Pact", 3, "3x3 Stepped Chevron", "3 Pulse Solenoids + 2 Repair Nodes",
		[Vector2i(0,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(0,1): CellType.MANA_SIPHON, Vector2i(2,1): CellType.MANA_SIPHON})

	_def(&"gilded_covenant", "Gilded Covenant", 3, "3x3 Vault Gate", "Gold Coin Vacuum + 2 Vault Bumpers",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1), Vector2i(1,2)],
		{Vector2i(1,0): CellType.FUNNEL, Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER, Vector2i(0,1): CellType.GUIDE_RAIL, Vector2i(2,1): CellType.GUIDE_RAIL, Vector2i(1,2): CellType.ROTARY_BOOSTER},
		{Vector2i(1,0): Vector2i.DOWN})

	_def(&"iron_bloom", "Iron Bloom", 3, "3x3 Giant Solenoid", "Dual Magnetic Core Wheels + Field Emitter",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.ROTARY_BOOSTER, Vector2i(0,2): CellType.ROTARY_BOOSTER, Vector2i(2,2): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(1,2): CellType.DIRECTIONAL_DEFLECTOR})

	_def(&"echoes_of_wrench", "Echoes of the Wrench", 3, "3x3 T-Beam", "Repair Capacitor Array + 2 Shock Plates",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(1,2)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER, Vector2i(1,0): CellType.MANA_SIPHON, Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(1,2): CellType.MANA_SIPHON})

	_def(&"stormgrid_coupling", "Stormgrid Coupling", 3, "3x3 Corner Cradle", "Magnetic Stabilizer Track + Arc Terminal",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2)],
		{Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(0,1): CellType.GUIDE_RAIL, Vector2i(0,2): CellType.GUIDE_RAIL, Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.BUMPER, Vector2i(1,2): CellType.ROTARY_BOOSTER})

	_def(&"leech_singularity", "Leech Singularity", 3, "3x3 Horseshoe Arch", "Dual High-Volume Drain Siphons + Energize Well",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1)],
		{Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(2,0): CellType.MANA_SIPHON, Vector2i(0,1): CellType.MANA_SIPHON, Vector2i(2,1): CellType.MANA_SIPHON})

	_def(&"phantom_resonance", "Phantom Resonance", 3, "3x3 Spectral Tunnel", "Permeable Siphon Rails + Tesla Arc Resonator",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(2,1), Vector2i(0,2), Vector2i(2,2)],
		{Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(2,0): CellType.MANA_SIPHON, Vector2i(0,1): CellType.MANA_SIPHON, Vector2i(2,1): CellType.MANA_SIPHON, Vector2i(0,2): CellType.GUIDE_RAIL, Vector2i(2,2): CellType.GUIDE_RAIL})

static func _build_wall_break_cross_links() -> void:
	# Tier 2: Synergy Modules & Cross-Links (3 to 5 Cells)
	_def(&"supernova_peg", "Supernova Peg", 2, "2x2 Box", "Central Embedded Bomb Core + 4 Spark Pins",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.BUMPER, Vector2i(0,1): CellType.BUMPER, Vector2i(1,1): CellType.BUMPER})

	_def(&"chain_conduction", "Chain Conduction", 2, "4x1 Straight Rail", "Linear Lightning Rail + 4 Contact Pins",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)],
		{Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(1,0): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER, Vector2i(3,0): CellType.GUIDE_RAIL})

	_def(&"overcharged_drain", "Overcharged Drain", 2, "4-Cell L-Shape", "2 Leech Siphons + 1 Overcharge Bumper + 1 Funnel",
		[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)],
		{Vector2i(0,0): CellType.FUNNEL, Vector2i(0,1): CellType.MANA_SIPHON, Vector2i(0,2): CellType.MANA_SIPHON, Vector2i(1,2): CellType.BUMPER})

	_def(&"final_arc_detonation", "Final Arc Detonation", 2, "3-Cell V-Chevron", "Spark Sensor + Angled Blast Cap",
		[Vector2i(0,0), Vector2i(1,1), Vector2i(2,0)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.BUMPER})

	_def(&"energy_collapse", "Energy Collapse", 2, "4-Cell Z-Shape", "Volatile Drain Siphon + Concussive Spring",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)],
		{Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(1,0): CellType.MANA_SIPHON, Vector2i(1,1): CellType.BUMPER, Vector2i(2,1): CellType.BUMPER})

	_def(&"shrapnel_split", "Shrapnel Split", 2, "4-Cell T-Shape", "Fragment Deflector + Bomb Trigger Plate",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(2,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(1,0): CellType.BUMPER, Vector2i(1,1): CellType.BUMPER},
		{Vector2i(0,0): Vector2i.LEFT, Vector2i(2,0): Vector2i.RIGHT})

	_def(&"energized_fragments", "Energized Fragments", 2, "3-Cell Skew Rhombus", "Dual Energize Rollers + Contact Plate",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.ACCELERATOR, Vector2i(1,0): CellType.ACCELERATOR, Vector2i(1,1): CellType.BUMPER})

	_def(&"arc_twins", "Arc Twins", 2, "4x1 Gap Rail", "Dual Spark Terminals + Open Center Gap",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.GUIDE_RAIL, Vector2i(2,0): CellType.GUIDE_RAIL, Vector2i(3,0): CellType.ROTARY_BOOSTER})

	_def(&"phase_siphon", "Phase Siphon", 2, "3-Cell V-Chevron", "Permeable Siphon Core + Energy Drain Plate",
		[Vector2i(0,0), Vector2i(1,1), Vector2i(2,0)],
		{Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(1,1): CellType.MANA_SIPHON, Vector2i(2,0): CellType.BUMPER})

	_def(&"phase_detonation", "Phase Detonation", 2, "4-Cell Hook", "Phantom Detection Gate + Blast Chamber",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(2,1)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.GUIDE_RAIL, Vector2i(2,0): CellType.BUMPER, Vector2i(2,1): CellType.BUMPER})

	_def(&"spectral_conduit", "Spectral Conduit", 2, "4-Cell Stepped Diagonal", "Spectral Trail Rail + Spark Guide",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)],
		{Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(1,0): CellType.ACCELERATOR, Vector2i(1,1): CellType.GUIDE_RAIL, Vector2i(2,1): CellType.ACCELERATOR})

	_def(&"impact_burst", "Impact Burst", 2, "4-Cell T-Shape", "Heavy Kinetic Bumper + Impact Sensor",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.BUMPER, Vector2i(1,1): CellType.BUMPER})

	_def(&"kinetic_charge", "Kinetic Charge", 2, "3-Cell Skew Rhombus", "Speed Boost Wheel + Energize Battery",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.ACCELERATOR, Vector2i(1,0): CellType.MANA_SIPHON, Vector2i(1,1): CellType.ROTARY_BOOSTER})

	_def(&"static_bounce", "Static Bounce", 2, "3-Cell L-Tromino", "Overdrive Sensor + Tesla Spark Node",
		[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(0,1): CellType.BUMPER, Vector2i(1,1): CellType.BUMPER})

	_def(&"parasitic_arc", "Parasitic Arc", 2, "3-Cell V-Chevron", "Arc Spreader + Drain Mist Nozzle",
		[Vector2i(0,0), Vector2i(1,1), Vector2i(2,0)],
		{Vector2i(0,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(1,1): CellType.MANA_SIPHON, Vector2i(2,0): CellType.DIRECTIONAL_DEFLECTOR},
		{Vector2i(0,0): Vector2i.LEFT, Vector2i(2,0): Vector2i.RIGHT})

	_def(&"draining_fragments", "Draining Fragments", 2, "3-Cell Skew Rhombus", "Fragment Siphon Needle Array",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(1,0): CellType.MANA_SIPHON, Vector2i(1,1): CellType.BUMPER})

	_def(&"resonant_bounce", "Resonant Bounce", 2, "3-Cell Straight Bar", "Resonance Tuning Plate",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,0): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.BUMPER})

	_def(&"ricochet_blast", "Ricochet Blast", 2, "4-Cell L-Shape", "Overdrive Sensor + Concussive Bumper",
		[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(0,1): CellType.BUMPER, Vector2i(0,2): CellType.BUMPER, Vector2i(1,2): CellType.BUMPER})

	_def(&"blast_launch", "Blast Launch", 2, "3-Cell V-Chevron", "Blast Deflector + Upward Spring Ramp",
		[Vector2i(0,0), Vector2i(1,1), Vector2i(2,0)],
		{Vector2i(0,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(1,1): CellType.ACCELERATOR, Vector2i(2,0): CellType.DIRECTIONAL_DEFLECTOR},
		{Vector2i(0,0): Vector2i.UP, Vector2i(1,1): Vector2i.UP, Vector2i(2,0): Vector2i.UP})

	_def(&"arc_surge_wrench", "Arc Surge Wrench", 2, "3-Cell Straight Bar", "Repair Pulse Solenoid + Wire Harness",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.GUIDE_RAIL, Vector2i(2,0): CellType.ROTARY_BOOSTER})

	_def(&"goblin_width_pulse", "Goblin Surge Chute", 2, "3-Cell Skew Rhombus", "Ball Return Sensor + Chute Expander",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.FUNNEL, Vector2i(1,1): CellType.FUNNEL})

	_def(&"magnet_arc_snare", "Magnet Arc Snare", 2, "3-Cell V-Chevron", "Magnetic Snare Coil + Spark Terminal",
		[Vector2i(0,0), Vector2i(1,1), Vector2i(2,0)],
		{Vector2i(0,0): CellType.FUNNEL, Vector2i(1,1): CellType.ROTARY_BOOSTER, Vector2i(2,0): CellType.FUNNEL})

	_def(&"spark_trampoline", "Spark Trampoline", 2, "3-Cell Straight Bar", "Charged Spring Plate + Grounding Wire",
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,0): CellType.ACCELERATOR, Vector2i(2,0): CellType.BUMPER},
		{Vector2i(1,0): Vector2i.UP})

static func _build_single_ball_enhancements() -> void:
	# Tier 1 (2 to 3 Cells)
	_def(&"hyper_elastic", "Hyper Elastic", 1, "1x2 Vertical Bar", "Upward Boost Accelerator Track",
		[Vector2i(0,0), Vector2i(0,1)],
		{Vector2i(0,0): CellType.ACCELERATOR, Vector2i(0,1): CellType.ACCELERATOR},
		{Vector2i(0,0): Vector2i.UP, Vector2i(0,1): Vector2i.UP})

	_def(&"overdrive_hits", "Overdrive Hits", 1, "2-Cell Diagonal Skew", "Overdrive Multiplier Gate",
		[Vector2i(0,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER})

	_def(&"overclock_network", "Overclock Network", 1, "3-Cell V-Chevron", "Grid Resonance Mesh",
		[Vector2i(0,0), Vector2i(1,1), Vector2i(2,0)],
		{Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(1,1): CellType.BUMPER, Vector2i(2,0): CellType.GUIDE_RAIL})

	_def(&"spreading_rot", "Spreading Rot", 1, "3-Cell L-Tromino", "Spore Dispenser + Rot Siphon",
		[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)],
		{Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(0,1): CellType.MANA_SIPHON, Vector2i(1,1): CellType.BUMPER})

	_def(&"cluster_grenade", "Cluster Grenade", 1, "3-Cell V-Chevron", "Sub-Munition Dispenser",
		[Vector2i(0,0), Vector2i(1,1), Vector2i(2,0)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER})

	_def(&"blast_lift", "Blast Lift", 1, "1x2 Vertical Bar", "Upward Concussion Chute",
		[Vector2i(0,0), Vector2i(0,1)],
		{Vector2i(0,0): CellType.ACCELERATOR, Vector2i(0,1): CellType.ACCELERATOR},
		{Vector2i(0,0): Vector2i.UP, Vector2i(0,1): Vector2i.UP})

	_def(&"fragmentation_tag", "Fragmentation Tag", 1, "2-Cell Diagonal Skew", "Blast Impact Sensor Core",
		[Vector2i(0,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER})

	_def(&"storm_feedback", "Storm Feedback", 1, "1x2 Horizontal Bar", "Energy Feedback Solenoid",
		[Vector2i(0,0), Vector2i(1,0)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.BUMPER})

	_def(&"overcurrent_surge", "Overcurrent Surge", 1, "2-Cell Diagonal Skew", "Rapid Discharge Resistor",
		[Vector2i(0,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER})

	_def(&"fragment_echo", "Fragment Echo", 1, "1x2 Horizontal Bar", "Exit Funnel + Top Spawner Link",
		[Vector2i(0,0), Vector2i(1,0)],
		{Vector2i(0,0): CellType.FUNNEL, Vector2i(1,0): CellType.ROTARY_BOOSTER})

	_def(&"mass_cascade", "Mass Cascade", 1, "2-Cell Diagonal Skew", "Fragment Collision Plate",
		[Vector2i(0,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER})

	_def(&"ghost_trail", "Ghost Trail", 1, "1x2 Vertical Bar", "Permeable Trail Emitter",
		[Vector2i(0,0), Vector2i(0,1)],
		{Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(0,1): CellType.MANA_SIPHON})

	_def(&"phase_instability", "Phase Instability", 1, "1x2 Horizontal Bar", "Zero-Hit Siphon Return Track",
		[Vector2i(0,0), Vector2i(1,0)],
		{Vector2i(0,0): CellType.ACCELERATOR, Vector2i(1,0): CellType.ROTARY_BOOSTER})

	_def(&"chest_random_ball", "Plunderer's Cut", 1, "2-Cell Diagonal Skew", "Locked Scrap Vault",
		[Vector2i(0,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.BUMPER})

	_def(&"plain_surge", "Plain Surge", 1, "1x2 Horizontal Bar", "Plain Kinetic Bumper Array",
		[Vector2i(0,0), Vector2i(1,0)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,0): CellType.ACCELERATOR})

	_def(&"plain_horde", "Plain Horde", 1, "2-Cell Diagonal Skew", "Horde Sensor Core",
		[Vector2i(0,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER})

	_def(&"plain_momentum", "Plain Momentum", 1, "1x2 Vertical Bar", "Overdrive Kinetic Plate",
		[Vector2i(0,0), Vector2i(0,1)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(0,1): CellType.ACCELERATOR})

	_def(&"volt_primer", "Volt Primer", 1, "1x2 Horizontal Bar", "Cannon Discount Capacitor",
		[Vector2i(0,0), Vector2i(1,0)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,0): CellType.GUIDE_RAIL})

static func _build_treasure_chest_passives() -> void:
	# Tier 1 (2 to 3 Cells)
	_def(&"explosion_radius", "Bigger Blasts", 1, "2-Cell Diagonal Skew", "Blast Expansion Chamber",
		[Vector2i(0,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER})

	_def(&"explosion_peg_hit_count", "More Explosion Hits", 1, "1x2 Horizontal Bar", "Shrapnel Dispersion Tube",
		[Vector2i(0,0), Vector2i(1,0)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,0): CellType.DIRECTIONAL_DEFLECTOR},
		{Vector2i(1,0): Vector2i.RIGHT})

	_def(&"explosion_impulse", "Stronger Blast Push", 1, "1x2 Vertical Bar", "Concussion Wave Baffle",
		[Vector2i(0,0), Vector2i(0,1)],
		{Vector2i(0,0): CellType.ACCELERATOR, Vector2i(0,1): CellType.BUMPER},
		{Vector2i(0,0): Vector2i.UP})

	_def(&"chain_arc", "+1 Chain Jump", 1, "2-Cell Diagonal Skew", "Arc Extender Node",
		[Vector2i(0,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.GUIDE_RAIL})

	_def(&"chain_range", "Longer Chains", 1, "1x2 Horizontal Bar", "High-Voltage Spark Rail",
		[Vector2i(0,0), Vector2i(1,0)],
		{Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(1,0): CellType.ROTARY_BOOSTER})

	_def(&"max_energize_stacks", "Deeper Energize", 1, "2-Cell Diagonal Skew", "Dual Capacitor Cell",
		[Vector2i(0,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.MANA_SIPHON})

	_def(&"energize_decays_slower", "Slower Energize Fade", 1, "1x2 Vertical Bar", "Insulation Mesh Core",
		[Vector2i(0,0), Vector2i(0,1)],
		{Vector2i(0,0): CellType.GUIDE_RAIL, Vector2i(0,1): CellType.MANA_SIPHON})

	_def(&"energized_pegs_repair_faster", "Fast Heal (Energized)", 1, "2-Cell Diagonal Skew", "Nanite Dispenser Tube",
		[Vector2i(0,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.MANA_SIPHON})

	_def(&"global_peg_durability", "Tough Pegs", 1, "3-Cell V-Chevron", "Armor Plating Bracket",
		[Vector2i(0,0), Vector2i(1,1), Vector2i(2,0)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.BUMPER, Vector2i(2,0): CellType.BUMPER})

	_def(&"peg_recovery_speed", "Faster Peg Recovery", 1, "3-Cell V-Chevron", "Rapid Reset Spring Frame",
		[Vector2i(0,0), Vector2i(1,1), Vector2i(2,0)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ACCELERATOR, Vector2i(2,0): CellType.BUMPER})

	_def(&"devastating_barrage", "Devastating Barrage", 1, "3-Cell L-Tromino", "Heavy Shell Breech + Ammo Track",
		[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(0,1): CellType.ROTARY_BOOSTER, Vector2i(1,1): CellType.BUMPER})

	_def(&"compressed_charge", "Compressed Charge", 1, "3-Cell L-Tromino", "High-Density Capacitor Bank",
		[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)],
		{Vector2i(0,0): CellType.ROTARY_BOOSTER, Vector2i(0,1): CellType.MANA_SIPHON, Vector2i(1,1): CellType.ROTARY_BOOSTER})

	_def(&"chest_leech_drain", "Leech Drain Up", 1, "2-Cell Diagonal Skew", "Micro Drain Siphon Rail",
		[Vector2i(0,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(1,1): CellType.BUMPER})

	_def(&"chest_leech_duration", "Longer Leech", 1, "1x2 Vertical Bar", "Leech Sustainer Capsule",
		[Vector2i(0,0), Vector2i(0,1)],
		{Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(0,1): CellType.GUIDE_RAIL})

	_def(&"chest_phantom_energy", "Phantom Energy", 1, "2-Cell Diagonal Skew", "Spectral Permeability Siphon",
		[Vector2i(0,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.MANA_SIPHON, Vector2i(1,1): CellType.GUIDE_RAIL})

	_def(&"chest_rubbery_energy", "Rubbery Energy", 1, "1x2 Horizontal Bar", "Elastic Impact Siphon",
		[Vector2i(0,0), Vector2i(1,0)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,0): CellType.ACCELERATOR})

	_def(&"chest_bounce_energy", "Plain Energy", 1, "2-Cell Diagonal Skew", "Standard Impact Siphon",
		[Vector2i(0,0), Vector2i(1,1)],
		{Vector2i(0,0): CellType.BUMPER, Vector2i(1,1): CellType.ROTARY_BOOSTER})

	_def(&"chest_split_energy", "Split Energy", 1, "1x2 Vertical Bar", "Fragment Impact Siphon",
		[Vector2i(0,0), Vector2i(0,1)],
		{Vector2i(0,0): CellType.DIRECTIONAL_DEFLECTOR, Vector2i(0,1): CellType.ACCELERATOR},
		{Vector2i(0,0): Vector2i.DOWN, Vector2i(0,1): Vector2i.DOWN})
