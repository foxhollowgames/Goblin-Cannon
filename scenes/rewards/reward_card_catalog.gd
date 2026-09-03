class_name RewardCardCatalog
extends RefCounted
## Static catalog definition builders for RewardHandler candidates.

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
	u.description = desc
	u.upgrade_id = StringName(uid)
	u.category = cat
	u.ball_type = ball_t
	return u

static func mk_cross(def_name: String, desc: String, uid: StringName, req_types: Array[String]) -> MajorUpgradeDefinition:
	var u: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	u.display_name = def_name
	u.description = desc
	u.upgrade_id = StringName(uid)
	u.category = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
	u.required_ball_types = req_types
	return u

static func mk_boss(def_name: String, desc: String, uid: StringName, req_types: Array[String] = []) -> MajorUpgradeDefinition:
	var u: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	u.display_name = def_name
	u.description = desc
	u.upgrade_id = StringName(uid)
	u.category = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
	u.required_ball_types = req_types
	return u

static func build_onboard_effect_candidates() -> Array:
	var list: Array = []
	var cat_on: int = MajorUpgradeDefinition.Category.ONBOARD_PASSIVE
	list.append(mk("Bigger Blasts", "Explosions: Blast radius +1.", &"explosion_radius", cat_on))
	list.append(mk("More Explosion Hits", "Explosions: Damages +1 additional peg.", &"explosion_peg_hit_count", cat_on))
	list.append(mk("Stronger Blast Push", "Explosions: +25% push force on nearby balls.", &"explosion_impulse", cat_on))
	list.append(mk("+1 Chain Jump", "Chain Lightning: +1 lightning jump arc.", &"chain_arc", cat_on))
	list.append(mk("Longer Chains", "Chain Lightning: Increases jump distance between pegs.", &"chain_range", cat_on))
	list.append(mk("Deeper Energize", "Energize: Maximum peg stacks +1.", &"max_energize_stacks", cat_on))
	list.append(mk("Slower Energize Fade", "Energize: Decays 15% slower on pegs.", &"energize_decays_slower", cat_on))
	list.append(mk("Fast Heal (Energized)", "Energize: Energized pegs repair +20% faster.", &"energized_pegs_repair_faster", cat_on))
	list.append(mk("Tough Pegs", "All Pegs: Durability +1 hit.", &"global_peg_durability", cat_on))
	list.append(mk("Faster Peg Recovery", "All Pegs: Broken pegs recover +15% faster.", &"peg_recovery_speed", cat_on))
	list.append(mk("Devastating Barrage", "Main Cannon: +10 damage per shot. (Max 1 stack)", &"devastating_barrage", cat_on))
	list.append(mk("Compressed Charge", "Main Cannon: Requires less Energy to fire. (Max 1 stack)", &"compressed_charge", cat_on))
	list.append(mk("Leech Drain Up", "Drain: +1 Energy drained per second per leeched peg.", &"chest_leech_drain", cat_on))
	list.append(mk("Longer Leech", "Drain: Duration +1 second.", &"chest_leech_duration", cat_on))
	list.append(mk("Phantom Energy", "Phantom: +5% Energy generated per peg pass.", &"chest_phantom_energy", cat_on))
	list.append(mk("Rubbery Energy", "Rubbery: +5% Energy generated per peg hit.", &"chest_rubbery_energy", cat_on))
	list.append(mk("Plain Energy", "Plain: +5% Energy generated per peg hit.", &"chest_bounce_energy", cat_on))
	list.append(mk("Split Energy", "Split: +5% Energy generated per fragment peg hit.", &"chest_split_energy", cat_on))
	return list

static func build_wall_break_candidates() -> Dictionary:
	var cross: Array = []
	var ball_enh: Array = []
	var board_cand: Array = []
	var cat_b: int = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
	var cat_board: int = MajorUpgradeDefinition.Category.BOARD_UPGRADE

	cross.append(mk_cross("Explosions Apply Energize", "Explosions: Applies 1 Energize stack to all damaged pegs.", &"explosions_apply_energize", ["Explosive", "Energize"]))
	cross.append(mk_cross("Supernova Peg", "Supernova: Triggers a large explosion that damages nearby pegs.", &"supernova_peg", ["Explosive", "Energize"]))
	cross.append(mk_cross("Chain Hits Apply Energize", "Chain Lightning: Applies 1 Energize stack to struck pegs.", &"chain_hits_apply_energize", ["Chain Lightning", "Energize"]))
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
	var list: Array = []
	list.append(mk_boss("Cascade Reactor", "Supernova: Chain Lightning automatically strikes every peg with Drain.", &"cascade_reactor", ["Energize", "Chain Lightning", "Leech"]))
	list.append(mk_boss("Perpetual Engine", "On Break (Energized): Spawns 1 Phantom ball at the top of the board.", &"perpetual_engine", ["Energize", "Phantom"]))
	list.append(mk_boss("Storm of Fragments", "Split: Fragment hitting 3+ energized pegs fires Chain Lightning from each.", &"storm_of_fragments", ["Split", "Energize", "Chain Lightning"]))
	list.append(mk_boss("Explosive Contagion", "Explosions: Each damaged peg gains 1 stack of Drain.", &"explosive_contagion", ["Explosive", "Leech"]))
	list.append(mk_boss("Overdrive Cascade", "Overdrive 5: All balls gain +1 Energy per hit for 3 seconds.", &"overdrive_cascade", []))
	list.append(mk_boss("Superconductor", "Chain Lightning: A second chain starts from the farthest energized peg.", &"superconductor", ["Energize", "Chain Lightning"]))
	list.append(mk_boss("Leech Singularity", "Drain (3 stacks + Energize): Drain ticks damage the peg and neighbors.", &"leech_singularity", ["Leech", "Energize"]))
	list.append(mk_boss("Phantom Resonance", "Phantom: Passing through recently zapped pegs grants 2× Energy.", &"phantom_resonance", ["Phantom", "Chain Lightning"]))
	list.append(mk_boss("Rubber Storm", "Rubbery (Max Speed): Discharges Chain Lightning on every bounce.", &"rubber_storm", ["Rubbery", "Chain Lightning"]))
	list.append(mk_boss("Fragment Swarm", "Split: Divides into 3 fragments. Fragments can split again on Bomb Pegs.", &"fragment_swarm", ["Split", "Explosive"]))
	list.append(mk_boss("Goblin Width Tempest", "Hopper: Returning a ball greatly expands hopper width for longer.", &"goblin_width_tempest", []))
	list.append(mk_boss("Echoes of the Wrench", "Wrench: Arc Surge Wrench repairs +5 additional broken pegs.", &"echoes_of_wrench", ["Chain Lightning"]))
	list.append(mk_boss("Stormgrid Coupling", "Magnet Peg: +60% pull force and stabilizes ball motion.", &"stormgrid_coupling", ["Chain Lightning"]))
	list.append(mk_boss("Blood Tithe", "Drain: Drains +1 additional Energy per second per leeched peg.", &"blood_tithe", ["Leech"]))
	list.append(mk_boss("Crown Ricochet", "Overdrive 5 (Plain): Later bounces grant +2 Energy per peg hit.", &"crown_ricochet", ["Plain"]))
	list.append(mk_boss("Twin Mandate", "Split: +18% Energy generated from all fragment peg hits.", &"twin_mandate", ["Split"]))
	list.append(mk_boss("Velocity Dividend", "Rubbery (High Speed): Peg hits grant +3 Energy without lightning.", &"velocity_dividend", ["Rubbery"]))
	list.append(mk_boss("Phase Sovereign", "Phantom: +22% Energy generated from all peg passes.", &"phase_sovereign", ["Phantom"]))
	list.append(mk_boss("Resonant Well", "Energize: All hits on energized pegs grant +2 Energy.", &"resonant_well", ["Energize"]))
	list.append(mk_boss("Renewal Pact", "All Pegs: Broken pegs recover +12% faster.", &"renewal_pact", []))
	list.append(mk_boss("Gilded Covenant", "Gold Pegs: Hits on Gold or Lucky Gold pegs award +1 run Gold.", &"gilded_covenant", []))
	list.append(mk_boss("Iron Bloom", "Magnet Peg: Ambient magnetic pull strength +35%.", &"iron_bloom", []))
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
