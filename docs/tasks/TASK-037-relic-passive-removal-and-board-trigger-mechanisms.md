# TASK-037: Relic Passive Removal and Board Trigger Mechanisms

- **Status:** DONE
- **Priority:** P1
- **Category:** Systems / Gameplay / Design
- **Target Branch:** `feature/relic-passive-removal-board-triggers`
- **Related Tasks:** [TASK-010](TASK-010-final-relic-list-campaign-1.md), [TASK-024](TASK-024-polyomino-relic-shapes-and-sizes.md), [TASK-026](TASK-026-polyomino-internal-machinery-and-bumpers.md), [TASK-036](TASK-036-pinball-kinetic-machinery-and-lane-switches.md)

## Description

Remove all passive relic stat modifiers from the game.
Reincorporate all relic effects as kinetic pinball triggers on the pegboard layout.
Ensure that no passive effects exist on relics.
All relic effects must trigger from ball interactions with the board layout.

---

## Requirements

### 1. Passive Relic Effect Removal
- Remove static passive stat modifier hooks in `PolyominoRelicDatabase` (`apply_relic_effects_to_game_state` and `remove_relic_effects_from_game_state`).
- Remove static relic stack properties from `GameState` (such as passive damage bonuses, radius bonuses, and passive recovery speed multipliers).
- Update relic reward descriptions to reflect kinetic pinball board triggers instead of passive stat bonuses.

### 2. Pegboard Trigger Mechanism Reincorporation
- Convert every existing passive relic concept into a kinetic pinball board trigger mechanism.
- Implement hit triggers, rollover switches, drop targets, bumper banks, and kinetic peg layout activation events.
- Ensure that relic effects trigger dynamically when active balls hit or traverse specific components on the pegboard.
- Support temporary kinetic board pulses (such as timed energize waves or active charge bursts) upon layout trigger completion.

### 3. Data Model and Database Audit
- Update `PolyominoRelicDatabase` definitions to associate every relic with specific kinetic goals and cell component triggers.
- Update `PolyominoModuleData` to support trigger-activated board actions and event dispatches.
- Ensure that shop cards and reward previews display tactile kinetic trigger mechanics instead of passive text descriptions.

### 4. Automated Tests
- Add headless unit tests in `tests/test_relic_board_triggers.gd`.
- Verify that slotting a relic does not apply passive stat stack changes to `GameState`.
- Verify that ball hits on board trigger components execute the intended kinetic relic actions.
- Verify that bank completion events on the pegboard trigger expected board rewards and temporary pulses.

---

## Acceptance Criteria

- [x] All passive relic stat hooks are removed from `GameState` and `PolyominoRelicDatabase`.
- [x] Every relic effect functions strictly through kinetic pinball triggers on the pegboard layout.
- [x] Relic reward descriptions show interactive trigger mechanisms instead of passive stat bonuses.
- [x] Dynamic kinetic board pulses execute on target component completion.
- [x] Headless unit tests verify trigger mechanism execution and zero passive stat mutation.
