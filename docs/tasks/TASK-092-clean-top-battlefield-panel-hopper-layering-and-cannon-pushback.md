# TASK-092: Clean Top Battlefield Panel, Hopper Layering, and Cannon Pushback

- **Status:** DONE
- **Priority:** P1
- **Category:** UI / Visuals / Gameplay
- **Target Branch:** `feature/clean-top-battlefield-and-cannon-pushback`
- **Related Tasks:** [TASK-021](TASK-021-wall-siege-timer-and-pushback.md), [TASK-046](TASK-046-cannon-scrolling-terrain-animation.md), [TASK-091](TASK-091-peglin-style-top-cannon-battlefield-and-mob-timer.md)

## Description

Address visual artifacts and gameplay interactions following the Peglin-style top battlefield transition:
1. **Remove Old Cannon Panel & Green Outline:** Eliminate the leftover `CircularCannonWidget` (290x184 box with green border `#5d7545` and vertical wood planks) that was being created in `game_coordinator_ui.gd` and lingering in the top-left over the playfield.
2. **Hopper Repositioning & Layering:** Move `Hopper` down slightly into the playfield area and ensure the top battlefield and header bar sit in front of the hopper on visual layers so the hopper cleanly slides behind the top bar.
3. **Cannon Firing Timer Extension & Mob Pushback:** When the main cannon fires at the wall, extend the siege countdown timer by a configurable duration (e.g. +3.0 to 5.0 seconds in `CombatManager`), pushing the defending city mob backwards towards the wall with reactive knockback feedback.

---

## Requirements

### 1. Remove CircularCannonWidget Residue
- In `scenes/main/game_coordinator_ui.gd`, remove the fallback instantiation that added `CircularCannonWidget` to `UILayer`.
- Ensure no lingering green-outlined boxes or extra panels exist below the top 110px bar.

### 2. Hopper Positioning and Visual Layering
- Adjust `Hopper` position in `scenes/main/main.tscn` (and `layout_constants.gd` if applicable) slightly downward (e.g. y: 145–155) so its mouth is well-spaced from the top bar.
- Ensure the top battlefield backdrop and header bar render on top of the hopper's top rim so the hopper appears behind the top bar on the canvas layers.

### 3. Cannon Firing Timer Extension & Mob Pushback
- In `CombatManager`, add a method (or extend `_on_main_cannon_fired`) to add time to the siege timer when the main cannon fires (e.g. +3 to +5 seconds, capped at max phase time or reasonable threshold).
- In `CityMobVisual` / `BattlefieldView`, when time is extended or cannon fires, update the mob's position smoothly with a recoil/stumble-back tween pushing the mob backwards towards the wall.

### 4. Automated Tests and Verification
- Update or add unit tests verifying:
  - No `CircularCannonWidget` is attached to `UILayer` in `Main`.
  - `Hopper` positioning and layering order.
  - Cannon firing extends timer seconds in `CombatManager` and pushes `CityMobVisual` back.
- Pass full headless test suite and all linters.

---

## Acceptance Criteria

- [x] Green outline and extra panel below the top bar removed completely.
- [x] Hopper positioned slightly lower and rendered behind the top bar.
- [x] Firing the cannon extends the siege timer by several seconds.
- [x] Firing the cannon pushes the city mob backwards toward the wall.
- [x] All automated unit tests pass in headless mode (`tests/run_tests.gd`).
- [x] GDScript standards and file length linters pass with 0 errors.
