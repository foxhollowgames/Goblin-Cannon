# TASK-055: Relic Directional Machinery Rotation Compliance

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** Systems / Gameplay / Physics
- **Target Branch:** `feature/relic-directional-machinery-rotation`
- **Related Tasks:** [TASK-025](TASK-025-polyomino-drag-drop-and-grid-snapping.md), [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-053](TASK-053-relic-machinery-audit-and-widget-distribution.md)

## Description

Make sure that internal relic machinery components rotate with the rotation of the relic itself.
Make sure directional widgets such as guide tracks and kickers update launch vectors upon rotation.

---

## Requirements

### 1. Directional Component Rotation
- Rotate internal machinery components with the rotation angle of the relic.
- Make sure guide tracks rotate with the relic rotation instead of pointing up.
- Rotate kickers, mechanical ramps, and diverters according to relic orientation.

### 2. Physics Vector and Collider Transformation
- Transform launching vectors and force directions to match the rotated relic angle.
- Rotate collision shapes and trigger boundaries for internal pinball widgets.
- Make sure ball physics interactions follow the rotated machinery paths accurately.

### 3. Visual Sprite and Preview Alignment
- Rotate component sprites and visual indicators when the player rotates the relic.
- Update hover previews to show rotated machinery directions before grid placement.
- Retain correct rotation angles during drag, hover, and drop operations.

### 4. Automated Tests
- Write unit tests in `tests/test_relic_machinery_rotation.gd`.
- Test that guide track launch vectors change with relic rotation angles.
- Test that kicker physics vectors transform for 0, 90, 180, and 270 degree rotations.
- Test that visual component rotation matches the parent relic orientation.

---

## Acceptance Criteria

- [ ] Guide tracks and directional machinery rotate with relic rotation.
- [ ] Launch vectors and physics colliders match rotated relic angles.
- [ ] Component sprites and hover previews display rotated orientations correctly.
- [ ] Unit tests pass cleanly in headless mode.
