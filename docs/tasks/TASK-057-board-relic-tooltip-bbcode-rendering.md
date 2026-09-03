# TASK-057: Board Relic Tooltip BBCode Formatting and Text Styling

- **Status:** DONE
- **Priority:** P1
- **Category:** UI / Polish
- **Target Branch:** `fix/board-relic-tooltip-bbcode-rendering`
- **Related Tasks:** [TASK-048](TASK-048-relic-activation-requirements-pinball-widget-rework.md), [TASK-049](TASK-049-on-board-relic-tooltip-rework.md)

## Description

Fix the text styling for on-board relic hover tooltips to render BBCode formatting instead of raw markup tags.
The tooltip body currently displays raw [u] tags because the flyout component uses a standard Label control instead of a BBCode-capable RichTextLabel.

---

## Requirements

### 1. Flyout Tooltip BBCode Support
- Update the instant flyout tooltip system in `autoloads/keyword_database.gd`.
- Replace the plain Label node for `_flyout_body` with a `RichTextLabel` node.
- Enable BBCode parsing (`bbcode_enabled = true`) on the flyout body control.
- Configure `autowrap_mode`, `fit_content = true`, and size constraints to keep the panel compact and legible.

### 2. Board Relic Hover Tooltip Formatting
- Verify that on-board relic tooltip text in `scenes/board/board.gd` parses cleanly without visible markup tags.
- Make sure headers such as `[u]Activation Requirement[/u]`, `[u]Relic Effect[/u]`, and `[u]Charge Progress[/u]` render with proper styling.

### 3. Automated Tests
- Add unit tests in `tests/test_keyword_flyout_tooltip.gd` or update existing tooltip test suites.
- Verify that the KeywordDatabase flyout body is a RichTextLabel with BBCode enabled.

- Verify that tooltips format correctly without displaying raw BBCode tags.

---

## Acceptance Criteria

- [x] On-board relic hover tooltips render formatted text without raw BBCode tags.
- [x] KeywordDatabase flyout body uses a RichTextLabel with `bbcode_enabled = true`.
- [x] The flyout panel sizes correctly and clamps within viewport boundaries.
- [x] All automated tests pass cleanly in headless mode.
- [x] All modified files adhere to the 500-line repository limit.
