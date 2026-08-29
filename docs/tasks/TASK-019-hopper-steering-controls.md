# TASK-019: Hopper Steering and Active Aiming Controls

- **Status:** READY
- **Priority:** P1
- **Category:** Controls / Gameplay
- **Parent Task:** [TASK-001](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-001-gameplay-loop-and-pacing.md)
- **Target Branch:** `feature/hopper-steering-controls`

## Description

Implement horizontal player movement for the hopper.
The player steers the hopper left and right during active combat to aim ball drops into specific pegboard columns.

## Requirements

1. **Keyboard Movement:**
   - Press `A` or `Left Arrow` to move the hopper left.
   - Press `D` or `Right Arrow` to move the hopper right.
   - Clamp hopper movement to the top boundary of the pegboard grid.

2. **Continuous Auto-Drop:**
   - The hopper continues to drop balls at the configured time interval while moving.
   - Ball initial velocity inherits or ignores hopper horizontal speed based on game settings.

## Acceptance Criteria

- [ ] The hopper moves smoothly between the left and right grid limits.
- [ ] Keyboard input does not interrupt automated ball drop timers.
- [ ] Headless unit tests verify movement boundaries and input handling.
