# TASK-051: Componentized Pinball Machinery Roster

- **Status:** DONE
- **Priority:** P1
- **Category:** Systems / Gameplay / Physics
- **Target Branch:** `feature/pinball-machinery-componentization`
- **Related Tasks:** [TASK-024](TASK-024-polyomino-relic-shapes-and-sizes.md), [TASK-026](TASK-026-polyomino-internal-machinery-and-bumpers.md), [TASK-053](TASK-053-relic-machinery-audit-and-widget-distribution.md), [TASK-055](TASK-055-relic-directional-machinery-rotation.md)

## Description

Define and implement the complete modular roster of 15 pinball machinery components for polyomino relics.
Each widget features standardized physics collisions, impulse responses, sound triggers, and event dispatches to power active board cascades.

---

## Requirements

### 1. Standardized 15-Widget Roster
Implement dedicated component behaviors for all 15 machinery types:
1. Pop Bumper — Radial impulse with bright comic bounce VFX.
2. Drop Target — Retracts upon impact, rewarding score/energy when bank cleared.
3. Standup Target — Bounces balls and triggers activation signals.
4. Spinner — High-frequency rotation on ball pass-through.
5. Scoop Sinkhole — Captures ball briefly and ejects toward target trajectory.
6. Ball Lock — Stores balls for multiball release conditions.
7. Guide Track — Constrains ball to directional metal lane.
8. Orbit Loop — Smooth curved high-speed turnaround rail.
9. Slingshot Kicker — High-velocity angled rebound kicker.
10. Rollover Switch — Pressure plate registering roll-overs without velocity loss.
11. Captive Ball — Confined ball transferring momentum to secondary targets.
12. Mechanical Diverter — Flips lane paths based on alternating triggers.
13. Vertical Up Kicker — Blasts ball upward against gravity.
14. Bash Toy — High-health durable target with multi-hit wobble VFX.
15. Outlane Kickback — Saves draining balls with explosive return impulse.

### 2. Event & Signal Integration
- Connect all widget collision events to GameState energy dispatchers.
- Standardize rotation compliance and grid-relative positioning.

### 3. Automated Tests
- Unit tests in `tests/test_pinball_components.gd`.
- Verify impulse calculation, hit registration, and component instantiation across all 15 widgets.

---

## Acceptance Criteria

- [x] All 15 pinball machinery components are defined and componentized.
- [x] Widgets register ball impacts, apply directional impulses, and fire signals.
- [x] Relic database and board nodes integrate the full machinery roster.
- [x] Unit tests pass cleanly in headless mode.
