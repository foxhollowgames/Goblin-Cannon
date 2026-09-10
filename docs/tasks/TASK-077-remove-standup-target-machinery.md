# TASK-077: Remove Standup Target Machinery Component from the Game

- **Status:** READY
- **Priority:** P1
- **Category:** Systems / Cleanup
- **Target Branch:** `feature/remove-standup-target-machinery`
- **Related Tasks:** [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-053](TASK-053-relic-machinery-audit-and-widget-distribution.md), [TASK-071](TASK-071-diegetic-relic-activation-categories.md), [TASK-075](TASK-075-update-relic-hover-tooltips.md)

## Description

Remove the standup target machinery component from the game.
Standup targets do not read well in a top-down 2D board with downward falling balls.
Replace existing standup target relics with clearer top-down physical components.

---

## Requirements

### 1. Component Code and Visual Removal
- Remove `scenes/board/machinery/standup_target.gd` and its `.uid` file.
- Remove standup target drawing logic from `scenes/board/machinery/polyomino_machinery_visuals.gd`.
- Remove standup target diegetic rendering logic from `scenes/board/machinery/polyomino_diegetic_renderer.gd`.
- Remove standup target creation and hit tracking from `scenes/board/machinery/polyomino_module_node.gd`.
- Remove debug standup target definitions from `scenes/board/machinery/board_machinery_showcase.gd`.

### 2. Relic Database Migration
- Replace `STANDUP_TARGET` components in `resources/polyomino/polyomino_relic_database.gd` with drop targets, bash toys, or bumpers.
- Update relic goals that use `STANDUP_BANK` in `resources/polyomino/polyomino_relic_database.gd`.
- Remove `STANDUP_TARGET` and `STANDUP_BANK` from `resources/polyomino/polyomino_module_data.gd`.
- Update `docs/knowledge/relic-activation-categories.md` to remove the standup target bank archetype.

### 3. Automated Tests and Verification
- Update unit tests in `tests/test_multi_peg_machinery.gd` and other test files.
- Remove obsolete standup target assertions.
- Make sure that all headless unit tests pass cleanly.

---

## Acceptance Criteria

- [ ] `standup_target.gd` is removed from the codebase.
- [ ] Standup targets no longer appear in the machinery showcase or relics.
- [ ] All relics using standup targets migrate to other physical machinery components.
- [ ] Visual rendering and diegetic code no longer reference standup targets.
- [ ] Headless unit tests pass cleanly.
- [ ] All modified source files remain under 500 lines.
