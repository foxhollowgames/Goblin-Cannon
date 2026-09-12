# TASK-091: Peglin-Style Top Cannon Battlefield and City Mob Timer

- **Status:** DONE
- **Priority:** P1
- **Category:** UI / Visuals / Gameplay
- **Target Branch:** `feature/peglin-style-top-battlefield`
- **Related Tasks:** [TASK-004](TASK-004-right-panel-and-comic-cutouts.md), [TASK-021](TASK-021-wall-siege-timer-and-pushback.md), [TASK-039](TASK-039-junk-box-sidebar-integration-and-pegboard-display.md), [TASK-046](TASK-046-cannon-scrolling-terrain-animation.md), [TASK-087](TASK-087-lower-right-wall-cannonball-and-impact-vfx.md)

## Description

Restructure the game UI to follow a horizontal Peglin-style top combat stage layout. Move the combat and cannon panel out of the bottom right corner and span it across the top of the screen (1280x110). Replace the numeric countdown timer with an animated sprite of a mob representing the current city (Halfling, Human, Elf) marching from the right fortification towards the player cannon on the left across the timer duration. If the mob reaches the cannon, the cannon explodes in debris and fire, triggering game over. Reposition the right junk box drawer to start below the top combat strip while extending down to the very bottom of the screen (y=720), giving maximum vertical inventory space by eliminating the bottom cannon widget.

---

## Requirements

### 1. Top Battlefield Panel Reorganization
- Relocate `BattlefieldView` from the 320px right column to a wide horizontal strip across the top of the viewport (x: 0..1280, y: 0..110).
- Position `CannonVisual` on the left of the top strip (e.g. x: 80, y: 55), aiming and firing rightward towards the enemy fortifications.
- Position `WallVisual` and fortifications on the far right of the top strip (e.g. x: 1180, y: 55).
- Integrate `WallHealthBar` with `ValueLabel` and `GoldContainer` cleanly into the top header area.
- Adapt the battlefield background and terrain strip across the 1280px width with a clear bottom dividing border/ledge above the playfield and sidebar.

### 2. City Mob Marching Timer
- Replace the standalone numeric timer label with an animated city mob sprite that advances toward the cannon.
- Dynamically determine the mob visual based on `GameState.current_city_id`:
  - **Halfling Shire:** Halfling mob sprite (scaled-down adventurer humanoid with rustic styling).
  - **Human Kingdom:** Armored soldier / knight mob sprite.
  - **Elf Palace:** Elegant elf mob sprite with woodland/silver tint.
- Synchronize mob advancement strictly with `CombatManager.get_timer_seconds_remaining()`:
  - Starts at the far right near the wall at full phase duration (`Constants.WALL_PHASE_TIME_SECONDS`).
  - Marches steadily to the left with an active walk animation.
  - Arrives at the cannon when `time_expired` is reached.
- When the wall is destroyed before the timer expires, the mob is defeated/cleared, and a fresh mob spawns when the next wall intro plays.

### 3. Cannon Catastrophic Explosion on Breach
- If the mob reaches the cannon (timer hits zero / `time_expired` emitted), trigger a dramatic cannon explosion:
  - Cannon sprite triggers violent screen/recoil shake.
  - Debris and fire explosion particles burst at the cannon origin.
  - Signal / trigger game over screen via `GameCoordinator._on_time_expired()`.

### 4. Right Sidebar & Junk Drawer Repositioning
- Remove the `CircularCannonWidget` from `junk_box_panel.tscn` since the cannon now lives on the top battlefield.
- Adjust `UILayer/CenterPanel` and `RightPanelBg` to start below the top battlefield (y: 110) and extend to the bottom of the screen (y: 720).
- Allow `ScrollContainer` in `JunkBoxPanel` to expand and utilize the full available height (~550px of vertical inventory space).

### 5. Automated Tests and Verification
- Update existing tests in `test_cannon_scrolling_terrain.gd`, `test_lower_right_wall_combat_visuals.gd`, and `test_ui_wireframe_and_screen_layout.gd` to validate the new top coordinates and layout bounds.
- Add automated unit tests verifying:
  - Mob instantiation, correct city texture resolution, and walking progress mapping.
  - Cannon explosion trigger on timer expiration / mob contact.
  - Junk box panel full-height extension without bottom cannon widget.
- Ensure all headless unit tests pass cleanly with 0 errors.
- Ensure file length linter and GDScript standards pass.

---

## Acceptance Criteria

- [x] Cannon and combat battlefield moved from bottom-right to across the top of the screen (1280x110).
- [x] Text timer replaced by animated city mob (Halfling/Human/Elf) marching toward the cannon.
- [x] Mob traversal time matches `CombatManager` siege timer countdown.
- [x] If mob reaches the cannon, cannon explodes in fire and debris and triggers game over.
- [x] Junk drawer starts below the top battlefield and extends to the bottom of the screen (y=720) with no cannon widget at the bottom.
- [x] All automated unit tests pass in headless mode (`tests/run_tests.gd`).
- [x] Source files respect the 500-line limit and coding standards.
