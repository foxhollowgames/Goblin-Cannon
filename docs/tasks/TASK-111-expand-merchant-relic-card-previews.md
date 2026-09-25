# TASK-111: Expand Merchant relic card previews

- **Status:** DONE
- **Priority:** P1
- **Category:** UI / Visuals
- **Target Branch:** `fix/expand-merchant-relic-previews`
- **Related Tasks:** 

## Description

Expand Merchant relic card previews

---

## Requirements

### 1. Scope and Implementation
- Expand Merchant relic images within the available card height.
- Keep the reward line below the image and above the lower card border.

---

## Acceptance Criteria

- [x] Requirements implemented and verified.
- [x] Tests pass cleanly.
- [x] File lengths adhere to the 500-line repository limit.
- [x] Pull Request opened, audited by independent PR reviewer, and merged.

## Checkpoint — expanded relic image area

- Increased the Merchant relic preview height to 72 pixels.
- Increased the preview cell range while keeping the image inside the card width.
- Added a layout assertion for the expanded preview holder.
