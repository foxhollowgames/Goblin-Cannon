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
			out.append(c)
	return out

## Plain balls granted when a milestone board event peg is claimed (and by legacy apply_milestone_pick BASIC_BATCH).
## Not offered in the gold milestone shop — pick_milestone_options never inserts a BASIC_BATCH card.
const BASIC_BATCH_SIZE: int = 5

## Milestone shop mix for legacy ball-upgrade callers.
## How many ball-upgrade slots; mean ~= 0.6 * n (n = slots).
const MILESTONE_SHOP_BALL_SHARE: float = 0.6
## Among non-ball slots, chance the flex slot is a peg.
const MILESTONE_SHOP_PEG_FLEX_CHANCE_MULTI: float = 0.42
const MILESTONE_SHOP_PEG_FLEX_CHANCE_SINGLE: float = 0.28

## GDD §12: 5 milestone shop options — ball, peg, or physical relic options.
## rarity_weights: [common%, uncommon%, rare%, epic%] from Constants.milestone_reward_rarity_weights (sums to 100).
## peg_candidates: MilestoneOption templates (PEG_UPGRADE, peg_kind + rarity set). If empty, no peg offers.
## If allow_ball_upgrades is false, the shop returns physical relics and pegs.
func pick_milestone_options(ball_candidates: Array, total_count: int = 5, allow_ball_upgrades: bool = false, peg_candidates: Array = [], rarity_weights: Array = [], max_ball_rarity: int = 5, relic_candidates: Array = [], max_relic_tier: int = 1) -> Array:
	var weights: Array = rarity_weights
	if weights.is_empty():
		weights = [90, 10, 0, 0]
	var after_basic: int = total_count
	var out: Array = []
	var seen_peg_kind: Dictionary = {}

	if not allow_ball_upgrades:
		# Merchant Shop mode: Relics + Pegs only. Zero ball upgrades, zero stats.
		var peg_quota: int = 0
		if not peg_candidates.is_empty() and after_basic > 0:
			if after_basic == 1:
				peg_quota = 1 if _rng.randf() < MILESTONE_SHOP_PEG_FLEX_CHANCE_SINGLE else 0
			else:
				peg_quota = 1 if _rng.randf() < MILESTONE_SHOP_PEG_FLEX_CHANCE_MULTI else 0
		var relic_quota: int = after_basic - peg_quota

		for _i in range(peg_quota):
			var tier_p: int = _roll_milestone_tier(weights)
			var peg_opt: MilestoneOption = _pick_peg_option_for_tier(peg_candidates, tier_p, seen_peg_kind)
			if peg_opt:
				out.append(peg_opt)
			else:
				relic_quota += 1

		var seen_relic_id: Dictionary = {}
		var relic_pool: Array = relic_candidates.duplicate()
		if relic_pool.is_empty():
			var cat: Dictionary = DeliberateRelicCatalog.get_catalog()
			for id in cat:
				var opt: MilestoneOption = MilestoneOption.new()
				opt.option_type = MilestoneOption.Type.RELIC
				opt.relic_id = id
				opt.rarity = int(cat[id].get("tier", 1))
				relic_pool.append(opt)

		for _k in range(relic_quota):
			var rolled_tier: int = _roll_milestone_tier(weights)
			var target_tier: int = _relic_tier_for_roll(rolled_tier, max_relic_tier)
			var r_opt: MilestoneOption = _pick_relic_option_for_tier(relic_pool, target_tier, seen_relic_id, max_relic_tier)
			if r_opt:
				out.append(r_opt)
			elif not peg_candidates.is_empty():
				var tier_p2: int = _roll_milestone_tier(weights)
				var peg_opt2: MilestoneOption = _pick_peg_option_for_tier(peg_candidates, tier_p2, seen_peg_kind)
				if peg_opt2:
					out.append(peg_opt2)

		shuffle_array(out)
		return out

	# Ball upgrade mode: return ordinary ball and peg options only.
	var ball_quota: int = _sample_milestone_ball_quota(after_basic) if not ball_candidates.is_empty() else 0
	var remaining: int = after_basic - ball_quota
	var peg_quota: int = mini(remaining, peg_candidates.size())
	if peg_quota <= 0 and ball_quota < after_basic and not ball_candidates.is_empty():
		ball_quota = after_basic
		remaining = 0
	var seen_ball_key: Dictionary = {}
	var seen_peg_kind_ball_mode: Dictionary = {}
	for _i in ball_quota:
		var tier: int = _roll_milestone_tier(weights)
		var b: BallDefinition = _pick_ball_for_tier(ball_candidates, tier, max_ball_rarity, seen_ball_key)
		if b:
			var ball_opt: MilestoneOption = MilestoneOption.new()
			ball_opt.option_type = MilestoneOption.Type.BALL_UPGRADE
			ball_opt.ball_definition = b
			out.append(ball_opt)
	for _i in peg_quota:
		var tier_p: int = _roll_milestone_tier(weights)
		var peg_opt: MilestoneOption = _pick_peg_option_for_tier(peg_candidates, tier_p, seen_peg_kind_ball_mode)
		if peg_opt:
			out.append(peg_opt)
	shuffle_array(out)
	return out

## Soft count of ball-upgrade cards: mean ~= MILESTONE_SHOP_BALL_SHARE * n, variance so 2–4 balls are common at n=5.
func _sample_milestone_ball_quota(non_basic_slots: int) -> int:
	if non_basic_slots <= 0:
		return 0
	var center: float = MILESTONE_SHOP_BALL_SHARE * float(non_basic_slots)
	var weights: Array = []
	var wsum: float = 0.0
	for b in range(non_basic_slots + 1):
		var d: float = abs(float(b) - center)
		var w: float = 1.0 / (1.0 + d * d * 1.85)
		weights.append(w)
		wsum += w
	var r: float = _rng.randf() * wsum
	var acc: float = 0.0
	for b2 in range(non_basic_slots + 1):
		acc += weights[b2]
		if r <= acc:
			return b2
	return non_basic_slots

func _roll_milestone_tier(weights: Array) -> int:
	var w0: int = int(weights[0]) if weights.size() > 0 else 100
	var w1: int = int(weights[1]) if weights.size() > 1 else 0
	var w2: int = int(weights[2]) if weights.size() > 2 else 0
	var w3: int = int(weights[3]) if weights.size() > 3 else 0
	var total: int = w0 + w1 + w2 + w3
	if total <= 0:
		return 0
	var r: int = _rng.randi() % total
	if r < w0:
		return 0
	r -= w0
	if r < w1:
		return 1
	r -= w1
	if r < w2:
		return 2
	return 3

func _lower_rarity_tier(r: int) -> int:
	if r >= Constants.RARITY_EPIC:
		return Constants.RARITY_RARE
	if r == Constants.RARITY_RARE:
		return Constants.RARITY_UNCOMMON
	if r == Constants.RARITY_UNCOMMON:
		return Constants.RARITY_COMMON
	return -1

func _ball_candidates_have_rarity(ball_candidates: Array, rarity: int) -> bool:
	for c in ball_candidates:
		var def: BallDefinition = c as BallDefinition
		if def and def.rarity == rarity:
			return true
	return false

## Ball shop defs are usually uncommon+; tier "common" still rolls often. Skip COMMON when no defs use it.
func _lower_rarity_tier_for_ball_pool(ball_candidates: Array, target: int) -> int:
	var t: int = _lower_rarity_tier(target)
	if t == Constants.RARITY_COMMON and not _ball_candidates_have_rarity(ball_candidates, Constants.RARITY_COMMON):
		return -1
	return t

func _pick_ball_for_tier(ball_candidates: Array, tier: int, max_city_rarity: int, seen_ball_key: Dictionary) -> BallDefinition:
	var target: int = mini(Constants.milestone_tier_to_rarity_constant(tier), max_city_rarity)
	if target == Constants.RARITY_COMMON and not _ball_candidates_have_rarity(ball_candidates, Constants.RARITY_COMMON):
		target = Constants.RARITY_UNCOMMON
	var pool: Array = []
	for _attempt in range(8):
		pool.clear()
		for c in ball_candidates:
			var def: BallDefinition = c as BallDefinition
			if not def or def.rarity != target:
				continue
			var key: String = "%s_%d" % [def.ability_name, def.alignment]
			if seen_ball_key.get(key, false):
				continue
			pool.append(def)
		if not pool.is_empty():
			break
		target = _lower_rarity_tier_for_ball_pool(ball_candidates, target)
		if target < 0:
			break
	if pool.is_empty():
		return null
	var pick: BallDefinition = pool[_rng.randi() % pool.size()] as BallDefinition
	var k: String = "%s_%d" % [pick.ability_name, pick.alignment]
	seen_ball_key[k] = true
	return pick

func _pick_peg_option_for_tier(peg_templates: Array, tier: int, seen_kind: Dictionary) -> MilestoneOption:
	var target: int = Constants.milestone_tier_to_rarity_constant(tier)
	var pool: Array = []
	for _attempt in range(8):
		pool.clear()
		for p in peg_templates:
			var proto: MilestoneOption = p as MilestoneOption
			if not proto or proto.option_type != MilestoneOption.Type.PEG_UPGRADE:
				continue
			if proto.rarity != target:
				continue
			if proto.peg_kind.is_empty() or seen_kind.get(proto.peg_kind, false):
				continue
			pool.append(proto)
		if not pool.is_empty():
			break
		target = _lower_rarity_tier(target)
		if target < 0:
			break
	if pool.is_empty():
		return null
	var chosen: MilestoneOption = pool[_rng.randi() % pool.size()] as MilestoneOption
	seen_kind[chosen.peg_kind] = true
	return chosen.duplicate() as MilestoneOption

func _pick_relic_option_for_tier(relic_templates: Array, target_tier: int, seen_id: Dictionary, max_tier: int = 1) -> MilestoneOption:
	var tier: int = clampi(target_tier, 1, max_tier)
	var pool: Array = []
	for _attempt in range(4):
		pool.clear()
		for r in relic_templates:
			var proto: MilestoneOption = r as MilestoneOption
			if not proto or proto.option_type != MilestoneOption.Type.RELIC:
				continue
			if proto.rarity != tier:
				continue
			if proto.relic_id.is_empty() or seen_id.get(proto.relic_id, false):
				continue
			pool.append(proto)
		if not pool.is_empty():
			break
		tier = maxi(1, tier - 1)
	if pool.is_empty():
		for r in relic_templates:
			var proto: MilestoneOption = r as MilestoneOption
			if proto and proto.option_type == MilestoneOption.Type.RELIC and not seen_id.get(proto.relic_id, false) and proto.rarity <= max_tier:
				pool.append(proto)
	if pool.is_empty():
		return null
	var chosen: MilestoneOption = pool[_rng.randi() % pool.size()] as MilestoneOption
	seen_id[chosen.relic_id] = true
	return chosen.duplicate() as MilestoneOption


## Weighted unique picks by upgrade_id. If weights.size() != candidates.size(), falls back to shuffle (uniform).
func pick_major_upgrades(candidates: Array, count: int, weights: Array = []) -> Array:
	if candidates.is_empty() or count <= 0:
		return []
	var use_weights: bool = weights.size() == candidates.size()
	if not use_weights:
		var shuffled: Array = candidates.duplicate()
		shuffle_array(shuffled)
		var out_uniform: Array = []
		var seen_uniform: Dictionary = {}
		for c in shuffled:
			if out_uniform.size() >= count:
				break
			var id_key: StringName = c.upgrade_id if c is MajorUpgradeDefinition else (c.get("upgrade_id", c) if c is Dictionary else &"")
			if id_key.is_empty():
				id_key = StringName(str(c))
			if not seen_uniform.get(id_key, false):
				seen_uniform[id_key] = true
				out_uniform.append(c)
		return out_uniform
	var pool_mut: Array = candidates.duplicate()
	var w_mut: Array = weights.duplicate()
	var out: Array = []
	var seen_ids: Dictionary = {}
	while out.size() < count and not pool_mut.is_empty():
		var idx: int = _weighted_pick_index(pool_mut, w_mut)
		var c: Variant = pool_mut[idx]
		var id_key: StringName = c.upgrade_id if c is MajorUpgradeDefinition else (c.get("upgrade_id", c) if c is Dictionary else &"")
		if id_key.is_empty():
			id_key = StringName(str(c))
		pool_mut.remove_at(idx)
		w_mut.remove_at(idx)
		if seen_ids.get(id_key, false):
			continue
		seen_ids[id_key] = true
		out.append(c)
	return out

## Wall break: 1 cross-link + 1 ball enhancement + 1 plain-swarm when pools allow; fill to count from union without dupes.
## Optional per-pool weights (same length as each pool): down-weight ball-gated upgrades when types are missing.
func pick_wall_break_draft(cross_link: Array, ball_enhancement: Array, plain_board: Array, count: int, weights_cross: Array = [], weights_ball: Array = [], weights_board: Array = []) -> Array:
	if count <= 0:
		return []
	var seen_ids: Dictionary = {}
	var out: Array = []
	if not cross_link.is_empty():
		var pick: Variant = _weighted_pick_one(cross_link, weights_cross)
		var id_key: StringName = _major_upgrade_id(pick)
		if not id_key.is_empty() and not seen_ids.get(id_key, false):
			seen_ids[id_key] = true
			out.append(pick)
	if not ball_enhancement.is_empty():
		var pick2: Variant = _weighted_pick_one(ball_enhancement, weights_ball)
		var id2: StringName = _major_upgrade_id(pick2)
		if not id2.is_empty() and not seen_ids.get(id2, false):
			seen_ids[id2] = true
			out.append(pick2)
	if not plain_board.is_empty():
		var pick3: Variant = _weighted_pick_one(plain_board, weights_board)
		var id3: StringName = _major_upgrade_id(pick3)
		if not id3.is_empty() and not seen_ids.get(id3, false):
			seen_ids[id3] = true
			out.append(pick3)
	shuffle_array(out)
	var union: Array = []
	var union_weights: Array = []
	for i in range(cross_link.size()):
		union.append(cross_link[i])
		union_weights.append(weights_cross[i] if weights_cross.size() == cross_link.size() else 1.0)
	for i in range(ball_enhancement.size()):
		union.append(ball_enhancement[i])
		union_weights.append(weights_ball[i] if weights_ball.size() == ball_enhancement.size() else 1.0)
	for i in range(plain_board.size()):
		union.append(plain_board[i])
		union_weights.append(weights_board[i] if weights_board.size() == plain_board.size() else 1.0)
	while out.size() < count:
		var rem: Array = []
		var rem_w: Array = []
		for j in range(union.size()):
			var c: Variant = union[j]
			var id_u: StringName = _major_upgrade_id(c)
			if id_u.is_empty() or seen_ids.get(id_u, false):
				continue
			rem.append(c)
			rem_w.append(union_weights[j])
		if rem.is_empty():
			break
		var fill: Variant = _weighted_pick_one(rem, rem_w)
		var id_f: StringName = _major_upgrade_id(fill)
		if id_f.is_empty() or seen_ids.get(id_f, false):
			break
		seen_ids[id_f] = true
		out.append(fill)
	return out

func _weighted_pick_one(pool: Array, weights: Array) -> Variant:
	if pool.is_empty():
		return null
	if weights.is_empty() or weights.size() != pool.size():
		return pool[_rng.randi() % pool.size()]
	var total: float = 0.0
	for w in weights:
		total += float(w)
	if total <= 0.0:
		return pool[_rng.randi() % pool.size()]
	var r: float = _rng.randf() * total
	var acc: float = 0.0
	for i in range(pool.size()):
		acc += float(weights[i])
		if r <= acc:
			return pool[i]
	return pool[pool.size() - 1]

func _weighted_pick_index(pool: Array, weights: Array) -> int:
	if pool.is_empty():
		return 0
	if weights.is_empty() or weights.size() != pool.size():
		return _rng.randi() % pool.size()
	var total: float = 0.0
	for w in weights:
		total += float(w)
	if total <= 0.0:
		return _rng.randi() % pool.size()
	var r: float = _rng.randf() * total
	var acc: float = 0.0
	for i in range(pool.size()):
		acc += float(weights[i])
		if r <= acc:
			return i
	return pool.size() - 1

func _major_upgrade_id(c: Variant) -> StringName:
	if c is Resource:
		var v: Variant = (c as Resource).get("upgrade_id")
		if v is StringName:
			return v as StringName
		if typeof(v) == TYPE_STRING:
			return StringName(v)
	return &""

## Deprecated name: use pick_wall_break_draft(cross, ball, plain, n). Kept for tests.
func pick_wall_break_trio(sidearm_candidates: Array, ball_candidates: Array, board_candidates: Array) -> Array:
	return pick_wall_break_draft(sidearm_candidates, ball_candidates, board_candidates, 3)

func shuffle_array(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi() % (i + 1)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t

## Random int in [min_val, max_val] inclusive.
func randi_range(min_val: int, max_val: int) -> int:
	if min_val > max_val:
		return min_val
	return _rng.randi() % (max_val - min_val + 1) + min_val

func _relic_tier_for_roll(rolled_tier: int, max_relic_tier: int) -> int:
	if max_relic_tier >= 3 and rolled_tier >= 3:
		return 3
	elif max_relic_tier >= 2 and rolled_tier >= 2:
		return 2
	else:
		return 1

