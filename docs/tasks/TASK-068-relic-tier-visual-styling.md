# TASK-068: Visual Representation of Relic Tiers Through Styling

- **Status:** BACKLOG
- **Priority:** P2
- **Category:** UI / Visuals / Art
- **Target Branch:** `feature/relic-tier-visual-styling`
- **Related Tasks:** [TASK-024](TASK-024-polyomino-relic-shapes-and-sizes.md), [TASK-063](TASK-063-junk-box-relic-display-and-tooltip-fix.md), [TASK-067](TASK-067-remove-relic-tooltip-metadata.md)

## Description

Represent the relic tier visually through graphic styling instead of text numbers in tooltips.
Apply visual styling rules to polyomino relics on the board, in the Junk Box, and in shops.
Each relic tier must have distinct visual styling.

---

## Requirements

### 1. Visual Tier Styling System
- Define visual styles for each relic tier (Tier 1 through Tier 4+).
- Use distinct border colors, corner accents, or outer glow effects for different tiers.
- Apply the tier styling to polyomino modules in `PolyominoModuleNode` and `JunkBoxGridView`.

### 2. Shop and Preview Alignment
- Show the visual tier styling on relic draft cards and shop previews.
- Make sure that players can identify the relic tier quickly without reading text.

### 3. Visual Hierarchy
- Keep the comic ink aesthetic consistent across all relic tiers.
- Make sure that high-tier visual accents do not hide kinetic machinery glyphs or ball paths.

---

## Acceptance Criteria

- [ ] Visual styling rules are defined for each relic tier.
- [ ] Relic modules display tier styling on the board and in the Junk Box.
- [ ] Relic draft cards and shop views reflect the tier styling.
- [ ] Unit tests verify tier style mapping for relic data resources.
- [ ] All modified source files remain under 500 lines.
