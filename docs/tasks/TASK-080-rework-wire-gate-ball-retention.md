# TASK-080: Rework Wire Gate to Retain Downward Falling Balls and Support Retentive Holding Cups

- **Status:** READY
- **Priority:** P1
- **Category:** Systems / Gameplay
- **Target Branch:** `feature/rework-wire-gate-ball-retention`
- **Related Tasks:** [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-071](TASK-071-diegetic-relic-activation-categories.md)

## Description

Rework the wire gate component to retain balls against downward gravity.
Change the gate mechanism from an anti-backflow blocker to a retentive holding barrier.
Allow components to trap balls in a cup until full, then release all balls as a cascade bonus.

---

## Requirements

### 1. Downward Ball Retention Physics
- Modify `scenes/board/machinery/wire_gate.gd` to block downward ball motion by default.
- Allow balls to enter from above or designated directions, but stop balls from falling through.
- Implement open and close states for the wire gate.

### 2. Retentive Cup Integration
- Support retention cup mechanics where balls collect behind the gate.
- Track the count of captured balls in the retention cup.
- When the cup reaches full capacity, open the gate to release all trapped balls.
- Trigger a bonus reward signal upon release of the ball cascade.

### 3. Visual and Diegetic Updates
- Update wire gate visual drawing in `scenes/board/machinery/polyomino_machinery_visuals.gd`.
- Show open and closed gate states clearly.
- Render visual tension or capacity fill indicators in `polyomino_diegetic_renderer.gd`.

### 4. Automated Tests and Verification
- Update `tests/test_pinball_machinery.gd` to test downward retention and release mechanics.
- Verify that balls do not fall through closed wire gates.
- Verify that the gate opens when the cup fills to capacity.
- Make sure that all headless unit tests pass cleanly.

---

## Acceptance Criteria

- [ ] Wire gates prevent downward ball drops while in the closed state.
- [ ] Retentive holding cup mechanics track accumulated balls.
- [ ] The gate opens and releases all trapped balls when capacity is reached.
- [ ] Visual indicators show open, closed, and fill states.
- [ ] Headless unit tests pass cleanly.
- [ ] All modified source files remain under 500 lines.
