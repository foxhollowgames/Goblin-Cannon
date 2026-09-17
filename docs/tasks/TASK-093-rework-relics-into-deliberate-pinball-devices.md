# TASK-093: Rework Relics into Deliberate Pinball Devices and Mechanisms

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** Systems / Gameplay / Visuals
- **Target Branch:** `fix/task-093-relic-flow`
- **Related Tasks:** [TASK-024](TASK-024-polyomino-relic-shapes-and-sizes.md), [TASK-026](TASK-026-polyomino-internal-machinery-and-bumpers.md), [TASK-033](TASK-033-relic-bounding-enclosures-and-dividing-lanes.md), [TASK-036](TASK-036-pinball-kinetic-machinery-and-lane-switches.md), [TASK-048](TASK-048-relic-activation-requirements-pinball-widget-rework.md), [TASK-071](TASK-071-diegetic-relic-activation-categories.md), [TASK-074](TASK-074-relic-machinery-trigger-safeguards-and-debounce.md), [TASK-083](TASK-083-rework-wire-gate-component-holding-cup.md)

## Description

Rework the entire relic roster away from randomized machine pieces slotted haphazardly into shapes, replacing them with **deliberate, cohesive pinball machine mechanisms** with clear physical visual identities, intuitive kinetic logic, and player-driven board routing combos:

1. **Bumper Chambers & Cores (Pachinko Bumper Vessel):**
   - Rounded or funnel-shaped vessels with open top entrances and open bottom exits.
   - Symmetrically filled with multiple bumpers (e.g. 4 bumpers in a diamond, 3 in a triangle).
   - Functions purely as a high-frequency kinetic bounce chamber that generates intense ball energy on rapid ricochets before dropping out the bottom.
2. **Rollover Word & Lane Banks (Spelling Chutes):**
   - Multi-lane divided structures with vertical dividing walls (`DIVIDED_LANES`).
   - Floor switches (Rollover Switches) in each lane, with corresponding letter/glyph labels above each lane (e.g., "W-I-N", "G-O-B", "P-O-P", "Z-A-P").
   - Rolling over an unlit switch lights it up and awards an instant energy bonus to the ball.
   - Lighting all switches in the bank triggers the relic completion bonus and resets all switches back to unlit so the word can be spelled again.
3. **Ball Retention Reservoirs (Wire Gate Catch & Release):**
   - Vessel/bowl enclosures with open top to catch downward-falling balls and a closed wire gate at the bottom.
   - Accumulates and holds balls inside until reaching full capacity (e.g. 3–6 balls).
   - Once full, the wire gate opens, releasing the accumulated balls in an ejection cascade, triggering the relic bonus, and closing after exit.
4. **Crackling Detonation Triangles (Energizing Slingshot Wedges):**
   - Right-triangle and wedge bumpers that bounce balls off their angled hypotenuse face.
   - Each ball impact charges the bumper, causing electric blue crackling lightning arcs to crawl and intensify across its surface.
   - Upon reaching full charge (e.g. 3–4 hits), detonates with an explosive shockwave, damaging/energizing nearby pegs, granting bonus energy, and resetting charge.
5. **Chonky Bash Toys (Board Setpieces):**
   - Large 2x2 and 3x3 multi-cell visual centerpieces that act as focal points on the board, absorbing repeated hits to trigger massive demolitions.
6. **Funneled Spinners (Kinetic Rev Engines):**
   - Spinners housed in larger machines with funneling walls/rails directing balls straight into the blades.
   - Spinning fast enough (RPM threshold) triggers the relic bonus and initiates a cooldown, while continuing to award base energy on each spin.
7. **Speed Rails & Flow Control Tracks (Momentum Routers):**
   - Polyomino track shapes (straight runs, L-turns, U-curves, speed-wheel rails) that accelerate and redirect ball momentum, allowing players to build intentional delivery pipelines into downstream relics.
8. **Roster Audit & Unification:**
   - Overhaul the 81+ relic definitions in `PolyominoRelicDatabase` so every relic follows one of these cohesive, purposeful pinball machine archetypes rather than an arbitrary salad of unrelated components.

---

## Requirements

### 1. Rollover Word Bank Mechanics & Reset Cycle
- Enhance `RolloverSwitch` and `PolyominoModuleNode` to support letter/glyph tags per switch.
- When an unlit switch is hit, grant bonus energy to the activating ball and light the switch.
- When all switches in the word/bank are lit:
  - Trigger relic goal/reward completion.
  - Reset all switches in the bank back to unlit state.
- Render letters/glyphs cleanly above or inside each divided rollover lane.

### 2. Ball Retention Reservoir Mechanics
- Ensure `WireGate` and holding vessel enclosures catch downward balls and hold them.
- When held ball count reaches capacity, trigger relic reward and open gate with exit impulse.
- Visually represent the reservoir holding balls and the gate mechanism opening/closing.

### 3. Crackling Detonation Triangle Component
- Implement or enhance triangular bumper / slingshot kicker with hit charging and crackle VFX.
- Draw animated electrical lightning arcs along the hypotenuse face that scale in intensity with charge level.
- On threshold hit, trigger explosive detonation shockwave (radial blast, peg hits/impulse, explosion effect) and reset charge.

### 4. Funneled Spinners with RPM Threshold & Cooldown
- In `Spinner`, track RPM / burst speed, trigger relic effect on threshold, and enter cooldown while continuing base energy.
- House spinners in funneled relic structures that channel balls into the blades.

### 5. Speed Rails & Flow Control Tracks
- Support speed boost wheel combos and polyomino routing tracks (straight, L-bends, U-turns).

### 6. Bumper Chamber & Core Assembly
- Configure rounded/funnel enclosures with open top and open bottom exits.
- Arrange 3–4 bumpers inside for sustained bouncing action.

### 7. Relic Database Audit & Overhaul
- Restructure relics in `PolyominoRelicDatabase` into deliberate, coherent designs based on these archetypes.
- Ensure all relics have clear trigger/effect descriptions and valid tooltips.
- Maintain test compatibility for all existing suites.

---

## Acceptance Criteria

- [x] Rollover switch banks grant ball energy when lit and reset after spelling all letters/triggers.
- [x] Letters or glyphs render visibly above rollover lanes in divided lane assemblies.
- [x] Retention reservoirs trap falling balls until capacity is reached, then release them and trigger relic bonuses.
- [x] Triangular bumpers crackle with electric lightning as they are struck and detonate on full charge with an explosion.
- [x] Funneled spinners trigger effects at high RPM and enter cooldown while awarding base energy.
- [x] Speed boost wheels and track conduits redirect ball momentum for board combos.
- [x] Bumper chambers bounce balls repeatedly between internal bumpers and release them through open exits.
- [x] Relic definitions in `PolyominoRelicDatabase` reworked into deliberate, purposeful pinball machines.
- [x] All automated tests pass in headless mode (`tests/run_tests.gd`).
- [x] GDScript standards and file length limits (<= 500 lines) strictly satisfied.

## Iteration 2: Accessible Ball Flow (2026-09-16)

The first implementation did not prove usable entrance-to-exit paths. Reopened after user review.

### Approved scope
- Audit both relic catalogs for sealed passages, missing components, and false trigger descriptions.
- Separate physical walls from placement footprints. Rotate openings with the device.
- Prove open word lanes, bumper chambers, and retention reservoirs before expanding variants.
- Connect spinner, route, and reservoir rewards to mechanism events.
- Add safe partial reservoir release, entrance/exit placement feedback, and physical flow tests.
- Keep seven distinct device families and preserve open board space.

### Iteration acceptance
- [x] Word banks have accessible entrances and exits in every supported rotation.
- [x] Passage walls and preview walls use the same geometry.
- [x] All catalog component cells belong to the reserved footprint.
- [x] Chambers guide balls without blocking their drain.
- [x] Reservoirs release captured balls, including underfilled recovery without a full reward.
- [x] Spinner and route rewards match the displayed condition.
- [x] Placement shows entrances/exits and detects directly blocked ports.
- [x] Real physics tests cover passage, retention, rotation, and device combinations.
- [ ] Quality checks and independent PR review pass; changes merge to main.

Review: [Ball flow review and implementation contract](../knowledge/relic-ball-flow-review.md).

Iteration 2 verification: 16,651 assertions pass, real physics scenarios pass, and independent PR review approved both follow-up fixes. PR: https://github.com/foxhollowgames/Goblin-Cannon/pull/76. Merge pending.
