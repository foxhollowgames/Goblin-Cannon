# TASK-113: Restore keyword hover tooltips

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** UI / Tooltips
- **Target Branch:** `fix/restore-keyword-hover-tooltips`
- **Related Tasks:** 

## Description

Restore keyword hover tooltips

---

## Requirements

### 1. Scope and Implementation
- Ensure every shared RichTextLabel keyword helper enables BBCode parsing.
- Keep keyword labels hoverable and connected to the existing flyout signals.

---

## Acceptance Criteria

- [x] Requirements implemented and verified.
- [x] Tests pass cleanly.
- [x] File lengths adhere to the 500-line repository limit.
- [ ] Pull Request opened, audited by independent PR reviewer, and merged.

## Checkpoint — shared keyword label repair

- Enabled BBCode parsing and hover input in `KeywordDatabase.attach_rich_text_label`.
- Added assertions that shared labels parse keyword markup and accept hover input.
