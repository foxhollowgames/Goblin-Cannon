class_name MilestoneCurve
extends RefCounted
## Pure logic for milestone threshold lookup (§6.9, §7). No RNG; no nodes.
## Thresholds in display units. Returns milestone index when total crosses threshold.

static func next_threshold_index(total_display: int, thresholds: Array) -> int:
	for i in range(thresholds.size()):
		if total_display >= thresholds[i]:
			return i
	return -1

## Returns array of milestone indices that total_display has crossed (for enqueue-all rule).
static func crossed_indices(total_display: int, thresholds: Array) -> Array:
	var out: Array[int] = []
	for i in range(thresholds.size()):
		if total_display >= thresholds[i]:
			out.append(i)
	return out
