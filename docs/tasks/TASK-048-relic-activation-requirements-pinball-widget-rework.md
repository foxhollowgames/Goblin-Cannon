# TASK-048: Relic Activation Requirements Pinball Widget Rework

- **Status:** BACKLOG
- **Priority:** P1
- **Category:** Systems / Gameplay
- **Target Branch:** `feature/relic-pinball-activation-rework`
- **Related Tasks:** [TASK-024](TASK-024-polyomino-relic-shapes-and-sizes.md), [TASK-049](TASK-049-on-board-relic-tooltip-rework.md), [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-053](TASK-053-relic-machinery-audit-and-widget-distribution.md)

## Description

Rework Campaign 1 polyomino relics so their active triggers and effects link directly to kinetic hits on integrated pinball machinery widgets (bumpers, targets, spinners, and rollover switches) instead of arbitrary counters.
Display explicit activation requirements on inventory tooltips and cards to provide clear tactical placement incentives.

---

## Requirements

### 1. Widget Hit Activation Binding
- Bind polyomino relic trigger counters to collisions with specific internal pinball machinery components.
- Support hit count accumulation for pop bumpers, standup targets, drop targets, spinners, and rollover switches.
- Trigger relic active effects when component hit thresholds are reached during ball cascades.

### 2. UI Activation Requirement Specification
- Expose clear `Activation Requirement` strings in relic data definitions.
- Display requirements on hover tooltips in Junk Box and Shop card views as established in [TASK-049](TASK-049-on-board-relic-tooltip-rework.md).
- Show current hit counters and charge progress during live combat simulation.

### 3. Automated Tests
- Write unit tests in `tests/test_relic_pinball_activation.gd`.
- Verify that widget hits increment relic activation counters.
- Verify that relic abilities fire upon reaching activation thresholds.

---

## Acceptance Criteria

- [ ] Relic activation conditions directly connect to kinetic hits on internal pinball widgets.
- [ ] Activation requirements and counters are clearly exposed in UI tooltips and relic data.
- [ ] Relic active abilities trigger correctly upon meeting hit thresholds.
- [ ] Unit tests pass cleanly in headless mode.
