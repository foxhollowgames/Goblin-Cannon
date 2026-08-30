# TASK-037: Organic Ball Physics, Hopper Stacking Prevention, and Upward Kinetic Anti-Looping

- **Status:** READY
- **Priority:** P1
- **Category:** Physics / Systems / Gameplay
- **Target Branch:** `feature/organic-physics-and-anti-looping`
- **Related Tasks:** [TASK-019](TASK-019-hopper-steering-controls.md), [TASK-026](TASK-026-polyomino-internal-machinery-and-bumpers.md), [TASK-033](TASK-033-relic-bounding-enclosures-and-dividing-lanes.md), [TASK-036](TASK-036-pinball-kinetic-machinery-and-lane-switches.md)

## Description

Prevent artificial physics behavior during gameplay.
Introduce natural dispersion to hopper ball drops to prevent balls from stacking in artificial vertical towers.
Introduce angular deflection and anti-looping dynamics to upward velocity machinery (accelerators, deflectors, spring ramps, and trampoline pegs) to prevent balls from locking into infinite vertical bounce cycles.

---

## Requirements

### 1. Hopper Spawn Dispersion and Natural Cascade
- Add randomized horizontal offset (jitter) within a controlled range to ball spawn and return positions above the hopper.
- Add subtle initial lateral velocity variance to falling balls.
- Ensure that balls entering the hopper bin slip, roll, and cascade naturally into empty spaces instead of balancing in a single vertical column.
- Maintain hopper horizontal carry synchronization so falling balls follow the hopper movement accurately.

### 2. Upward Velocity Machinery Angular Deflection
- Update directional kinetic machinery (`SpeedBoostWheel`, `DirectionalDeflector`, `PinballBumper`, and upward spring ramps) to apply subtle angular deflection (`±1.0°` to `±3.5°`).
- Ensure that impulses applied to balls calculate contact point offset relative to component center.
- Prevent upward launchers from resetting ball horizontal velocity strictly to zero on vertical axes.

### 3. Cyclic Resonance and Anti-Looping Detection
- Track consecutive vertical cycles and repetitive machine activations for active balls.
- Apply progressive lateral micro-nudges when a ball oscillates between a vertical launcher and gravity along the same path.
- Ensure that the ball breaks free from resonant loops within 2 to 3 bounce cycles without jarring visual snaps.

### 4. Headless Automated Unit Tests
- Add a new unit test suite in `tests/test_physics_anti_looping.gd`.
- Test that balls dropped consecutively into the hopper do not settle in a single vertical line with identical horizontal coordinates.
- Test that upward kinetic launchers produce trajectory variance and do not bounce balls in an infinite vertical loop.
- Test that anti-looping logic applies corrective impulses during repetitive bounce cycles.

---

## Acceptance Criteria

- [ ] Consecutive balls spawned into the hopper cascade laterally and fill the bin naturally.
- [ ] Balls do not stack in a rigid vertical tower inside the hopper bin.
- [ ] Upward velocity machines and spring ramps launch balls with subtle natural angular deflection.
- [ ] Balls bouncing on upward machinery do not get stuck in infinite vertical oscillation loops.
- [ ] Resonance detection applies progressive lateral micro-nudges to break repetitive bouncing paths.
- [ ] Headless unit tests in `tests/test_physics_anti_looping.gd` pass completely.
- [ ] All source files comply with the 500-line length limit.
