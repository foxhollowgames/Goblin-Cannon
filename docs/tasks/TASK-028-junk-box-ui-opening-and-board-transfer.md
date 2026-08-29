# TASK-028: Junk Box UI Opening, Representation, and Board Item Transfer

- **Status:** READY
- **Priority:** P1
- **Category:** UI / Controls / Gameplay
- **Parent Task:** [TASK-027](TASK-027-junk-box-backpack-inventory-system.md)
- **Target Branch:** `feature/junk-box-ui-and-board-transfer`

## Description

Design and implement the complete UI representation and interaction workflow for the Junk Box.
The player must be able to open the Junk Box easily during gameplay.
The player must see the Junk Box clearly on the screen.
The player must be able to drag polyomino modules from the Junk Box onto the board grid.

---

## Requirements

### 1. Junk Box Opening and Drawer Controls
- Add a dedicated HUD button (backpack or toolbox icon) to open and close the Junk Box.
- Support standard toggle hotkeys (`B` and `I`) to open and close the panel.
- Allow the player to close the Junk Box with the `Escape` key.
- Provide smooth open and close animations for the drawer interface.
- Make sure that the Junk Box does not hide the board completely when open.

### 2. Junk Box UI Visual Representation
- Style the Junk Box container with the established comic book art theme.
- Show leather straps, brass rivets, gears, and thick ink outlines on the panel frame.
- Show the endless scrollable grid view with smooth vertical navigation.
- Show an item count badge on the HUD button when unplaced modules exist in the box.
- Show rich hover tooltips with tier levels, cell sizes, and kinetic component stats.

### 3. Moving Items from the Junk Box to the Board
- Allow the player to grab an item from the Junk Box grid with the left mouse button.
- Drag the item smoothly across the screen to the active pegboard.
- Rotate the dragged item 90 degrees with the `R` key or the right mouse button.
- Show a ghost placement preview on the board grid during drag operations:
  - Show a green highlight overlay when the target grid cells are valid and empty.
  - Show a red highlight overlay when the target cells collide or exceed board boundaries.
- Drop the module onto valid board cells to slot it into the board.
- Integrate with the live board ghost system ([TASK-020](TASK-020-live-board-ghost-placement.md)) so new placements wait for balls to leave.
- Return the module to the Junk Box if the player drops it in an invalid location.
- Allow the player to pick up a module from the board and move it back into the Junk Box.

### 4. Data State Synchronization
- Update `GameState.junk_box` and the board data model immediately during every transfer.
- Keep item coordinates, rotation steps, and unique IDs consistent.
- Save and load inventory states and board placements accurately without data loss.

---

## Acceptance Criteria

- [ ] The HUD backpack button and keyboard shortcuts (`B`, `I`, `Esc`) open and close the Junk Box.
- [ ] The Junk Box panel renders with comic style frames and does not obstruct the board grid.
- [ ] The player can drag polyomino modules from the Junk Box onto valid board cells.
- [ ] Modules rotate 90 degrees cleanly during drag operations.
- [ ] Ghost overlays show green for valid placement and red for invalid placement.
- [ ] Dropping a module on an invalid cell returns the item safely to the Junk Box.
- [ ] The player can move placed modules from the board back into the Junk Box.
- [ ] Headless unit tests verify UI opening logic, drag controller transfers, and state synchronization.
