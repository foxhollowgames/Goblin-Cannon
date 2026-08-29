# TASK-030: Relic Placement Peg Replacement and Mutual Exclusivity

- **Status:** READY
- **Priority:** P1
- **Category:** Systems / Gameplay
- **Target Branch:** `feature/relic-placement-peg-replacement`
- **Related Tasks:** [TASK-025](TASK-025-polyomino-drag-drop-and-grid-snapping.md), [TASK-029](TASK-029-peg-and-relic-unified-grid-alignment.md)

## Description

Replace existing pegs when a polyomino relic drops onto occupied grid cells.
Enforce strict mutual exclusivity to prevent illegal stacking of relics and pegs.

---

## Requirements

### 1. Automatic Peg Replacement on Relic Drop
- Identify all pegs occupying the footprint of a dropped polyomino relic.
- Remove all replaced pegs from the active board scene cleanly.
- Remove replaced peg entries from the internal board state and lookup tables.

### 2. Mutual Exclusivity and Overlap Prevention
- Prevent placing a polyomino relic on top of another polyomino relic.
- Show an invalid red highlight overlay when a dragged relic overlaps existing relics.
- Prevent spawning or placing pegs on cells that already hold a relic module.
- Reject invalid drops and return the item to its previous location.

### 3. Board Cell Occupancy State Synchronization
- Update the board cell occupancy dictionary when a relic replaces pegs.
- Ensure that removed peg nodes free their collision shapes and visuals cleanly.
- Ensure that unslotting a relic leaves empty grid cells ready for future placement.

### 4. Integration with Ghost State
- Move the placed relic into a non-colliding ghost state if active balls touch the area.
- Remove replaced pegs immediately when the relic drops on the grid.

### 5. Automated Tests
- Add headless unit tests in `tests/test_relic_peg_replacement.gd`.
- Test that dropping a relic removes all pegs in occupied cells.
- Test that dropping a relic on an existing relic is rejected.
- Test that pegs cannot spawn on cells occupied by a relic.

---

## Acceptance Criteria

- [ ] Dropping a polyomino relic removes all pegs underneath its occupied cells.
- [ ] Relics cannot drop on top of other relics on the board grid.
- [ ] Pegs cannot spawn or place on cells that contain a relic.
- [ ] The board cell occupancy registry updates accurately.
- [ ] Headless unit tests verify replacement and rejection logic.
