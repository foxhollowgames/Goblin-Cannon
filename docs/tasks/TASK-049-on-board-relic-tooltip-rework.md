# TASK-049: On-Board Relic Tooltip Information Rework

- **Status:** DONE
- **Priority:** P1
- **Category:** UI / Polish
- **Target Branch:** `feature/on-board-relic-tooltip-rework`
- **Related Tasks:** [TASK-028](TASK-028-junk-box-ui-opening-and-board-transfer.md), [TASK-038](TASK-038-tooltip-text-and-language-refinement.md), [TASK-047](TASK-047-pinball-widget-research-and-machine-layout-analysis.md), [TASK-053](TASK-053-relic-machinery-audit-and-widget-distribution.md)

## Description

Rework hover tooltips for polyomino relics on active pegboard layout to omit detailed specs like tier, size, and shape properties to avoid visual clutter, while displaying activation requirements and relic effects.
Preserve full item specifications on inventory cards in the Junk Box and shop.

---

## Requirements

### 1. Board Relic Tooltip Simplification
- Modify on-board relic hover tooltip generation to omit redundant structural metadata (Tier, Size, Cell count, Shape name).
- Display clear `[u]Activation Requirement[/u]` and `[u]Relic Effect[/u]` sections in the on-board tooltip body.

### 2. Inventory Tooltip Preservation
- Keep complete item specifications (tier, dimensions, shape, kinetic components) visible in the Junk Box inventory tooltips and shop card views.

### 3. Automated Tests
- Write unit tests in `tests/test_on_board_relic_tooltips.gd`.
- Verify that on-board tooltips omit tier, size, and shape properties.
- Verify that on-board tooltips contain activation requirements and effects.
- Verify that Junk Box tooltips retain full item specifications.

---

## Acceptance Criteria

- [x] Board relic tooltips omit tier, size, and shape properties.
- [x] Board relic tooltips clearly show Activation Requirement and Relic Effect sections.
- [x] Junk Box inventory tooltips preserve full item details (tier, size, shape).
- [x] Unit tests pass cleanly in headless mode.
