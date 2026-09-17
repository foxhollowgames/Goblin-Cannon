# TASK-096: Archive Ball Upgrades in Merchant and Refocus Shop on Relics

- **Status:** DONE
- **Priority:** P1
- **Category:** Systems / Gameplay
- **Target Branch:** `feature/archive-ball-upgrades-in-merchant-and-refocus-shop`
- **Related Tasks:** [TASK-008](TASK-008-build-archetypes-and-synergies.md), [TASK-048](TASK-048-relic-activation-requirements-pinball-widget-rework.md), [TASK-093](TASK-093-rework-relics-into-deliberate-pinball-devices.md), [TASK-094](TASK-094-update-debug-menu-stores-with-new-relics.md)

## Description

Archive ball and stat upgrades in the merchant shop and orient the shop around deliberate relics. Balls and stats must no longer be offered in the merchant shop. The shop will offer deliberate relics (alongside peg upgrades) that transfer directly to the player's Junk Box upon purchase. Relic generation follows the level's rarity scale but strictly defaults to the lowest tier (Tier 1 Common relics for early cities), leaving rarer Tier 2 and Tier 3 relics for wall break rewards. Relic trigger mechanics and temporary ball rewards are deferred for future iteration.

---

## Requirements

### 1. Archive Ball and Stat Upgrades in Merchant Shop
- Remove and archive `MilestoneOption.Type.BALL_UPGRADE` and `MilestoneOption.Type.STAT` from merchant shop generation (`simulation/reward_generation.gd`, `scenes/rewards/reward_handler.gd`).
- Remove ball and stat purchase cards from the merchant shop UI (`scenes/rewards/reward_draft_panel.gd`, `scenes/rewards/reward_card_builder.gd`).
- Ensure balls and stats are not purchasable in the merchant storefront.

### 2. Relic Offerings in Merchant Shop
- Introduce deliberate relic purchase options into the milestone/merchant shop candidate pool (`MilestoneOption.Type.RELIC`).
- Populate merchant relic offerings from `DeliberateRelicCatalog` / `PolyominoRelicDatabase` with appropriate tier weighting and gold pricing.
- Respect the current level/city rarity progression, but strictly bias toward the lowest end (Tier 1 Common relics), reserving higher tiers for wall breaks.
- Purchasing a relic immediately places the item into the player's Junk Box inventory (`GameState.junk_box`), ready for board placement.

### 3. Code Standards & File Lengths (Rule 7)
- Maintain all modified files strictly <= 500 lines:
  - `simulation/reward_generation.gd`
  - `scenes/rewards/reward_handler.gd`
  - `scenes/rewards/reward_draft_panel.gd`
  - `scenes/rewards/reward_card_builder.gd`
  - `resources/rewards/milestone_option.gd`
  - `autoloads/constants.gd`
- Run `python scripts/lint_gdscript.py` and `python scripts/lint_file_lengths.py`.

### 4. Verification & Headless Testing
- Author unit tests in `tests/test_shop_relic_focus.gd` verifying:
  - Merchant generator yields zero ball and stat upgrade options.
  - Merchant generator yields deliberate relic options matching the city's lowest tier bias.
  - Relic purchase successfully transfers the item to `GameState.junk_box`.
  - All modified files pass linting and headless test suites cleanly.
- Ensure all tests pass under `godot --headless -s tests/run_tests.gd`.

---

## Acceptance Criteria

- [ ] Ball upgrades and stat upgrades are archived and removed from merchant shop candidate generation.
- [ ] Deliberate relics are offered for gold in the merchant shop.
- [ ] Relics offered default to the lowest tier for the current city (Tier 1 Common in City 0/1).
- [ ] Purchased relics immediately transfer to the player's Junk Box.
- [ ] All modified files comply with the 500-line limit and coding standards.
- [ ] Headless tests pass cleanly with zero regressions.


