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

func shuffle_array(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi() % (i + 1)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t
