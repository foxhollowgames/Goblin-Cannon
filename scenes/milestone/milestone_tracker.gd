extends Node
## MilestoneTracker. Milestone rewards come from board events only.

signal milestone_reached(milestone_index: int, total_energy_display: int)

## Next milestone level (0-based); advanced when a board milestone event is claimed.
var _milestones_reached_count: int = 0
var _pending_queue: Array[int] = []

## Reset progress for new run.
func set_thresholds_from_city(_thresholds: Array[int]) -> void:
	_milestones_reached_count = 0
	_pending_queue.clear()

## Call when the player destroys a milestone event peg; emits milestone_reached once.
func register_milestone_reward() -> void:
	var idx: int = _milestones_reached_count
	_pending_queue.append(idx)
	milestone_reached.emit(idx, 0)
	_milestones_reached_count += 1

func pop_next_milestone() -> int:
	if _pending_queue.is_empty():
		return -1
	return _pending_queue.pop_front()

func get_pending_milestones() -> Array:
	return _pending_queue.duplicate()

## Legacy UI: total energy toward milestones (no longer incremented automatically).
func get_total_display() -> int:
	return 0

## Legacy: next threshold from curve (display only).
func get_next_threshold() -> int:
	return MilestoneCurve.threshold_for_level(_milestones_reached_count)
