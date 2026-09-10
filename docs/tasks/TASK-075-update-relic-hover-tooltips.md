# TASK-075: Update All Relic Hover Tooltips

- **Status:** DONE
- **Priority:** P1
- **Category:** UI / Polish
- **Target Branch:** `feature/update-relic-hover-tooltips`
- **Related Tasks:** [TASK-049](TASK-049-on-board-relic-tooltip-rework.md), [TASK-060](TASK-060-tooltip-rewrite-and-keyword-tag-hover-audit.md), [TASK-067](TASK-067-remove-relic-tooltip-metadata.md), [TASK-071](TASK-071-diegetic-relic-activation-categories.md), [TASK-076](TASK-076-unify-junk-box-and-board-relic-tooltips.md)

## Description

Audit and update hover tooltips for all relics in Campaign 1.
Make sure all relic tooltips show accurate activation requirements and clear relic effects.
Align the tooltip text with physical machinery archetypes and diegetic board cues.

---

## Requirements

### 1. Relic Tooltip Audit
- Inspect all relic definitions in `resources/polyomino/polyomino_relic_database.gd`.
- Verify that every relic has a clean title, an activation requirement, and a relic effect.
- Remove vague descriptions and outdated text.

### 2. Physical Machinery Alignment
- Match activation requirement text to the physical components of each relic.
- Use consistent pinball terminology (for example: drop targets, pop bumpers, and spinners).
- Follow the activation categories defined in `docs/knowledge/relic-activation-categories.md`.

### 3. Text Formatting and Clarity
- Use approved BBCode formatting for titles and section headers.
- Keep the tooltip descriptions concise and readable.
- Make sure that values, counts, and duration numbers match gameplay logic.

### 4. Automated Tests
- Update unit tests in `tests/test_on_board_relic_tooltips.gd`.
- Update unit tests in `tests/test_tooltip_text_refinement.gd`.
- Verify that all relic tooltips contain valid activation and effect text.

---

## Acceptance Criteria

- [x] All Campaign 1 relics have updated hover tooltip text.
- [x] Tooltips accurately describe physical activation requirements.
- [x] Tooltips clearly describe relic rewards and effects.
- [x] Headless unit tests pass.
- [x] All modified source files remain under 500 lines.

