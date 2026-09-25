# TASK-110: Fix Merchant peg and relic card descriptions

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** UI / Visuals
- **Target Branch:** `fix/merchant-card-description-layout`
- **Related Tasks:**

## Description

Fix Merchant peg and relic card descriptions

---

## Requirements

### 1. Scope and Implementation
- Keep peg, ball, stat, and relic descriptions below their visual preview rows.
- Stack relic previews and reward labels vertically so reward text cannot overlap the relic image.
- Preserve the existing concise reward wording and card descriptions.

---

## Acceptance Criteria

- [x] Requirements implemented and verified.
- [x] Tests pass cleanly.
- [x] File lengths adhere to the 500-line repository limit.
- [ ] Pull Request opened, audited by independent PR reviewer, and merged.

## Checkpoint — separated Merchant preview and reward rows

- Changed `scenes/rewards/reward_card_builder.gd` so relic images and reward labels use separate vertical rows.
- Updated `tests/test_relic_visual_tiles.gd` to verify the image and reward rows do not share an overlapping container.
- Raw Godot result: `18,185 passed, 0 failed`.
- The repository linter reports 32 existing function-length warnings; no new file-length violations were found.
