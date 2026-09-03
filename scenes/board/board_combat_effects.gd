extends Node2D
## Combat status effects, hit cascades, explosions, chain lightning, and leech drain processing for Board.

#region State and References
var _leeched_pegs: Array = []  ## Array[Dictionary]: { peg_id, alignment, drains_remaining }
var _explosion_triggered_pegs_this_tick: Dictionary = {}  ## int -> bool
var _supernova_triggered_pegs_this_tick: Dictionary = {}  ## int -> bool
var _chain_conduction_done_this_event: bool = false
var _board_root: Node2D = null
#endregion

#region Initialization & Resets
## Initializes reference to root Board node.
func setup(board_root: Node2D) -> void:
	_board_root = board_root

## Resets per-tick hard caps on explosive hit cascades and chain conduction.
func reset_per_tick_caps() -> void:
	_explosion_triggered_pegs_this_tick.clear()
	_supernova_triggered_pegs_this_tick.clear()
	_chain_conduction_done_this_event = false
#endregion

#region Combat Effects API
## Returns true if an explosive cascade was already triggered for target peg this sim tick.
func has_explosion_triggered(peg_id: int) -> bool:
	return _explosion_triggered_pegs_this_tick.get(peg_id, false)

## Marks target peg as having triggered an explosion this sim tick.
func mark_explosion_triggered(peg_id: int) -> void:
	_explosion_triggered_pegs_this_tick[peg_id] = true

## Returns true if supernova was already triggered for target peg this sim tick.
func has_supernova_triggered(peg_id: int) -> bool:
	return _supernova_triggered_pegs_this_tick.get(peg_id, false)

## Marks target peg as having triggered supernova this sim tick.
func mark_supernova_triggered(peg_id: int) -> void:
	_supernova_triggered_pegs_this_tick[peg_id] = true

## Adds a new leeched peg entry to the active leech drain list.
func add_leeched_peg(peg_id: int, alignment: int, duration_sec: int) -> void:
	_leeched_pegs.append({
		"peg_id": peg_id,
		"alignment": alignment,
		"drains_remaining": duration_sec
	})

## Returns the array of active leeched peg records.
func get_leeched_pegs() -> Array:
	return _leeched_pegs
#endregion


