# TASK-081: Remove Directional Deflector Machinery Component from the Game

- **Status:** REVIEW
- **Priority:** P1
- **Category:** Systems / Cleanup
- **Target Branch:** `feature/remove-directional-deflector-machinery`
- **Related Tasks:** [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-053](TASK-053-relic-machinery-audit-and-widget-distribution.md), [TASK-071](TASK-071-diegetic-relic-activation-categories.md), [TASK-077](TASK-077-remove-standup-target-machinery.md), [TASK-078](TASK-078-remove-outlane-kickback-machinery.md)

## Description

Remove the directional deflector machinery component from the game.
Rigid fixed-angle deflector baffles create unnatural trajectory overrides that clash with pegboard physics.
Replace directional deflectors with natural kinetic components like slingshots, guide rails, or pop bumpers.

---

## Requirements

### 1. Component Code and Visual Removal
- Remove `scenes/board/machinery/directional_deflector.gd` and its `.uid` file.
- Remove directional deflector drawing logic from `scenes/board/machinery/polyomino_machinery_visuals.gd`.
- Remove directional deflector creation from `scenes/board/machinery/polyomino_module_node.gd`.
- Remove debug directional deflector definitions from `scenes/board/machinery/board_machinery_showcase.gd`.

### 2. Relic Database Migration
- Replace `DIRECTIONAL_DEFLECTOR` components in `resources/polyomino/polyomino_relic_database.gd` with natural kinetic widgets.
- Update relics that use `DIRECTIONAL_DEFLECTOR` (such as `perpetual_engine`, `storm_of_fragments`, and `fragment_swarm`).
- Remove `DIRECTIONAL_DEFLECTOR` from `resources/polyomino/polyomino_module_data.gd`.

### 3. Automated Tests and Verification
- Update unit tests in `tests/test_polyomino_machinery.gd` and `tests/test_relic_audio_levels.gd`.
- Remove obsolete directional deflector assertions.
- Make sure that all headless unit tests pass cleanly.

---

## Acceptance Criteria

- [x] `directional_deflector.gd` is removed from the codebase.
- [x] Directional deflectors no longer appear in the machinery showcase or relics.
- [x] Relics with directional deflectors migrate to natural kinetic components.
- [x] Visual rendering and module node code no longer reference directional deflectors.
- [x] Headless unit tests pass cleanly.
- [x] All modified source files remain under 500 lines.
