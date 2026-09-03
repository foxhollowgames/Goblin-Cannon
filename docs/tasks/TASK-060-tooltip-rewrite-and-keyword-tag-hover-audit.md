# TASK-060: In-Game Tooltip Rewrite and Keyword Tag Hover Audit

- **Status:** DONE
- **Priority:** P1
- **Category:** UI / Polish / Design
- **Target Branch:** `feature/tooltip-rewrite-and-keyword-tag-hover-audit`
- **Related Tasks:** [TASK-038](TASK-038-tooltip-text-and-language-refinement.md), [TASK-049](TASK-049-on-board-relic-tooltip-rework.md), [TASK-057](TASK-057-board-relic-tooltip-bbcode-rendering.md)

## Description

Perform a comprehensive rewrite and audit of all in-game hover tooltips, keyword flyout definitions, card descriptions, and shop text.
Tooltip copy and tag markup have drifted across recent game features:
1. Gameplay tags and keywords (such as `Energize`, `Drain`, `Chain Lightning`, and `Overdrive`) appear in descriptions without interactive hover states or keyword flyout bindings.
2. Several descriptions violate established game writing rules (concise action phrases, max 1–2 short lines, under 80 characters for glossary definitions, under 100 characters for item descriptions).
3. Tooltip text must be rewritten to provide immediate mechanical clarity without technical jargon or wordy explanations.

---

## Requirements

### 1. Keyword & Tag Hover State Audit
- Audit all gameplay keywords, tags, and status effects in `autoloads/keyword_database.gd`.
- Ensure all ability tags used in cards, relics, and board tooltips (e.g., `Energize`, `Supernova`, `Drain`, `Leech`, `Chain Lightning`, `Overdrive`, `Phantom`, `Volatile`, `Split`, `Bloom`, `Binary`, `Rubbery`) have valid definitions.
- Ensure all text surfaces displaying tags (relic tooltips, draft cards, shop cards) wrap keywords via `KeywordDatabase.format_bbcode` and connect hover signals via `KeywordDatabase.attach_rich_text_label`.
- Eliminate orphan tags (like `Energize`) that lack hover feedback or flyout explanations.

### 2. Tooltip Text & Writing Style Rewrite
- Audit and rewrite descriptions in `KeywordDatabase`, `MilestoneShopData`, `PolyominoRelicDatabase`, and `RewardCardCatalog`.
- Rewrite multi-line explanations into direct, active action phrases (for example: "Launches balls." or "Adds stacks that boost Energy and repair speed.").
- Enforce strict brevity limits:
  - Keyword definitions must not exceed 80 characters.
  - Shop and item descriptions must not exceed 100 characters.
  - No tooltip body must exceed 2 short lines in standard UI cards.
- Remove redundant technical jargon and align terminology across all ball, peg, and relic descriptions.

### 3. Flyout Tooltip UI Consistency
- Ensure keyword flyouts render cleanly through RichTextLabel BBCode nodes (aligned with [TASK-057](TASK-057-board-relic-tooltip-bbcode-rendering.md)).
- Ensure flyout positioning dynamically clamps within viewport margins and avoids flickering on hover.

### 4. Automated Tests
- Expand test coverage in `tests/test_tooltip_text_refinement.gd` and `tests/test_keyword_database.gd`.
- Verify that every registered ball ability, relic effect tag, and shop card keyword has a valid glossary entry.
- Verify that no tooltip, definition, or shop blurb exceeds length constraints (<= 80 chars for definitions, <= 100 chars for shop text).
- Verify that `format_bbcode` correctly detects and highlights `Energize` and other core tags.

---

## Acceptance Criteria

- [x] All gameplay tags (including `Energize`) display hover highlights and open keyword flyouts.
- [x] All tooltip, relic, and shop descriptions are rewritten to match established writing style rules.
- [x] No keyword definition exceeds 80 characters.
- [x] No shop or peg description exceeds 100 characters.
- [x] Tooltip strings fit cleanly in UI cards without exceeding 2 lines or clipping.
- [x] Headless unit tests pass cleanly without errors.
