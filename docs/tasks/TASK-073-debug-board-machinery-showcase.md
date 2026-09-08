# TASK-073: Debug Menu Option to Showcase All Relic Machinery Permutations and Sizes on Board

- **Status:** IN_REVIEW
- **Priority:** P1
- **Category:** Gameplay / Tooling / Debug
- **Target Branch:** `feature/debug-board-machinery-showcase`
- **Related Tasks:** [TASK-026](TASK-026-polyomino-internal-machinery-and-bumpers.md), [TASK-036](TASK-036-pinball-kinetic-machinery-and-lane-switches.md), [TASK-051](TASK-051-componentized-pinball-machinery-roster.md), [TASK-069](TASK-069-in-game-machinery-components-dashboard.md), [TASK-072](TASK-072-multi-peg-machinery-and-size-variations.md)

## Description

Create a debug menu option to change the board into a full machinery showcase.
Place every pinball machinery component, size variation, and directional permutation on the board simultaneously.
When the user moves the mouse cursor over any debug machinery item, show a detailed tooltip with its name, physical behavior description, and gameplay statistics.

---

## Requirements

### 1. Debug Menu Integration
- Add a new tool button in the left panel debug menu (`scenes/main/game_coordinator_debug.gd`).
- Label the button "All Machinery" with a tooltip explaining its function.
- Connect the button to trigger the machinery showcase setup on the active board.

### 2. Full Machinery Catalog, Sizes, and Permutations
- Create a dedicated showcase builder (`scenes/board/machinery/board_machinery_showcase.gd`).
- Include all component types from the pinball roster:
  - **Pop Bumper**: 1x1 standard, 2x2 unified Mega Pop Bumper, 3x3 unified Giga Pop Bumper.
  - **Pinball Bumper**: 1x1 standard contact bumper.
  - **Speed Boost Wheel / Rotary Booster**: 4 directional permutations (Down, Up, Left, Right).
  - **Mana Siphon**: 1x1 permeable energy ring.
  - **Drop Target**: 1x1 retractable target plate.
  - **Standup Target**: 1x1 rigid rebound plate.
  - **Spinner**: 1x1 rotating axle target.
  - **Rollover Switch**: 1x1 floor wire switch.
  - **Slingshot Kicker**: 1x1 corner kicker, 3-cell unified L-shape corner kicker.
  - **Directional Deflector**: 4 directional permutations (Down, Up, Left, Right).
  - **Scoop Sinkhole**: 1x1 standard catch scoop, 2x2 unified Abyssal Maw multi-ball sinkhole.
  - **Ball Lock**: 1x1 multi-ball storage magazine.
  - **Guide Track**: Horizontal and Vertical directional rails.
  - **Orbit Loop**: 1x1 curved sweep channel.
  - **Captive Ball**: 1x1 momentum transfer sphere.
  - **Mechanical Diverter**: Alternating left and right routing flappers.
  - **Vertical Up Kicker**: 1x1 subterranean launch cup.
  - **Bash Toy**: 1x1 legacy totem, 2x2 unified Golem Effigy.
  - **Outlane Kickback**: 1x1 emergency solenoid puncher.
  - **Wire Gate**: 1x1 one-way check gate.

### 3. Board Placement Layout
- Lay out all permutations cleanly without overlap across the 15x8 board grid.
- Clear previous modules and suppressed pegs before laying out the showcase items.
- Maintain full collision and visual rendering for all placed showcase components.

### 4. Detailed Mouse-Over Tooltip Inspection
- When the mouse cursor moves over a showcase component, display:
  - Canonical Component Name and Footprint/Direction Tag.
  - Detailed Physical Behavior description.
  - Gameplay Statistics:
    - Component Classification / Category.
    - Grid Dimensions & Footprint size.
    - Energy Granted on hit/trigger.
    - Impulse Velocity and Direction.
    - Hitbox Radius / Dimensions.
- Keep standard campaign relic tooltips unaffected without metadata leakage.

### 5. Automated Tests
- Create automated headless unit tests in `tests/test_debug_board_machinery_showcase.gd`.
- Verify debug button existence and action trigger.
- Verify that all machinery permutations are generated and placed on the board without collision overlap.
- Verify tooltip content formatting for showcase items versus standard campaign relics.

---

## Acceptance Criteria

- [x] "All Machinery" button appears in the debug tools menu.
- [x] Clicking the button clears the board and populates all machinery permutations and sizes.
- [x] All 33 distinct machinery items fit cleanly on the 15x8 board grid without overlaps.
- [x] Hovering over any showcase item shows its name, physical behavior, and statistics.
- [x] Standard campaign relics continue to use simplified tooltips.
- [x] Automated headless tests pass cleanly.
- [x] All new and modified files remain under the 500-line project threshold.
