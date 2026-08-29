# TASK-031: Board Relic Repositioning and In-Place Dragging

- **Status:** READY
- **Priority:** P1
- **Category:** UI / Controls
- **Target Branch:** `feature/board-relic-repositioning`
- **Related Tasks:** [TASK-025](TASK-025-polyomino-drag-drop-and-grid-snapping.md), [TASK-028](TASK-028-junk-box-ui-opening-and-board-transfer.md), [TASK-030](TASK-030-relic-placement-peg-replacement-and-overlap-prevention.md)

## Description

Allow the player to click and drag placed relics directly on the active board.
Enable smooth repositioning and re-arrangement of slotted relics on the grid.

---

## Requirements

### 1. Board Click and Drag Initiation
- Allow the player to grab any cell of a placed relic with a left mouse click.
- Unslot the relic from its current board cells while dragging.
- Compute the grab offset cell accurately so the shape moves with the cursor.

### 2. In-Flight Manipulation and Preview
- Follow the mouse cursor smoothly across the board surface.
- Allow 90-degree clockwise rotation with the `R` key or the right mouse button.
- Show grid snap previews and highlight overlays (green for valid, red for invalid).

### 3. Repositioning and Board Transfers
- Drop the relic onto a new valid board location to place it.
- Remove pegs at the new target location upon drop.
- Allow dragging the relic into the open Junk Box drawer to store it.

### 4. Drag Cancellation and Recovery
- Cancel dragging when the player presses the `Escape` key.
- Cancel dragging when the player drops the relic on an invalid area.
- Return the relic to its original board cell and rotation on cancellation.
- Restore relic passive effects and state cleanly on cancellation.

### 5. Automated Tests
- Add headless unit tests in `tests/test_board_relic_repositioning.gd`.
- Test that clicking a placed relic starts drag mode.
- Test that dropping on a new grid cell updates relic position.
- Test that canceling a drag restores the original position.

---

## Acceptance Criteria

- [ ] The player can click and drag placed relics directly on the board.
- [ ] Relics rotate and snap accurately to new grid coordinates.
- [ ] Relics replace pegs at the new target location upon drop.
- [ ] Drag cancellation restores the relic to its previous position.
- [ ] Headless unit tests verify board drag and repositioning logic.
