# TASK-029: Peg and Relic Unified Grid Alignment

- **Status:** IN_REVIEW
- **Priority:** P1
- **Category:** Systems / Board Physics
- **Target Branch:** `feature/peg-and-relic-unified-grid-alignment`

## Description

Align the default pegboard layout to the shared rectangular board grid.
Unify the spatial coordinate system between standard pegs and polyomino relics.

---

## Requirements

### 1. Unified Grid Coordinates
- Use the shared board grid dimensions (`BOARD_GRID_COLS` and `BOARD_GRID_ROWS`).
- Remove the horizontal offset on odd rows in the base peg generator.
- Remove the alternating empty space checkerboard pattern.
- Position each peg at the center of its board grid cell.

### 2. Spacing and Coordinate Mapping
- Align grid column spacing (`BOARD_GRID_COL_SPACING = 52.0`) and row spacing (`BOARD_GRID_ROW_SPACING = 56.0`).
- Make sure that coordinate conversion functions map positions accurately:
  - `world_to_board_cell()` converts world coordinates to integer grid cells.
  - `board_cell_to_world()` converts integer grid cells to world coordinates.

### 3. Dynamic Peg Spawning
- Update dynamic peg spawning logic (such as wall break rewards) to target valid empty grid cells.
- Ensure that dynamic pegs align to the same grid cell coordinates.

### 4. Automated Tests
- Add headless unit tests in `tests/test_peg_grid_alignment.gd`.
- Verify that initial pegs occupy exact integer grid coordinates.
- Verify that coordinate mapping matches polyomino cell coordinates.

---

## Acceptance Criteria

- [x] Pegs spawn directly on integer grid coordinates without row offsets.
- [x] Pegs and polyomino relic cells share identical spacing and alignment.
- [x] Coordinate conversion functions map peg positions accurately to grid cells.
- [x] Dynamic peg spawning targets valid empty cells on the grid.
- [x] Headless unit tests verify grid alignment and position calculation.
