class_name MilestoneCurve
extends RefCounted
## Pure logic for milestone threshold lookup (§6.9, §7). No RNG; no nodes.
## Thresholds in display units. Returns milestone index when total crosses threshold.
## First 3 milestones linear (2k, 4k, 6k); then exponential (12k, 24k, 48k, 96k…).

const MILESTONE_STEP: int = 2_000
## First N milestones use linear scaling.
const LINEAR_MILESTONE_COUNT: int = 3
## Exponential base for milestones after the linear ones. Threshold = linear_cap * (EXP_BASE ^ (level - 2)).
const EXP_BASE: float = 2.0

## Returns the display-unit threshold for milestone level (0-based).
## Levels 0-2: linear (2k, 4k, 6k). Level 3+: exponential from 6k.
static func threshold_for_level(level: int) -> int:
	if level < 0:
		return 0
	if level < LINEAR_MILESTONE_COUNT:
		return MILESTONE_STEP * (level + 1)
	var linear_cap: int = MILESTONE_STEP * LINEAR_MILESTONE_COUNT  # 6_000
	var exp_index: int = level - LINEAR_MILESTONE_COUNT + 1
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
