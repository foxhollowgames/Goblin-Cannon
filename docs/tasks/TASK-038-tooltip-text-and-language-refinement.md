# TASK-038: Tooltip Text and Language Refinement

- **Status:** READY
- **Priority:** P1
- **Category:** UI / Language Polish
- **Target Branch:** `feature/tooltip-text-refinement`
- **Related Tasks:** [TASK-028](TASK-028-junk-box-ui-opening-and-board-transfer.md), [TASK-035](TASK-035-relic-selection-layout-and-machinery-preview.md)

## Description

Audit and refine all in-game hover tooltips, keyword definitions, item descriptions, and milestone shop text.
Shorten long multi-line descriptions into concise, clear action phrases.
For example, change the Trampoline Peg description from multi-line text to a simple phrase: "Launches balls."

---

## Requirements

### 1. Description Shortening & Language Audit
- Review all item descriptions in `KeywordDatabase`, `MilestoneShopData`, and `PolyominoRelicDatabase`.
- Remove unnecessary multi-line explanations and technical jargon from hover tooltips.
- Simplify core item descriptions to direct action phrases (e.g., "Trampoline Peg: Launches balls.").
- Maintain clear readability without overwhelming the user with long text blocks.

### 2. Standardized Tooltip Format
- Enforce consistent line length limits (maximum 1–2 short sentences per tooltip).
- Ensure keyword flyouts present clean, bite-sized text.
- Preserve key gameplay metrics (e.g., exact energy numbers) where relevant while keeping descriptions brief.

### 3. UI Display & Layout Verification
- Verify that shortened tooltip strings fit cleanly inside UI popups without unnecessary line wraps.
- Ensure flyout card containers resize dynamically to match the shorter text dimensions.

### 4. Automated Tests
- Add unit tests in `tests/test_tooltip_text_refinement.gd`.
- Verify that `KeywordDatabase` entries satisfy maximum string length guidelines.
- Verify that all registered items and relics have valid, non-empty, concise descriptions.

---

## Acceptance Criteria

- [ ] All tooltip strings across items, pegs, and relics are audited and shortened.
- [ ] The Trampoline Peg tooltip is simplified to concise text ("Launches balls.").
- [ ] No tooltip exceeds 2 concise lines of text.
- [ ] Keyword database and shop data use direct action phrases.
- [ ] Headless unit tests verify string constraints and database definitions.
