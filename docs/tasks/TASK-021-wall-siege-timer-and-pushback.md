# TASK-021: Wall Siege Timer, Auto-Progression, and Defender Pushback

- **Status:** DONE
- **Priority:** P1
- **Category:** Gameplay / Logic
- **Parent Task:** [TASK-001](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-001-gameplay-loop-and-pacing.md)
- **Target Branch:** `feature/wall-siege-timer-and-pushback`

## Description

Implement the wall siege timer, automatic victory progression, and defender pushback failure loop.

## Requirements

1. **Siege Timer:**
   - Initialize a 120-second countdown timer when a wall siege begins.
   - The UI shows the remaining siege time prominently.

2. **Victory and Auto-Progression:**
   - When the wall reaches 0 health, the siege succeeds.
   - The game immediately advances the player to the next wall without manual prompt.

3. **Failure State (Defender Pushback):**
   - If the timer reaches 0 before the wall breaks, the siege fails.
   - Defenders push the cannon back to the previous wall.
   - The failed wall resets to 100% maximum health.
   - When the player destroys the previous farm wall again, the game auto-advances back to the failed wall.

## Acceptance Criteria

- [x] Timer accurately counts down from 120 seconds during combat.
- [x] Wall destruction immediately advances the game state to the next fortification.
- [x] Timer expiration resets wall health and returns the cannon to the previous wall.
- [x] Headless unit tests verify victory, timeout, and pushback state transitions.
