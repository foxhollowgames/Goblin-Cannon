# TASK-071: Diegetic Relic Activation Categories and Condition Rules

- **Status:** DONE
- **Priority:** P1
- **Category:** Design
- **Target Branch:** `feature/diegetic-relic-activation-categories`
- **Related Tasks:** [TASK-024](TASK-024-polyomino-relic-shapes-and-sizes.md), [TASK-048](TASK-048-relic-activation-requirements-pinball-widget-rework.md), [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-053](TASK-053-relic-machinery-audit-and-widget-distribution.md), [TASK-060](TASK-060-tooltip-rewrite-and-keyword-tag-hover-audit.md), [TASK-069](TASK-069-in-game-machinery-components-dashboard.md)

## Description

Define a discrete set of activation condition categories for polyomino relics.
Make relic activations diegetic and intuitive through visual machinery layout.
Replace arbitrary multi-hit sequences with clear, readable physical mechanics.
Establish explicit activation categories that players learn over time.

---

## Requirements

### 1. Diegetic Activation Design Framework
- Remove arbitrary, disconnected activation rules across relics.
- Establish visual readability rules where internal machinery components show activation requirements clearly.
- Make sure that players understand how to trigger a relic by inspecting its board layout.

### 2. Discrete Activation Categories
- Define four to six explicit, named activation condition categories.
- Example categories:
  - **Impact Threshold**: Triggered by hitting bumpers or heavy targets.
  - **Sequential Route**: Triggered by completing an ordered path through guide tracks and switches.
  - **Sustained Momentum**: Triggered by accumulating continuous spins on spinners.
  - **Bank Completion**: Triggered by knocking down an entire bank of drop targets.
  - **Pocket Lock**: Triggered by sinking balls into scoop holes or ball locks.
- Document clear mechanical rules and player visual cues for each category.

### 3. Relic Roster Mapping and Design Rules
- Examine Campaign 1 relics in `polyomino_relic_database.gd`.
- Map every relic to one of the defined activation categories.
- Create standardized data structures and tooltip text for each category.
- Help players learn the mechanics during gameplay.

### 4. Design Documentation
- Create design documentation in `docs/knowledge/relic-activation-categories.md`.
- Give visual examples, machinery combinations, and player mental model guidelines.

---

## Acceptance Criteria

- [x] A discrete taxonomy of relic activation categories is defined and documented.
- [x] Each activation category has clear visual and diegetic rules.
- [x] Category-aligned mechanics replace arbitrary multi-target hit requirements.
- [x] The Campaign 1 relic catalog maps to the new activation categories.
- [x] Documentation explains the player learning curve for activation categories.
- [x] The task dashboard shows the new task in the Design category.

