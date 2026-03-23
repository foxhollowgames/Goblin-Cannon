extends Node
## RewardHandler (§6.10). grant_ball_rewards, grant_stat_upgrades; calls simulation/reward_generation only.

var _reward_gen: RewardGeneration
var _hopper: Node
var _game_coordinator: Node
var _ball_candidates: Array = []
var _ball_enhancement_candidates: Array = []
var _board_candidates: Array = []

func _ready() -> void:
	_reward_gen = RewardGeneration.new(GameState.run_seed)
	var main: Node = get_parent()
	_hopper = main.get_node_or_null("Hopper")
	_game_coordinator = main.get_node_or_null("GameCoordinator")
	_ball_candidates = _build_ball_candidates()
	_build_wall_break_candidates()

func _build_ball_candidates() -> Array:
	var list: Array = []
	var M: int = Constants.ALIGNMENT_MAIN
	var t1: Array = [
		_create_ball_def("Bounce", M, 1, Constants.RARITY_COMMON, {0: 100}, BallVisuals.ShapeType.CIRCLE),
		_create_ball_def("Split", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.HEXAGON),
		_create_ball_def("Energize", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.PENTAGON),
		_create_ball_def("Explosive", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.SQUARE),
		_create_ball_def("Chain Lightning", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.STAR),
		_create_ball_def("Leech", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.DIAMOND),
		_create_ball_def("Rubbery", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.CIRCLE),
		_create_ball_def("Phantom", M, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.HEXAGON),
	]
	var t2: Array = [
		_create_ball_def("Split", M, 2, 2, {0: 50, 1: 100}, BallVisuals.ShapeType.HEXAGON),
		_create_ball_def("Energize", M, 2, 2, {0: 50, 1: 100}, BallVisuals.ShapeType.PENTAGON),
		_create_ball_def("Explosive", M, 2, 3, {0: 40, 1: 100}, BallVisuals.ShapeType.SQUARE),
		_create_ball_def("Chain Lightning", M, 2, 3, {0: 40, 1: 100}, BallVisuals.ShapeType.STAR),
		_create_ball_def("Leech", M, 2, 2, {0: 50, 1: 100}, BallVisuals.ShapeType.DIAMOND),
		_create_ball_def("Rubbery", M, 2, 2, {0: 50, 1: 100}, BallVisuals.ShapeType.CIRCLE),
		_create_ball_def("Phantom", M, 2, 2, {0: 50, 1: 100}, BallVisuals.ShapeType.HEXAGON),
	]
	for d in t1 + t2:
		list.append(d)
	return list

func _create_ball_def(ability_name: String, alignment: int, tier: int, rarity: int, city_weights: Dictionary, shape_type: int = -1, status_effects: Dictionary = {}) -> BallDefinition:
	var d: BallDefinition = BallDefinition.new()
	d.ability_name = ability_name
	d.alignment = alignment
	d.tier = tier
	d.rarity = rarity
	d.base_energy = 20
	d.city_weights = city_weights
	d.shape_type = shape_type
	d.status_effects = status_effects
	return d

## GDD §7: city-weighted rarity distribution. Build candidate list weighted by current city; only include rarities allowed in this city.
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
		# Fallback: only candidates allowed in this city by rarity (still respect scale)
		for def in _ball_candidates:
			if def is BallDefinition and def.rarity <= max_rarity:
				weighted.append(def)
	return weighted

## GDD §7: rarity scale per city. City 1 = common/uncommon only; City 2 = through purple; City 3 = all rarities.
func _get_max_rarity_for_city(city_id: int) -> int:
	if city_id >= 0 and city_id < Constants.MAX_RARITY_BY_CITY.size():
		return Constants.MAX_RARITY_BY_CITY[city_id]
	return Constants.RARITY_UNCOMMON

## Wall break: pick 3 from ball enhancements + board upgrades. Only offers ball enhancements for types in the run.
func get_major_upgrade_picks(count: int = 3) -> Array:
	var max_stacks_for: Dictionary = {
		&"impact_burst": 2,
		&"hyper_elastic": 1, &"overdrive_hits": 1, &"supernova_peg": 1, &"chain_conduction": 1,
		&"spreading_rot": 1, &"energy_collapse": 1, &"cluster_grenade": 1, &"storm_feedback": 1,
		&"final_arc_detonation": 1, &"overcurrent_surge": 1, &"fragment_echo": 1, &"mass_cascade": 1,
		&"ghost_trail": 1, &"phase_instability": 1
	}
	var pool: Array = []
	for c in _ball_enhancement_candidates:
		var def: MajorUpgradeDefinition = c as MajorUpgradeDefinition
		if not def:
			continue
		if not def.ball_type.is_empty() and not GameState.has_ball_ability_in_run(def.ball_type):
			continue
		var cap: Variant = max_stacks_for.get(def.upgrade_id, -1)
		if cap >= 0 and GameState.get_wall_break_upgrade_stacks(def.upgrade_id) >= cap:
			continue
		pool.append(c)
	for c in _board_candidates:
		pool.append(c)
	return _reward_gen.pick_major_upgrades(pool, count)

func _mk(def_name: String, desc: String, uid: StringName, cat: int, ball_t: String = "") -> MajorUpgradeDefinition:
	var u: MajorUpgradeDefinition = MajorUpgradeDefinition.new()
	u.display_name = def_name
	u.description = desc
	u.upgrade_id = StringName(uid)
	u.category = cat
	u.ball_type = ball_t
	return u

## Wall break pool: Ball Enhancements by type + Board/Tag upgrades.
func _build_wall_break_candidates() -> void:
	var cat_b: int = MajorUpgradeDefinition.Category.BALL_ENHANCEMENT
	var cat_board: int = MajorUpgradeDefinition.Category.BOARD_UPGRADE
	# ——— BALL ENHANCEMENTS (only offered if ball type in bag) ———
	# Rubbery
	_ball_enhancement_candidates.append(_mk("Impact Burst", "Each peg hit creates a small explosion. Max 2 stacks (radius increase).", &"impact_burst", cat_b, "Rubbery"))
	_ball_enhancement_candidates.append(_mk("Hyper Elastic", "Strong upward rebounds grant temporary speed boost and increased peg hit intensity. Max 1 stack.", &"hyper_elastic", cat_b, "Rubbery"))
	# Generic (all balls)
	_ball_enhancement_candidates.append(_mk("Overdrive Hits", "After 5 peg hits in one fall, additional hits generate double energy. Max 1 stack.", &"overdrive_hits", cat_b, ""))
	# Energizer
	_ball_enhancement_candidates.append(_mk("Supernova Peg", "If energized stacks exceed threshold: large explosion, releases bonus energy, hits nearby pegs, pushes balls up, resets durability. Max 1 stack.", &"supernova_peg", cat_b, "Energize"))
	_ball_enhancement_candidates.append(_mk("Chain Conduction", "If an energized peg is hit by chain: chain arcs to all energized pegs (once per chain event). Max 1 stack.", &"chain_conduction", cat_b, "Energize"))
	_ball_enhancement_candidates.append(_mk("Overclock Network", "Energized peg gains +1 durability per adjacent energized peg. No stack cap.", &"overclock_network", cat_b, "Energize"))
	# Leech
	_ball_enhancement_candidates.append(_mk("Overcharged Drain", "Leech on energized peg generates double energy. No hard cap.", &"overcharged_drain", cat_b, "Leech"))
	_ball_enhancement_candidates.append(_mk("Spreading Rot", "When leech expires, applies mini-leech to adjacent pegs. Max 1 stack.", &"spreading_rot", cat_b, "Leech"))
	_ball_enhancement_candidates.append(_mk("Energy Collapse", "If peg with 3+ leech stacks is destroyed: triggers explosion, releases stored leech energy. Max 1 stack.", &"energy_collapse", cat_b, "Leech"))
	# Explosive
	_ball_enhancement_candidates.append(_mk("Cluster Grenade", "Explosion hit spawns 1–2 secondary small explosions. Secondary cannot spawn further clusters. Max 1 stack.", &"cluster_grenade", cat_b, "Explosive"))
	_ball_enhancement_candidates.append(_mk("Blast Lift", "Explosions push nearby balls upward. Stackable (impulse increases).", &"blast_lift", cat_b, "Explosive"))
	_ball_enhancement_candidates.append(_mk("Fragmentation Tag", "Explosion hits generate +1 extra peg hit on affected pegs. Stackable.", &"fragmentation_tag", cat_b, "Explosive"))
	# Chain Lightning
	_ball_enhancement_candidates.append(_mk("Storm Feedback", "Lightning between energized pegs creates temporary field. Balls in field gain +1 peg hit credit. Max 1 stack.", &"storm_feedback", cat_b, "Chain Lightning"))
	_ball_enhancement_candidates.append(_mk("Final Arc Detonation", "Final peg in a chain triggers mini explosion. Max 1 stack.", &"final_arc_detonation", cat_b, "Chain Lightning"))
	_ball_enhancement_candidates.append(_mk("Overcurrent Surge", "If chain hits same peg twice in one sim tick: peg fully refreshes durability, generates energy again. Max 1 stack.", &"overcurrent_surge", cat_b, "Chain Lightning"))
	# Split
	_ball_enhancement_candidates.append(_mk("Fragment Echo", "When fragment reaches bottom: shrinks, floats to top, falls once more. Cannot echo again. Max 1 stack.", &"fragment_echo", cat_b, "Split"))
	_ball_enhancement_candidates.append(_mk("Mass Cascade", "If two fragments collide: temporary bonus peg hit energy. Max 1 stack.", &"mass_cascade", cat_b, "Split"))
	# Phasing (Phantom in code)
	_ball_enhancement_candidates.append(_mk("Ghost Trail", "While phasing: leaves temporary trail; pegs in trail generate +1 energy per hit. Max 1 stack.", &"ghost_trail", cat_b, "Phantom"))
	_ball_enhancement_candidates.append(_mk("Phase Instability", "If phasing ball hits no pegs: re-enters top, gains bonus peg hit credit on next collision. Max 1 stack.", &"phase_instability", cat_b, "Phantom"))
	# ——— TAG UPGRADES (board-level) ———
	_board_candidates.append(_mk("+Explosion Radius", "Explosion tag: increase explosion radius.", &"explosion_radius", cat_board))
	_board_candidates.append(_mk("+Explosion Peg Hit Count", "Explosion tag: increase peg hit count from explosions.", &"explosion_peg_hit_count", cat_board))
	_board_candidates.append(_mk("+Explosion Impulse", "Explosion tag: increase impulse from explosions.", &"explosion_impulse", cat_board))
	_board_candidates.append(_mk("Explosions Apply Energize", "Explosion tag: explosions apply 1 Energize stack.", &"explosions_apply_energize", cat_board))
	_board_candidates.append(_mk("+1 Chain Arc", "Chain tag: +1 chain arc.", &"chain_arc", cat_board))
	_board_candidates.append(_mk("+Chain Range", "Chain tag: increase chain range.", &"chain_range", cat_board))
	_board_candidates.append(_mk("Chain Hits Apply Energize", "Chain tag: chain hits apply 1 Energize stack.", &"chain_hits_apply_energize", cat_board))
	_board_candidates.append(_mk("+Max Energize Stacks per Peg", "Energize: increase max stacks per peg.", &"max_energize_stacks", cat_board))
	_board_candidates.append(_mk("Energize Decays Slower", "Energize: decay slower.", &"energize_decays_slower", cat_board))
	_board_candidates.append(_mk("Energized Pegs Repair Faster", "Energize: energized pegs repair faster.", &"energized_pegs_repair_faster", cat_board))
	# ——— BOARD UPGRADES ———
	_board_candidates.append(_mk("Add Bomb Peg", "Add a bomb peg to the board. Auto-placed.", &"add_bomb_peg", cat_board))
	_board_candidates.append(_mk("Add Trampoline Peg", "Add a trampoline peg to the board. Auto-placed.", &"add_trampoline_peg", cat_board))
	_board_candidates.append(_mk("Add Goblin Reset Node", "Add a Goblin reset node. Auto-placed.", &"add_goblin_reset_node", cat_board))
	_board_candidates.append(_mk("+Global Peg Durability", "Increase global peg durability.", &"global_peg_durability", cat_board))
	_board_candidates.append(_mk("+Peg Recovery Speed", "Pegs recover faster.", &"peg_recovery_speed", cat_board))

## Returns N random ball picks for the draft UI (city-weighted, same RNG as grant path).
func get_ball_reward_picks(count: int) -> Array:
	var candidates: Array = _get_candidates_for_current_city()
	return _reward_gen.pick_ball_rewards(candidates, count)

## GDD §12: 5 milestone options (typical 3 ball + 2 stat), random order. For milestone draft UI.
func get_milestone_reward_picks(count: int = 5) -> Array:
	var candidates: Array = _get_candidates_for_current_city()
	return _reward_gen.pick_milestone_options(candidates, count)

## Apply a single draft pick: add one ball with the chosen definition to reserve.
func apply_ball_pick(pick: Resource) -> void:
	_apply_ball_to_hopper(pick)

## GDD §12: Apply one chosen milestone option (ball or stat). Used when player picks from 5-option draft.
func apply_milestone_pick(option: Resource) -> void:
	if option is MilestoneOption:
		var opt: MilestoneOption = option as MilestoneOption
		if opt.option_type == MilestoneOption.Type.BALL and opt.ball_definition:
			apply_ball_pick(opt.ball_definition)
		elif opt.option_type == MilestoneOption.Type.STAT and not opt.stat_id.is_empty():
			apply_stat_upgrade(opt.stat_id)

## Apply a single stat upgrade.
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
			GameState.cannon_charge_reduction += 2000

func grant_ball_rewards(count: int) -> void:
	var candidates: Array = _get_candidates_for_current_city()
	var picks: Array = _reward_gen.pick_ball_rewards(candidates, count)
	for p in picks:
		_apply_ball_to_hopper(p)

## GDD §12: 2 stat upgrades per milestone. Applies stacking bonuses (main charge +5%, sidearm cap +10%, shield cap +10%).
func grant_stat_upgrades(count: int) -> void:
	if not GameState:
		return
	var options: Array[String] = ["main_charge", "door_interval", "door_duration", "cannon_damage", "cannon_energy"]
	for i in count:
		if options.is_empty():
			break
		var idx: int = _reward_gen.randi_range(0, options.size() - 1) if _reward_gen and options.size() > 0 else 0
		var pick: String = options[idx]
		options.remove_at(idx)
		apply_stat_upgrade(pick)

## Apply chosen major upgrade (wall break / conquest). Stack caps enforced here; board/ball read via GameState.
func apply_major_upgrade(pick: Resource) -> void:
	if not pick is MajorUpgradeDefinition:
		return
	var def: MajorUpgradeDefinition = pick as MajorUpgradeDefinition
	var uid: StringName = def.upgrade_id
	# ——— Ball enhancements (stack caps) ———
	var max_stacks: int = -1
	match uid:
		&"impact_burst": max_stacks = 2
		&"hyper_elastic", &"overdrive_hits", &"supernova_peg", &"chain_conduction", &"spreading_rot", &"energy_collapse": max_stacks = 1
		&"cluster_grenade", &"storm_feedback", &"final_arc_detonation", &"overcurrent_surge": max_stacks = 1
		&"fragment_echo", &"mass_cascade", &"ghost_trail", &"phase_instability": max_stacks = 1
	if max_stacks >= 0:
		if GameState.get_wall_break_upgrade_stacks(uid) < max_stacks:
			GameState.add_wall_break_upgrade(uid, 1)
		return
	# No cap or stackable
	match uid:
		&"overcharged_drain", &"blast_lift", &"fragmentation_tag", &"overclock_network":
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
	if uid == &"explosions_apply_energize":
		GameState.add_wall_break_upgrade(&"explosions_apply_energize", 1)
		return
	if uid == &"chain_arc":
		GameState.chain_arc_bonus += 1
		return
	if uid == &"chain_range":
		GameState.chain_range_bonus += 1
		return
	if uid == &"chain_hits_apply_energize":
		GameState.add_wall_break_upgrade(&"chain_hits_apply_energize", 1)
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
	# ——— Board upgrades ———
	if uid == &"add_bomb_peg":
		GameState.bomb_peg_count += 1
		_tell_board_add_extra_pegs()
		return
	if uid == &"add_trampoline_peg":
		GameState.trampoline_peg_count += 1
		_tell_board_add_extra_pegs()
		return
	if uid == &"add_goblin_reset_node":
		GameState.goblin_reset_node_count += 1
		_tell_board_add_extra_pegs()
		return
	if uid == &"global_peg_durability":
		GameState.global_peg_durability_bonus += 1
		return
	if uid == &"peg_recovery_speed":
		GameState.peg_recovery_speed_scale += 0.15
		return

func _tell_board_add_extra_pegs() -> void:
	var main: Node = get_parent()
	var board: Node = main.get_node_or_null("Board") if main else null
	if board and board.has_method("add_extra_pegs_if_needed"):
		board.add_extra_pegs_if_needed()

func _apply_ball_to_hopper(pick: Variant) -> void:
	if pick is Resource and _hopper and _hopper.has_method("add_balls_with_definition"):
		if pick is BallDefinition:
			GameState.record_ball_ability_in_run((pick as BallDefinition).ability_name)
		var in_hopper: int = _hopper.get_stored_ball_count() if _hopper.has_method("get_stored_ball_count") else 0
		const HOPPER_MAX: int = 100
		if in_hopper < HOPPER_MAX:
			_hopper.add_balls_with_definition(1, pick)
			return
	if _game_coordinator and _game_coordinator.has_method("add_balls_to_reserve"):
		_game_coordinator.add_balls_to_reserve(1)
	elif _hopper and _hopper.has_method("add_balls"):
		_hopper.add_balls(1)
