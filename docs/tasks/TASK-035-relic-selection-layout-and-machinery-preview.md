# TASK-035: Relic Selection Screen Layout and Machine Composition Preview

- **Status:** READY
- **Priority:** P1
- **Category:** UI / Visuals / Rewards
- **Target Branch:** `feature/relic-selection-preview`
- **Related Tasks:** [TASK-024](TASK-024-polyomino-relic-shapes-and-sizes.md), [TASK-026](TASK-026-polyomino-internal-machinery-and-bumpers.md), [TASK-028](TASK-028-junk-box-ui-opening-and-board-transfer.md)

## Description

Add a visual layout and machine composition preview to each card on the relic selection screen.
Show the multi-cell polyomino shape and kinetic machine parts directly underneath the relic title.
Help the player understand the spatial footprint and internal mechanism of each relic before selection.

---

## Requirements

### 1. Visual Preview Container Below the Title
- Add a dedicated preview container on each draft reward card in the relic selection panel.
- Place the preview container directly underneath the title label and above the description text.
- Center the polyomino preview horizontally within the card frame.
- Keep card dimensions balanced and prevent visual clipping of description text.

### 2. Polyomino Footprint and Grid Layout Rendering
- Read the module shape and cell list from `PolyominoRelicDatabase` with the relic identifier.
- Draw each occupied cell on a compact local preview grid (for example: 20 to 24 pixels per cell).
- Apply comic-style dark ink border outlines to each cell.
- Color the cells based on the relic tier or rarity accent color (using `Constants.shop_rarity_accent_color(tier)`).
- Center multi-cell shapes (dominos, trominos, tetrominos, and mega-contraptions) in the preview bounds.

### 3. Machine Composition and Kinetic Icon Rendering
- Inspect the internal machinery definition of each cell (`cell_types` and `cell_directions` in `PolyominoModuleData`).
- Draw distinct glyphs or icons for internal kinetic components on occupied cells:
  - **Bumpers:** Circular bumper icon with a high-contrast inner ring.
  - **Accelerators:** Directional wedge pointing in the boost direction.
  - **Funnels:** Converging guide rails pointing toward the exit slot.
  - **Rotary Boosters:** Circular arc spinner with rotational tick marks.
  - **Specialized components:** Distinct kinetic component indicators.
- Show directional arrows when a component has an active flow direction.

### 4. Integration and Fallback Handling
- Connect the preview control to `major_upgrade_draft_panel.gd` during card creation (`_make_card`).
- Verify whether the offered upgrade resource has a matching polyomino relic definition in `PolyominoRelicDatabase`.
- When a matching relic exists, instantiate and show the polyomino layout preview.
- When an upgrade does not have a polyomino shape definition, show a clean fallback spacer to keep card layouts consistent.

### 5. Automated Tests and Verification
- Create headless unit tests in `tests/test_relic_selection_preview.gd`.
- Verify that every relic in `PolyominoRelicDatabase` generates a valid preview shape.
- Verify that cell bounds, dimensions, and machine glyph types match data definitions.
- Verify that draft cards construct cleanly with the preview control attached.

---

## Acceptance Criteria

- [ ] Relic selection cards show a polyomino layout preview directly underneath the card title.
- [ ] The preview renders the exact multi-cell spatial footprint of the relic.
- [ ] Cells show comic-style ink borders and tier-based accent colors.
- [ ] Internal kinetic machinery components (bumpers, accelerators, funnels, boosters) render clear glyphs.
- [ ] Multi-cell shapes are centered and scaled cleanly without clipping text or borders.
- [ ] Upgrades without polyomino definitions fall back cleanly without layout distortion.
- [ ] Headless unit tests verify preview generation and component rendering across all campaign relics.
