# TASK-020: Live Board Ghost State and Placement Physics

- **Status:** READY
- **Priority:** P1
- **Category:** Physics / Systems
- **Parent Task:** [TASK-001](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-001-gameplay-loop-and-pacing.md)
- **Target Branch:** `feature/live-board-ghost-placement`

## Description

Implement the safe live-placement system for pegs and tetromino modules.
Allows players to move and swap components during live simulation without physics glitches.

## Requirements

1. **Mouse Drag and Drop:**
   - The player drags and drops components between the scrapbox inventory and the board grid.
   - The player can rotate modules before placement.

2. **Ghost Collision State:**
   - Newly positioned components render at 50% opacity in a non-colliding "ghost state".
   - An area monitor checks for active balls within the component collision box.
   - When all balls leave the collision area, the component becomes 100% opaque and enables its 2D physics collider.

## Acceptance Criteria

- [ ] Moving a peg or module does not trap or teleport active balls.
- [ ] Ghost components do not deflect balls until the collision area is completely clear.
- [ ] Headless unit tests verify the transition from ghost state to active state.
