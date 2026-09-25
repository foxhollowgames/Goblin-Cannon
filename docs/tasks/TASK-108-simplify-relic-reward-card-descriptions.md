# TASK-108: Simplify relic reward card descriptions

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** UI / Visuals
- **Target Branch:** `fix/simplify-relic-reward-descriptions`
- **Related Tasks:** 

## Description

Simplify relic reward card descriptions

---

## Requirements

### 1. Scope and Implementation
- Offerable relic cards show one concise `Reward: <count> <ball type>` line.
- Offerable relic cards do not repeat the trigger, kinetic description, or long reward sentence.
- Retired relic and non-relic card descriptions keep their existing fallback behavior.
- Shared reward badges use the same concise reward wording.

---

## Acceptance Criteria

- [x] Requirements implemented and verified.
- [x] Tests pass cleanly.
- [x] File lengths adhere to the 500-line repository limit.
- [ ] Pull Request opened, audited by independent PR reviewer, and merged.

## Checkpoint — concise reward card text

- Changed `scenes/rewards/major_upgrade_draft_panel.gd` to suppress duplicated trigger and effect blocks for offerable relics.
- Changed `scenes/rewards/reward_card_builder.gd` to use `Reward: <count> <ball type>` in shared badges.
- Added a card hierarchy test for `Twin Core Bumper Vessel`.
- Raw Godot result: `18,180 passed, 0 failed`.
