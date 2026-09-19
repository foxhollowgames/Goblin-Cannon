# TASK-099: Restore Junk Box Physical Relic Visuals and Flow Representation

- **Status:** IN_REVIEW
- **Priority:** P1
- **Category:** UI / Visuals / Relics
- **Target Branch:** `fix/junk-box-physical-relic-visuals`
- **Related Tasks:** [TASK-028](TASK-028-junk-box-ui-opening-and-board-transfer.md), [TASK-039](TASK-039-junk-box-sidebar-integration-and-pegboard-display.md), [TASK-063](TASK-063-junk-box-relic-display-and-tooltip-fix.md), [TASK-068](TASK-068-relic-tier-visual-styling.md), [TASK-093](TASK-093-rework-relics-into-deliberate-pinball-devices.md), [TASK-097](TASK-097-relic-visual-tiles-and-description-updates.md), [TASK-098](TASK-098-triangle-bumper-rotation-with-polyomino.md)

## Description

The Junk Box inventory grid reverted to rendering schematic, primitive glyphs (two-dot arrows, blank circles, and generic lines) instead of matching the actual physical pinball mechanisms and deliberate ball flow devices introduced in TASK-093 and TASK-098.

Specifically:
1. **Flow Tracks**: Track polyominoes render with generic circle/parallel line glyphs instead of the physical cyan/blue conduit pipe routes (`FlowVisuals.draw_route`).
2. **Entrances & Exits**: Passage devices in the Junk Box omit directional port arrows (`FlowVisuals.draw_ports`), making open entrances and exits invisible.
3. **Triangle Bumpers / Slingshots**: Slingshot kickers render as tiny double-headed line arrows instead of rotated physical white triangular bumpers with corner steel posts matching `SlingshotKicker`.
4. **Word Banks / Rollover Switches**: Rollover switches render as blank yellow circles without their associated letter glyphs ("G", "O", "B" / "W", "I", "N").
5. **Retention Reservoirs / Wire Gates**: Wire gates render as a basic line instead of showing the retention holding cup and capacity pips.
6. **Bumper Vessels / Funnels**: Funnel bumper chambers lack outward bumper offsets and open funnel flow geometry.
7. **Drag Ghost Preview**: In-flight dragging in `JunkBoxDragController` displays primitive chevrons and geometric lines instead of authentic device visuals.

This task restores full visual equivalence between the Junk Box inventory, in-flight drag ghost previews, and the live board mechanisms.

---

## Requirements

### 1. Single Source of Truth Architecture (`PolyominoModuleNode`)
- The board representation (`PolyominoModuleNode`) is the sole authoritative visual definition of all relics.
- No parallel drawing engines or separate glyph systems.
- In UI and preview contexts (Junk Box, shop cards, drag ghost), `PolyominoModuleNode` is instantiated in ghost/preview mode (`set_ghost_state(true, alpha)`), with collision disabled (`collision_layer = 0`, `collision_mask = 0`), scaled to the container cell dimensions.

### 2. Junk Box Grid View Integration
- Replace manual `_draw_item()` custom drawing in `JunkBoxGridView` with child `PolyominoModuleNode` instances mapped to `junk_box_data.get_all_items()`.
- Scale each module node by `Vector2(CELL_SIZE / PolyominoModuleNode.CELL_WIDTH, CELL_SIZE / PolyominoModuleNode.CELL_HEIGHT)`.
- Position each module node at `Vector2((item.grid_position.x + 0.5) * CELL_SIZE, (item.grid_position.y + 0.5) * CELL_SIZE)`.
- Synchronize nodes on `inventory_changed` and update opacity (`0.35` when dragged, `1.0` when idle).

### 3. Drag Ghost Controller Integration
- Replace `_GhostPreviewVisual` primitive lines and chevrons with `PolyominoModuleNode` in `JunkBoxDragController`.
- Update module configuration and rotation dynamically as the item is rotated in flight.
- Modulate green for valid placement and red for invalid placement.

### 4. Shop Card Preview Synchronization
- Update `RelicLayoutPreview` to host a child `PolyominoModuleNode` scaled down to fit the preview box.

### 4. File Length and Coding Standards (Rule 7)
- Maintain all modified files strictly <= 500 lines:
  - `scenes/board/machinery/polyomino_machinery_visuals.gd`
  - `scenes/ui/junk_box/junk_box_grid_view.gd`
  - `scenes/ui/junk_box/junk_box_drag_controller.gd`
  - `scenes/rewards/relic_layout_preview.gd`
- Run `python scripts/lint_gdscript.py` and `python scripts/lint_file_lengths.py`.

### 5. Verification and Automated Tests
- Author tests in `tests/test_junk_box_physical_visuals.gd` validating:
  - `JunkBoxGridView` draws flow routes, ports, rollover letters, and triangle bumpers.
  - `JunkBoxDragController` ghost visual renders authentic device components during drag.
  - All headless unit tests pass cleanly (`godot --headless -s tests/run_tests.gd`).

---

## Acceptance Criteria

- [x] Junk Box renders flow tracks with authentic conduit pipe paths.
- [x] Junk Box renders green entrance and orange exit port arrows for passage devices.
- [x] Triangle bumpers render as rotated triangular bodies with white frames and corner posts in both Junk Box and shop previews.
- [x] Rollover switch banks render their letter glyphs in the Junk Box.
- [x] Wire gates render with retention cups and capacity indicators in the Junk Box.
- [x] Drag ghost preview displays authentic component styling without fallback chevrons.
- [x] All modified files stay strictly <= 500 lines.
- [x] Headless test suite passes with zero regressions.

