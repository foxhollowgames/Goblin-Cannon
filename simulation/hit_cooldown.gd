class_name HitCooldown
extends RefCounted
## Pure logic for per-ball-per-peg hit cooldown (§1.6). (ball_id, peg_id) → last_hit_sim_tick.
## Board uses this; no node dependencies.

var _last_hit: Dictionary = {}  # key = "ball_id:peg_id" or Vector2i(ball_id, peg_id)

func cooldown_ok(ball_id: int, peg_id: int, current_sim_tick: int, cooldown_ticks: int) -> bool:
	var key: Vector2i = Vector2i(ball_id, peg_id)
	var last: int = _last_hit.get(key, -99999)
	return (current_sim_tick - last) >= cooldown_ticks

func record_hit(ball_id: int, peg_id: int, sim_tick: int) -> void:
	_last_hit[Vector2i(ball_id, peg_id)] = sim_tick

func clear() -> void:
	_last_hit.clear()
