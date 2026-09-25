# TASK-108: Simplify relic reward card descriptions

- **Status:** DONE
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
- [x] Pull Request opened, audited by independent PR reviewer, and merged.

## Checkpoint — concise reward card text

- Changed `scenes/rewards/major_upgrade_draft_panel.gd` to suppress duplicated trigger and effect blocks for offerable relics.
- Changed `scenes/rewards/reward_draft_panel.gd` to remove the verbose Merchant description for offerable relics.
- Changed `scenes/rewards/reward_card_builder.gd` to use `Reward: <count> <ball type>` in shared badges.
- Added card hierarchy checks for `Twin Core Bumper Vessel` in both reward card paths.
- Raw Godot result: `18,181 passed, 0 failed`.
