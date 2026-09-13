# TASK-093: Remove Top Row of Pegs

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** Systems / Board Physics / Gameplay
- **Target Branch:** `feature/remove-top-row-of-pegs`
- **Related Tasks:** [TASK-029](TASK-029-peg-and-relic-unified-grid-alignment.md), [TASK-091](TASK-091-peglin-style-top-cannon-battlefield-and-mob-timer.md), [TASK-092](TASK-092-clean-top-battlefield-panel-hopper-layering-and-cannon-pushback.md)

## Description

Following the repositioning and lowering of the Hopper into the playfield area (y = 150), the top row of pegs (at y = 200, row 0) sits directly below the hopper mouth and collides visually with the hopper funnel flaps. Balls dropping from the hopper immediately impact pegs without gaining natural downward fall velocity, and horizontal hopper steering clips through row 0 pegs.

We need to remove the top row of pegs from the initial board layout. The remaining rows of pegs (rows 1 through 7, starting at y = 256) remain in place, with the top-most row now centered cleanly below the hopper mouth with ample vertical clearance. Dynamic milestone event pegs and empty cell queries will also exclude row 0 to prevent dynamic events from spawning directly beneath the hopper.

---

## Requirements

### 1. Board Peg Generation
- In `scenes/board/board.gd` `_spawn_peg_layout()`, skip row 0 so that no baseline pegs spawn in the top row.
- Total baseline pegs spawned changes from 60 to 52 pegs (8 pegs removed from row 0).
- Row 1 (y = 256) becomes the topmost row of pegs, with 7 pegs staggered at odd columns (including column 7 at x = 480 directly below the centered hopper).

### 2. Event and Dynamic Placement Safeguards
- In `scenes/board/board.gd` `get_empty_grid_cells()`, start searching at row 1 so that milestone event pegs, dynamic reward pegs, and event controllers do not spawn into row 0 right in front of the hopper.
- In `scenes/board/board.gd` `resolve_milestone_event_position()` and `scenes/board/board_peg_layout.gd` `resolve_event_position()`, clamp minimum row to 1.

### 3. Sub-Manager and Layout Consistency
- Keep `scenes/board/board_peg_layout.gd` and `scenes/board/board_grid_modules.gd` synchronized with row bounds and empty cell queries.

### 4. Automated Tests
- Update `tests/test_peg_grid_alignment.gd`:
  - Assert total initial peg count is 52.
  - Assert row 0 has no pegs.
  - Assert row 1 through 7 retain their staggered lattice arrangement.
  - Assert `get_empty_grid_cells()` returns 53 empty cells across the playable rows.
- Verify all unit tests pass in headless mode (`tests/run_tests.gd`).
- Verify GDScript style and file lengths (`python scripts/lint_gdscript.py`, `python scripts/lint_file_lengths.py`).

---

## Acceptance Criteria

- [ ] Row 0 pegs (at y = 200) are removed from the board.
- [ ] Row 1 pegs (at y = 256) form the new top row with proper vertical clearance from the hopper.
- [ ] Milestone event pegs and dynamic pegs never spawn in row 0.
- [ ] All automated unit tests pass in headless mode (`tests/run_tests.gd`).
- [ ] GDScript standards and file length linters pass with 0 errors.
