# TASK-072: Multi-Peg Machinery and Component Size Variations

- **Status:** IN PROGRESS
- **Priority:** P1
- **Category:** Gameplay / Systems
- **Target Branch:** feature/multi-peg-machinery-size-variations
- **Related Tasks:** [TASK-026](TASK-026-polyomino-internal-machinery-and-bumpers.md), [TASK-036](TASK-036-pinball-kinetic-machinery-and-lane-switches.md), [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-070](TASK-070-pop-bumper-energy-tuning.md)

## Description

Support multi-peg machinery components across polyomino relic modules.
Remove single-cell constraints for major centerpiece components like the Bash Toy and Slingshot Kicker.
Allow unified multi-cell footprints such as 2x2 square Mega Bumpers, multi-ball Abyssal Sinkholes, and corner kickers.

---

## Requirements

### 1. Polyomino Module Data Architecture
- Add MachineryLayoutMode (PER_CELL = 0, UNIFIED = 1) to PolyominoModuleData.
- Add layout_mode and unified_component_type export variables.
- Add helper method get_module_center_offset(rotation_step: int) -> Vector2 to calculate geometric center.
- Support serialization and deserialization of the new properties.

### 2. Multi-Cell Machinery Component Support
- Add shape type support to PolyominoMachineryComponent (CIRCLE, RECTANGLE, SEGMENT).
- Scale collision shapes and visual drawing based on component footprint dimensions.
- Update PopBumper to scale radius, energy, and impulse for 2x2 and 3x3 footprints.
- Update ScoopSinkhole to hold multiple balls in an array and release them in an outward volley.
- Update BashToy to require a minimum 4-peg (2x2) footprint as a major centerpiece.
- Update SlingshotKicker to support angled segment collision across corner and linear bands.

### 3. Module Node Spawning Integration
- Update PolyominoModuleNode._rebuild_components() to spawn one unified component when layout_mode == UNIFIED.
- Position unified components at the module center offset.
- Ensure PolyominoModuleNode.gd does not exceed the 500-line project limit.

### 4. Relic Database Additions
- Add multi-peg relic definitions to PolyominoRelicDatabase:
  - mega_pop_bumper (2x2 O-shape, unified Mega Pop Bumper)
  - abyssal_maw (2x2 O-shape, unified multi-ball Scoop Sinkhole)
  - golem_effigy (2x2 O-shape, unified Bash Toy)
  - corner_slingshot (3-peg L-shape, unified Corner Slingshot Kicker)

### 5. Automated Tests
- Create tests/test_multi_peg_machinery.gd.
- Test unified component instantiation and positioning.
- Test 2x2 Mega Pop Bumper collision and impulse.
- Test multi-ball Scoop Sinkhole capture and volley ejection.
- Test corner slingshot normal vector impulse.
- Verify that legacy 1x1 per-cell modules remain fully functional.

---

## Acceptance Criteria

- [ ] PolyominoModuleData supports UNIFIED machinery layout mode.
- [ ] PolyominoModuleNode instantiates unified multi-cell components correctly.
- [ ] Bash Toy enforces a minimum 4-peg (2x2) footprint.
- [ ] Slingshot Kicker supports multi-peg angled corner and linear configurations.
- [ ] Scoop Sinkhole supports multi-ball simultaneous capture and ejection.
- [ ] Automated headless tests pass cleanly.
- [ ] All source files remain under the 500-line project threshold.
