# TASK-027: Junk Box Backpack Inventory System

- **Status:** DONE
- **Priority:** P1
- **Category:** UI / Systems
- **Target Branch:** `feature/junk-box-backpack-inventory`

## Description

Design and implement the **Junk Box** (backpack inventory system) — a scrollable, endless-capacity spatial storage container where players stash, organize, rotate, and manage unplaced polyomino modules, spare kinetic components, ball reserves, and scrap materials during a run.

The Junk Box serves as the central off-board staging area for the drag-and-drop module placement loop ([TASK-025](file:///c:/Users/josep/Desktop/Coding%20Projects/goblin-cannon/docs/tasks/TASK-025-polyomino-drag-drop-and-grid-snapping.md)), live board ghost placement ([TASK-020](file:///c:/Users/josep/Desktop/Coding%20Projects/goblin-cannon/docs/tasks/TASK-020-live-board-ghost-placement.md)), module fusion/crafting ([TASK-018](file:///c:/Users/josep/Desktop/Coding%20Projects/goblin-cannon/docs/tasks/TASK-018-tetromino-module-crafting-and-fusion.md)), and reward drafting.

---

## Requirements

### 1. Endless-Capacity Scrollable Grid Storage
- Implement a scrollable 2D grid/tray storage container with **unconstrained / endless capacity** (e.g. continuous vertical scrolling as modules are collected).
- Support storing multi-cell polyomino relics (Tiers 1–3 from [TASK-024](file:///c:/Users/josep/Desktop/Coding%20Projects/goblin-cannon/docs/tasks/TASK-024-polyomino-relic-shapes-and-sizes.md)) and $1 \times 1$ components/pegs without artificial slot limits.
- Smooth mouse wheel scrolling and scrollbar dragging for navigating through the stored collection.
- Support 90-degree item rotation (`R` key or RMB) directly within the backpack inventory.
- Enforce bounds checking and collision prevention within the grid so items do not overlap.

### 2. Seamless Drag-and-Drop & Board Transfer
- Allow fluid dragging of modules between the Junk Box and the active pegboard:
  - Dragging from Junk Box to the pegboard transitions the module into board placement/ghost state.
  - Dragging a module from the pegboard back into the Junk Box frees the occupied board cells and stashes the item back into the bag.
- Provide responsive hotkeys (`B` / `I`) and a HUD bag/toolbox button to toggle the Junk Box tray overlay during combat or draft phases.
- Support auto-scrolling when dragging an item near the top or bottom edges of the inventory container.

### 3. UI Presentation & Comic Aesthetics
- Visual framing styled as a goblin tinkerer's cluttered, overflowing backpack/toolbox with leather straps, brass rivets, gears, and thick comic inking.
- Rich hover tooltips displaying module dimensions, kinetic components (bumpers, accelerators, funnels), durability stats, and synergy tags.
- Tactile audio feedback for bag zipper/latches opening, module pickups, rotation snaps, and placement drops.

### 4. Data Model & State Persistence
- Integrate with `GameState` and `InventoryData` to persist held items, positions, scroll state, and rotation states across combat waves, wall breaks, scene transitions, and save/load cycles.

---

## Acceptance Criteria

- [x] Junk Box grid supports endless capacity with smooth vertical mouse wheel and scrollbar navigation.
- [x] Drag-and-drop between the Junk Box and live pegboard transfers ownership smoothly without duplicate instances or coordinate drift.
- [x] Polyomino modules of all tiers (Tiers 1–3 and 1×1 pegs) rotate 90 degrees cleanly and enforce collision prevention in the bag grid.
- [x] Auto-scrolling functions properly when dragging items near the inventory view edges.
- [x] UI panel opens, closes, and renders cleanly with comic styling, tooltips, and tactile audio feedback.
- [x] Headless unit tests verify endless grid insertion, boundary math, rotation transformations, collision prevention, and `GameState` serialization.
