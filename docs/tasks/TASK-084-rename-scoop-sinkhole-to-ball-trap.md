# TASK-084: Rename Scoop Sinkhole to Ball Trap

- **Status:** READY
- **Priority:** P1
- **Category:** Systems / Cleanup
- **Target Branch:** `feature/rename-scoop-sinkhole-to-ball-trap`
- **Related Tasks:** [TASK-036](TASK-036-pinball-kinetic-machinery-and-lane-switches.md), [TASK-048](TASK-048-relic-activation-requirements-pinball-widget-rework.md), [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-069](TASK-069-in-game-machinery-components-dashboard.md), [TASK-071](TASK-071-diegetic-relic-activation-categories.md), [TASK-072](TASK-072-multi-peg-machinery-and-size-variations.md), [TASK-073](TASK-073-debug-board-machinery-showcase.md), [TASK-074](TASK-074-relic-machinery-trigger-safeguards-and-debounce.md), [TASK-082](TASK-082-simplify-relic-tooltip-terminology.md)

## Description

Rename the "Scoop Sinkhole" machinery component simply to "Ball Trap".
The term "Scoop Sinkhole" is long and uses complex pinball jargon.
The simplified name "Ball Trap" clearly communicates the mechanical function to players.
This change updates the data models, scenes, visuals, tooltips, test scripts, and documentation.

---

## Requirements

### 1. Data Model and Enumeration Updates
- Add `BALL_TRAP` to `CellType` in `resources/polyomino/polyomino_module_data.gd`.
- Keep or replace `SCOOP_SINKHOLE` with `BALL_TRAP` cleanly across the module system.
- Update relic component definitions in `resources/polyomino/polyomino_relic_database.gd` to reference `BALL_TRAP`.

### 2. Scene and Script Renaming
- Rename `scenes/board/machinery/scoop_sinkhole.gd` to `scenes/board/machinery/ball_trap.gd`.
- Rename class `ScoopSinkhole` to `BallTrap`.
- Update script references in `scenes/board/machinery/polyomino_module_node.gd`.
- Update visual rendering methods in `scenes/board/machinery/polyomino_machinery_visuals.gd` to use `_draw_ball_trap`.
- Update `scenes/board/machinery/polyomino_diegetic_renderer.gd` to use the new identifier.

### 3. Display Text and Descriptions
- Change user-facing text from "Scoop Sinkhole" to "Ball Trap" across relic descriptions and tooltips.
- Update relic composition strings in `resources/polyomino/polyomino_relic_database.gd`.
- Update the debug machinery showcase in `scenes/board/machinery/board_machinery_showcase.gd`.
- Update the interactive component dashboard in `docs/knowledge/in-game-components-dashboard.html`.

### 4. Knowledge Base and Documentation
- Update references in `docs/knowledge/relic-activation-categories.md`.
- Update references in `docs/knowledge/pinball-widget-research-and-layout-analysis.md`.
- Update the component list and definitions in related documentation files.

### 5. Automated Tests and Verification
- Update references in test scripts (for example, `tests/test_relic_machinery_rotation.gd` and `tests/test_relic_machinery_trigger_safeguards.gd`).
- Update component validation in `tests/test_in_game_components_dashboard.py`.
- Verify that all headless unit tests pass cleanly.
- Verify that all modified source files stay under the 500-line limit.

---

## Acceptance Criteria

- [ ] `CellType` defines `BALL_TRAP` for the component.
- [ ] `scenes/board/machinery/ball_trap.gd` replaces `scoop_sinkhole.gd`.
- [ ] Relic compositions and tooltips show "Ball Trap" instead of "Scoop Sinkhole".
- [ ] The debug showcase displays "Ball Trap".
- [ ] Component documentation and dashboards show "Ball Trap".
- [ ] All automated tests pass cleanly.
- [ ] All modified source files remain under the 500-line project threshold.
