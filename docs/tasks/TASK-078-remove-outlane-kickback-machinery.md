# TASK-078: Remove Outlane Kickback Machinery Component from the Game

- **Status:** READY
- **Priority:** P1
- **Category:** Systems / Cleanup
- **Target Branch:** `feature/remove-outlane-kickback-machinery`
- **Related Tasks:** [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-053](TASK-053-relic-machinery-audit-and-widget-distribution.md), [TASK-071](TASK-071-diegetic-relic-activation-categories.md), [TASK-077](TASK-077-remove-standup-target-machinery.md)

## Description

Remove the outlane kickback machinery component from the game.
Outlane kickbacks do not apply to a top-down 2D pegboard layout.
Replace existing outlane kickback relics with standard pinball components like slingshots and accelerators.

---

## Requirements

### 1. Component Code and Visual Removal
- Remove `scenes/board/machinery/outlane_kickback.gd` and its `.uid` file.
- Remove outlane kickback drawing logic from `scenes/board/machinery/polyomino_machinery_visuals.gd`.
- Remove outlane kickback diegetic rendering logic from `scenes/board/machinery/polyomino_diegetic_renderer.gd`.
- Remove outlane kickback creation from `scenes/board/machinery/polyomino_module_node.gd`.
- Remove debug outlane kickback definitions from `scenes/board/machinery/board_machinery_showcase.gd`.

### 2. Relic Database Migration
- Replace `OUTLANE_KICKBACK` in `resources/polyomino/polyomino_relic_database.gd` with slingshots, pop bumpers, or accelerators.
- Update relics that use `OUTLANE_KICKBACK` (such as `renewal_pact` and `arc_surge_wrench`).
- Remove `OUTLANE_KICKBACK` from `resources/polyomino/polyomino_module_data.gd`.
- Update `docs/knowledge/relic-activation-categories.md` to remove outlane kickbacks.

### 3. Automated Tests and Verification
- Update unit tests in `tests/test_relic_machinery_rotation.gd` and `tests/test_relic_widget_distribution.gd`.
- Remove obsolete outlane kickback assertions.
- Make sure that all headless unit tests pass cleanly.

---

## Acceptance Criteria

- [ ] `outlane_kickback.gd` is removed from the codebase.
- [ ] Outlane kickbacks no longer appear in the machinery showcase or relics.
- [ ] Relics with outlane kickbacks migrate to active physical components.
- [ ] Visual rendering and diegetic code no longer reference outlane kickbacks.
- [ ] Headless unit tests pass cleanly.
- [ ] All modified source files remain under 500 lines.
