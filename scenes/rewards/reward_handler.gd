extends Node
## RewardHandler (§6.10). Milestones, wall-break synergies, treasure-chest onboard passives, boss amplifiers.

const PolyominoRelicDatabase = preload("res://resources/polyomino/polyomino_relic_database.gd")
const JunkBoxItem = preload("res://resources/inventory/junk_box_item.gd")

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
	_reward_gen = RewardGeneration.new(GameState.run_seed if GameState else 0)
	var main: Node = get_parent()
	if main:
		_hopper = main.get_node_or_null("Hopper")
		_game_coordinator = main.get_node_or_null("GameCoordinator")
	_ball_candidates = _build_ball_candidates()
	_build_peg_shop_candidates()
	_build_wall_break_candidates()
	_build_onboard_effect_candidates()
	_build_boss_candidates()

func _build_ball_candidates() -> Array:
	return RewardCardCatalog.build_ball_candidates()

func _create_ball_def(ability_name: String, alignment: int, tier: int, rarity: int, city_weights: Dictionary, shape_type: int = -1, status_effects: Dictionary = {}) -> BallDefinition:
	return RewardCardCatalog.create_ball_def(ability_name, alignment, tier, rarity, city_weights, shape_type, status_effects)

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
	return RewardCardCatalog.mk(def_name, desc, uid, cat, ball_t)

func _mk_cross(def_name: String, desc: String, uid: StringName, req_types: Array[String]) -> MajorUpgradeDefinition:
	return RewardCardCatalog.mk_cross(def_name, desc, uid, req_types)

func _mk_boss(def_name: String, desc: String, uid: StringName, req_types: Array[String] = []) -> MajorUpgradeDefinition:
	return RewardCardCatalog.mk_boss(def_name, desc, uid, req_types)

func _build_onboard_effect_candidates() -> void:
	_onboard_effect_candidates = RewardCardCatalog.build_onboard_effect_candidates()

func _build_wall_break_candidates() -> void:
	var res: Dictionary = RewardCardCatalog.build_wall_break_candidates()
	_cross_link_candidates = res.get("cross_link", [])
	_ball_enhancement_candidates = res.get("ball_enhancement", [])
	_board_candidates = res.get("board", [])

func _build_boss_candidates() -> void:
	_boss_candidates = RewardCardCatalog.build_boss_candidates()

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

func _add_relic_to_junk_box(uid: StringName) -> void:
	if GameState and GameState.junk_box != null:
		var item: JunkBoxItem = PolyominoRelicDatabase.create_item_for_relic(uid)
		if item != null:
			GameState.junk_box.add_item_auto(item)

## Apply chosen major upgrade (wall break). Creates and adds the polyomino relic item to the Junk Box.
func apply_major_upgrade(pick: Resource) -> void:
	if not pick is MajorUpgradeDefinition:
		return
	var def: MajorUpgradeDefinition = pick as MajorUpgradeDefinition
	var uid: StringName = def.upgrade_id
	_add_relic_to_junk_box(uid)

## Apply chosen boss amplifier (city completion). Creates and adds the polyomino relic item to the Junk Box.
func apply_boss_upgrade(pick: Resource) -> void:
	if not pick is MajorUpgradeDefinition:
		return
	var def: MajorUpgradeDefinition = pick as MajorUpgradeDefinition
	var uid: StringName = def.upgrade_id
	_add_relic_to_junk_box(uid)

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
	return RewardCardCatalog.get_peg_unlock_count(kind)

func _decrement_peg_unlock_count(kind: String) -> void:
	RewardCardCatalog.decrement_peg_unlock_count(kind)

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
