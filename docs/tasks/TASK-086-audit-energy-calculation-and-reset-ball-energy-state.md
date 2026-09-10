# TASK-086: Audit Energy Calculation and Reset Ball Energy State

- **Status:** READY
- **Priority:** P1
- **Category:** Systems / Gameplay
- **Target Branch:** `feature/audit-energy-calculation-and-ball-reset`
- **Related Tasks:** [TASK-001](TASK-001-gameplay-loop-and-pacing.md), [TASK-008](TASK-008-build-archetypes-and-synergies.md), [TASK-022](TASK-022-exponential-scaling-pacing-model.md), [TASK-070](TASK-070-pop-bumper-energy-tuning.md)

## Description

This task investigates energy calculations and fixes unintended exponential energy growth.
Players receive large energy increases over time without adding new balls or relics.
The energy state on individual balls is not wiped between board runs.
Balls that return to the hopper keep their accumulated energy.
Subsequent peg hits add new energy on top of the old energy values.
This task audits the energy pipeline and resets ball energy state upon each cycle.

---

## Requirements

### 1. Energy Calculation and Accumulation Audit
- Examine the energy pipeline across `Board`, `Ball`, `Hopper`, and `EnergyManager`.
- Trace energy addition during peg collisions and machinery interactions.
- Verify how total energy converts to internal energy units for cannon firing.
- Identify all sources of unintended energy retention and compounding.

### 2. Ball Energy State Wipe on Board Exit and Reset
- Clear the accumulated energy on the ball when it reaches the bottom of the board.
- Reset the energy state when a ball returns to the hopper.
- Make sure that each ball starts with its base energy value upon board entry.
- Clear auxiliary stack counters and temporary buffs during the reset cycle.

### 3. Hopper Recycle and Bag Queue Validation
- Verify energy values when balls recycle into the hopper through `return_ball`.
- Verify energy values when balls move to the bag queue.
- Make sure that recycled balls do not retain past hit energy.

### 4. Automated Tests and Verification
- Create automated unit tests in `tests/test_ball_energy_reset.gd`.
- Test that a ball resets to base energy after exit and re-entry.
- Test that multi-cycle ball runs do not cause compounding energy growth.
- Verify that all existing unit tests pass cleanly.

---

## Acceptance Criteria

- [ ] The energy state on each ball resets to base energy before a new drop.
- [ ] Balls returned to the hopper do not carry over previously gained energy.
- [ ] Energy calculation matches specified formulas without compounding accumulation.
- [ ] Automated tests verify ball energy reset across repeated cycles.
- [ ] All headless unit tests pass cleanly.
