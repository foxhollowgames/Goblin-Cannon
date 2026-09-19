# TASK-102: Unlock Tier 3 Relics in the Third City

- **Status:** READY
- **Priority:** P1
- **Category:** Progression / Rewards
- **Target Branch:** `feature/third-city-tier-three-relics`
- **Related Tasks:** [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md), [TASK-101](TASK-101-remove-passive-upgrades-completely.md), [TASK-103](TASK-103-validate-relic-variant-choices-in-reward-redesign.md), [TASK-104](TASK-104-balance-siege-timer-wall-health-and-cannon-damage.md), [TASK-105](TASK-105-validate-relic-reward-variety-through-special-ball.md)

## Description

Make Tier 3 relics available through normal play in the third city (Elf Palace; current zero-based city index 2). This resolves audit point 3 and overrides the earlier shop Tier 2 ceiling for that city.

## Requirements

- Define and apply city-based eligibility consistently: the third city's normal relic pool must include Tier 3; do not restrict these relics to debug stores or the reward after the third city is already finished.
- Extend third-city merchant generation to support Tier 3 eligibility and a nonzero selection weight. Preserve lower-tier options where the progression design calls for them; Tier 3 availability does not mean every offer must be Tier 3.
- Unify or reconcile shop, wall-break, boss, and chest acquisition sources against the production relic roster. Document each relic's intended normal source and earliest eligible city.
- Audit all 14 deliberate Tier 3 entries. Give every retained production entry a normal acquisition route in the third city, including the 10 absent from the audited normal reward lists.
- Keep normal Tier 3 acquisition gated out of cities one and two unless a separately specified exception is intentionally adopted. Debug access remains a separate concern.
- Include pricing/affordability and enough purchase/reward opportunities before the final encounter; hand numeric tuning to [TASK-104](TASK-104-balance-siege-timer-wall-health-and-cannon-damage.md).
- Coordinate roster changes with [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md) and passive removal with [TASK-101](TASK-101-remove-passive-upgrades-completely.md). Do not restore passive rewards while repairing availability.

## Source Pointers

- scenes/rewards/reward_handler.gd:get_milestone_reward_picks
- simulation/reward_generation.gd:pick_milestone_options
- scenes/rewards/reward_card_catalog.gd
- resources/polyomino/deliberate_relic_catalog.gd
- autoloads/constants.gd (rarity weights and prices)

## Acceptance Criteria

- [ ] Third-city merchant offers can contain Tier 3 relics with nonzero probability during the city.
- [ ] Every retained production Tier 3 relic has an explicit, reachable normal third-city source.
- [ ] Earlier-city eligibility and intended lower-tier availability are preserved and tested.
- [ ] Deterministic acquisition tests cover eligibility, weights, roster reachability, duplicates, and purchase-to-inventory flow.
- [ ] Pricing and timing are checked for practical acquisition before the third city ends.
- [ ] Required quality checks and the implementation PR/review/merge workflow complete.
