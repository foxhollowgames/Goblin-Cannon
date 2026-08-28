extends Node
## RewardHandler (§6.10). Milestones, wall-break synergies, treasure-chest onboard passives, boss amplifiers.

## Relative weight for major/boss picks when required ball types are not in the run (vs 1.0 when satisfied).
const MAJOR_UPGRADE_UNOWNED_BALL_WEIGHT: float = 0.05

var _reward_gen: RewardGeneration
var _hopper: Node
var _game_coordinator: Node
var _ball_candidates: Array = []
var _ball_enhancement_candidates: Array = []
var _cross_link_candidates: Array = []
var _board_candidates: Array = []
## Treasure chest / onboard: passive tag upgrades and global peg scaling (no synergy gates).
var _onboard_effect_candidates: Array = []
var _boss_candidates: Array = []
var _peg_shop_candidates: Array = []
var _pending_peg_selection_kind: String = ""

func _ready() -> void:
	_reward_gen = RewardGeneration.new(GameState.run_seed)
	var main: Node = get_parent()
	_hopper = main.get_node_or_null("Hopper")
	_game_coordinator = main.get_node_or_null("GameCoordinator")
	_ball_candidates = _build_ball_candidates()
	_build_peg_shop_candidates()
	_build_wall_break_candidates()
	_build_onboard_effect_candidates()
	_build_boss_candidates()

func _build_ball_candidates() -> Array:
	var list: Array = []
	var M: int = Constants.ALIGNMENT_MAIN
	var t1: Array = [
		_create_ball_def("Split", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.HEXAGON),
		_create_ball_def("Energize", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.PENTAGON),
		_create_ball_def("Explosive", M, 1, Constants.RARITY_LEGENDARY, {0: 100}, BallVisuals.ShapeType.SQUARE),
		_create_ball_def("Chain Lightning", M, 1, Constants.RARITY_LEGENDARY, {0: 100}, BallVisuals.ShapeType.STAR),
		_create_ball_def("Constellation", M, 1, Constants.RARITY_LEGENDARY, {0: 100}, BallVisuals.ShapeType.PLUS),
		_create_ball_def("Binary", M, 1, Constants.RARITY_LEGENDARY, {0: 100}, BallVisuals.ShapeType.TRIANGLE),
		_create_ball_def("Bloom", M, 1, Constants.RARITY_LEGENDARY, {0: 100}, BallVisuals.ShapeType.PENTAGON),
		_create_ball_def("Leech", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.DIAMOND),
		_create_ball_def("Rubbery", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.CIRCLE),
		_create_ball_def("Phantom", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.HEXAGON),
		_create_ball_def("Volatile", M, 1, Constants.RARITY_RARE, {0: 100}, BallVisuals.ShapeType.PLUS),
	]
	var t2: Array = [
		_create_ball_def("Split", M, 2, Constants.RARITY_UNCOMMON, {0: 50, 1: 100, 2: 40}, BallVisuals.ShapeType.HEXAGON),
		_create_ball_def("Energize", M, 2, Constants.RARITY_UNCOMMON, {0: 50, 1: 100, 2: 40}, BallVisuals.ShapeType.PENTAGON),
		_create_ball_def("Explosive", M, 2, Constants.RARITY_LEGENDARY, {0: 40, 1: 100, 2: 40}, BallVisuals.ShapeType.SQUARE),
		_create_ball_def("Chain Lightning", M, 2, Constants.RARITY_LEGENDARY, {0: 40, 1: 100, 2: 40}, BallVisuals.ShapeType.STAR),
		_create_ball_def("Constellation", M, 2, Constants.RARITY_LEGENDARY, {0: 40, 1: 100, 2: 40}, BallVisuals.ShapeType.PLUS),
		_create_ball_def("Binary", M, 2, Constants.RARITY_LEGENDARY, {0: 40, 1: 100, 2: 40}, BallVisuals.ShapeType.TRIANGLE),
		_create_ball_def("Bloom", M, 2, Constants.RARITY_LEGENDARY, {0: 40, 1: 100, 2: 40}, BallVisuals.ShapeType.PENTAGON),
		_create_ball_def("Leech", M, 2, Constants.RARITY_UNCOMMON, {0: 50, 1: 100, 2: 40}, BallVisuals.ShapeType.DIAMOND),
		_create_ball_def("Rubbery", M, 2, Constants.RARITY_UNCOMMON, {0: 50, 1: 100, 2: 40}, BallVisuals.ShapeType.CIRCLE),
		_create_ball_def("Phantom", M, 2, Constants.RARITY_UNCOMMON, {0: 50, 1: 100, 2: 40}, BallVisuals.ShapeType.HEXAGON),
		_create_ball_def("Volatile", M, 2, Constants.RARITY_RARE, {0: 50, 1: 100, 2: 40}, BallVisuals.ShapeType.PLUS),
	]
	var t3: Array = [
		_create_ball_def("Split", M, 3, Constants.RARITY_UNCOMMON, {1: 30, 2: 100}, BallVisuals.ShapeType.HEXAGON),
		_create_ball_def("Energize", M, 3, Constants.RARITY_UNCOMMON, {1: 30, 2: 100}, BallVisuals.ShapeType.PENTAGON),
		_create_ball_def("Explosive", M, 3, Constants.RARITY_LEGENDARY, {1: 20, 2: 100}, BallVisuals.ShapeType.SQUARE),
		_create_ball_def("Chain Lightning", M, 3, Constants.RARITY_LEGENDARY, {1: 20, 2: 100}, BallVisuals.ShapeType.STAR),
		_create_ball_def("Constellation", M, 3, Constants.RARITY_LEGENDARY, {1: 20, 2: 100}, BallVisuals.ShapeType.PLUS),
		_create_ball_def("Binary", M, 3, Constants.RARITY_LEGENDARY, {1: 20, 2: 100}, BallVisuals.ShapeType.TRIANGLE),
		_create_ball_def("Bloom", M, 3, Constants.RARITY_LEGENDARY, {1: 20, 2: 100}, BallVisuals.ShapeType.PENTAGON),
		_create_ball_def("Leech", M, 3, Constants.RARITY_UNCOMMON, {1: 30, 2: 100}, BallVisuals.ShapeType.DIAMOND),
		_create_ball_def("Rubbery", M, 3, Constants.RARITY_UNCOMMON, {1: 30, 2: 100}, BallVisuals.ShapeType.CIRCLE),
		_create_ball_def("Phantom", M, 3, Constants.RARITY_UNCOMMON, {1: 20, 2: 100}, BallVisuals.ShapeType.HEXAGON),
		_create_ball_def("Volatile", M, 3, Constants.RARITY_RARE, {1: 20, 2: 100}, BallVisuals.ShapeType.PLUS),
	]
	for d in t1 + t2 + t3:
		list.append(d)
	return list

func _create_ball_def(ability_name: String, alignment: int, tier: int, rarity: int, city_weights: Dictionary, shape_type: int = -1, status_effects: Dictionary = {}) -> BallDefinition:
	var d: BallDefinition = BallDefinition.new()
	d.ability_name = ability_name
	d.alignment = alignment
	d.tier = tier
	d.rarity = rarity
	d.base_energy = Constants.legacy_display_energy_to_current(20)
	d.city_weights = city_weights
	d.shape_type = shape_type
	d.status_effects = status_effects
	return d

func _get_candidates_for_current_city() -> Array:
	var city_id: int = GameState.current_city_id
	var max_rarity: int = _get_max_rarity_for_city(city_id)
	var weighted: Array = []
	for def in _ball_candidates:
		if def is BallDefinition and def.rarity <= max_rarity:
			var w: int = def.city_weights.get(city_id, 0)
			for _i in range(w):
				weighted.append(def)
	if weighted.is_empty():
		for def in _ball_candidates:
			if def is BallDefinition and def.rarity <= max_rarity:
				weighted.append(def)
	return weighted

func _get_max_rarity_for_city(city_id: int) -> int:
	if city_id >= 0 and city_id < Constants.MAX_RARITY_BY_CITY.size():
		return Constants.MAX_RARITY_BY_CITY[city_id]
	return Constants.RARITY_UNCOMMON

func _get_reward_wall_index() -> int:
	if _game_coordinator:
		var cm: Node = _game_coordinator.get_node_or_null("CombatManager")
		if cm and cm.has_method("get_current_wall_index"):
			return cm.get_current_wall_index()
	var main: Node = get_parent()
	if main:
		var cm2: Node = main.get_node_or_null("CombatManager")
		if cm2 and cm2.has_method("get_current_wall_index"):
			return cm2.get_current_wall_index()
	return 0

func _build_peg_shop_candidates() -> void:
	_peg_shop_candidates.clear()
	_add_peg_shop_template("bomb", Constants.RARITY_COMMON)
	_add_peg_shop_template("trampoline", Constants.RARITY_COMMON)
	_add_peg_shop_template("goblin_reset", Constants.RARITY_UNCOMMON)
	_add_peg_shop_template("gold", Constants.RARITY_UNCOMMON)
	_add_peg_shop_template("splitter", Constants.RARITY_UNCOMMON)
	_add_peg_shop_template("eternal", Constants.RARITY_RARE)
	_add_peg_shop_template("extreme_bouncer", Constants.RARITY_RARE)
	_add_peg_shop_template("magnet", Constants.RARITY_RARE)
	_add_peg_shop_template("lucky_gold", Constants.RARITY_RARE)
	_add_peg_shop_template("phase", Constants.RARITY_EPIC)
	_add_peg_shop_template("wrench", Constants.RARITY_EPIC)
	_add_peg_shop_template("gravity_well", Constants.RARITY_EPIC)

func _add_peg_shop_template(kind: String, rarity: int) -> void:
	var opt: MilestoneOption = MilestoneOption.new()
	opt.option_type = MilestoneOption.Type.PEG_UPGRADE
	opt.peg_kind = kind
	opt.rarity = rarity
	_peg_shop_candidates.append(opt)

## Treasure chest: pick 3 passive onboard upgrades (global peg scaling + explosion/chain/energize tags).
func get_onboard_effect_picks(count: int = 3) -> Array:
	var pool: Array = []
	for c in _onboard_effect_candidates:
		var bdef: MajorUpgradeDefinition = c as MajorUpgradeDefinition
		if bdef and _plain_swarm_upgrade_at_cap(bdef.upgrade_id):
			continue
		if bdef and _chest_passive_at_cap(bdef.upgrade_id):
			continue
		pool.append(c)
	return _reward_gen.pick_major_upgrades(pool, count)

func _chest_passive_at_cap(uid: StringName) -> bool:
	if not GameState:
		return false
	match uid:
		&"chest_leech_drain":
			return GameState.chest_leech_drain_stacks >= Constants.CHEST_PASSIVE_MAX_STACKS
		&"chest_leech_duration":
			return GameState.chest_leech_duration_stacks >= Constants.CHEST_PASSIVE_MAX_STACKS
		&"chest_phantom_energy":
			return GameState.chest_phantom_energy_stacks >= Constants.CHEST_PASSIVE_MAX_STACKS
		&"chest_rubbery_energy":
			return GameState.chest_rubbery_energy_stacks >= Constants.CHEST_PASSIVE_MAX_STACKS
		&"chest_bounce_energy":
			return GameState.chest_bounce_energy_stacks >= Constants.CHEST_PASSIVE_MAX_STACKS
		&"chest_split_energy":
			return GameState.chest_split_energy_stacks >= Constants.CHEST_PASSIVE_MAX_STACKS
		&"devastating_barrage":
			return GameState.chest_devastating_barrage_taken
		&"compressed_charge":
			return GameState.chest_compressed_charge_taken
		_:
			return false

func _major_upgrade_ball_gate_weight(def: MajorUpgradeDefinition) -> float:
	if not GameState:
		return 1.0
	for req_type in def.required_ball_types:
		if not GameState.has_ball_ability_in_run(req_type):
			return MAJOR_UPGRADE_UNOWNED_BALL_WEIGHT
	if not def.ball_type.is_empty() and not GameState.has_ball_ability_in_run(def.ball_type):
		return MAJOR_UPGRADE_UNOWNED_BALL_WEIGHT
	return 1.0

## Wall break: pick 3 — one each from cross-link / single-type / plain swarm when possible, then fill without dupes.
## Ball-gated upgrades stay in the pool but are heavily down-weighted when their ball types are missing.
func get_major_upgrade_picks(count: int = 3) -> Array:
	var max_stacks_for: Dictionary = {
		&"volt_primer": 1,
		&"supernova_peg": 1, &"chain_conduction": 1, &"explosions_apply_energize": 1,
		&"chain_hits_apply_energize": 1, &"overcharged_drain": 1, &"final_arc_detonation": 1,
		&"energy_collapse": 1, &"shrapnel_split": 1, &"energized_fragments": 1,
		&"arc_twins": 1, &"phase_siphon": 1, &"phase_detonation": 1,
		&"spectral_conduit": 1, &"impact_burst": 2, &"kinetic_charge": 1,
		&"static_bounce": 1, &"parasitic_arc": 1, &"draining_fragments": 1,
		&"resonant_bounce": 1, &"ricochet_blast": 1, &"blast_launch": 1,
		&"hyper_elastic": 1, &"overdrive_hits": 1, &"cluster_grenade": 1,
		&"storm_feedback": 1, &"overcurrent_surge": 1, &"fragment_echo": 1,
		&"mass_cascade": 1, &"ghost_trail": 1, &"phase_instability": 1,
		&"chain_surge_wrench": 1, &"goblin_width_pulse": 1, &"magnet_arc_snare": 1, &"spark_trampoline": 1,
		&"chest_random_ball": 1
	}
	var cross_pool: Array = []
	var cross_weights: Array = []
	for c in _cross_link_candidates:
		var def: MajorUpgradeDefinition = c as MajorUpgradeDefinition
		if not def:
			continue
		var cap: Variant = max_stacks_for.get(def.upgrade_id, -1)
		if cap >= 0 and GameState.get_wall_break_upgrade_stacks(def.upgrade_id) >= cap:
			continue
		cross_pool.append(c)
		cross_weights.append(_major_upgrade_ball_gate_weight(def))
	var ball_pool: Array = []
	var ball_weights: Array = []
	for c in _ball_enhancement_candidates:
		var def: MajorUpgradeDefinition = c as MajorUpgradeDefinition
		if not def:
			continue
		var cap: Variant = max_stacks_for.get(def.upgrade_id, -1)
		if cap >= 0 and GameState.get_wall_break_upgrade_stacks(def.upgrade_id) >= cap:
			continue
		ball_pool.append(c)
		ball_weights.append(_major_upgrade_ball_gate_weight(def))
	var board_pool: Array = []
	var board_weights: Array = []
	for c in _board_candidates:
		var bdef: MajorUpgradeDefinition = c as MajorUpgradeDefinition
		if bdef and _plain_swarm_upgrade_at_cap(bdef.upgrade_id):
			continue
		board_pool.append(c)
		board_weights.append(_major_upgrade_ball_gate_weight(bdef) if bdef else 1.0)
	return _reward_gen.pick_wall_break_draft(cross_pool, ball_pool, board_pool, count, cross_weights, ball_weights, board_weights)

func _plain_swarm_upgrade_at_cap(uid: StringName) -> bool:
	match uid:
		&"plain_surge":
			return GameState.plain_surge_stacks >= 5
		&"plain_horde":
			return GameState.plain_horde_stacks >= 3
		&"plain_momentum":
			return GameState.plain_momentum_stacks >= 3
		_:
			return false

## Boss reward: pick 3 amplifiers; ball-gated options stay in the pool but are heavily down-weighted when types are missing.
func get_boss_upgrade_picks(count: int = 3) -> Array:
	var pool: Array = []
	var weights: Array = []
	for c in _boss_candidates:
		var def: MajorUpgradeDefinition = c as MajorUpgradeDefinition
		if not def:
			continue
		if GameState.has_boss_upgrade(def.upgrade_id):
			continue
		pool.append(c)
		weights.append(_major_upgrade_ball_gate_weight(def))
	return _reward_gen.pick_major_upgrades(pool, count, weights)

func _mk(def_name: String, desc: String, uid: StringName, cat: int, ball_t: String = "") -> MajorUpgradeDefinition:
	var u: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	u.display_name = def_name
	u.description = desc
	u.upgrade_id = StringName(uid)
	u.category = cat
	u.ball_type = ball_t
	return u

func _mk_cross(def_name: String, desc: String, uid: StringName, req_types: Array[String]) -> MajorUpgradeDefinition:
	var u: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	u.display_name = def_name
	u.description = desc
	u.upgrade_id = StringName(uid)
	u.category = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
	u.required_ball_types = req_types
	return u

func _mk_boss(def_name: String, desc: String, uid: StringName, req_types: Array[String] = []) -> MajorUpgradeDefinition:
	var u: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	u.display_name = def_name
	u.description = desc
	u.upgrade_id = StringName(uid)
	u.category = MajorUpgradeDefinition.Category.BOSS_AMPLIFIER
	u.required_ball_types = req_types
	return u

## Phase 2: Cross-link upgrades (require two ball types) + single-type + board upgrades.
func _build_onboard_effect_candidates() -> void:
	var cat_on: int = MajorUpgradeDefinition.Category.ONBOARD_PASSIVE
	# ——— TAG / GLOBAL PASSIVE ——— (treasure chest; not conquest synergy picks)
	_onboard_effect_candidates.append(_mk("Bigger Blasts", "Explosions: Blast radius +1.", &"explosion_radius", cat_on))
	_onboard_effect_candidates.append(_mk("More Explosion Hits", "Explosions: Damages +1 additional peg.", &"explosion_peg_hit_count", cat_on))
	_onboard_effect_candidates.append(_mk("Stronger Blast Push", "Explosions: +25% push force on nearby balls.", &"explosion_impulse", cat_on))
	_onboard_effect_candidates.append(_mk("+1 Chain Jump", "Chain Lightning: +1 lightning jump arc.", &"chain_arc", cat_on))
	_onboard_effect_candidates.append(_mk("Longer Chains", "Chain Lightning: Increases jump distance between pegs.", &"chain_range", cat_on))
	_onboard_effect_candidates.append(_mk("Deeper Energize", "Energize: Maximum peg stacks +1.", &"max_energize_stacks", cat_on))
	_onboard_effect_candidates.append(_mk("Slower Energize Fade", "Energize: Decays 15% slower on pegs.", &"energize_decays_slower", cat_on))
	_onboard_effect_candidates.append(_mk("Fast Heal (Energized)", "Energize: Energized pegs repair +20% faster.", &"energized_pegs_repair_faster", cat_on))
	_onboard_effect_candidates.append(_mk("Tough Pegs", "All Pegs: Durability +1 hit.", &"global_peg_durability", cat_on))
	_onboard_effect_candidates.append(_mk("Faster Peg Recovery", "All Pegs: Broken pegs recover +15% faster.", &"peg_recovery_speed", cat_on))
	_onboard_effect_candidates.append(_mk("Devastating Barrage", "Main Cannon: +10 damage per shot. (Max 1 stack)", &"devastating_barrage", cat_on))
	_onboard_effect_candidates.append(_mk("Compressed Charge", "Main Cannon: Requires less Energy to fire. (Max 1 stack)", &"compressed_charge", cat_on))
	_onboard_effect_candidates.append(_mk("Leech Drain Up", "Drain: +1 Energy drained per second per leeched peg.", &"chest_leech_drain", cat_on))
	_onboard_effect_candidates.append(_mk("Longer Leech", "Drain: Duration +1 second.", &"chest_leech_duration", cat_on))
	_onboard_effect_candidates.append(_mk("Phantom Energy", "Phantom: +5% Energy generated per peg pass.", &"chest_phantom_energy", cat_on))
	_onboard_effect_candidates.append(_mk("Rubbery Energy", "Rubbery: +5% Energy generated per peg hit.", &"chest_rubbery_energy", cat_on))
	_onboard_effect_candidates.append(_mk("Plain Energy", "Plain: +5% Energy generated per peg hit.", &"chest_bounce_energy", cat_on))
	_onboard_effect_candidates.append(_mk("Split Energy", "Split: +5% Energy generated per fragment peg hit.", &"chest_split_energy", cat_on))

func _build_wall_break_candidates() -> void:
	var cat_b: int = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
	var cat_board: int = MajorUpgradeDefinition.Category.BOARD_UPGRADE

	# ——— CROSS-LINK UPGRADES (require two systems) ———
	# Explosive + Energize
	_cross_link_candidates.append(_mk_cross("Explosions Apply Energize", "Explosions: Applies 1 Energize stack to all damaged pegs.", &"explosions_apply_energize", ["Explosive", "Energize"]))
	_cross_link_candidates.append(_mk_cross("Supernova Peg", "Supernova: Triggers a large explosion that damages nearby pegs.", &"supernova_peg", ["Explosive", "Energize"]))
	# Chain + Energize
	_cross_link_candidates.append(_mk_cross("Chain Hits Apply Energize", "Chain Lightning: Applies 1 Energize stack to struck pegs.", &"chain_hits_apply_energize", ["Chain Lightning", "Energize"]))
	_cross_link_candidates.append(_mk_cross("Chain Conduction", "Chain Lightning: Also strikes every energized peg on the board.", &"chain_conduction", ["Chain Lightning", "Energize"]))
	# Leech + Energize
	_cross_link_candidates.append(_mk_cross("Overcharged Drain", "Drain: Draining an energized peg generates 2× Energy.", &"overcharged_drain", ["Leech", "Energize"]))
	# Chain + Explosive
	_cross_link_candidates.append(_mk_cross("Final Arc Detonation", "Chain Lightning: Final lightning jump triggers a small explosion.", &"final_arc_detonation", ["Chain Lightning", "Explosive"]))
	# Leech + Explosive
	_cross_link_candidates.append(_mk_cross("Energy Collapse", "On Break (3+ Drain): Triggers an explosion at that peg.", &"energy_collapse", ["Leech", "Explosive"]))
	# Split + Explosive
	_cross_link_candidates.append(_mk_cross("Shrapnel Split", "Split: Fragment hitting a Bomb Peg doubles explosion radius.", &"shrapnel_split", ["Split", "Explosive"]))
	# Split + Energize
	_cross_link_candidates.append(_mk_cross("Energized Fragments", "Split: Fragment hits apply 1 Energize stack to pegs.", &"energized_fragments", ["Split", "Energize"]))
	# Split + Chain
	_cross_link_candidates.append(_mk_cross("Arc Twins", "Split: Chain Lightning can jump between both active fragments.", &"arc_twins", ["Split", "Chain Lightning"]))
	# Phantom + Energize
	_cross_link_candidates.append(_mk_cross("Phase Siphon", "Phantom: Passing through energized pegs drains 1 stack for +50% Energy.", &"phase_siphon", ["Phantom", "Energize"]))
	# Phantom + Explosive
	_cross_link_candidates.append(_mk_cross("Phase Detonation", "Drop End (5+ passes): Phantom triggers an explosion at the bottom.", &"phase_detonation", ["Phantom", "Explosive"]))
	# Phantom + Chain
	_cross_link_candidates.append(_mk_cross("Spectral Conduit", "Phantom: Leaves a trail that Chain Lightning can jump through.", &"spectral_conduit", ["Phantom", "Chain Lightning"]))
	# Rubbery + Explosive
	_cross_link_candidates.append(_mk_cross("Impact Burst", "Rubbery: High-speed hits trigger small explosions. (Max 2 stacks)", &"impact_burst", ["Rubbery", "Explosive"]))
	# Rubbery + Energize
	_cross_link_candidates.append(_mk_cross("Kinetic Charge", "Rubbery: Bouncing off energized pegs boosts speed and grants +3 Energy.", &"kinetic_charge", ["Rubbery", "Energize"]))
	# Rubbery + Chain
	_cross_link_candidates.append(_mk_cross("Static Bounce", "Overdrive 4 (Rubbery): Discharges Chain Lightning from that peg.", &"static_bounce", ["Rubbery", "Chain Lightning"]))
	# Leech + Chain
	_cross_link_candidates.append(_mk_cross("Parasitic Arc", "Chain Lightning: Striking a peg with Drain spreads Drain across the chain.", &"parasitic_arc", ["Leech", "Chain Lightning"]))
	# Leech + Split
	_cross_link_candidates.append(_mk_cross("Draining Fragments", "Split: Fragment hits apply short Drain to pegs.", &"draining_fragments", ["Leech", "Split"]))
	# Plain + Energize
	_cross_link_candidates.append(_mk_cross("Resonant Bounce", "Plain: Hits on energized pegs grant +1 Energy per Energize stack.", &"resonant_bounce", ["Plain", "Energize"]))
	# Plain + Explosive
	_cross_link_candidates.append(_mk_cross("Ricochet Blast", "Overdrive 6 (Plain): Next peg hit triggers an explosion.", &"ricochet_blast", ["Plain", "Explosive"]))
	# Bomb Peg + Trampoline (board-level cross-link, no ball type gate)
	_cross_link_candidates.append(_mk_cross("Blast Launch", "Explosions: Blasts near Trampolines launch nearby balls upward.", &"blast_launch", []))
	# Board peg synergies (chain + special pegs; no extra ball gate beyond Chain Lightning where noted)
	_cross_link_candidates.append(_mk_cross("Arc Surge Wrench", "Chain Lightning: Striking a Wrench Peg repairs up to 10 broken pegs.", &"chain_surge_wrench", ["Chain Lightning"]))
	_cross_link_candidates.append(_mk_cross("Goblin Surge Chute", "Hopper: Returning a ball from the board temporarily widens the hopper.", &"goblin_width_pulse", []))
	_cross_link_candidates.append(_mk_cross("Magnet Arc Snare", "Chain Lightning: Striking a Magnet Peg pulls nearby balls toward it.", &"magnet_arc_snare", ["Chain Lightning"]))
	_cross_link_candidates.append(_mk_cross("Spark Trampoline", "Chain Lightning: Striking a Trampoline grants extra upward lift to balls.", &"spark_trampoline", ["Chain Lightning"]))

	# ——— SINGLE-TYPE ENHANCEMENTS (lower priority, kept in wall-break pool) ———
	_ball_enhancement_candidates.append(_mk("Hyper Elastic", "Rubbery: Upward bounces boost ball speed. (Max 1 stack)", &"hyper_elastic", cat_b, "Rubbery"))
	_ball_enhancement_candidates.append(_mk("Overdrive Hits", "Overdrive 6: Later bounces grant 2× Energy. (Max 1 stack)", &"overdrive_hits", cat_b, ""))
	_ball_enhancement_candidates.append(_mk("Overclock Network", "Energize: Energized pegs gain +1 durability per adjacent energized peg.", &"overclock_network", cat_b, "Energize"))
	_ball_enhancement_candidates.append(_mk("Spreading Rot", "On Expiry (Drain): Spreads short Drain to adjacent pegs. (Max 1 stack)", &"spreading_rot", cat_b, "Leech"))
	_ball_enhancement_candidates.append(_mk("Cluster Grenade", "Explosions: Spawns 1–2 secondary explosions. (Max 1 stack)", &"cluster_grenade", cat_b, "Explosive"))
	_ball_enhancement_candidates.append(_mk("Blast Lift", "Explosions: Blasts push nearby balls upward with extra force.", &"blast_lift", cat_b, "Explosive"))
	_ball_enhancement_candidates.append(_mk("Fragmentation Tag", "Explosions: Blast damage counts as +1 extra peg hit for Energy.", &"fragmentation_tag", cat_b, "Explosive"))
	_ball_enhancement_candidates.append(_mk("Storm Feedback", "Chain Lightning: Arcs between energized pegs boost peg Energy. (Max 1 stack)", &"storm_feedback", cat_b, "Chain Lightning"))
	_ball_enhancement_candidates.append(_mk("Overcurrent Surge", "Chain Lightning: Striking the same peg twice resets its HP and pays Energy. (Max 1 stack)", &"overcurrent_surge", cat_b, "Chain Lightning"))
	_ball_enhancement_candidates.append(_mk("Fragment Echo", "Drop End (Split): Fragment exiting bottom spawns 1 new ball at top. (Max 1 stack)", &"fragment_echo", cat_b, "Split"))
	_ball_enhancement_candidates.append(_mk("Mass Cascade", "Split: Collision between two fragments temporarily boosts peg Energy. (Max 1 stack)", &"mass_cascade", cat_b, "Split"))
	_ball_enhancement_candidates.append(_mk("Ghost Trail", "Phantom: Leaves a trail; pegs in trail grant +1 Energy when hit. (Max 1 stack)", &"ghost_trail", cat_b, "Phantom"))
	_ball_enhancement_candidates.append(_mk("Phase Instability", "Drop End (0 hits): Phantom respawns at top with bonus speed. (Max 1 stack)", &"phase_instability", cat_b, "Phantom"))
	_ball_enhancement_candidates.append(_mk("Plunderer's Cut", "Treasure Chests: Opening a chest grants 1 random ball. (Max 1 stack)", &"chest_random_ball", cat_b))

	# Plain-ball swarm (wall break only; too build-defining for milestone shop)
	_board_candidates.append(_mk("Plain Surge", "Plain Balls: +1 Energy per peg hit per stack. (Max 5 stacks)", &"plain_surge", cat_board))
	_board_candidates.append(_mk("Plain Horde", "Plain Balls: +1 Energy per hit per 5 Plain balls in play (max +3). (Max 3 stacks)", &"plain_horde", cat_board))
	_board_candidates.append(_mk("Plain Momentum", "Overdrive 7 (Plain): +1 Energy per hit per stack. (Max 3 stacks)", &"plain_momentum", cat_board))
	_board_candidates.append(_mk("Volt Primer", "Energize: Gaining Energize discounts next Cannon shot by 5 Energy. (Max 1 stack)", &"volt_primer", cat_board))

## Phase 3: Boss amplifiers — high power chain-reaction upgrades offered on city completion.
func _build_boss_candidates() -> void:
	_boss_candidates.append(_mk_boss("Cascade Reactor", "Supernova: Chain Lightning automatically strikes every peg with Drain.", &"cascade_reactor", ["Energize", "Chain Lightning", "Leech"]))
	_boss_candidates.append(_mk_boss("Perpetual Engine", "On Break (Energized): Spawns 1 Phantom ball at the top of the board.", &"perpetual_engine", ["Energize", "Phantom"]))
	_boss_candidates.append(_mk_boss("Storm of Fragments", "Split: Fragment hitting 3+ energized pegs fires Chain Lightning from each.", &"storm_of_fragments", ["Split", "Energize", "Chain Lightning"]))
	_boss_candidates.append(_mk_boss("Explosive Contagion", "Explosions: Each damaged peg gains 1 stack of Drain.", &"explosive_contagion", ["Explosive", "Leech"]))
	# Always eligible (no ball-type gate)
	_boss_candidates.append(_mk_boss("Overdrive Cascade", "Overdrive 5: All balls gain +1 Energy per hit for 3 seconds.", &"overdrive_cascade", []))
	_boss_candidates.append(_mk_boss("Superconductor", "Chain Lightning: A second chain starts from the farthest energized peg.", &"superconductor", ["Energize", "Chain Lightning"]))
	_boss_candidates.append(_mk_boss("Leech Singularity", "Drain (3 stacks + Energize): Drain ticks damage the peg and neighbors.", &"leech_singularity", ["Leech", "Energize"]))
	_boss_candidates.append(_mk_boss("Phantom Resonance", "Phantom: Passing through recently zapped pegs grants 2× Energy.", &"phantom_resonance", ["Phantom", "Chain Lightning"]))
	_boss_candidates.append(_mk_boss("Rubber Storm", "Rubbery (Max Speed): Discharges Chain Lightning on every bounce.", &"rubber_storm", ["Rubbery", "Chain Lightning"]))
	_boss_candidates.append(_mk_boss("Fragment Swarm", "Split: Divides into 3 fragments. Fragments can split again on Bomb Pegs.", &"fragment_swarm", ["Split", "Explosive"]))
	_boss_candidates.append(_mk_boss("Goblin Width Tempest", "Hopper: Returning a ball greatly expands hopper width for longer.", &"goblin_width_tempest", []))
	_boss_candidates.append(_mk_boss("Echoes of the Wrench", "Wrench: Arc Surge Wrench repairs +5 additional broken pegs.", &"echoes_of_wrench", ["Chain Lightning"]))
	_boss_candidates.append(_mk_boss("Stormgrid Coupling", "Magnet Peg: +60% pull force and stabilizes ball motion.", &"stormgrid_coupling", ["Chain Lightning"]))
	# Single-type and universal bosses (avoid triple gates; diversify away from bombs/lightning)
	_boss_candidates.append(_mk_boss("Blood Tithe", "Drain: Drains +1 additional Energy per second per leeched peg.", &"blood_tithe", ["Leech"]))
	_boss_candidates.append(_mk_boss("Crown Ricochet", "Overdrive 5 (Plain): Later bounces grant +2 Energy per peg hit.", &"crown_ricochet", ["Plain"]))
	_boss_candidates.append(_mk_boss("Twin Mandate", "Split: +18% Energy generated from all fragment peg hits.", &"twin_mandate", ["Split"]))
	_boss_candidates.append(_mk_boss("Velocity Dividend", "Rubbery (High Speed): Peg hits grant +3 Energy without lightning.", &"velocity_dividend", ["Rubbery"]))
	_boss_candidates.append(_mk_boss("Phase Sovereign", "Phantom: +22% Energy generated from all peg passes.", &"phase_sovereign", ["Phantom"]))
	_boss_candidates.append(_mk_boss("Resonant Well", "Energize: All hits on energized pegs grant +2 Energy.", &"resonant_well", ["Energize"]))
	_boss_candidates.append(_mk_boss("Renewal Pact", "All Pegs: Broken pegs recover +12% faster.", &"renewal_pact", []))
	_boss_candidates.append(_mk_boss("Gilded Covenant", "Gold Pegs: Hits on Gold or Lucky Gold pegs award +1 run Gold.", &"gilded_covenant", []))
	_boss_candidates.append(_mk_boss("Iron Bloom", "Magnet Peg: Ambient magnetic pull strength +35%.", &"iron_bloom", []))

func get_ball_reward_picks(count: int) -> Array:
	var candidates: Array = _get_candidates_for_current_city()
	return _reward_gen.pick_ball_rewards(candidates, count)

func get_milestone_reward_picks(count: int = 5) -> Array:
	var candidates: Array = _get_candidates_for_current_city()
	var max_r: int = _get_max_rarity_for_city(GameState.current_city_id if GameState else 0)
	var endless: bool = GameState.endless_mode if GameState else false
	var city_id: int = GameState.current_city_id if GameState else 0
	var weights: Array = Constants.milestone_reward_rarity_weights(city_id, _get_reward_wall_index(), endless)
	return _reward_gen.pick_milestone_options(candidates, count, true, _peg_shop_candidates, weights, max_r)

func apply_ball_pick(pick: Resource) -> void:
	_apply_ball_to_hopper(pick)

## Treasure chest bonus: one random ball from the current city's reward pool (same logic as milestone ball picks).
func grant_random_ball_from_city_pool() -> void:
	var picks: Array = get_ball_reward_picks(1)
	if picks.size() > 0:
		apply_ball_pick(picks[0])

func apply_milestone_pick(option: Resource) -> void:
	if option is MilestoneOption:
		var opt: MilestoneOption = option as MilestoneOption
		match opt.option_type:
			MilestoneOption.Type.BASIC_BATCH:
				if _game_coordinator and _game_coordinator.has_method("add_basic_balls"):
					_game_coordinator.add_basic_balls(RewardGeneration.BASIC_BATCH_SIZE)
			MilestoneOption.Type.STAT:
				if not opt.stat_id.is_empty():
					apply_stat_upgrade(opt.stat_id)
			MilestoneOption.Type.BALL_UPGRADE:
				if opt.ball_definition:
					var converted: bool = false
					if _game_coordinator and _game_coordinator.has_method("apply_ball_upgrade_conversion"):
						converted = _game_coordinator.apply_ball_upgrade_conversion(opt.ball_definition)
					if not converted:
						# If there are no plain balls to convert, still grant the ball directly
						# so the shop purchase always provides meaningful value.
						_apply_ball_to_hopper(opt.ball_definition)
			MilestoneOption.Type.PEG_UPGRADE:
				apply_peg_shop_unlock(opt.peg_kind)

func apply_stat_upgrade(stat_id: String) -> void:
	if not GameState:
		return
	match stat_id:
		"main_charge":
			GameState.main_charge_bonus += 0.05
		"door_interval":
			GameState.conduit_wave_interval_scale = maxf(0.5, GameState.conduit_wave_interval_scale - 0.1)
		"door_duration":
			GameState.conduit_open_duration_scale += 0.1
		"cannon_damage":
			GameState.cannon_base_damage_bonus += 5
		"cannon_energy":
			GameState.cannon_charge_reduction += Constants.legacy_internal_energy_to_current(2000)
		"plain_surge":
			GameState.plain_surge_stacks = mini(5, GameState.plain_surge_stacks + 1)
		"plain_momentum":
			GameState.plain_momentum_stacks = mini(3, GameState.plain_momentum_stacks + 1)
		"plain_horde":
			GameState.plain_horde_stacks = mini(3, GameState.plain_horde_stacks + 1)
		"hopper_width":
			GameState.hopper_width_scale = minf(2.0, GameState.hopper_width_scale + 0.1)
			if _hopper and _hopper.has_method("refresh_width_from_game_state"):
				_hopper.refresh_width_from_game_state()

func grant_ball_rewards(count: int) -> void:
	if _game_coordinator and _game_coordinator.has_method("add_basic_balls"):
		_game_coordinator.add_basic_balls(count)

func grant_stat_upgrades(count: int) -> void:
	if not GameState:
		return
	var options: Array[String] = ["main_charge", "door_interval", "door_duration", "cannon_damage", "cannon_energy", "hopper_width"]
	for i in count:
		if options.is_empty():
			break
		var idx: int = _reward_gen.randi_range(0, options.size() - 1) if _reward_gen and options.size() > 0 else 0
		var pick: String = options[idx]
		options.remove_at(idx)
		apply_stat_upgrade(pick)

## Milestone shop: unlock a special peg and prompt placement (same state as former wall-break peg picks).
func apply_peg_shop_unlock(kind: String) -> void:
	if not GameState:
		return
	match kind:
		"bomb":
			GameState.bomb_peg_count += 1
			_pending_peg_selection_kind = "bomb"
		"trampoline":
			GameState.trampoline_peg_count += 1
			_pending_peg_selection_kind = "trampoline"
		"goblin_reset":
			GameState.goblin_reset_node_count += 1
			_pending_peg_selection_kind = "goblin_reset"
		"eternal":
			GameState.eternal_peg_count += 1
			_pending_peg_selection_kind = "eternal"
		"extreme_bouncer":
			GameState.extreme_bouncer_peg_count += 1
			_pending_peg_selection_kind = "extreme_bouncer"
		"magnet":
			GameState.magnet_peg_count += 1
			_pending_peg_selection_kind = "magnet"
		"splitter":
			GameState.splitter_peg_count += 1
			_pending_peg_selection_kind = "splitter"
		"gold":
			GameState.gold_peg_count += 1
			_pending_peg_selection_kind = "gold"
		"lucky_gold":
			GameState.lucky_gold_peg_count += 1
			_pending_peg_selection_kind = "lucky_gold"
		"gravity_well":
			GameState.gravity_well_peg_count += 1
			_pending_peg_selection_kind = "gravity_well"
		"phase":
			GameState.phase_peg_count += 1
			_pending_peg_selection_kind = "phase"
		"wrench":
			GameState.wrench_peg_count += 1
			_pending_peg_selection_kind = "wrench"
		_:
			pass

## Apply chosen major upgrade (wall break). Stack caps enforced here.
func apply_major_upgrade(pick: Resource) -> void:
	if not pick is MajorUpgradeDefinition:
		return
	var def: MajorUpgradeDefinition = pick as MajorUpgradeDefinition
	var uid: StringName = def.upgrade_id
	match uid:
		&"plain_surge", &"plain_horde", &"plain_momentum":
			apply_stat_upgrade(String(uid))
			return
	# ——— Cross-link and ball enhancements (stack caps) ———
	var max_stacks: int = -1
	match uid:
		&"impact_burst": max_stacks = 2
		&"hyper_elastic", &"overdrive_hits", &"supernova_peg", &"chain_conduction": max_stacks = 1
		&"spreading_rot", &"energy_collapse", &"cluster_grenade", &"storm_feedback": max_stacks = 1
		&"final_arc_detonation", &"overcurrent_surge", &"fragment_echo", &"mass_cascade": max_stacks = 1
		&"ghost_trail", &"phase_instability": max_stacks = 1
		&"explosions_apply_energize", &"chain_hits_apply_energize": max_stacks = 1
		&"overcharged_drain", &"shrapnel_split", &"energized_fragments", &"arc_twins": max_stacks = 1
		&"phase_siphon", &"phase_detonation", &"spectral_conduit": max_stacks = 1
		&"kinetic_charge", &"static_bounce", &"parasitic_arc", &"draining_fragments": max_stacks = 1
		&"resonant_bounce", &"ricochet_blast", &"blast_launch": max_stacks = 1
		&"volt_primer", &"chain_surge_wrench", &"goblin_width_pulse", &"magnet_arc_snare", &"spark_trampoline", &"chest_random_ball": max_stacks = 1
	if max_stacks >= 0:
		if GameState.get_wall_break_upgrade_stacks(uid) < max_stacks:
			GameState.add_wall_break_upgrade(uid, 1)
		return
	# No cap or stackable
	match uid:
		&"blast_lift", &"fragmentation_tag", &"overclock_network":
			GameState.add_wall_break_upgrade(uid, 1)
			return
	# ——— Tag upgrades ———
	if uid == &"explosion_radius":
		GameState.explosion_radius_bonus += 1
		return
	if uid == &"explosion_peg_hit_count":
		GameState.explosion_peg_hit_count_bonus += 1
		return
	if uid == &"explosion_impulse":
		GameState.explosion_impulse_bonus += 0.25
		return
	if uid == &"chain_arc":
		GameState.chain_arc_bonus += 1
		return
	if uid == &"chain_range":
		GameState.chain_range_bonus += 1
		return
	if uid == &"max_energize_stacks":
		GameState.max_energize_stacks_per_peg += 1
		return
	if uid == &"energize_decays_slower":
		GameState.energize_decay_scale *= 0.85
		return
	if uid == &"energized_pegs_repair_faster":
		GameState.energized_peg_repair_scale += 0.2
		return
	# ——— Board upgrades (peg unlocks are milestone-shop only) ———
	if uid == &"global_peg_durability":
		GameState.global_peg_durability_bonus += 1
		return
	if uid == &"peg_recovery_speed":
		GameState.peg_recovery_speed_scale += 0.15
		return
	# ——— Treasure chest numeric passives (stack caps) ———
	match uid:
		&"devastating_barrage":
			if not GameState.chest_devastating_barrage_taken:
				GameState.chest_devastating_barrage_taken = true
				GameState.cannon_base_damage_bonus += 10
			return
		&"compressed_charge":
			if not GameState.chest_compressed_charge_taken:
				GameState.chest_compressed_charge_taken = true
				GameState.cannon_charge_reduction += Constants.legacy_internal_energy_to_current(2000)
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

## Apply chosen boss amplifier (city completion). Each can only be picked once.
func apply_boss_upgrade(pick: Resource) -> void:
	if not pick is MajorUpgradeDefinition:
		return
	var def: MajorUpgradeDefinition = pick as MajorUpgradeDefinition
	var uid: StringName = def.upgrade_id
	if GameState.has_boss_upgrade(uid):
		return
	match uid:
		&"renewal_pact":
			GameState.peg_recovery_speed_scale += 0.12
		_:
			pass
	GameState.add_boss_upgrade(uid, 1)

func has_pending_peg_selection() -> bool:
	return not _pending_peg_selection_kind.is_empty()

func get_pending_peg_kind() -> String:
	return _pending_peg_selection_kind

func clear_pending_peg_selection() -> void:
	_pending_peg_selection_kind = ""

func _tell_board_add_extra_pegs() -> void:
	var main: Node = get_parent()
	var board: Node = main.get_node_or_null("Board") if main else null
	if board and board.has_method("add_extra_pegs_if_needed"):
		board.add_extra_pegs_if_needed()

func get_upgrade_display_info(upgrade_id: StringName) -> Dictionary:
	for list in [_onboard_effect_candidates, _cross_link_candidates, _ball_enhancement_candidates, _board_candidates, _boss_candidates]:
		for c in list:
			var def: MajorUpgradeDefinition = c as MajorUpgradeDefinition
			if def and def.upgrade_id == upgrade_id:
				return {"name": def.display_name, "description": def.description}
	return {"name": String(upgrade_id), "description": ""}

func get_catalog_ball_definitions() -> Array:
	return _ball_candidates.duplicate()

func get_catalog_peg_milestone_options() -> Array:
	return _peg_shop_candidates.duplicate()

func get_catalog_wall_break_major_definitions() -> Array:
	var out: Array = []
	for c in _cross_link_candidates:
		out.append(c)
	for c in _ball_enhancement_candidates:
		out.append(c)
	for c in _board_candidates:
		out.append(c)
	return out

func get_catalog_boss_definitions() -> Array:
	return _boss_candidates.duplicate()

## Milestone shop stat picks (conduit / cannon / hopper); same IDs as `apply_stat_upgrade`.
func get_catalog_milestone_stat_ids() -> Array:
	return RewardGeneration.MILESTONE_STAT_IDS.duplicate()

## Treasure-chest onboard passives and global tag upgrades (not in wall-break draft list).
func get_catalog_onboard_effect_definitions() -> Array:
	return _onboard_effect_candidates.duplicate()

func remove_one_almanac_wall_break(uid: StringName) -> bool:
	if not GameState:
		return false
	match uid:
		&"plain_surge":
			if GameState.plain_surge_stacks <= 0:
				return false
			GameState.plain_surge_stacks -= 1
			return true
		&"plain_horde":
			if GameState.plain_horde_stacks <= 0:
				return false
			GameState.plain_horde_stacks -= 1
			return true
		&"plain_momentum":
			if GameState.plain_momentum_stacks <= 0:
				return false
			GameState.plain_momentum_stacks -= 1
			return true
		_:
			if GameState.get_wall_break_upgrade_stacks(uid) <= 0:
				return false
			GameState.remove_wall_break_upgrade_stack(uid, 1)
			return true

func remove_one_almanac_boss(uid: StringName) -> bool:
	if not GameState or not GameState.has_boss_upgrade(uid):
		return false
	GameState.remove_boss_upgrade_entry(uid)
	return true

## Remove one milestone-shop peg unlock: revert a placed peg if possible, then decrement GameState count.
func remove_one_peg_unlock_for_almanac(kind: String, board: Node) -> bool:
	if kind.is_empty() or not GameState:
		return false
	if _get_peg_unlock_count(kind) <= 0:
		return false
	if board and board.has_method("revert_one_shop_peg_of_kind"):
		board.revert_one_shop_peg_of_kind(kind)
	_decrement_peg_unlock_count(kind)
	return true

func _get_peg_unlock_count(kind: String) -> int:
	match kind:
		"bomb":
			return GameState.bomb_peg_count
		"trampoline":
			return GameState.trampoline_peg_count
		"goblin_reset":
			return GameState.goblin_reset_node_count
		"gold":
			return GameState.gold_peg_count
		"splitter":
			return GameState.splitter_peg_count
		"eternal":
			return GameState.eternal_peg_count
		"extreme_bouncer":
			return GameState.extreme_bouncer_peg_count
		"magnet":
			return GameState.magnet_peg_count
		"lucky_gold":
			return GameState.lucky_gold_peg_count
		"phase":
			return GameState.phase_peg_count
		"wrench":
			return GameState.wrench_peg_count
		"gravity_well":
			return GameState.gravity_well_peg_count
		_:
			return 0

func _decrement_peg_unlock_count(kind: String) -> void:
	match kind:
		"bomb":
			GameState.bomb_peg_count = maxi(0, GameState.bomb_peg_count - 1)
		"trampoline":
			GameState.trampoline_peg_count = maxi(0, GameState.trampoline_peg_count - 1)
		"goblin_reset":
			GameState.goblin_reset_node_count = maxi(0, GameState.goblin_reset_node_count - 1)
		"gold":
			GameState.gold_peg_count = maxi(0, GameState.gold_peg_count - 1)
		"splitter":
			GameState.splitter_peg_count = maxi(0, GameState.splitter_peg_count - 1)
		"eternal":
			GameState.eternal_peg_count = maxi(0, GameState.eternal_peg_count - 1)
		"extreme_bouncer":
			GameState.extreme_bouncer_peg_count = maxi(0, GameState.extreme_bouncer_peg_count - 1)
		"magnet":
			GameState.magnet_peg_count = maxi(0, GameState.magnet_peg_count - 1)
		"lucky_gold":
			GameState.lucky_gold_peg_count = maxi(0, GameState.lucky_gold_peg_count - 1)
		"phase":
			GameState.phase_peg_count = maxi(0, GameState.phase_peg_count - 1)
		"wrench":
			GameState.wrench_peg_count = maxi(0, GameState.wrench_peg_count - 1)
		"gravity_well":
			GameState.gravity_well_peg_count = maxi(0, GameState.gravity_well_peg_count - 1)
		_:
			pass

func _apply_ball_to_hopper(pick: Variant) -> void:
	if pick is Resource and _hopper and _hopper.has_method("add_balls_with_definition"):
		if pick is BallDefinition:
			var picked_ab: String = (pick as BallDefinition).ability_name
			GameState.record_ball_ability_in_run(picked_ab if not picked_ab.is_empty() else "Plain")
		var in_hopper: int = _hopper.get_stored_ball_count() if _hopper.has_method("get_stored_ball_count") else 0
		const HOPPER_MAX: int = 100
		if in_hopper < HOPPER_MAX:
			_hopper.add_balls_with_definition(1, pick)
			return
	if _game_coordinator and _game_coordinator.has_method("add_balls_to_reserve"):
		_game_coordinator.add_balls_to_reserve(1)
	elif _hopper and _hopper.has_method("add_balls"):
		_hopper.add_balls(1)
