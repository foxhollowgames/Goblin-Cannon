# TASK-039: Junk Box Sidebar Integration and Pegboard Display Equivalence

- **Status:** READY
- **Priority:** P1
- **Category:** UI / Controls / Gameplay
- **Target Branch:** `feature/junk-box-sidebar-and-pegboard-display`
- **Related Tasks:** [TASK-004](TASK-004-right-panel-and-comic-cutouts.md), [TASK-027](TASK-027-junk-box-backpack-inventory-system.md), [TASK-028](TASK-028-junk-box-ui-opening-and-board-transfer.md), [TASK-035](TASK-035-relic-selection-layout-and-machinery-preview.md)

## Description

Integrate the Junk Box UI panel directly into the right sidebar location where the Cannon and Wall elements currently sit.
Make sure that the pegboard UI preview matches the exact visual display of the active main board.

---

## Requirements

### 1. Junk Box Right Sidebar Integration
- Move the Junk Box UI panel into the right sidebar panel area.
- Position the Junk Box panel in the space where the Cannon and Wall elements are now located.
- Adjust the layout of the right sidebar so the Junk Box fits cleanly inside the panel boundaries.
- Keep the Cannon and Wall status elements visible alongside or integrated within the right sidebar layout.
- Make sure that opening the Junk Box does not overlap or obscure the main playing board.

### 2. Pegboard Display Equivalence
- Update all pegboard UI previews to match the exact visual style of the active game board.
- Make sure that peg spacing, cell dimensions, and grid lines in previews match the live board layout.
- Render relic shapes, icons, and peg points in the UI with identical proportions to the live board.
- Maintain consistent visual scale and aspect ratio across all pegboard preview containers.

### 3. Drag and Drop Interaction
- Allow the player to drag polyomino modules directly from the right sidebar Junk Box onto the live board.
- Support rotation, snapping, and placement ghost previews during drag operations.
- Return items to the sidebar Junk Box if dropped on invalid board cells.

### 4. Automated Tests
- Add unit tests in `tests/test_junk_box_sidebar_display.gd`.
- Verify that the Junk Box UI node resides within the right sidebar panel hierarchy.
- Verify that pegboard preview grid dimensions match live board grid parameters.

---

## Acceptance Criteria

- [ ] The Junk Box UI panel fits cleanly into the right sidebar space occupied by the Cannon and Wall.
- [ ] The Cannon and Wall status elements remain visible in the updated right sidebar layout.
- [ ] Pegboard UI previews display pegs, cells, and relics with identical visuals to the main board.
- [ ] Players can drag modules from the right sidebar Junk Box onto valid board grid cells.
- [ ] Headless unit tests verify sidebar layout positioning and pegboard display equivalence.
