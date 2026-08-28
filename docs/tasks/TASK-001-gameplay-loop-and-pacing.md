# TASK-001: Gameplay Loop and Incremental Pacing

- **Status:** READY
- **Priority:** P1
- **Category:** Gameplay
- **Target Branch:** `feature/gameplay-loop-pacing`

## Description

Define and implement the hybrid active incremental loop.
Balance automated physics simulation with active player choices and tactical intervention.

## Requirements

1. **Automated Baseline (Hands-Off):**
   - Hopper auto-drops balls at the set interval.
   - Circuit board routes energy deterministically.
   - Weapons auto-fire upon reaching energy thresholds.

2. **Active Player Systems (Hands-On):**
   - Milestone draft selections (balls, peg modifications, stat upgrades).
   - Manual hopper release valve for burst waves.
   - Interactive board customization between combat waves.
   - Active character skills on tactical cooldowns.

## Acceptance Criteria

- [ ] The simulation runs autonomously without blocking user input.
- [ ] The player can trigger manual ball drops and valve releases.
- [ ] Milestone drafts pause or slow combat cleanly.
- [ ] Headless unit tests pass with `tests/run_tests.gd`.
