# TASK-094: Update Debug Menu Stores with New Relics

- **Status:** DONE
- **Priority:** P1
- **Category:** Debug / UI / Systems
- **Target Branch:** `feature/update-debug-menu-stores-with-new-relics`
- **Related Tasks:** [TASK-073](TASK-073-debug-board-machinery-showcase.md), [TASK-093](TASK-093-rework-relics-into-deliberate-pinball-devices.md)

## Description

Update the stores in the debug menu (`DebugFullStoreModal`) to display only the newly built deliberate relics, leaving legacy randomized machine pieces and passive stat buffs behind. Rename the debug store tab simply to `"Relics"`. Ensure full variety across the 7 core deliberate archetypes with 2 variations per tier across all 3 tiers (14 per tier = 42 total deliberate relics), featuring meaningful differences in sizes, configurations, and scaling abilities, as well as varied polyomino track configurations (stairs, right angles, U-turns, zigzags, and closed loops). Refactor `DebugFullStoreModal` to strictly adhere to Rule 7 (<= 500 lines).

---

## Requirements

### 1. Catalog & Archetype Variations
- Define 42 deliberate relics in `DeliberateRelicCatalog` across 7 core archetypes x 3 tiers x 2 variations:
  1. Bumper Chambers & Vessels (T1: Twin Core, Staggered Funnel; T2: Pachinko Chamber, Octagon Chamber; T3: Mega Bumper Citadel, Cyclone Bounce Vault)
  2. Rollover Word Banks (T1: G-O-B, P-O-P; T2: W-I-N, B-A-M; T3: B-O-O-M, L-O-O-T)
  3. Wire Gate Retention Reservoirs (T1: Retention Cup, Funnel Basin; T2: Reservoir Basin, Abyssal Maw; T3: Grand Wire Reservoir, Armory Ball Vault)
  4. Crackling Detonation Triangles (T1: Wedge Kicker, Acute Triangle; T2: Corner Slingshot, Dual Pincer; T3: Storm Bastion, Apex Overcharge)
  5. Chonky Bash Toys (T1: Lesser Goblin Idol, Blacksmith Anvil; T2: Golem Effigy, Iron Sentinel; T3: Colossus War Effigy, Juggernaut Monolith)
  6. Funneled Spinners (T1: Chute Spinner, V-Funnel Pocket Spinner; T2: Funneled Kinetic Spinner, Dual Funnel Rev Engine; T3: Resonant Well, Overdrive Vortex Spinner)
  7. Momentum Tracks & Speed Rails (T1: Straight Guide Rail, Z-Step Polyomino Stairs; T2: L-Turn Right-Angle Polyomino, U-Turn Polyomino; T3: S-Snake Zigzag Polyomino, Closed Loop Accelerator Ring)
- Provide standardized colon format (`[Component]: [Description]`) and rich kinetic descriptions.

### 2. Debug Store Relics Tab & Junk Box Delivery
- In `DebugFullStoreModal`:
  - Rename tab simply to `"Relics"`.
  - Display only deliberate relics; leave old legacy passives, wall breaks, and boss relic duplicates behind.
  - Display kinetic machine descriptions, shape name, tier tags, and activation goals.
  - Provide an "Add" button that automatically creates a `JunkBoxItem` and adds it directly to `GameState.junk_box` with instant visual confirmation ("Added!").

### 3. File Length & Architecture (Rule 7)
- Maintain all modified and created files strictly <= 500 lines:
  - `resources/polyomino/deliberate_relic_catalog.gd`
  - `resources/polyomino/polyomino_relic_database.gd`
  - `scenes/rewards/reward_card_catalog.gd`
  - `scenes/rewards/reward_handler.gd`
  - `scenes/ui/debug_full_store_modal.gd` (refactored from 547 lines down to ~360 lines)
- Remove `debug_full_store_modal.gd` from baseline limits in `lint_file_lengths.py` and `tests/test_file_lengths.gd`.

### 4. Verification & Testing
- Unit test `tests/test_debug_store_new_relics.gd` verifying all 42 deliberate relics, track polyomino configurations, catalog integration, tab name, and Junk Box placement.
- Pass `python scripts/lint_gdscript.py` and full test suite (`tests/run_tests.gd`).

---

## Acceptance Criteria

- [x] Exactly 42 deliberate relics across 7 archetypes and 3 tiers (14 per tier) defined in `DeliberateRelicCatalog`.
- [x] Track polyomino configurations include stairs, right angles, U-turns, zigzags, and closed loops.
- [x] Debug store modal tab named simply `"Relics"`.
- [x] Only deliberate relics shown in the debug store; legacy relics left behind.
- [x] "Add" button grants deliberate relic directly to `GameState.junk_box`.
- [x] All repository files comply with Rule 7 (<= 500 lines).
- [x] All automated tests pass in headless mode (12,560+ tests passing, 0 failing).
