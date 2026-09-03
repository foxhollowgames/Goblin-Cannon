# TASK-063: Junk Box Relic Display Equivalence and Hover Tooltip Fix

- **Status:** READY
- **Priority:** P1
- **Category:** UI / Polish / Gameplay
- **Target Branch:** `fix/junk-box-relic-display-and-tooltips`
- **Related Tasks:** [TASK-028](TASK-028-junk-box-ui-opening-and-board-transfer.md), [TASK-039](TASK-039-junk-box-sidebar-integration-and-pegboard-display.md), [TASK-049](TASK-049-on-board-relic-tooltip-rework.md), [TASK-057](TASK-057-board-relic-tooltip-bbcode-rendering.md)

## Description

Fix the relic visual display and hover tooltips in the Junk Box inventory grid.
Relics in the Junk Box currently do not display the same way that they do on the active board:
- In `JunkBoxGridView`, relics render as flat solid rectangles with crude primitive line/arc shapes instead of matching the board relic aesthetic (translucent cell backgrounds, comic ink perimeter borders, internal dividing lines, and detailed machinery component glyphs/sprites).
- Relics in the Junk Box no longer show hover tooltips. `_get_tooltip_lbl()` in `junk_box_panel.gd` returns `null`, causing all hover tooltip updates to fail silently.

The Junk Box must render polyomino relics with visual equivalence to the board, and show full item tooltips using the standard flyout tooltip system when hovered.

---

## Requirements

### 1. Junk Box Relic Display Equivalence
- Update `JunkBoxGridView._draw_item` to render relics with visual equivalence to on-board relics (`PolyominoModuleNode` / `RelicLayoutPreview`):
  - Draw cell backgrounds with rarity accent color and appropriate alpha transparency.
  - Draw solid outer comic ink perimeter walls (`4.0` ink line, `2.0` highlight) using `PolyominoModuleData.get_solid_edge_segments`.
  - Draw internal dividing lines between adjacent cells (`3.0` ink line, `1.5` accent).
  - Render kinetic machinery components (bumpers, deflector arrows, funnels, boosters, drop targets, spinners) using the standard component glyphs/sprites rather than crude geometric primitives.
  - Make sure module rotation step and cell dimensions align accurately within the Junk Box grid cells.

### 2. Junk Box Hover Tooltip Restoration
- Restore hover tooltips when the mouse hovers over relics in the Junk Box grid:
  - Connect `JunkBoxGridView` item hover events to the central flyout tooltip system (`KeywordDatabase.show_flyout_custom`).
  - Format the tooltip with full inventory item details: Relic Name, Tier, Size (cell count), Shape Name, Activation Requirement, Relic Effect, and Machinery Components.
  - Position the flyout tooltip near the hovered relic or mouse position without obscuring the Junk Box panel or extending off-screen.
  - Hide the flyout tooltip (`KeywordDatabase.hide_flyout`) when the item is unhovered, when the cursor leaves the grid view, or when drag-and-drop begins.

### 3. Drag-and-Drop Compatibility
- Make sure that updating the visual rendering does not break item grabbing, dragging, rotation, or drop detection in `JunkBoxDragController`.
- Hide any active tooltip immediately when a drag operation starts (`start_drag`).

### 4. Automated Tests
- Create unit tests in `tests/test_junk_box_relic_display_and_tooltips.gd`:
  - Verify that `JunkBoxGridView` calculates and renders solid edge segments and component glyphs.
  - Verify that hovering over a relic in the Junk Box emits or triggers a formatted flyout tooltip with required fields (name, tier, activation requirement, effect).
  - Verify that unhovering or mouse exit dismisses the tooltip.
  - Verify that drag start dismisses the tooltip.

---

## Acceptance Criteria

- [ ] Relics in the Junk Box display with translucent cell fills, comic ink outer borders, internal dividing lines, and proper kinetic machinery visuals.
- [ ] Hovering over a relic in the Junk Box displays a flyout tooltip containing complete relic specifications.
- [ ] Unhovering a relic or moving the mouse out of the Junk Box hides the tooltip.
- [ ] Starting a drag-and-drop operation hides the tooltip immediately.
- [ ] Drag-and-drop from Junk Box to the board continues to function cleanly.
- [ ] All modified and new files remain strictly under 500 lines.
- [ ] Headless unit tests pass cleanly.
