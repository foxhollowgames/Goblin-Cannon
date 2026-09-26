# flow

[Learning index](../LEARNINGS.md)

## <a id="lrn-054"></a> LRN-054: Takeover Cutscene Reward Sequencing
- **Task:** TASK-005
- **Category:** flow
- **Created:** 2026-09-02T09:34:04.851333
- **Tags:** 

### Context
Sequenced reward selection modal popups after full-screen comic takeover cutscenes.

### Learning
GameCoordinatorFlow.handle_wall_destroyed plays FullscreenComicTakeover first, connecting takeover_completed signal to handle_wall_break_transition_finished.

### Guideline
Chain cutscene takeover completion signals before dispatching reward modal popups.

