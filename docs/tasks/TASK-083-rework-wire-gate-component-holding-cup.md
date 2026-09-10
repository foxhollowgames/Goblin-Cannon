# TASK-083: Rework Wire Gate for Component Holding Cups

- **Status:** READY
- **Priority:** P1
- **Category:** Systems / Gameplay
- **Target Branch:** `feature/wire-gate-component-holding-cup`
- **Related Tasks:** [TASK-033](TASK-033-relic-bounding-enclosures-and-dividing-lanes.md), [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-071](TASK-071-diegetic-relic-activation-categories.md), [TASK-072](TASK-072-multi-peg-machinery-and-size-variations.md), [TASK-080](TASK-080-rework-wire-gate-ball-retention.md)

## Description

This task reworks the wire gate mechanism to control an entire component.
The component operates as a holding cup that catches and stores balls.
The wire gate serves as an exit barrier for the component cup.
The gate stops balls from leaving the cup until the component meets its activation requirements.
When the component meets the activation requirements, the wire gate opens and releases the balls.

---

## Requirements

### 1. Component Cup Enclosure and Gate Attachment
- Remove the single peg constraint from the wire gate component.
- Attach the wire gate to the exit boundary of an entire component cup enclosure.
- Support multi-cell cup footprints where balls collect inside the cup interior.
- Position the wire gate barrier across the designated opening of the component enclosure.

### 2. Activation Requirement Gate Control
- Connect the gate state directly to the activation requirements of the component.
- Keep the wire gate in the closed state while the component activation conditions remain incomplete.
- Retain all incoming balls inside the boundary of the component cup.
- Open the wire gate when the component satisfies its activation requirements.
- Release all trapped balls in a cascade through the open gate.

### 3. Ball Retention Physics in Cup Interior
- Stop balls from escaping the component cup while the wire gate remains closed.
- Allow balls to move inside the cup enclosure rather than locking balls to a single peg.
- Apply release impulses to all trapped balls when the gate opens.
- Close the wire gate after all released balls exit the component.

### 4. Visual Presentation and Diegetic States
- Draw the wire gate barrier across the exit opening of the multi-cell component.
- Show clear visual differences between the closed state and the open state of the gate.
- Show visual charge or fill progress on the component cup.

### 5. Automated Tests and Verification
- Add automated tests in `tests/test_wire_gate_component_cup.gd`.
- Verify that balls remain inside the component cup while the gate is closed.
- Verify that the gate stays closed before the component meets its activation requirements.
- Verify that the gate opens and releases all balls when the component meets its requirements.
- Make sure that all headless unit tests pass cleanly.

---

## Acceptance Criteria

- [ ] Wire gates attach to the exit boundaries of multi-cell component cups.
- [ ] Balls collect inside the component cup without pinning to a single peg.
- [ ] The wire gate prevents balls from leaving until the component meets its activation requirements.
- [ ] The wire gate opens and releases all trapped balls when the component meets its requirements.
- [ ] Clear visual indicators show the closed and open gate states.
- [ ] Automated headless unit tests pass cleanly.
- [ ] All modified source files remain under the 500-line project threshold.
