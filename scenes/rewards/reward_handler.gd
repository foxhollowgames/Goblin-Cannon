extends Node
## RewardHandler (§6.10). grant_ball_rewards, grant_stat_upgrades; calls simulation/reward_generation only.

var _reward_gen: RewardGeneration
var _hopper: Node
var _game_coordinator: Node
## Slice: cached candidate list (BallDefinition resources) for draft picks.
var _ball_candidates: Array = []
## GDD: wall break = major upgrades (conquest/boss tier), not balls+stats.
var _major_upgrade_candidates: Array = []

func _ready() -> void:
	_reward_gen = RewardGeneration.new(GameState.run_seed)
	var main: Node = get_parent()
	_hopper = main.get_node_or_null("Hopper")
	_game_coordinator = main.get_node_or_null("GameCoordinator")
	_ball_candidates = _build_ball_candidates()
	_major_upgrade_candidates = _build_major_upgrade_candidates()

## GDD §7: Tier 1 (City 1 primary), Tier 2 (City 2 primary), base_energy 20, city_weights. §8: alignments Main/Sidearm/Defense. Rarity 0-5.
func _build_ball_candidates() -> Array:
	var list: Array = []
	# Tier 1 – City 1 primary (slice). Each ability has a unique shape (BallVisuals.ShapeType).
	# Status effect keys match Constants (fire, frozen, lightning). GDD §8: ball abilities apply status on peg hit or ball_reached_bottom.
	var fire: Dictionary = { "fire": 1 }
	var frozen: Dictionary = { "frozen": 1 }
	var lightning: Dictionary = { "lightning": 1 }
	# GDD: Split and Energize are additional ball abilities (alignment randomized at pick time).
	var t1: Array = [
		_create_ball_def("Bounce", Constants.ALIGNMENT_MAIN, 1, Constants.RARITY_COMMON, {0: 100}, BallVisuals.ShapeType.CIRCLE),
		_create_ball_def("Flame", Constants.ALIGNMENT_SIDEARM, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.TRIANGLE, fire),
		_create_ball_def("Frost", Constants.ALIGNMENT_DEFENSE, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.DIAMOND, frozen),
		_create_ball_def("Spark", Constants.ALIGNMENT_MAIN, 1, 2, {0: 100}, BallVisuals.ShapeType.SQUARE, lightning),  # Rare
		_create_ball_def("Ember", Constants.ALIGNMENT_SIDEARM, 1, Constants.RARITY_COMMON, {0: 100}, BallVisuals.ShapeType.PENTAGON, fire),
		_create_ball_def("Chill", Constants.ALIGNMENT_DEFENSE, 1, 2, {0: 100}, BallVisuals.ShapeType.HEXAGON, frozen),  # Rare
		_create_ball_def("Bolt", Constants.ALIGNMENT_MAIN, 1, 3, {0: 80}, BallVisuals.ShapeType.STAR, lightning),  # Purple
		_create_ball_def("Flare", Constants.ALIGNMENT_SIDEARM, 1, 3, {0: 80}, BallVisuals.ShapeType.PLUS, fire),
		_create_ball_def("Ward", Constants.ALIGNMENT_DEFENSE, 1, 3, {0: 80}, BallVisuals.ShapeType.CIRCLE),
		_create_ball_def("Split", Constants.ALIGNMENT_MAIN, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.HEXAGON),  # GDD: split-style energy
		_create_ball_def("Energize", Constants.ALIGNMENT_MAIN, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.PENTAGON),  # GDD: bonus energy
		_create_ball_def("Explosive", Constants.ALIGNMENT_SIDEARM, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.SQUARE),  # GDD: area hit; Uncommon so offered in City 0
		_create_ball_def("Chain Lightning", Constants.ALIGNMENT_MAIN, 1, Constants.RARITY_UNCOMMON, {0: 100}, BallVisuals.ShapeType.STAR),  # GDD: chain + lightning; Uncommon so offered in City 0
	]
	# Tier 2
	var t2: Array = [
		_create_ball_def("Surge", Constants.ALIGNMENT_MAIN, 2, 2, {0: 50, 1: 100}, BallVisuals.ShapeType.TRIANGLE, lightning),
		_create_ball_def("Blaze", Constants.ALIGNMENT_SIDEARM, 2, Constants.RARITY_EPIC, {0: 50, 1: 100}, BallVisuals.ShapeType.DIAMOND, fire),
		_create_ball_def("Aegis", Constants.ALIGNMENT_DEFENSE, 2, Constants.RARITY_EPIC, {0: 50, 1: 100}, BallVisuals.ShapeType.SQUARE),
		_create_ball_def("Volt", Constants.ALIGNMENT_MAIN, 2, 4, {0: 40, 1: 100}, BallVisuals.ShapeType.PENTAGON, lightning),  # Orange
		_create_ball_def("Inferno", Constants.ALIGNMENT_SIDEARM, 2, 4, {0: 40, 1: 100}, BallVisuals.ShapeType.HEXAGON, fire),
		_create_ball_def("Glacier", Constants.ALIGNMENT_DEFENSE, 2, 4, {0: 40, 1: 100}, BallVisuals.ShapeType.STAR, frozen),
		_create_ball_def("Split", Constants.ALIGNMENT_MAIN, 2, 2, {0: 50, 1: 100}, BallVisuals.ShapeType.HEXAGON),  # GDD: Tier 2 variant
		_create_ball_def("Energize", Constants.ALIGNMENT_MAIN, 2, 2, {0: 50, 1: 100}, BallVisuals.ShapeType.PENTAGON),  # GDD: Tier 2 variant
		_create_ball_def("Explosive", Constants.ALIGNMENT_SIDEARM, 2, 3, {0: 40, 1: 100}, BallVisuals.ShapeType.SQUARE),
		_create_ball_def("Chain Lightning", Constants.ALIGNMENT_MAIN, 2, 3, {0: 40, 1: 100}, BallVisuals.ShapeType.STAR),
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

## GDD: wall break rewards = major upgrades (conquest tier). Returns N picks for major draft UI.
func get_major_upgrade_picks(count: int) -> Array:
	return _reward_gen.pick_major_upgrades(_major_upgrade_candidates, count)

func _build_major_upgrade_candidates() -> Array:
	var list: Array = []
	var u: MajorUpgradeDefinition
	u = MajorUpgradeDefinition.new()
	u.display_name = "Bonus Balls"
	u.description = "Add 5 balls to your reserve."
	u.upgrade_id = &"bonus_balls"
	list.append(u)
	u = MajorUpgradeDefinition.new()
	u.display_name = "Conduit Size"
	u.description = "Release more balls per wave."
	u.upgrade_id = &"conduit_size"
	list.append(u)
	u = MajorUpgradeDefinition.new()
	u.display_name = "Cannon Charge"
	u.description = "Main cannon charges faster."
	u.upgrade_id = &"cannon_charge"
	list.append(u)
	u = MajorUpgradeDefinition.new()
	u.display_name = "Fortification"
	u.description = "Next wall starts with bonus HP."
	u.upgrade_id = &"fortification"
	list.append(u)
	u = MajorUpgradeDefinition.new()
	u.display_name = "Sidearm Energy"
	u.description = "Sidearm pool holds more energy."
	u.upgrade_id = &"sidearm_energy"
	list.append(u)
	return list

## Returns N random ball picks for the draft UI (city-weighted, same RNG as grant path).
func get_ball_reward_picks(count: int) -> Array:
	var candidates: Array = _get_candidates_for_current_city()
	return _reward_gen.pick_ball_rewards(candidates, count)

## Apply a single draft pick: add one ball with the chosen definition to reserve.
func apply_ball_pick(pick: Resource) -> void:
	_apply_ball_to_hopper(pick)

func grant_ball_rewards(count: int) -> void:
	var candidates: Array = _get_candidates_for_current_city()
	var picks: Array = _reward_gen.pick_ball_rewards(candidates, count)
	for p in picks:
		_apply_ball_to_hopper(p)

func grant_stat_upgrades(count: int) -> void:
	pass  # TODO: present 2 stat upgrades

## Apply chosen major upgrade (wall break / conquest). GDD: major upgrades, not same as milestone.
func apply_major_upgrade(pick: Resource) -> void:
	if not pick is MajorUpgradeDefinition:
		return
	var def: MajorUpgradeDefinition = pick as MajorUpgradeDefinition
	match def.upgrade_id:
		&"bonus_balls":
			if _game_coordinator and _game_coordinator.has_method("add_balls_to_reserve"):
				_game_coordinator.add_balls_to_reserve(5)
		&"conduit_size":
			pass  # TODO: Conduit config +1 release per wave
		&"cannon_charge":
			pass  # TODO: Main cannon charge rate upgrade
		&"fortification":
			pass  # TODO: Next wall bonus HP
		&"sidearm_energy":
			pass  # TODO: Sidearm pool cap upgrade
		_:
			pass

func _apply_ball_to_hopper(pick: Variant) -> void:
	if pick is Resource and _hopper and _hopper.has_method("add_balls_with_definition"):
		var in_hopper: int = _hopper.get_stored_ball_count() if _hopper.has_method("get_stored_ball_count") else 0
		const HOPPER_MAX: int = 100
		if in_hopper < HOPPER_MAX:
			_hopper.add_balls_with_definition(1, pick)
			return
	if _game_coordinator and _game_coordinator.has_method("add_balls_to_reserve"):
		_game_coordinator.add_balls_to_reserve(1)
	elif _hopper and _hopper.has_method("add_balls"):
		_hopper.add_balls(1)
