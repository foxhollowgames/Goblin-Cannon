# TASK-101: Remove Passive Upgrades Completely

- **Status:** DONE
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

- [x] No passive upgrade can be acquired, applied, or activated in the current playable game, including through debug or legacy data paths.
- [x] Installing/removing/repositioning a relic changes only its physical presence and bookkeeping; it grants no passive global/stat bonus.
- [x] Reward descriptions and upgrade menus contain no functioning-passive promises.
- [x] Ordinary ball/peg behavior and physical activation rewards continue to function.
- [x] Tests prove former passive effects stay absent even when legacy IDs/data are supplied.
- [x] Required directory maintenance, lint/file-length checks, headless tests, independent PR review, merge, and learning capture complete when implemented.


## Execution note

The consumer inventory and migration baseline are recorded in [Passive removal baseline](../knowledge/passive-removal-baseline.md). Repeated local Qwen attempts produced invalid or incomplete edits. Rejected code was removed. No gameplay changes have shipped. The user authorized a lower-grade Codex fallback after three consecutive Qwen review failures. That threshold was met for this implementation. A GPT-5.6 Luna agent is implementing the task; independent review and all quality checks still apply. TASK-102 remains queued after this task.



## Allowance checkpoint — 2026-09-22

The included weekly allowance refreshed and work resumed. The shorter usage window then reached 88% used. Work paused before credits were needed. The credit balance did not change. Resume is scheduled for 2026-09-23 at 00:30 America/Denver, after the 00:25 reset.

The lower-grade fallback implementation is saved on this branch. It removes passive gameplay consumers, ignores old passive state, preserves physical reward items, updates physical inventory counts, and updates regression tests. The full local audit passed after the final edits: directory sync, GDScript lint, file lengths, and headless Godot tests.

Remaining: inspect the final diff and test coverage, open the PR, obtain independent review, resolve findings, merge, and record learnings. No TASK-101 gameplay changes have shipped. TASK-102 remains queued. TASK-100 remains plan-only.

## Review checkpoint — 2026-09-23

PR: https://github.com/foxhollowgames/Goblin-Cannon/pull/82. Independent review found one remaining glossary correction. No other gameplay defect was found. The full audit passed before review. The glossary correction is in progress. Merge and learning capture remain.


Independent reviewer approved the glossary correction. The complete quality audit passed again on 2026-09-23. Ready to merge PR #82.


## Completion

Merged PR #82 at 3e1a486. Independent review approved the final correction. All quality checks passed. Post-merge learning recorded. Earlier execution notes are historical checkpoints.

