class_name RewardCardCatalog
extends RefCounted
## Static catalog definition builders for RewardHandler candidates.

const DeliberateRelicCatalog = preload("res://resources/polyomino/deliberate_relic_catalog.gd")
const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")

static func create_ball_def(ability_name: String, alignment: int, tier: int, rarity: int, city_weights: Dictionary, shape_type: int = -1, status_effects: Dictionary = {}) -> BallDefinition:
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

static func build_ball_candidates() -> Array:
	var list: Array = []
	var M: int = Constants.ALIGNMENT_MAIN
	var t1: Array = [
		create_ball_def("Split", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.HEXAGON),
		create_ball_def("Energize", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.PENTAGON),
		create_ball_def("Explosive", M, 1, Constants.RARITY_LEGENDARY, {0: 100}, BallVisuals.ShapeType.SQUARE),
		create_ball_def("Chain Lightning", M, 1, Constants.RARITY_LEGENDARY, {0: 100}, BallVisuals.ShapeType.STAR),
		create_ball_def("Constellation", M, 1, Constants.RARITY_LEGENDARY, {0: 100}, BallVisuals.ShapeType.PLUS),
		create_ball_def("Binary", M, 1, Constants.RARITY_LEGENDARY, {0: 100}, BallVisuals.ShapeType.TRIANGLE),
		create_ball_def("Bloom", M, 1, Constants.RARITY_LEGENDARY, {0: 100}, BallVisuals.ShapeType.PENTAGON),
		create_ball_def("Leech", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.DIAMOND),
		create_ball_def("Rubbery", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.CIRCLE),
		create_ball_def("Phantom", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.HEXAGON),
		create_ball_def("Volatile", M, 1, Constants.RARITY_RARE, {0: 100}, BallVisuals.ShapeType.PLUS),
	]
	var t2: Array = [
		create_ball_def("Split", M, 2, Constants.RARITY_UNCOMMON, {0: 50, 1: 100, 2: 40}, BallVisuals.ShapeType.HEXAGON),
		create_ball_def("Energize", M, 2, Constants.RARITY_UNCOMMON, {0: 50, 1: 100, 2: 40}, BallVisuals.ShapeType.PENTAGON),
		create_ball_def("Explosive", M, 2, Constants.RARITY_LEGENDARY, {0: 40, 1: 100, 2: 40}, BallVisuals.ShapeType.SQUARE),
		create_ball_def("Chain Lightning", M, 2, Constants.RARITY_LEGENDARY, {0: 40, 1: 100, 2: 40}, BallVisuals.ShapeType.STAR),
		create_ball_def("Constellation", M, 2, Constants.RARITY_LEGENDARY, {0: 40, 1: 100, 2: 40}, BallVisuals.ShapeType.PLUS),
		create_ball_def("Binary", M, 2, Constants.RARITY_LEGENDARY, {0: 40, 1: 100, 2: 40}, BallVisuals.ShapeType.TRIANGLE),
		create_ball_def("Bloom", M, 2, Constants.RARITY_LEGENDARY, {0: 40, 1: 100, 2: 40}, BallVisuals.ShapeType.PENTAGON),
		create_ball_def("Leech", M, 2, Constants.RARITY_UNCOMMON, {0: 50, 1: 100, 2: 40}, BallVisuals.ShapeType.DIAMOND),
		create_ball_def("Rubbery", M, 2, Constants.RARITY_UNCOMMON, {0: 50, 1: 100, 2: 40}, BallVisuals.ShapeType.CIRCLE),
		create_ball_def("Phantom", M, 2, Constants.RARITY_UNCOMMON, {0: 50, 1: 100, 2: 40}, BallVisuals.ShapeType.HEXAGON),
		create_ball_def("Volatile", M, 2, Constants.RARITY_RARE, {0: 50, 1: 100, 2: 40}, BallVisuals.ShapeType.PLUS),
	]
	var t3: Array = [
		create_ball_def("Split", M, 3, Constants.RARITY_UNCOMMON, {1: 30, 2: 100}, BallVisuals.ShapeType.HEXAGON),
		create_ball_def("Energize", M, 3, Constants.RARITY_UNCOMMON, {1: 30, 2: 100}, BallVisuals.ShapeType.PENTAGON),
		create_ball_def("Explosive", M, 3, Constants.RARITY_LEGENDARY, {1: 20, 2: 100}, BallVisuals.ShapeType.SQUARE),
		create_ball_def("Chain Lightning", M, 3, Constants.RARITY_LEGENDARY, {1: 20, 2: 100}, BallVisuals.ShapeType.STAR),
		create_ball_def("Constellation", M, 3, Constants.RARITY_LEGENDARY, {1: 20, 2: 100}, BallVisuals.ShapeType.PLUS),
		create_ball_def("Binary", M, 3, Constants.RARITY_LEGENDARY, {1: 20, 2: 100}, BallVisuals.ShapeType.TRIANGLE),
		create_ball_def("Bloom", M, 3, Constants.RARITY_LEGENDARY, {1: 20, 2: 100}, BallVisuals.ShapeType.PENTAGON),
		create_ball_def("Leech", M, 3, Constants.RARITY_UNCOMMON, {1: 30, 2: 100}, BallVisuals.ShapeType.DIAMOND),
		create_ball_def("Rubbery", M, 3, Constants.RARITY_UNCOMMON, {1: 30, 2: 100}, BallVisuals.ShapeType.CIRCLE),
		create_ball_def("Phantom", M, 3, Constants.RARITY_UNCOMMON, {1: 20, 2: 100}, BallVisuals.ShapeType.HEXAGON),
		create_ball_def("Volatile", M, 3, Constants.RARITY_RARE, {1: 20, 2: 100}, BallVisuals.ShapeType.PLUS),
	]
	for d in t1 + t2 + t3:
		list.append(d)
	return list

static func mk(def_name: String, desc: String, uid: StringName, cat: int, ball_t: String = "") -> MajorUpgradeDefinition:
	var u: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	u.display_name = def_name
	u.description = _physical_relic_description(uid, desc)
	u.upgrade_id = StringName(uid)
	u.category = cat
	u.ball_type = ball_t
	return u

static func mk_cross(def_name: String, desc: String, uid: StringName, req_types: Array[String]) -> MajorUpgradeDefinition:
	var u: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	u.display_name = def_name
	u.description = _physical_relic_description(uid, desc)
	u.upgrade_id = StringName(uid)
	u.category = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
	u.required_ball_types = req_types
	return u

static func mk_boss(def_name: String, desc: String, uid: StringName, req_types: Array[String] = []) -> MajorUpgradeDefinition:
	var u: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	u.display_name = def_name
	u.description = _physical_relic_description(uid, desc)
	u.upgrade_id = StringName(uid)
	u.category = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
	u.required_ball_types = req_types
	return u

static func build_onboard_effect_candidates() -> Array:
	return build_deliberate_relic_candidates()

static func _physical_relic_description(uid: StringName, _legacy_desc: String) -> String:
	if not PolyominoRelicDatabase.is_relic_offerable(uid):
		return PolyominoRelicDatabase.get_retired_relic_label()
	var kinetic: String = PolyominoRelicDatabase.get_relic_kinetic_description(uid)
	var trigger: String = PolyominoRelicDatabase.get_relic_activation_requirement(uid)
	var reward: String = PolyominoRelicDatabase.get_relic_reward_description(uid)
	if kinetic.is_empty() and trigger.is_empty() and reward.is_empty():
		return "Physical pinball relic. Complete its on-board device goal."
	return "Physical device: %s\nTrigger: %s\nReward: %s" % [kinetic, trigger, reward]

static func build_wall_break_candidates() -> Dictionary:
	var deliberate: Array = build_deliberate_relic_candidates()
	var cross: Array = []
	var ball_enh: Array = []
	var board_cand: Array = []
	for candidate in deliberate:
		var tier: int = PolyominoRelicDatabase.get_relic_tier(candidate.upgrade_id)
		if tier >= 3:
			cross.append(candidate)
		elif tier == 2:
			ball_enh.append(candidate)
		else:
			board_cand.append(candidate)
	return {"cross_link": cross, "ball_enhancement": ball_enh, "board": board_cand}

static func _build_legacy_wall_break_candidates() -> Dictionary:
	var cross: Array = []
	var ball_enh: Array = []
	var board_cand: Array = []
	var cat_b: int = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
	var cat_board: int = MajorUpgradeDefinition.Category.BOARD_UPGRADE

	cross.append(mk_cross("Supernova Peg", "Supernova: Triggers a large explosion that damages nearby pegs.", &"supernova_peg", ["Explosive", "Energize"]))
	cross.append(mk_cross("Chain Conduction", "Chain Lightning: Also strikes every energized peg on the board.", &"chain_conduction", ["Chain Lightning", "Energize"]))
	cross.append(mk_cross("Overcharged Drain", "Drain: Draining an energized peg generates 2× Energy.", &"overcharged_drain", ["Leech", "Energize"]))
	cross.append(mk_cross("Final Arc Detonation", "Chain Lightning: Final lightning jump triggers a small explosion.", &"final_arc_detonation", ["Chain Lightning", "Explosive"]))
	cross.append(mk_cross("Energy Collapse", "On Break (3+ Drain): Triggers an explosion at that peg.", &"energy_collapse", ["Leech", "Explosive"]))
	cross.append(mk_cross("Shrapnel Split", "Split: Fragment hitting a Bomb Peg doubles explosion radius.", &"shrapnel_split", ["Split", "Explosive"]))
	cross.append(mk_cross("Energized Fragments", "Split: Fragment hits apply 1 Energize stack to pegs.", &"energized_fragments", ["Split", "Energize"]))
	cross.append(mk_cross("Arc Twins", "Split: Chain Lightning can jump between both active fragments.", &"arc_twins", ["Split", "Chain Lightning"]))
	cross.append(mk_cross("Phase Siphon", "Phantom: Passing through energized pegs drains 1 stack for +50% Energy.", &"phase_siphon", ["Phantom", "Energize"]))
	cross.append(mk_cross("Phase Detonation", "Drop End (5+ passes): Phantom triggers an explosion at the bottom.", &"phase_detonation", ["Phantom", "Explosive"]))
	cross.append(mk_cross("Spectral Conduit", "Phantom: Leaves a trail that Chain Lightning can jump through.", &"spectral_conduit", ["Phantom", "Chain Lightning"]))
	cross.append(mk_cross("Impact Burst", "Rubbery: High-speed hits trigger small explosions. (Max 2 stacks)", &"impact_burst", ["Rubbery", "Explosive"]))
	cross.append(mk_cross("Kinetic Charge", "Rubbery: Bouncing off energized pegs boosts speed and grants +3 Energy.", &"kinetic_charge", ["Rubbery", "Energize"]))
	cross.append(mk_cross("Static Bounce", "Overdrive 4 (Rubbery): Discharges Chain Lightning from that peg.", &"static_bounce", ["Rubbery", "Chain Lightning"]))
	cross.append(mk_cross("Parasitic Arc", "Chain Lightning: Striking a peg with Drain spreads Drain across the chain.", &"parasitic_arc", ["Leech", "Chain Lightning"]))
	cross.append(mk_cross("Draining Fragments", "Split: Fragment hits apply short Drain to pegs.", &"draining_fragments", ["Leech", "Split"]))
	cross.append(mk_cross("Resonant Bounce", "Plain: Hits on energized pegs grant +1 Energy per Energize stack.", &"resonant_bounce", ["Plain", "Energize"]))
	cross.append(mk_cross("Ricochet Blast", "Overdrive 6 (Plain): Next peg hit triggers an explosion.", &"ricochet_blast", ["Plain", "Explosive"]))
	cross.append(mk_cross("Blast Launch", "Explosions: Blasts near Trampolines launch nearby balls upward.", &"blast_launch", []))
	cross.append(mk_cross("Arc Surge Wrench", "Chain Lightning: Striking a Wrench Peg repairs up to 10 broken pegs.", &"chain_surge_wrench", ["Chain Lightning"]))
	cross.append(mk_cross("Goblin Surge Chute", "Hopper: Returning a ball from the board temporarily widens the hopper.", &"goblin_width_pulse", []))
	cross.append(mk_cross("Magnet Arc Snare", "Chain Lightning: Striking a Magnet Peg pulls nearby balls toward it.", &"magnet_arc_snare", ["Chain Lightning"]))
	cross.append(mk_cross("Spark Trampoline", "Chain Lightning: Striking a Trampoline grants extra upward lift to balls.", &"spark_trampoline", ["Chain Lightning"]))

	ball_enh.append(mk("Hyper Elastic", "Rubbery: Upward bounces boost ball speed. (Max 1 stack)", &"hyper_elastic", cat_b, "Rubbery"))
	ball_enh.append(mk("Overdrive Hits", "Overdrive 6: Later bounces grant 2× Energy. (Max 1 stack)", &"overdrive_hits", cat_b, ""))
	ball_enh.append(mk("Overclock Network", "Energize: Energized pegs gain +1 durability per adjacent energized peg.", &"overclock_network", cat_b, "Energize"))
	ball_enh.append(mk("Spreading Rot", "On Expiry (Drain): Spreads short Drain to adjacent pegs. (Max 1 stack)", &"spreading_rot", cat_b, "Leech"))
	ball_enh.append(mk("Cluster Grenade", "Explosions: Spawns 1–2 secondary explosions. (Max 1 stack)", &"cluster_grenade", cat_b, "Explosive"))
	ball_enh.append(mk("Blast Lift", "Explosions: Blasts push nearby balls upward with extra force.", &"blast_lift", cat_b, "Explosive"))
	ball_enh.append(mk("Fragmentation Tag", "Explosions: Blast damage counts as +1 extra peg hit for Energy.", &"fragmentation_tag", cat_b, "Explosive"))
	ball_enh.append(mk("Storm Feedback", "Chain Lightning: Arcs between energized pegs boost peg Energy. (Max 1 stack)", &"storm_feedback", cat_b, "Chain Lightning"))
	ball_enh.append(mk("Overcurrent Surge", "Chain Lightning: Striking the same peg twice resets its HP and pays Energy. (Max 1 stack)", &"overcurrent_surge", cat_b, "Chain Lightning"))
	ball_enh.append(mk("Fragment Echo", "Drop End (Split): Fragment exiting bottom spawns 1 new ball at top. (Max 1 stack)", &"fragment_echo", cat_b, "Split"))
	ball_enh.append(mk("Mass Cascade", "Split: Collision between two fragments temporarily boosts peg Energy. (Max 1 stack)", &"mass_cascade", cat_b, "Split"))
	ball_enh.append(mk("Ghost Trail", "Phantom: Leaves a trail; pegs in trail grant +1 Energy when hit. (Max 1 stack)", &"ghost_trail", cat_b, "Phantom"))
	ball_enh.append(mk("Phase Instability", "Drop End (0 hits): Phantom respawns at top with bonus speed. (Max 1 stack)", &"phase_instability", cat_b, "Phantom"))
	ball_enh.append(mk("Plunderer's Cut", "Treasure Chests: Opening a chest grants 1 random ball. (Max 1 stack)", &"chest_random_ball", cat_b))

	board_cand.append(mk("Plain Surge", "Plain Balls: +1 Energy per peg hit per stack. (Max 5 stacks)", &"plain_surge", cat_board))
	board_cand.append(mk("Plain Horde", "Plain Balls: +1 Energy per hit per 5 Plain balls in play (max +3). (Max 3 stacks)", &"plain_horde", cat_board))
	board_cand.append(mk("Plain Momentum", "Overdrive 7 (Plain): +1 Energy per hit per stack. (Max 3 stacks)", &"plain_momentum", cat_board))
	board_cand.append(mk("Volt Primer", "Energize: Gaining Energize discounts next Cannon shot by 5 Energy. (Max 1 stack)", &"volt_primer", cat_board))

	return {
		"cross_link": cross,
		"ball_enhancement": ball_enh,
		"board": board_cand
	}

static func build_boss_candidates() -> Array:
	return build_deliberate_relic_candidates()

static func build_deliberate_relic_candidates() -> Array:
	var list: Array = []
	var cat: Dictionary = DeliberateRelicCatalog.get_catalog()
	for id in DeliberateRelicCatalog.get_all_ids():
		var d: Dictionary = cat[id]
		var u: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
		u.upgrade_id = id
		u.display_name = str(d.get("display_name", id))
		u.description = _physical_relic_description(id, "")
		var tier: int = int(d.get("tier", 1))
		if tier >= 3:
			u.category = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
		else:
			u.category = MajorUpgradeDefinition.Category.BOARD_UPGRADE
		list.append(u)
	return list

static func get_peg_unlock_count(kind: String) -> int:
	if not GameState:
		return 0
	match kind:
		"bomb": return GameState.bomb_peg_count
		"trampoline": return GameState.trampoline_peg_count
		"goblin_reset": return GameState.goblin_reset_node_count
		"gold": return GameState.gold_peg_count
		"splitter": return GameState.splitter_peg_count
		"eternal": return GameState.eternal_peg_count
		"extreme_bouncer": return GameState.extreme_bouncer_peg_count
		"magnet": return GameState.magnet_peg_count
		"lucky_gold": return GameState.lucky_gold_peg_count
		"phase": return GameState.phase_peg_count
		"wrench": return GameState.wrench_peg_count
		"gravity_well": return GameState.gravity_well_peg_count
		_: return 0

static func decrement_peg_unlock_count(kind: String) -> void:
	if not GameState:
		return
	match kind:
		"bomb": GameState.bomb_peg_count = maxi(0, GameState.bomb_peg_count - 1)
		"trampoline": GameState.trampoline_peg_count = maxi(0, GameState.trampoline_peg_count - 1)
		"goblin_reset": GameState.goblin_reset_node_count = maxi(0, GameState.goblin_reset_node_count - 1)
		"gold": GameState.gold_peg_count = maxi(0, GameState.gold_peg_count - 1)
		"splitter": GameState.splitter_peg_count = maxi(0, GameState.splitter_peg_count - 1)
		"eternal": GameState.eternal_peg_count = maxi(0, GameState.eternal_peg_count - 1)
		"extreme_bouncer": GameState.extreme_bouncer_peg_count = maxi(0, GameState.extreme_bouncer_peg_count - 1)
		"magnet": GameState.magnet_peg_count = maxi(0, GameState.magnet_peg_count - 1)
		"lucky_gold": GameState.lucky_gold_peg_count = maxi(0, GameState.lucky_gold_peg_count - 1)
		"phase": GameState.phase_peg_count = maxi(0, GameState.phase_peg_count - 1)
		"wrench": GameState.wrench_peg_count = maxi(0, GameState.wrench_peg_count - 1)
		"gravity_well": GameState.gravity_well_peg_count = maxi(0, GameState.gravity_well_peg_count - 1)
		_: pass
