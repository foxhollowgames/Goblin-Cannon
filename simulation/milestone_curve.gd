class_name MilestoneCurve
extends RefCounted
## Pure logic for milestone threshold lookup (§6.9, §7). No RNG; no nodes.
## Thresholds in display units. Returns milestone index when total crosses threshold.
## First 5 milestones linear (2k, 4k, 6k, 8k, 10k); then exponential.

const MILESTONE_STEP: int = 2_000
## First N milestones use linear scaling.
const LINEAR_MILESTONE_COUNT: int = 5
## Exponential base for milestones after the linear ones. Threshold = linear_cap * (EXP_BASE ^ (level - 5)).
const EXP_BASE: float = 1.5

## Returns the display-unit threshold for milestone level (0-based).
## Levels 0-4: linear (2k, 4k, 6k, 8k, 10k). Level 5+: exponential from 10k.
static func threshold_for_level(level: int) -> int:
	if level < 0:
		return 0
	if level < LINEAR_MILESTONE_COUNT:
		return MILESTONE_STEP * (level + 1)
	var linear_cap: int = MILESTONE_STEP * LINEAR_MILESTONE_COUNT  # 10_000
	var exp_index: int = level - LINEAR_MILESTONE_COUNT
	return int(round(linear_cap * pow(EXP_BASE, exp_index)))

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
