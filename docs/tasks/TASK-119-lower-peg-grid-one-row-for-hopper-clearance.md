# TASK-119: Lower peg grid one row for hopper clearance

- **Status:** IN_REVIEW
- **Priority:** P2
- **Category:** Systems / Gameplay
- **Target Branch:** `codex/lower-peg-grid`

## Description

Move the full peg grid down one 56-pixel row to increase hopper clearance.
Keep all 60 pegs, stable IDs, staggered rows, and relic placement aligned.

## Acceptance Criteria

- [x] Grid starts at y=256 instead of y=200 in all three layout scripts.
- [x] Existing alignment tests use the new origin.
- [x] Rendered main scene shows clearance below the hopper and all eight rows.
- [x] Focused alignment suite: exit 0, 610 passed, zero failures, no SCRIPT ERROR.
- [x] Full Godot suite: exit 0, 20,710 passed, zero failures, no SCRIPT ERROR.
- [x] Static checks and 15 tooling tests pass with the bundled Python on PATH.
- [x] Independent review approved with no actionable findings.
- [ ] Implementation PR merged.

## Current Checkpoint

Source: three BOARD_GRID_START_Y constants and tests/test_peg_grid_alignment.gd.
Raw evidence: .godot/audit/result.json, stdout.txt, stderr.txt, peg_focus.log,
task119-static.log, and task119-board.png.
The first audit failed because the Windows Python shim was inaccessible.
The corrected static checks passed. Existing function-length warnings remain advisory.
Rendered capture and focused checks use an explicit workspace log path.
No owned processes remain. Independent review approved. Await publication and merge.
