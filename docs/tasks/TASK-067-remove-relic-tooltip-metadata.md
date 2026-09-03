# TASK-067: Remove Size, Shape, Components, Machinery & Effect, and Tier from Relic Tooltips

- **Status:** READY
- **Priority:** P1
- **Category:** UI / Polish
- **Target Branch:** `feature/remove-relic-tooltip-metadata`
- **Related Tasks:** [TASK-049](TASK-049-on-board-relic-tooltip-rework.md), [TASK-063](TASK-063-junk-box-relic-display-and-tooltip-fix.md), [TASK-068](TASK-068-relic-tier-visual-styling.md)

## Description

Remove redundant metadata text from the relic tooltips.
The tooltips in the Junk Box and on the board must show only essential relic information.
The tooltips will show the relic title, the activation requirement, and the relic effect.
Remove size, shape, components, machinery and effect, and tier text from the tooltips.
Relic tier will be shown visually through styling in [TASK-068](TASK-068-relic-tier-visual-styling.md).

---

## Requirements

### 1. Tooltip Text Simplification
- Remove the tier text from relic tooltips.
- Remove the size text from relic tooltips.
- Remove the shape text from relic tooltips.
- Remove the kinetic components count text from relic tooltips.
- Remove the Machinery and Effect section from relic tooltips.
- Keep the relic name, the activation requirement, and the relic effect in the tooltip body.

### 2. Inventory and Board Consistency
- Update the `_format_item_tooltip` function in `scenes/ui/junk_box/junk_box_panel.gd`.
- Verify the `_format_module_tooltip_body` function in `scenes/board/board.gd`.
- Make sure that both tooltips use the same clean structure.

### 3. Automated Tests
- Update `tests/test_on_board_relic_tooltips.gd`.
- Update `tests/test_junk_box_relic_display_and_tooltips.gd`.
- Verify that relic tooltips do not contain tier, size, shape, or component strings.
- Verify that relic tooltips contain activation requirements and relic effects.

---

## Acceptance Criteria

- [ ] Relic tooltips omit size, shape, components, and machinery and effect text.
- [ ] Relic tooltips omit tier text.
- [ ] Relic tooltips show the relic name, activation requirement, and relic effect.
- [ ] Unit tests verify the simplified tooltip format.
- [ ] All modified test and source files remain under 500 lines.
