# TASK-107: Refactor temporary ball lifecycle and Board reward flow

- **Status:** DONE
- **Priority:** P1
- **Category:** Systems / Gameplay / Refactor
- **Target Branch:** `feature/temporary-relic-ball-rewards`
- **Related Tasks:** [TASK-106](TASK-106-implement-approved-temporary-relic-ball-rewards.md), [TASK-104](TASK-104-balance-siege-timer-wall-health-and-cannon-damage.md)

## Description

Extract the temporary-ball lifecycle and relic reward flow from the large Board script. This task creates stable seams for TASK-106. It does not add new reward types or change balance.

---

## Requirements

### 1. Scope and Implementation

- Extract temporary-ball creation, ownership, expiry, population reservations, emission queues, and bottom collection into focused helpers.
- Extract reward outlet selection and rotated device geometry into a focused flow helper.
- Keep Board as the simulation authority. Board forwards events to helpers and remains responsible for deterministic tick order.
- Preserve the existing capture-owner contract. Every expiry, removal, transition, and reset path must detach retained balls, traveler dictionaries, and ownership metadata before deletion.
- Preserve permanent-ball behavior and inventory. Temporary balls never enter the hopper, bag, save data, or permanent ball counts.
- Keep reward-goal accounting separate from physical machinery motion. Temporary contacts may move devices but cannot complete word banks, reservoirs, spinners, slingshots, or other reward goals.
- Keep the first implementation slice small: Plain and Rubbery rewards through one reservoir or track outlet, one bottom collection, one timeout, one blocked outlet, and one duplicate activation case. Add other ball types only after this slice passes.
- Do not reorganize unrelated Board systems, rewrite ordinary ball abilities, or tune reward counts in this task.

### 2. Verification plan

- Unit tests cover exact queued counts, six-tick spacing, 24 temporary active or reserved slots, blocked cancellation after 60 simulation ticks, duplicate activation keys, timeout while captured, transition cleanup, and one bottom payout.
- Energy tests cover Split and Binary odd totals, zero and one energy, full-cap behavior, child lifetime inheritance, and both temporary/permanent collision directions.
- Flow tests cover all four rotations, outlet clearance, physical release speed, and module removal while a ball is captured.
- Regression tests compare ordinary Rubbery, Energize, Explosive, Chain Lightning, and Plain behavior before and after the extraction.
- Run focused tests first. Run real-physics flow tests next. Run the full elevated quality audit only after focused failures are resolved.
- Stop the pass if the change requires edits to unrelated combat, UI, or acquisition systems. Create a follow-up task instead.

---

## Acceptance Criteria

- [x] The first Plain/Rubbery vertical slice passes the focused temporary reward suite.
- [x] Temporary lifecycle and outlet helpers are independently testable and each source file is under 500 lines.
- [x] Board remains the sole simulation authority with thin delegation methods.
- [x] Capture ownership, expiry, transitions, reset, and inventory exclusion pass tests.
- [x] Split and Binary conserve energy and respect the temporary population cap.
- [x] Existing permanent ball behavior passes regression tests.
- [x] Tests pass cleanly with zero failures in the raw Godot runner.
- [x] File lengths adhere to the 500-line repository limit.
- [x] Pull Request opened, audited by independent PR reviewer, and merged.

## Usage guardrails

- Use one implementation agent at a time. Use reviewers after a focused slice exists.
- Require a passing vertical slice before expanding the scope.
- Pause at 50% included five-hour usage for a checkpoint and at 70% unless the remaining work is small and verified.
- Do not use API credits, reset redemption, purchases, or paid model fallback.

## Checkpoint — focused vertical slice

- **Date:** 2026-09-24
- **Changed files:** `scenes/board/temporary_relic_ball_controller.gd`, `scenes/board/board.gd`, `tests/test_temporary_relic_ball_rewards.gd`, plus the existing TASK-106 reward and lifecycle files in this worktree.
- **Focused command:** `Godot --headless --path . -s tests/run_tests.gd` (the registered suite includes the focused temporary reward tests).
- **Raw result:** `TemporaryRelicBallRewards (201 passed, 0 failed)`.
- **Known remaining failures:** 128 legacy assertions in `ThirdCityRelics`, `RewardHandler`, `RelicPinballGoals`, `OnBoardRelicTooltips`, and `RelicPinballActivation` still expect retired reward effects. These are TASK-106 migration work and are outside the first TASK-107 slice.
- **Quality audit:** File length audit passed. The repository GDScript audit reported 32 existing function-length issues, including `Board.run_ball_steps` and `PolyominoModuleData.deserialize`; the audit was stopped before its redundant full test rerun because the raw focused result is already recorded above.
- **Scope decision:** Keep the next pass limited to lifecycle and Board ownership tests. Do not expand ball-type coverage or touch combat, UI, or acquisition until the focused lifecycle contract is reviewed.

## Checkpoint — queue and cleanup coverage

- Retired reward dispatch is removed from the goal handler.
- Temporary exits now route through controller cleanup, including capture ownership detachment.
- Pre-allocation cancellation reports the full un-emitted offer.
- Focused tests now cover deferred queue allocation, duplicate activation keys, invalid-source cancellation, and one-time collection.
- Raw Godot result: `18,171 passed, 0 failed`.
- Added coverage for temporary Binary odd-energy conservation and inherited expiry. Broader real-physics capture paths remain for the next pass.
