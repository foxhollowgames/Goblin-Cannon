# TASK-117: Remove Merchant relic subtitle and enlarge image

- **Status:** DONE
- **Priority:** P2
- **Category:** UI / Visuals
- **Target Branch:** `fix/merchant-relic-image`
- **Related Tasks:** 

## Description

Remove Merchant relic subtitle and enlarge image

---

## Requirements

### 1. Scope and Implementation
- Implement specifications for Remove Merchant relic subtitle and enlarge image.

---

## Acceptance Criteria

- [x] Requirements implemented and verified.
- [x] Tests pass cleanly.
- [x] File lengths adhere to the 500-line repository limit.
- [x] Pull Request opened, audited by independent PR reviewer, and merged.

## Verification

- Removed the Merchant relic category subtitle. Increased image height from 72 to 90 pixels and maximum cell size from 18 to 30 pixels.
- Baseline at dbcb9cb: static checks passed; tooling checks hit sandbox temporary-folder permissions. The final audit passed with the required access.
- Local Qwen returned two unusable scripts (incorrect replacement keys, then requiring all strings in both files). Neither was applied. Used approved direct-edit fallback.
- Focused checks: Godot --headless --script .godot/task117/focused.gd; exit 0; 225 passed, 0 failed, no script errors.
- Full check: python scripts/audit_quality.py; exit 0; 20,710 passed, 0 failed, no script errors.
- Inspected .godot/task117/merchant.png with the five requested relics. Titles, larger images, reward lines, and prices fit.
- Physics checks do not apply to this layout-only change.
- Changed source: reward_draft_panel.gd and reward_card_builder.gd. No background processes remain.
- Usage window 1790494983: 50% gate observed. Only verified review and merge work remains.

Independent pr_reviewer approved PR #95 without findings. Review agent stopped. Merged as PR #95. Post-merge learning: LRN-154.

