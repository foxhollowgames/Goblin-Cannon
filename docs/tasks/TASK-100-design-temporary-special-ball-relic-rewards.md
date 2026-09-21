# TASK-100: Design Temporary Special Ball Relic Rewards

- **Status:** READY
- **Priority:** P1
- **Category:** Design / Relics
- **Target Branch:** `feature/temporary-special-ball-reward-design`
- **Related Tasks:** [TASK-101](TASK-101-remove-passive-upgrades-completely.md), [TASK-102](TASK-102-unlock-tier-3-relics-in-the-third-city.md), [TASK-103](TASK-103-validate-relic-variant-choices-in-reward-redesign.md), [TASK-104](TASK-104-balance-siege-timer-wall-health-and-cannon-damage.md), [TASK-105](TASK-105-validate-relic-reward-variety-through-special-ball.md)

## Description

Design and plan a relic reward system centered on different temporary special balls produced by physical relic activations. This owns audit point 1 and the redesign work needed to resolve audit points 4 and 6. This packet is design/planning only; creating it does not authorize implementing the reward redesign.

## User Direction

- Different relic rewards should provide temporary special balls.
- Passive upgrades are being completely removed for now under [TASK-101](TASK-101-remove-passive-upgrades-completely.md). Do not design a hybrid passive/active system.
- Variant differentiation ([TASK-103](TASK-103-validate-relic-variant-choices-in-reward-redesign.md)) and reward variety ([TASK-105](TASK-105-validate-relic-reward-variety-through-special-ball.md)) must be solved within this work, not through independent redesigns.
- Tier 3 availability in the third city is tracked by [TASK-102](TASK-102-unlock-tier-3-relics-in-the-third-city.md). Overall numeric tuning belongs to [TASK-104](TASK-104-balance-siege-timer-wall-health-and-cannon-damage.md).

## Requirements

### 1. Authoritative reward design
- Inventory all production relics, including the deliberate roster and legacy conquest/chest entries; record trigger, physical role, present reward, proposed temporary special-ball reward, and acquisition tier.
- Define a small, understandable set of temporary special-ball behaviors and map relic families/variants to them. Any proposed ball types or numbers remain design proposals until the design is finalized.
- State whether an activation spawns new balls or temporarily transforms existing ones; specify ball count, spawn/release position, initial direction, reward recipient, and exactly-once activation behavior.
- Explain how special-ball effects interact with ordinary pegs, relic machinery, energy collection, the cannon, and downstream devices. Keep family identities rooted in physical routing.
- Specify whether any existing direct energy/knock/blast rewards remain, are replaced, or accompany special balls; never leave contradictory compound-reward descriptions.

### 2. Temporary lifecycle and safeguards
- Define lifetime in a clear unit (for example elapsed simulation time, board visits, or hits), expiration behavior, collection timing, and whether temporary balls return to the hopper.
- Distinguish temporary reward balls from the permanent starting/run ball population. Define behavior across pause, wall/city transitions, device removal, run reset, and persistence if applicable.
- Define global population limits, overflow policy, reward-ball recursion/chain limits, ownership of retained balls, and cleanup. Preserve satisfying combinations without unlimited reproduction or deleting permanent balls.

### 3. Meaningful choices and variety
- Deliver the same-tier comparison and family reward-role matrices required by [TASK-103](TASK-103-validate-relic-variant-choices-in-reward-redesign.md) and [TASK-105](TASK-105-validate-relic-reward-variety-through-special-ball.md) as sections of this design.
- Show concrete two-device chains and competing layouts demonstrating why different temporary balls change routing or timing decisions, rather than merely increasing payout.
- Include player-facing Trigger/Effect wording, visual identity, temporary-status/lifetime cues, and reward-preview requirements. Coordinate physical previews with existing TASK-099.

### 4. Implementation and verification plan
- Identify data definitions, reward dispatcher, ball lifecycle, UI, acquisition, and tests that a later implementation must touch; sequence the work and list unresolved decisions explicitly.
- Carry forward current reward-contract defects: B-O-O-M missing knock, Armory missing energy, Grand Switchback missing energy, Bastion's promised blast, and Global Knock's nonexistent GameState.add_energy call. Map each to replacement or repair so no issue disappears during redesign.
- Specify outcome-based tests for actual effects and expiration, plus real-physics device-chain tests. A completion signal alone is insufficient.
- Hand candidate values, output assumptions, and measurement needs to [TASK-104](TASK-104-balance-siege-timer-wall-health-and-cannon-damage.md); do not claim final balance without playtesting.

## Source Pointers

- resources/polyomino/deliberate_relic_catalog.gd
- resources/polyomino/polyomino_relic_database.gd
- scenes/board/machinery/polyomino_goal_reward_handler.gd
- scenes/board/machinery/polyomino_module_node.gd
- scenes/ball/ and scenes/rewards/
- docs/knowledge/relic-ball-flow-review.md (preserve accessible ports, safe retention, and exclusive ball control)

## Acceptance Criteria

- [ ] A repository design document maps every production relic to a specified temporary special-ball reward or an explicit retain/merge/retire decision.
- [ ] Special-ball behavior, lifetime, reward recipients, routing, recursion, population limits, and cleanup are unambiguous.
- [ ] All identified reward-contract defects have an explicit disposition and planned outcome-level verification.
- [ ] [TASK-103](TASK-103-validate-relic-variant-choices-in-reward-redesign.md) and [TASK-105](TASK-105-validate-relic-reward-variety-through-special-ball.md) checks are resolved in this design with traceable examples.
- [ ] No passive upgrade system is reintroduced.
- [ ] UI requirements, open decisions, implementation sequence, and balance handoff are documented.
- [ ] Completion of this packet is design/planning completion, not an assertion that gameplay changes shipped.

## Discussion draft

Implementation proposal: [Temporary relic balls](../knowledge/temporary-relic-ball-plan.md). Runtime inventory covers 122 IDs. Gameplay implementation is on hold for user discussion. Acceptance checks remain open until review.

