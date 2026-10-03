# TASK-122: Restore main screen gold counter

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** UI / Visuals
- **Target Branch:** `codex/restore-main-gold-counter`
- **Related Tasks:** 

## Description

Restore main screen gold counter

---

## Requirements

### 1. Scope and Implementation
- Implement specifications for Restore main screen gold counter.

---

## Acceptance Criteria

- [ ] Requirements implemented and verified.
- [ ] Tests pass cleanly.
- [ ] File lengths adhere to the 500-line repository limit.
- [ ] Required checks and review for the chosen workflow passed; Pull Request merged.

## Current Checkpoint

- Light workflow: five scene layout values changed.
- Counter moved beside Debug. Icon enlarged to 24 pixels, number to 22 pixels.
- Godot 4.6.2: raw exit 0, 11 passed, 0 failed, no SCRIPT ERROR.
- Render verified: starting gold 10 is clearly visible.
- Evidence: tmp/gold-counter contains raw stdout, stderr, exit codes, and after.png.
- Direct implementation followed the workflow read at start. Delegation rules changed concurrently after implementation.
- Other concurrent changes must be preserved.
- Owned processes: none.

