# TASK-025: Polyomino Drag-and-Drop, Rotation, and Grid Snapping

- **Status:** READY
- **Priority:** P1
- **Category:** UI / Controls
- **Target Branch:** `feature/polyomino-drag-and-drop`

## Description

Implement mouse drag-and-drop, 90-degree rotation, and grid snapping for polyomino relic modules.

## Requirements

1. **Mouse Drag and Drop:**
   - Grab modules from the scrapbox toolbox or the active pegboard with left mouse click.
   - Follow the mouse cursor smoothly during drag operations.

2. **Rotation Controls:**
   - Press `R` or click right mouse button during drag to rotate the module 90 degrees clockwise.
   - Update the preview boundary immediately upon rotation.

3. **Grid Snapping and Valid Placement Overlays:**
   - Snap the dragged polyomino to nearest grid coordinates.
   - Show green highlight overlays when all occupied cells are valid and unoccupied.
   - Show red highlight overlays when placement exceeds board bounds or overlaps existing modules.

4. **Integration with Ghost State:**
   - Connect with [TASK-020](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-020-live-board-ghost-placement.md) so dropped polyominos enter ghost state until active balls leave the area.

## Acceptance Criteria

- [ ] Drag-and-drop feels responsive and accurately aligns to the grid cells.
- [ ] Modules rotate 90 degrees cleanly without coordinate drift.
- [ ] Invalid placements reject drop and return the module to the scrapbox or prior position.
- [ ] Headless unit tests verify grid occupancy and placement validation logic.
