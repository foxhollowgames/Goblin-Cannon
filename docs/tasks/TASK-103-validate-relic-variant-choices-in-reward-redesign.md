# TASK-103: Validate Relic Variant Choices in Reward Redesign

- **Status:** BACKLOG
- **Priority:** P1
- **Category:** Design / Relics
- **Target Branch:** `feature/relic-variant-design-validation`
- **Related Tasks:** [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md), [TASK-101](TASK-101-remove-passive-upgrades-completely.md), [TASK-102](TASK-102-unlock-tier-3-relics-in-the-third-city.md), [TASK-104](TASK-104-balance-siege-timer-wall-health-and-cannon-damage.md), [TASK-105](TASK-105-validate-relic-reward-variety-through-special-ball.md)

## Description

Track audit point 4 as a required design-validation workstream inside [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md). Resolve redundant or strictly inferior same-tier variants through that task's temporary special-ball reward design. Do not launch a separate reward redesign or limit the solution to flat numerical buffs.

## Dependencies and Ownership

- Design owner: [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md); begin comparisons while that design is being developed.
- This task's output is a section of the same reward design document. Close this design-validation packet only when that section passes the criteria below.
- Gameplay implementation follows the parent design's implementation plan; this packet does not claim that planned changes already shipped.

## Requirements

- Compare normalized runtime geometry, not just authored names/shapes. Include G-O-B versus P-O-P, both Tier 1 spinner variants, and the Tier 2 spinner pair from the audit.
- For every same-tier family pair, compare footprint, entrance/exit, traffic needs, activation, temporary-ball behavior, lifetime/count, price, and downstream combinations.
- Give each retained variant a concrete context where it is preferable. Distinguish temporary-ball reward behavior and physical routing/timing costs; cosmetic differences and a larger energy number are insufficient.
- If no distinct role is justified, recommend merging or retiring the redundant variant and specify how acquisition and existing items should map.
- Preserve TASK-093 physical accessibility and port/rotation contracts when proposing differentiated geometry.
- Define comparative playtests with matched seeds/inputs and baseline peg opportunity cost. Final numerical tuning is owned by [TASK-104](TASK-104-balance-siege-timer-wall-health-and-cannon-damage.md).

## Acceptance Criteria

- [ ] The [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md) design contains a complete same-tier variant comparison.
- [ ] The named word-bank/spinner pairs have explicit differentiation or merge/retire decisions.
- [ ] Every retained alternative has an explainable use case and tradeoff using the proposed temporary-ball system.
- [ ] No intended choice is justified solely by a cosmetic label or unopposed higher payout.
- [ ] Comparative validation scenarios are handed to the parent implementation plan and balance suite.
