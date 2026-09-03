# TASK-065: UI Wireframe and Screen Layout Redesign

- **Status:** DONE
- **Priority:** P1
- **Category:** UI / Layout / Design
- **Target Branch:** `feature/ui-wireframe-redesign`
- **Related Tasks:** [TASK-004](TASK-004-right-panel-and-comic-cutouts.md), [TASK-017](TASK-017-ui-art-and-telemetry-panels.md), [TASK-042](TASK-042-hopper-positioning-top-ui-bar-and-debug-menu.md)

## Description

Redesign the wireframe layout for the Goblin Cannon user interface across all core game screens.
Establish clean spatial zones, responsive proportions, and visual hierarchy for the 1280x720 display canvas.

---

## Core Requirements

### 1. Primary Gameplay Screen Wireframe
- Define exact bounding zones for the primary playfield (0 to 960 px X-axis) and the right telemetry sidebar (960 to 1280 px X-axis).
- Redesign the top header bar layout to house wall health, siege timer, gold count, and pause controls in balanced zones.
- Position the hopper, pegboard grid, and bottom bucket collectors with clear vertical margins.
- Integrate the Junk Box inventory panel cleanly into the right sidebar layout without occluding combat monitors.

### 2. Overlay and Modal Screen Wireframes
- Wireframe the Milestone Shop and Relic Draft selection screen with clear card slots, descriptions, and purchase buttons.
- Wireframe the Fullscreen Comic Cutscene takeover overlay with dialogue panels and skip controls.
- Wireframe the Victory and Run Defeat screens with score breakdown, stats telemetry, and retry navigation.
- Wireframe the in-game settings and pause menu overlay.

### 3. Visual Hierarchy and Eye Flow
- Place critical combat telemetry (cannon charge gauge, wall status, countdown timers) in primary viewing zones.
- Enforce consistent 8px/16px padding grids across all control containers.
- Guarantee that all interactive buttons and draggable modules keep comfortable hit targets for mouse and pointer inputs.

---

## Acceptance Criteria

- [x] Complete wireframe layouts and coordinate maps documented for the primary gameplay screen.
- [x] Wireframe layouts documented for all modal screens (shop, pause, victory, defeat, comic takeovers).
- [x] Safe zone and padding guidelines established for 1280x720 canvas stretch modes.
- [x] Visual telemetry hierarchy verified to prevent gameplay information clutter.
- [x] Task registered in the master task board index and visual dashboard.
