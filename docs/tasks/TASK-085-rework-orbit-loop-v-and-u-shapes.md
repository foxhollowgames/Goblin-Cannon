# TASK-085: Rework Orbit Loop for Multi-Peg V and U Shapes

- **Status:** DONE
- **Priority:** P1
- **Category:** Systems / Gameplay
- **Target Branch:** `feature/rework-orbit-loop-v-and-u-shapes`
- **Related Tasks:** [TASK-024](TASK-024-polyomino-relic-shapes-and-sizes.md), [TASK-036](TASK-036-pinball-kinetic-machinery-and-lane-switches.md), [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-071](TASK-071-diegetic-relic-activation-categories.md), [TASK-072](TASK-072-multi-peg-machinery-and-size-variations.md), [TASK-083](TASK-083-rework-wire-gate-component-holding-cup.md)

## Description

This task reworks the orbit loop machinery component into multi-peg configurations.
The current orbit loop occupies only a single peg on the board.
The component must follow the established multi-cell V-shape and larger U-shape layouts.
These shapes provide true turnaround rail lanes for high-speed ball redirection.
Incoming balls enter one lane, travel around the curved apex, and exit through the opposite lane.

---

## Requirements

### 1. Multi-Peg Footprint and Shape Definitions
- Remove the single-peg constraint from the orbit loop component.
- Support compact 3-cell V-shape configurations for tight turnaround lanes.
- Support larger 5-cell and 7-cell U-shape configurations for wide loop channels.
- Set clear entry and exit ports at the open ends of the V and U shapes.

### 2. Guided Trajectory and Turnaround Physics
- Detect when a ball enters an open lane port.
- Capture the incoming ball velocity and guide the ball along the curved path.
- Direct the ball around the loop apex to the opposite lane.
- Apply high-speed exit impulse to the ball at the exit port.
- Increment the traversal counter upon successful completion of the loop.

### 3. Visual Rendering and Rail Presentation
- Draw dual curved metal guide rails along the multi-cell footprint.
- Draw directional neon indicators along the turnaround track.
- Show clear entrance and exit openings on the module boundary.
- Animate visual pulses when a ball traverses the loop.

### 4. Relic Database and Module Integration
- Update orbit loop relic entries in `resources/polyomino/polyomino_relic_database.gd`.
- Configure unified component layout mode in `resources/polyomino/polyomino_module_data.gd`.
- Connect multi-cell center offsets and rotational transforms.

### 5. Automated Tests and Verification
- Create automated tests in `tests/test_orbit_loop_shapes.gd`.
- Verify ball entry and traversal through 3-cell V-shape orbit loops.
- Verify ball entry and traversal through 5-cell and 7-cell U-shape orbit loops.
- Verify exit impulse direction and magnitude.
- Make sure that all headless unit tests pass cleanly.

---

## Acceptance Criteria

- [x] The orbit loop supports 3-cell V-shape turnaround layouts.
- [x] The orbit loop supports 5-cell and 7-cell U-shape turnaround layouts.
- [x] Balls enter one leg of the shape and exit the opposite leg with acceleration.
- [x] Visual guide rails and directional arrows render across the full multi-cell footprint.
- [x] Automated headless tests verify traversal through both shape variations.
- [x] All modified source files remain under the 500-line project threshold.
