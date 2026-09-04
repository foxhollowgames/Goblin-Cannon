# TASK-070: Tune Pop Bumper Energy to One Energy

- **Status:** DONE
- **Priority:** P1
- **Category:** Gameplay / Balance
- **Target Branch:** `feature/pop-bumper-one-energy`
- **Related Tasks:** [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-069](TASK-069-in-game-machinery-components-dashboard.md)

## Description

Change the Pop Bumper energy value.
The Pop Bumper must grant only one extra energy on ball impact.
Update the component code, the test cases, and the companion dashboard documentation.

---

## Requirements

### 1. Pop Bumper Code Adjustment
- Set `base_energy = 1` in `scenes/board/machinery/pop_bumper.gd`.
- Initialize `base_energy = 1` in both `_init()` and `_ready()` functions.

### 2. Documentation and Dashboard Update
- Update `docs/knowledge/in-game-components-dashboard.html` to show energy value `1` for `POP_BUMPER`.
- Update the description text to state that the component awards 1 energy.

### 3. Automated Tests
- Update `tests/test_pinball_machinery.gd` to verify that the Pop Bumper grants 1 energy.
- Verify that all tests pass.

---

## Acceptance Criteria

- [x] Pop Bumper grants 1 extra energy on ball impact.
- [x] Automated tests verify the 1 energy award.
- [x] Documentation reflects 1 energy for the Pop Bumper.
- [x] All modified files obey the 500-line limit.
