# TASK-102: Unlock Tier 3 Relics in the Third City

- **Status:** IN_REVIEW
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


## Checkpoint — 2026-09-23

TASK-101 merged in PR #82 at 3e1a486. Its learning and DONE status are included in this branch.

TASK-102 implementation is in progress. Local Qwen generated the changes in reward_handler.gd and reward_generation.gd. Accepted fragments add city gates, all-production merchant candidates, all Tier 3 wall candidates in city three, early boss fallback, and epic-roll Tier 3 selection. No passive effects return. The acquisition document records all 122 IDs, weights, prices, and free wall routes. The changes are not validated or submitted yet.

Qwen review history: a pool helper initially used an undeclared function; the corrected draft passed review. The main method draft used invalid nullable syntax, then a retry used Boolean city selection; its third draft passed review. These were not three consecutive failures. The first full test draft was rejected for invalid GDScript and invented APIs. A separate one-line registration draft lacked quotes. A 14B test rewrite was stopped at the allowance checkpoint before it returned. Do not claim three failed test reviews yet. Continue Qwen first; try smaller test fragments or a smaller local context. The 14B model used 32768 context and CPU offload, which was slow.

Accepted and rejected scratch outputs are in scratch_task102, outside production tests. The rejected test file is a text draft. No new test has been registered. Required tests: all source city gates and offer duplicates, all production Tier 3 and all 14 deliberate Tier 3 reachable in merchant AND free wall pools across deterministic seeds, explicit tier-roll weights, repeat-seed results, and purchase flow at 39/40 gold with duplicate purchase blocked. RewardDraftPanel._on_pick_pressed can be exercised with _picks and _purchased_flags and its pick_selected signal connected to RewardHandler.apply_milestone_pick.

Run the full quality audit with elevated execution; sandbox Godot cannot write its log. The accidental sandbox lint was stopped, and only the pre-existing Godot editor remained. No TASK-102 audit has passed. Next steps: finish tests with Qwen, validate and review the source and documentation, open PR, independent review, merge, and record learning. TASK-100 remains plan-only.

Included shorter allowance reached 93% used; credits were unchanged. Paused before paid usage. Next reset is 2026-09-23 05:30:29 America/Denver. Resume scheduled for 05:35.

## Verification — 2026-09-23

Local Qwen produced all implementation and test code. Smaller corrected test fragments passed review. The full quality audit passed: directory sync, GDScript lint, file lengths, and headless tests. The new suite checks all source city gates, all production Tier 3 reachability in shops and free wall rewards across 500 seeds, all 14 deliberate Tier 3 entries, tier rolls, repeat-seed offers, duplicate merchant offers, and 39/40-gold purchase behavior. Rejected scratch drafts were removed. Independent PR review and merge remain.

See [acquisition routes](../knowledge/third-city-relic-acquisition.md) for the roster, weights, cost, and timing.

