# TASK-001: Gameplay Loop and Incremental Pacing (Parent Task)

- **Status:** DONE
- **Priority:** P1
- **Category:** Gameplay
- **Target Branch:** `feature/gameplay-loop-pacing`

## Description

Define and implement the continuous active incremental loop.
The simulation runs continuously in real-time while the player steers the hopper, manages the board, and upgrades components.

---

## Child Sub-Tasks

| Sub-Task ID | Title | Category | Priority | Status |
| :--- | :--- | :--- | :--- | :--- |
| [TASK-019](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-019-hopper-steering-controls.md) | Hopper Steering and Active Aiming Controls | Controls | P1 | DONE |
| [TASK-020](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-020-live-board-ghost-placement.md) | Live Board Ghost State and Placement Physics | Physics/Systems | P1 | DONE |
| [TASK-021](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-021-wall-siege-timer-and-pushback.md) | Wall Siege Timer, Auto-Progression, and Defender Pushback | Gameplay/Logic | P1 | DONE |
| [TASK-022](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-022-exponential-scaling-pacing-model.md) | Wall Health Exponential Scaling and Campaign Pacing Model | Math/Balance | P1 | DONE |
| [TASK-023](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-023-emergency-tinkering-minigames-design.md) | Emergency Tinkering and Machine Breakdown Minigames Design | Design/Systems | P2 | BACKLOG |

---

## Core System Architecture

1. **Active Controls and Continuous Simulation:**
   - The player steers the hopper left and right using `A` and `D` keys to aim ball drops.
   - The mouse manages all board interactions (drag, drop, rotate, and swap components).
   - The hopper drops balls at set intervals continuously without interruption.
   - Weapons auto-fire upon reaching energy thresholds.

2. **Live Board Placement and Ghost Collision State:**
   - Newly placed or moved pegs and modules enter a semi-transparent "ghost state" without physics collision.
   - When no balls occupy the collision boundary, the tile becomes fully opaque and enables physics collisions.
   - The player can swap modules from the scrapbox inventory during active combat.

3. **Campaign Pacing, Scaling, and Progression:**
   - Wall health scales exponentially across the 45-to-60-minute campaign.
   - The player auto-progresses to the next wall when a wall breaks.

4. **Siege Timer and Defender Pushback (Failure State):**
   - Each wall has a standard 120-second siege timer.
   - If the player fails to destroy the wall in 120 seconds, defenders push the cannon back to the previous wall.
   - The defenders repair the failed wall to full health.
   - The player auto-advances to the failed wall again after destroying the previous farm wall.

5. **Machine Breakdown Minigames:**
   - Machine instability triggers quick emergency repair interactions (for example: taping pipes or tightening bolts) to keep the cannon running.

## Acceptance Criteria

- [x] All child implementation tasks ([TASK-019](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-019-hopper-steering-controls.md), [TASK-020](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-020-live-board-ghost-placement.md), [TASK-021](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-021-wall-siege-timer-and-pushback.md), [TASK-022](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-022-exponential-scaling-pacing-model.md)) complete and pass tests.
- [x] Emergency minigames design ([TASK-023](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-023-emergency-tinkering-minigames-design.md)) is defined and reviewed.
- [x] Headless unit tests pass with `tests/run_tests.gd`.




