class_name RewardGeneration
extends RefCounted
## Only place that may use RNG for rewards (§1.11). Candidate list, shuffle, take first N.
## RewardHandler calls into this; nodes never call rand* directly.
## Seed from GameState.run_seed; use separate stream (e.g. reward_rng).

var _rng: RandomNumberGenerator

func _init(seed_value: int = 0) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value

func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value

## Build candidate list from tier weights, shuffle, return first N unique (for ball picks).
func pick_ball_rewards(candidates: Array, count: int) -> Array:
	if candidates.is_empty() or count <= 0:
		return []
	var shuffled: Array = candidates.duplicate()
	shuffle_array(shuffled)
	var out: Array = []
	var seen: Dictionary = {}
	for c in shuffled:
		if out.size() >= count:
			break
		# Resource.get() takes one arg only; use instance as key for Resources.
		var id_key = c.get("id", c) if c is Dictionary else c
		if not seen.get(id_key, false):
			seen[id_key] = true
			# GDD §8: randomize alignment per pick so fire/frost/lightning can appear as Main, Sidearm, or Defense.
			var pick = c
			if c is BallDefinition:
				pick = c.duplicate(true)
				(pick as BallDefinition).alignment = _rng.randi() % 3  # 0=Main, 1=Sidearm, 2=Defense
			out.append(pick)
	return out

## All stat upgrade ids for milestone draft. Must match RewardHandler.apply_stat_upgrade and draft panel STAT_DISPLAY.
const MILESTONE_STAT_IDS: Array[String] = [
	"main_charge", "sidearm_cap", "shield_cap",
	"health_max", "shield_max",
	"door_interval", "door_duration",
	"cannon_damage", "cannon_energy"
]

## Rarity per stat: Common (0) = HP/shield/pool, Uncommon (1) = energy per ball / cannon, Rare (2) = hopper. Used for weighting and display.
const STAT_RARITY: Dictionary = {
	"health_max": 0, "shield_max": 0, "shield_cap": 0, "sidearm_cap": 0,  # Common
	"main_charge": 1, "cannon_damage": 1, "cannon_energy": 1,  # Uncommon
	"door_interval": 2, "door_duration": 2  # Rare
}

## Weight copies per stat in pool (common appears more often). Index = rarity tier.
const STAT_WEIGHT_BY_RARITY: Array[int] = [3, 2, 1]  # Common x3, Uncommon x2, Rare x1

## GDD §12: 5 milestone options; on average 3 ball / 2 stat, but with variance (sometimes 5 balls or 5 stats). Random order. No identical options.
## Balls: unique by ability_name+alignment. Stats: distinct stat types.
func pick_milestone_options(ball_candidates: Array, total_count: int = 5) -> Array:
	# Variance: ball_count 0..5 (mean ~2.5); stat_count = 5 - ball_count. Allows "5 balls" or "5 stats" sometimes.
	var ball_count: int = _rng.randi() % (total_count + 1)
	var stat_count: int = total_count - ball_count
	var out: Array = []
	# Ball options: take up to ball_count unique by ability+alignment
	var ball_pool: Array = pick_ball_rewards(ball_candidates, mini(ball_candidates.size(), 12))
	var seen_ball_key: Dictionary = {}
	var ball_picks: Array = []
	for b in ball_pool:
		if ball_picks.size() >= ball_count:
			break
		var def: BallDefinition = b as BallDefinition
		var key: String = "%s_%d" % [def.ability_name if def else "", def.alignment if def else 0]
		if not seen_ball_key.get(key, false):
			seen_ball_key[key] = true
			ball_picks.append(b)
	# If we couldn't fill ball_count (e.g. few candidates), give the rest to stats
	var actual_ball: int = ball_picks.size()
	if actual_ball < ball_count:
		stat_count += (ball_count - actual_ball)
	for b in ball_picks:
		var opt: MilestoneOption = MilestoneOption.new()
		opt.option_type = MilestoneOption.Type.BALL
		opt.ball_definition = b as BallDefinition
		out.append(opt)
	# Stat options: weighted pool by rarity, pick up to stat_count distinct
	var weighted_stat_pool: Array = []
	for stat_id in MILESTONE_STAT_IDS:
		var r: int = STAT_RARITY.get(stat_id, 0)
		var w: int = STAT_WEIGHT_BY_RARITY[r] if r < STAT_WEIGHT_BY_RARITY.size() else 1
		for _j in range(w):
			weighted_stat_pool.append(stat_id)
	shuffle_array(weighted_stat_pool)
	var seen_stat: Dictionary = {}
	var stat_picks: Array = []
	for sid in weighted_stat_pool:
		if stat_picks.size() >= stat_count:
			break
		if not seen_stat.get(sid, false):
			seen_stat[sid] = true
			stat_picks.append(sid)
	for sid in stat_picks:
		var opt: MilestoneOption = MilestoneOption.new()
		opt.option_type = MilestoneOption.Type.STAT
		opt.stat_id = sid as String
		opt.rarity = STAT_RARITY.get(sid, 0)
		out.append(opt)
	shuffle_array(out)
	return out

## Same as ball picks: shuffle, return first N (for major upgrade draft on wall break).
func pick_major_upgrades(candidates: Array, count: int) -> Array:
	if candidates.is_empty() or count <= 0:
		return []
	var shuffled: Array = candidates.duplicate()
	shuffle_array(shuffled)
	var out: Array = []
	var seen_ids: Dictionary = {}
	for c in shuffled:
		if out.size() >= count:
			break
		var id_key: StringName = c.upgrade_id if c is MajorUpgradeDefinition else (c.get("upgrade_id", c) if c is Dictionary else &"")
		if id_key.is_empty():
			id_key = StringName(str(c))
		if not seen_ids.get(id_key, false):
			seen_ids[id_key] = true
			out.append(c)
	return out

## Wall break: always 1 Sidearm + 1 Ball Enhancement + 1 Board (including Tag). Pick one from each list, shuffle order.
func pick_wall_break_trio(sidearm_candidates: Array, ball_candidates: Array, board_candidates: Array) -> Array:
	var out: Array = []
	if not sidearm_candidates.is_empty():
		out.append(sidearm_candidates[_rng.randi() % sidearm_candidates.size()])
	if not ball_candidates.is_empty():
		out.append(ball_candidates[_rng.randi() % ball_candidates.size()])
	if not board_candidates.is_empty():
		out.append(board_candidates[_rng.randi() % board_candidates.size()])
	shuffle_array(out)
	return out

func shuffle_array(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi() % (i + 1)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t

## Random int in [min_val, max_val] inclusive. Used for stat upgrade picks.
func randi_range(min_val: int, max_val: int) -> int:
	if min_val > max_val:
		return min_val
	return _rng.randi() % (max_val - min_val + 1) + min_val
