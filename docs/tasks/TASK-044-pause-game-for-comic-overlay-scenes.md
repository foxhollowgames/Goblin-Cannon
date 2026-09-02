# TASK-044: Pause Game State for Full Comic Overlay Cinematics

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** Gameplay / Systems / UI
- **Target Branch:** `feature/pause-game-comic-overlays`
- **Related Tasks:** [TASK-004](TASK-004-right-panel-and-comic-cutouts.md), [TASK-005](TASK-005-full-screen-conquest-cutscenes.md)

## Description

Pause the game state when full-screen comic overlay scenes run (such as wall breaks, boss victories, or story cinematics), matching merchant and reward screen pause behavior.
Exclude bottom-right cannon animations from pausing the game state.

---

## Requirements

### 1. Comic Overlay Game Pause Behavior
- When a full-screen comic overlay cutscene triggers (wall break, boss victory, or cinematic), the game state enters the paused state.
- Board physics, ball movement, timers, and enemy actions pause while the comic overlay scene is active.
- Game state unpauses when the user dismisses or finishes the comic overlay scene.

### 2. Cannon Firing Animation Exception
- Cannon firing animations in the bottom-right panel MUST NOT pause the game state.
- Bottom-right animations remain active state indicators while gameplay continues uninterrupted.

### 3. Automated Verification
- Create automated unit tests in `tests/test_pause_game_comic_overlays.gd`.
- Verify that comic overlay cutscene triggers pause and unpause the game state.
- Verify that bottom-right cannon animations do not pause the game state.

---

## Acceptance Criteria

- [x] Comic overlay cutscenes (wall break, boss victory, cinematics) pause the game state upon opening.
- [x] Game state resumes when comic overlay cutscenes finish or dismiss.
- [x] Bottom-right cannon firing animations do not pause game state.
- [x] Headless unit tests pass.
