# TASK-066: Junk Box Manual Relic Placement and Internal Repositioning

- **Status:** DONE
- **Priority:** P1
- **Category:** UI / Gameplay / Systems
- **Target Branch:** `feature/junk-box-manual-relic-placement`
- **Related Tasks:** [TASK-027](TASK-027-junk-box-backpack-inventory-system.md), [TASK-028](TASK-028-junk-box-ui-opening-and-board-transfer.md), [TASK-031](TASK-031-board-relic-repositioning-and-dragging.md), [TASK-054](TASK-054-relic-junk-box-return.md)

## Description

Allow the player to move relics manually to different positions inside the junk box inventory.
Make sure that the player can organize and arrange stored relics on the junk box grid.

---

## Requirements

### 1. Internal Drag Start
- Allow the player to grab any occupied cell of a stored relic with the left mouse button.
- Calculate the grab offset cell from the mouse position to the relic origin cell.
- Start the drag mode without removing the item data from the inventory.

### 2. In-Flight Movement and Visual Preview
- Show the ghost preview with the polyomino relic shape at the mouse position.
- Show green highlights when target junk box cells are empty and valid.
- Show red highlights when target junk box cells collide with other relics or go outside bounds.
- Allow 90-degree clockwise rotation with the `R` key or the right mouse button.
- Align ghost preview grid dimensions with the junk box grid cell size.

### 3. Collision and Self-Exclusion Logic
- Exclude the active dragged relic from collision verifications against its own previous cells.
- Prevent placement on cells occupied by other stored relics.
- Keep relics inside horizontal grid boundaries (columns 0 through 5).

### 4. Drop and Placement Process
- Move the relic to the new grid position and rotation when dropped on valid cells.
- Update occupied cells in the junk box data container.
- Redraw the junk box grid view immediately after placement.
- Trigger dynamic vertical row expansion when placing a relic near the bottom.

### 5. Drag Cancellation and Recovery
- Cancel the drag operation when the player presses the `Escape` key.
- Cancel the drag operation when the player releases the mouse over an invalid position.
- Return the relic to its original junk box position and rotation on cancellation.

### 6. Automated Tests
- Create headless unit tests in `tests/test_junk_box_manual_placement.gd`.
- Test moving a relic to an empty target location inside the junk box.
- Test rotating a relic during internal junk box repositioning.
- Test collision rejection when dropping onto cells occupied by another relic.
- Test drag cancellation and position restoration.

---

## Acceptance Criteria

- [x] The player can click and drag stored relics inside the junk box grid.
- [x] Relics can rotate 90 degrees while moving inside the junk box.
- [x] Dropping a relic on valid empty cells updates its position and rotation.
- [x] Relics do not collide with themselves during repositioning verifications.
- [x] Relics cannot overlap other stored items.
- [x] Canceling the drag restores the relic to its original cell and rotation.
- [x] Automated headless tests pass cleanly.
