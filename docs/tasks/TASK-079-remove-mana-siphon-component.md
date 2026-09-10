# TASK-079: Remove Mana Siphon as a Standard Machinery Component

- **Status:** READY
- **Priority:** P1
- **Category:** Systems / Cleanup
- **Target Branch:** `feature/remove-mana-siphon-component`
- **Related Tasks:** [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-053](TASK-053-relic-machinery-audit-and-widget-distribution.md), [TASK-071](TASK-071-diegetic-relic-activation-categories.md)

## Description

Remove the Mana Siphon component as a standard machinery item.
Permeable sensor rings lack tactile kinetic response during ball collisions.
Replace Mana Siphons across relics with active or reactive physical pinball machinery.

---

## Requirements

### 1. Component Code and Visual Removal
- Remove `scenes/board/machinery/mana_siphon.gd` and its `.uid` file.
- Remove mana siphon drawing logic from `scenes/board/machinery/polyomino_machinery_visuals.gd`.
- Remove mana siphon diegetic rendering logic from `scenes/board/machinery/polyomino_diegetic_renderer.gd`.
- Remove mana siphon creation from `scenes/board/machinery/polyomino_module_node.gd`.
- Remove debug mana siphon definitions from `scenes/board/machinery/board_machinery_showcase.gd`.

### 2. Relic Database Migration
- Replace `MANA_SIPHON` components in `resources/polyomino/polyomino_relic_database.gd` with physical widgets.
- Update relics that use `MANA_SIPHON` (such as `cascade_reactor`, `blood_tithe`, and `twin_mandate`).
- Remove `MANA_SIPHON` from `resources/polyomino/polyomino_module_data.gd`.
- Update `docs/knowledge/relic-activation-categories.md` and documentation dashboards.

### 3. Automated Tests and Verification
- Update unit tests in `tests/test_polyomino_machinery.gd` and `tests/test_relic_audio_levels.gd`.
- Remove obsolete mana siphon assertions.
- Make sure that all headless unit tests pass cleanly.

---

## Acceptance Criteria

- [ ] `mana_siphon.gd` is removed from the codebase.
- [ ] Mana Siphons no longer appear in the machinery showcase or relics.
- [ ] Relics with Mana Siphons migrate to tactile physical components.
- [ ] Visual rendering and diegetic code no longer reference Mana Siphons.
- [ ] Headless unit tests pass cleanly.
- [ ] All modified source files remain under 500 lines.
