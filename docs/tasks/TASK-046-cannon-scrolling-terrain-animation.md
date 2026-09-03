# TASK-046: Cannon Scrolling Terrain Animation & Right-Widget Wall Transition

- **Status:** DONE
- **Priority:** P1
- **Category:** UI / Visuals
- **Target Branch:** `feature/cannon-scrolling-terrain-animation`
- **Related Tasks:** [TASK-004](TASK-004-right-panel-and-comic-cutouts.md), [TASK-005](TASK-005-full-screen-conquest-cutscenes.md), [TASK-043](TASK-043-replace-drawn-cannons-with-sprite-assets.md)

## Description

Implement a scrolling terrain animation and smooth wall transition sequence for the right-widget battlefield view (`BattlefieldView`).
During normal combat, the cannon and terrain remain completely stationary while bombarding the enemy wall.
When a wall is destroyed, the terrain scrolls rapidly downward and the cannon rolls forward to simulate advancing into conquered territory.
When the next wall approaches, the terrain smoothly decelerates to a complete stop as the new fortification slides into place, returning to the stationary bombardment stance.

---

## Requirements

### 1. Stationary Combat State
- During regular combat, the terrain and cannon must remain completely still (`scroll_speed = 0.0`).
- The cannon remains positioned in front of the wall in standard siege stance.

### 2. Scrolling Terrain Component (`ScrollingTerrain`)
- Render a 320x720 terrain environment representing the roadway and surroundings between cannon and fortification.
- Uses `MonsterPalette` semantic colors (dirt roadway `DARK_OLIVE` / `WARM_BROWN`, verges `FOREST` / `OLIVE`, cart ruts, roadside cobblestones).
- Supports vertical scrolling with modulo loop wrapping so terrain wraps seamlessly without runaway coordinates or allocations.
- Speed control API: `set_scroll_speed(speed: float)`, `start_advancing(duration: float, max_speed: float)`, and `stop_advancing(duration: float)`.
- Graceful procedural rendering so tests and headless runs execute cleanly even if optional raw asset packs are omitted.

### 3. Synchronized Wall Break & Intro Transitions
- In `BattlefieldView.play_wall_destroyed_transition()`:
  - Trigger wall explosion debris (`WallVisual.play_explosion()`).
  - Cannon rolls forward (`_cannon_roll_offset_y` moves up towards the breach).
  - Terrain accelerates rapidly into motion, scrolling downward.
  - Emit `wall_break_transition_finished` upon completion of the advance.
- In `BattlefieldView.play_next_wall_intro()`:
  - New wall slides down into position (`WallVisual.play_rebuild()`).
  - Terrain smoothly decelerates from its advance speed to 0.0 (full stop).
  - Cannon settles back to default firing position (`_cannon_roll_offset_y = 0.0`).
  - Emit `next_wall_intro_finished` when the new wall is established and terrain has stopped.

### 4. Automated Verification & Quality Standards
- Unit tests in `tests/test_cannon_scrolling_terrain.gd` verifying stationary state during idle/combat, acceleration on wall break, deceleration to stop on next wall intro, signal emissions, and headless compatibility.
- Ensure all source files remain under the 500-line project limit.
- Maintain coding standards (type annotations, docstrings, region tags).

---

## Acceptance Criteria

- [x] Terrain and cannon remain completely stationary during normal combat.
- [x] `ScrollingTerrain` renders roadway, cart tracks, and verges with seamless vertical wrapping.
- [x] `play_wall_destroyed_transition()` scrolls terrain and advances the cannon forward into the breach.
- [x] `play_next_wall_intro()` decelerates terrain to a complete halt and returns the cannon to ready position.
- [x] `wall_break_transition_finished` and `next_wall_intro_finished` signals emit cleanly.
- [x] Automated headless unit tests pass cleanly.
