extends Node
## MilestoneTracker (§6.9). Display units only; enqueue indices; emit one at a time when drained.

signal milestone_reached(milestone_index: int, total_energy_display: int)

var _total_display: int = 0
## Next milestone level (0-based). Thresholds from MilestoneCurve: linear first 5, then exponential.
var _milestones_reached_count: int = 0
var _pending_queue: Array[int] = []

## Reset progress for new run. City thresholds array is ignored; scaling is linear then exponential (MilestoneCurve).
func set_thresholds_from_city(_thresholds: Array[int]) -> void:
	_total_display = 0
	_milestones_reached_count = 0
	_pending_queue.clear()

func add_display_energy(amount: int) -> void:
	_total_display += amount
	_check_thresholds()

func _check_thresholds() -> void:
	var thresh: int = MilestoneCurve.threshold_for_level(_milestones_reached_count)
	while _total_display >= thresh:
		var idx: int = _milestones_reached_count
		_pending_queue.append(idx)
		milestone_reached.emit(idx, _total_display)
		_milestones_reached_count += 1
		thresh = MilestoneCurve.threshold_for_level(_milestones_reached_count)

func pop_next_milestone() -> int:
	if _pending_queue.is_empty():
		return -1
	return _pending_queue.pop_front()

func get_pending_milestones() -> Array:
	return _pending_queue.duplicate()

## For UI: current total in display units (never decreases).
func get_total_display() -> int:
	return _total_display

## For UI: next milestone threshold in display units (scales with level).
func get_next_threshold() -> int:
	return MilestoneCurve.threshold_for_level(_milestones_reached_count)
