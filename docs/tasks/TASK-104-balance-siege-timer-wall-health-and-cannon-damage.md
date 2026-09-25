# TASK-104: Balance Siege Timer Wall Health and Cannon Damage

- **Status:** BACKLOG
- **Priority:** P1
- **Category:** Balance / Gameplay
- **Target Branch:** `feature/siege-and-cannon-balance`
- **Related Tasks:** [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md), [TASK-101](TASK-101-remove-passive-upgrades-completely.md), [TASK-102](TASK-102-unlock-tier-3-relics-in-the-third-city.md), [TASK-103](TASK-103-validate-relic-variant-choices-in-reward-redesign.md), [TASK-105](TASK-105-validate-relic-reward-variety-through-special-ball.md)

## Description

Address audit point 5 within a comprehensive balance suite covering siege timer behavior, wall health, cannon damage, and energy throughput. The four-second time extension per shot is one part of the balance model, not an isolated timer fix.

## Dependencies

- Prepare measurements/model now; finalize tuning after the [TASK-100](TASK-100-design-temporary-special-ball-relic-rewards.md) reward design is implemented, [TASK-101](TASK-101-remove-passive-upgrades-completely.md) passive removal is in place, and [TASK-102](TASK-102-unlock-tier-3-relics-in-the-third-city.md) third-city progression is available.
- Coordinate with existing TASK-021 (siege) and TASK-022 (scaling); document this task as the follow-up tuning pass rather than duplicating their original implementation scope.

## Requirements

- Establish an explicit target for encounter duration, campaign duration, difficulty progression, failure/recovery behavior, and desired active routing versus passive waiting.
- Model cannon charge cost, energy production, damage per shot, firing cadence/burstiness, wall HP growth, timer length, extension amount/cap, and city transitions together.
- Analyze the current four-second-per-shot equilibrium: regular one-shot-per-four-second production can sustain the timer; at the 100-energy/10-damage baseline this corresponds to 25 energy and 2.5 damage per simulation second. Account for burst timing and wasted capped extensions.
- Compare candidate timer policies with corresponding HP/damage curves. Options may include a finite extension budget, diminishing extensions, or deliberately retaining a throughput threshold; choose based on the intended experience, not a preset fix.
- Include temporary-ball lifetime and population, device retention/circulation time, peg opportunity cost, special-ball chains, Tier 3 power growth, gold/pricing, and acquisition timing in representative build scenarios.
- Evaluate weak/ordinary/strong builds across all three cities and the existing endless mode separately. Avoid tuning only a best-case combo or one seed.
- Build a repeatable balance measurement suite and record seeds, input policies, build/layout, version, and metrics: wall-clear time, energy rate, shot cadence, timer trajectory, failure rate, activation frequency, and menu/transition time where relevant.
- Pair numerical evidence with playtests for agency, perceived pressure, time spent waiting after a fight is effectively solved, and understandable failure feedback.

## Acceptance Criteria

- [ ] Target pacing and difficulty criteria are written before selecting final values.
- [ ] Timer, wall health, cannon damage/charge, and relic throughput are evaluated as one model.
- [ ] The timer equilibrium is tested with regular and bursty firing and has an explicit design decision.
- [ ] Representative builds/seeds cover all three cities, third-city Tier 3 acquisition, and temporary-ball chains without passives.
- [ ] A repeatable balance suite and before/after results support the selected tuning.
- [ ] Playtest evidence checks both challenge and waiting time; no unmeasured claim of a universal sweet spot.
- [ ] Any implemented tuning completes required quality checks and the PR/review/merge/learning workflow.

## Approved reward baseline for measurements

TASK-106 implements the approved [temporary relic ball contract](../knowledge/temporary-relic-ball-plan.md). Treat its values as starting values, not proven balance.

- Compare all 21 same-tier family pairs with matched seeds, permanent balls, and occupied area. Include a no-relic control.
- Test sparse and dense peg layouts, slow and fast feeds, and high and low placements.
- Record activation time, temporary survival, collected energy, cannon shots, blocked count, canceled count, and peak active or reserved population.
- Test the ten-Rubbery and twelve-Plain Tier 3 rewards with other active relics. Check whether the 24-slot cap regularly prevents their advertised output.
- Record the peg opportunities lost to each device footprint. A reliable small device can outperform a larger reward with a difficult route.
- Keep the initial 720-tick life and six-tick spacing visible in the report. Compare changes to these values separately from reward type or quantity changes.
- Keep normal city gates and prices from TASK-102. The new acquisition roster contains only the 42 deliberate relics; legacy physical items are retained only for existing inventory compatibility.

Do not merge same-tier variants based only on equal energy totals. Require measured use cases and player feedback before changing retained geometry or migrating existing items.
