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
		var id_key = c.get("id", c)
		if not seen.get(id_key, false):
			seen[id_key] = true
			out.append(c)
	return out

func shuffle_array(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi() % (i + 1)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t
