# TASK-082: Simplify Relic Tooltip Terminology and Section Headers

- **Status:** IN_REVIEW
- **Priority:** P1
- **Category:** UI / Polish
- **Target Branch:** `feature/simplify-relic-tooltip-terminology`
- **Related Tasks:** [TASK-038](TASK-038-tooltip-text-and-language-refinement.md), [TASK-049](TASK-049-on-board-relic-tooltip-rework.md), [TASK-060](TASK-060-tooltip-rewrite-and-keyword-tag-hover-audit.md), [TASK-067](TASK-067-remove-relic-tooltip-metadata.md), [TASK-075](TASK-075-update-relic-hover-tooltips.md), [TASK-076](TASK-076-unify-junk-box-and-board-relic-tooltips.md)

## Description

Simplify the terminology and structure of all relic tooltips.
Remove unclear terms such as "Concussive Overdrive Blast" that do not explain mechanics clearly.
Simplify condition phrasing such as "Knock down both drop targets" to "Knock down targets".
Rename the tooltip section headers from "Activation Requirement" to "Trigger", and from "Relic Effect" to "Effect".

---

## Requirements

### 1. Section Header Updates
- Change the header `[u]Activation Requirement[/u]` to `[u]Trigger[/u]`.
- Change the header `[u]Relic Effect[/u]` to `[u]Effect[/u]`.
- Update `format_relic_tooltip()` in `resources/polyomino/polyomino_relic_database.gd`.
- Make sure that both board tooltips and Junk Box tooltips show the new section headers.

### 2. Removal of Unclear Reward Phrasing
- Remove meaningless text like "Concussive Overdrive Blast" from relic reward descriptions.
- Replace that text with clear, direct mechanical descriptions (for example: energy values or impulse effects).
- Update affected relics in `resources/polyomino/polyomino_relic_database.gd` (such as `rubber_storm`, `supernova_peg`, and `explosion_radius`).

### 3. Simplification of Activation Descriptions
- Simplify wordy activation text across all relic definitions.
- Change phrases like "Knock down both drop targets" to concise phrases like "Knock down targets".
- Keep activation conditions short, plain, and easy to read.

### 4. Automated Tests and Verification
- Update unit test assertions that check for the old section headers.
- Update `tests/test_on_board_relic_tooltips.gd`, `tests/test_keyword_flyout_tooltip.gd`, and `tests/test_junk_box_relic_display_and_tooltips.gd`.
- Update `tests/test_debug_board_machinery_showcase.gd` and `tests/test_relic_pinball_activation.gd`.
- Verify that all headless unit tests pass cleanly.

---

## Acceptance Criteria

- [x] Relic tooltips show the header "[u]Trigger[/u]" instead of "[u]Activation Requirement[/u]".
- [x] Relic tooltips show the header "[u]Effect[/u]" instead of "[u]Relic Effect[/u]".
- [x] Meaningless jargon such as "Concussive Overdrive Blast" is removed from relic descriptions.
- [x] Activation language is simplified across all Campaign 1 relics (such as "Knock down targets").
- [x] All unit tests pass cleanly without errors.
- [x] All modified source files remain under 500 lines.
