# TASK-076: Unify Junk Box and Board Relic Hover Tooltips

- **Status:** DONE
- **Priority:** P1
- **Category:** UI / Systems
- **Target Branch:** `feature/unify-junk-box-and-board-relic-tooltips`
- **Related Tasks:** [TASK-049](TASK-049-on-board-relic-tooltip-rework.md), [TASK-063](TASK-063-junk-box-relic-display-and-tooltip-fix.md), [TASK-067](TASK-067-remove-relic-tooltip-metadata.md), [TASK-075](TASK-075-update-relic-hover-tooltips.md)

## Description

Unify hover tooltips between the Junk Box inventory and the board.
Use the board version of the tooltips as the single standard.
Both locations must show identical formatting, layout, and content.

---

## Requirements

### 1. Unified Tooltip Formatter
- Use a single shared function to format relic tooltips.
- Prevent duplicate tooltip formatting logic in `board.gd` and `junk_box_panel.gd`.
- Make sure that both systems produce identical tooltip text and styling.

### 2. Board Standard Compliance
- Apply the board tooltip standard to the Junk Box inventory.
- Include the relic title, `[u]Activation Requirement[/u]`, and `[u]Relic Effect[/u]`.
- Do not show size, shape, tier, or kinetic component lists.
- Support board charge progress strings when a relic is placed on the board.

### 3. Flyout Presentation Consistency
- Verify that `KeywordDatabase.show_flyout_custom` displays consistently in both views.
- Make sure that hover detection, mouse offset positioning, and dismissal behavior remain consistent.

### 4. Automated Tests
- Update `tests/test_junk_box_relic_display_and_tooltips.gd`.
- Update `tests/test_on_board_relic_tooltips.gd`.
- Verify that tooltips generated from the Junk Box and the board match exactly.

---

## Acceptance Criteria

- [x] A shared formatter generates relic hover tooltips for both the Junk Box and the board.
- [x] Junk Box tooltips match the board tooltip format exactly.
- [x] Duplicate tooltip formatting logic is removed from `junk_box_panel.gd`.
- [x] Board-specific dynamic progress continues to show for placed relics.
- [x] Headless unit tests pass.
- [x] All modified source files remain under 500 lines.
