# TASK-105: Validate Relic Reward Variety Through Special Balls

- **Status:** DONE
- **Priority:** P1
- **Category:** Design / Relics
- **Target Branch:** `feature/relic-reward-variety-validation`
- **Related Tasks:** [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md), [TASK-101](TASK-101-remove-passive-upgrades-completely.md), [TASK-102](TASK-102-unlock-tier-3-relics-in-the-third-city.md), [TASK-103](TASK-103-validate-relic-variant-choices-in-reward-redesign.md), [TASK-104](TASK-104-balance-siege-timer-wall-health-and-cannon-damage.md)

## Description

Track audit point 6 as a required workstream inside [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md): create reward variety through different temporary special balls rather than a roster dominated by interchangeable flat energy bonuses. This shares the parent design and implementation plan; do not create an independent reward system.

## Dependencies and Ownership

- Work alongside [TASK-103](TASK-103-validate-relic-variant-choices-in-reward-redesign.md) while [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md) is being designed.
- The deliverable belongs in the parent reward design document; completion means the design has passed these checks, not that the future implementation is finished.

## Requirements

- Use the audit baseline (32 of 42 deliberate relics dispatch ENERGY_SURGE, with all 14 Tier 1 entries using it) as a diagnostic, not an arbitrary percentage target.
- Map all seven families to distinct physical jobs and proposed temporary-ball rewards: bumper chambers, word banks, reservoirs, slingshots, bash toys, spinners, and tracks.
- Explain how reward balls change route choice, traffic distribution, timing, burst versus sustained output, or downstream interactions. A different color/name or energy amount alone is not sufficient variety.
- Provide early-game examples as well as Tier 2/3 developments; special-ball choice should become understandable before the third city.
- Specify representative complementary and competing device chains, including relevant limits and expiration behavior from [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md).
- Keep the player-facing vocabulary compact and physical feedback readable. Never substitute passive buffs for temporary-ball differentiation.
- Pass proposed output/chain scenarios to [TASK-104](TASK-104-balance-siege-timer-wall-health-and-cannon-damage.md) for whole-game balance rather than declaring equal numerical payouts equivalent in value.

## Acceptance Criteria

- [x] The parent design includes a seven-family reward-role matrix with explicit temporary special-ball behavior.
- [x] Early-game relic choices include meaningfully different reward behavior and clear explanations.
- [x] Concrete chain/layout examples demonstrate different decisions, not only different energy totals.
- [x] Lifetimes, limits, and feedback are consistent with the parent lifecycle design.
- [x] Findings feed [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md) and [TASK-103](TASK-103-validate-relic-variant-choices-in-reward-redesign.md) directly, without separate redesign or passive-upgrade reintroduction.

## Design approval — 2026-09-23

The user approved the revised plan for execution. The approved document contains the full 42-entry reward mapping, same-tier choices, physical roles, chain examples, lifecycle rules, and verification requirements. Earlier discussion notes are historical. Implementation is tracked in TASK-106. Final balance and comparative playtesting remain in TASK-104; this completion records design acceptance only.
