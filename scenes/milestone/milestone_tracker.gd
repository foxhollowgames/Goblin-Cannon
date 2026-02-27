extends Node
## MilestoneTracker (§6.9). Display units only; enqueue indices; emit one at a time when drained.

signal milestone_reached(milestone_index: int, total_energy_display: int)

var _total_display: int = 0
var _thresholds: Array[int] = [2000, 4000, 6500]  # display
var _pending_queue: Array[int] = []
var _emitted_for: Dictionary = {}  # index -> true once emitted

func add_display_energy(amount: int) -> void:
	_total_display += amount
	_check_thresholds()

func _check_thresholds() -> void:
	for i in range(_thresholds.size()):
		if _total_display >= _thresholds[i] and not _emitted_for.get(i, false):
			_pending_queue.append(i)
			_emitted_for[i] = true
			milestone_reached.emit(i, _total_display)

func pop_next_milestone() -> int:
	if _pending_queue.is_empty():
		return -1
	return _pending_queue.pop_front()

func get_pending_milestones() -> Array:
	return _pending_queue.duplicate()
