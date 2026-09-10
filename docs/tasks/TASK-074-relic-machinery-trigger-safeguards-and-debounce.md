# TASK-074: Relic Machinery Trigger Safeguards and Debounce

- **Status:** DONE
- **Assigned To:** Antigravity Orchestrator
- **Creation Date:** 2026-09-08
- **Completion Date:** 2026-09-08
- **Priority:** P1
- **Category:** Gameplay / Balance
- **Target Branch:** `feature/relic-machinery-trigger-safeguards`
- **Related Tasks:** [TASK-036](TASK-036-pinball-kinetic-machinery-and-lane-switches.md), [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-072](TASK-072-multi-peg-machinery-and-size-variations.md), [TASK-073](TASK-073-debug-board-machinery-showcase.md)

## Description

Add trigger safeguards to relic machinery components.
Prevent repeated activations on a single ball hit.
Stop guide tracks from repeatedly triggering when a ball slides up and falls back down.
Enforce contact debounce so a ball must exit contact before triggering a component again.

---

## Requirements

### 1. Machinery Component Contact Debounce
- Track continuous ball contact state in `PolyominoMachineryComponent`.
- Add `is_ball_contacting`, `set_ball_contact`, and `record_ball_exit` methods.
- Support component-specific `exit_cooldown_ticks`.
- Ensure components activate only once upon initial contact.

### 2. Guide Track Re-Entry Safeguards
- Prevent `GuideTrack` from activating while a ball is inside `_guided_balls`.
- Add an exit cooldown after a ball completes the track traversal.
- Prevent a ball from re-entering the track when it immediately falls back down.

### 3. Containment Component Safeguards
- Prevent `ScoopSinkhole` from activating while a ball is captured.
- Add an exit cooldown when balls eject from the sinkhole.
- Prevent `BallLock` from activating while a ball is held in the lock trough.
- Add an exit cooldown when multiball releases.

### 4. Module Node Collision Integration
- Update `PolyominoModuleNode.check_ball_collision` to update ball contact state.
- Suppress repeat activations while a ball remains in continuous contact.
- Record exit events when contact breaks.
- Keep `PolyominoModuleNode.gd` under the 500-line project limit.

### 5. Automated Tests
- Create `tests/test_relic_machinery_trigger_safeguards.gd`.
- Register the new test suite in `tests/run_tests.gd`.
- Verify all tests pass with zero failures.

---

## Acceptance Criteria

- [x] A single ball hit triggers a component only once during continuous contact.
- [x] Guide tracks trigger only once per traversal.
- [x] Guide tracks do not re-trigger when a ball immediately falls back down.
- [x] Sinkholes and ball locks do not trigger repeatedly while holding balls.
- [x] All automated tests pass.
- [x] All modified files obey the 500-line limit.
