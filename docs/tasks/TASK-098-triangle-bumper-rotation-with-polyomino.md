# TASK-098: Triangle Bumper Rotation with Polyomino

- **Status:** IN_PROGRESS
- **Priority:** P0
- **Category:** Physics / Systems / Visuals
- **Target Branch:** ix/triangle-bumper-polyomino-rotation
- **Related Tasks:** [TASK-072](TASK-072-multi-peg-machinery-and-size-variations.md), [TASK-093](TASK-093-rework-relics-into-deliberate-pinball-devices.md), [TASK-097](TASK-097-relic-visual-tiles-and-description-updates.md)

## Description

Triangle bumpers (\SlingshotKicker\) inside polyomino relic modules remain in static orientation when the module rotates. When a module is rotated by 90, 180, or 270 degrees, the cell grid positions rotate, but the triangular visual frame, corner posts, and segment collision vertices stay unrotated in their default orientation.

This task adds rotational transformation support to \SlingshotKicker\ and \PolyominoMachineryComponent\, passes the module otation_step\ to all child components, and ensures visual polygon vertices, crackle lines, collision segment endpoints, and impulse normals rotate synchronously with the polyomino module.

---

## Requirements

### 1. Component Rotation State and Transformation
- Add otation_step\ property with setter \set_rotation_step\ to \PolyominoMachineryComponent\.
- Pass \comp.rotation_step = rotation_step\ in \PolyominoModuleNode._rebuild_components()\ for both unified and per-cell layout modes.
- Pass rotated directions for unified components in \PolyominoModuleNode\ and \junk_box_grid_view.gd\.

### 2. Slingshot Kicker Rotational Geometry
- In \SlingshotKicker\, preserve unrotated base geometry (\ase_p1\, \ase_p2\, \ase_corner\).
- When otation_step\ changes (or when configured via \configure_corner\ / \configure_segment\), apply 90-degree clockwise step rotation to vertices:
  - \segment_p1  - \segment_p2  - \corner_p3\ (the 90-degree corner vertex)
- Update \direction\ to point outward from \corner_p3\ through the hypotenuse midpoint.
- Update \_collision_shape_node\ segment endpoints (\seg.a = segment_p1\, \seg.b = segment_p2\) if present.
- Use \corner_p3\ in \_draw_component_body()\ to render the rotated right triangle and frame lines.

### 3. File Length and Coding Standards (Rule 7)
- Maintain all modified files strictly <= 500 lines:
  - \scenes/board/machinery/polyomino_machinery_component.gd  - \scenes/board/machinery/slingshot_kicker.gd  - \scenes/board/machinery/polyomino_module_node.gd  - \scenes/ui/junk_box/junk_box_grid_view.gd- Run \python scripts/lint_gdscript.py\ and \python scripts/lint_file_lengths.py\.

### 4. Verification and Automated Tests
- Author comprehensive unit tests in \	ests/test_triangle_bumper_rotation.gd\ covering:
  - Slingshot vertices (\segment_p1\, \segment_p2\, \corner_p3\) at rotation steps 0, 1, 2, and 3.
  - Impulse normal directions at rotation steps 0, 1, 2, and 3 pointing into playfield.
  - \PolyominoModuleNode\ component generation at all rotation steps.
  - \SegmentShape2D\ collision endpoint updates upon rotation.
- Make sure all headless tests pass cleanly (\godot --headless -s tests/run_tests.gd\).

---

## Acceptance Criteria

- [ ] \SlingshotKicker\ visual triangle polygon and border lines rotate 90 degrees clockwise with each rotation step.
- [ ] Collision segment endpoints and ball contact detection match rotated geometry.
- [ ] Impulse vectors reflect ball away from the rotated hypotenuse into the board.
- [ ] Both per-cell and unified layout modes rotate triangle bumpers correctly.
- [ ] All tests pass cleanly without regressions.
