# TASK-101: Remove Passive Upgrades Completely

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** Systems / Cleanup
- **Target Branch:** `fix/remove-passive-upgrades`
- **Related Tasks:** [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md), [TASK-102](TASK-102-unlock-tier-3-relics-in-the-third-city.md), [TASK-103](TASK-103-validate-relic-variant-choices-in-reward-redesign.md), [TASK-104](TASK-104-balance-siege-timer-wall-health-and-cannon-damage.md), [TASK-105](TASK-105-validate-relic-reward-variety-through-special-ball.md)

## Description

Completely remove passive upgrades from the current playable game for now. This resolves audit point 2 and establishes an active physical-device baseline for [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md). Do not retain a hybrid system with hidden or labeled placement-only bonuses.

## Requirements

- Inventory passive wall-break, boss, chest, and relic upgrades and all gameplay consumers before removing them. Include global bonuses enabled merely by placing a relic and permanent passive/stat-upgrade offerings wherever they remain exposed.
- Remove passive acquisition offers, application paths, slotting side effects, active-state flags/stacks, and runtime checks. Relic placement, movement, rotation, return to inventory, and removal must not enable global passive benefits.
- Update reward catalogs, cards, tooltips, glossary/almanac entries, and ordinary/debug stores so removed passives cannot be acquired or advertised as functioning upgrades.
- Preserve physical device activation, ordinary ball abilities, baseline game statistics, peg mechanics, and inventory bookkeeping. If an ID is needed for ownership/acquisition, store it independently of passive effect activation.
- Ensure old saved/debug/scenario data cannot reactivate passives; document safe migration or ignored legacy fields. Historical documents may remain labeled as historical, but no disabled effect should remain live through a compatibility path.
- Coordinate active reward replacements with [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md) and remove eligibility/cap logic that only exists to support the deleted passive system.
- Record the resulting progression/output baseline for [TASK-104](TASK-104-balance-siege-timer-wall-health-and-cannon-damage.md); avoid compensating by silently adding replacement passives.

## Source Pointers

- resources/polyomino/polyomino_relic_database.gd (placement registration)
- autoloads/game_state.gd (upgrade registries and consumers)
- scenes/board/board.gd and ball/peg gameplay consumers
- scenes/rewards/reward_handler.gd and reward_card_catalog.gd
- tests/test_slotted_relic_effects.gd

## Acceptance Criteria

- [ ] No passive upgrade can be acquired, applied, or activated in the current playable game, including through debug or legacy data paths.
- [ ] Installing/removing/repositioning a relic changes only its physical presence and bookkeeping; it grants no passive global/stat bonus.
- [ ] Reward descriptions and upgrade menus contain no functioning-passive promises.
- [ ] Ordinary ball/peg behavior and physical activation rewards continue to function.
- [ ] Tests prove former passive effects stay absent even when legacy IDs/data are supplied.
- [ ] Required directory maintenance, lint/file-length checks, headless tests, independent PR review, merge, and learning capture complete when implemented.


## Execution note

The consumer inventory and migration baseline are recorded in [Passive removal baseline](../knowledge/passive-removal-baseline.md). Repeated local Qwen attempts produced invalid or incomplete edits. Rejected code was removed. No gameplay changes have shipped. Awaiting the user's answer on allowing direct code edits for this run. TASK-102 remains queued after this task.

