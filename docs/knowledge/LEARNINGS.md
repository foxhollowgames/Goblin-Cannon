# Goblin Cannon — Agent Knowledge Base & Learnings

This canonical knowledge base stores lessons, patterns, and optimization rules learned by agents during task execution.
**All agents must review this document or query `python scripts/learnings.py query <topic>` before starting complex tasks.**

---

## Quick Index

| ID | Task | Category | Topic | Created |
| :--- | :--- | :--- | :--- | :--- |
| [`LRN-001`](#lrn-001) | TASK-027 | `godot_engine` | Headless Preload & Circular Class References | 2026-08-28 |
| [`LRN-002`](#lrn-002) | TASK-027 | `subagents` | Sub-Agent Immediate Lifecycle Teardown | 2026-08-28 |
| [`LRN-003`](#lrn-003) | TASK-027 | `worktrees` | Windows Binary DLL Lock Handling During Worktree Cleanup | 2026-08-28 |
| [`LRN-004`](#lrn-004) | TASK-027 | `optimization` | Model Tier Allocation for Fast and Cheap Execution | 2026-08-28 |
| [`LRN-005`](#lrn-005) | TASK-024 | `godot_engine` | Multi-Cell Polyomino Coordinate Anchoring & Clockwise Rotation | 2026-08-28 |
| [`LRN-006`](#lrn-006) | TASK-025 | `godot_engine` | Headless Viewport & Mouse Position Safety | 2026-08-28 |
| [`LRN-007`](#lrn-007) | TASK-019 | `controls` | Hopper Steering and Keybind Separation | 2026-08-28 |
| [`LRN-008`](#lrn-008) | TASK-026 | `godot_engine` | Headless Node Hierarchy and Lazy Container Initialization | 2026-08-28 |
| [`LRN-009`](#lrn-009) | TASK-020 | `godot_engine` | Live Board Ghost Placement Area Monitoring & Collision Transition | 2026-08-28 |
| [`LRN-010`](#lrn-010) | TASK-028 | `ui` | Non-Modal Side Drawers for Dual-Surface Drag-and-Drop | 2026-08-28 |
| [`LRN-011`](#lrn-011) | TASK-028 | `tooling` | Windows GUI Godot Binary Console Redirection | 2026-08-28 |
| [`LRN-012`](#lrn-012) | TASK-024 | `godot_engine` | Polyomino Relic Database & ID Alias Mapping | 2026-08-28 |
| [`LRN-013`](#lrn-013) | TASK-028 | `godot_engine` | Slotted Board Relic Modifiers & Instant Hover Tooltips | 2026-08-29 |
| [`LRN-014`](#lrn-014) | TASK-029 | `board_systems` | Unified Board Grid and Relic Mutual Exclusivity Architecture | 2026-08-29 |
| [`LRN-015`](#lrn-015) | TASK-032 | `audio_and_mechanics` | Relic Audio Attenuation and Boundary Wall Physics Architecture | 2026-08-29 |
| [`LRN-016`](#lrn-016) | TASK-029 | `board_systems` | Rectangular Pegboard Layout and Polyomino Grid Alignment | 2026-08-29 |
| [`LRN-017`](#lrn-017) | TASK-029 | `board_systems` | Staggered Checkerboard Peg Lattice on Discrete Rectangular Grid | 2026-08-29 |
| [`LRN-018`](#lrn-018) | TASK-033 | `subagents` | Open-Model Subagent Allocation & Test State Isolation | 2026-08-29 |
| [`LRN-019`](#lrn-019) | TASK-032 | `audio_and_mechanics` | Relic Machinery Audio Attenuation and Concurrency Throttling | 2026-08-29 |
| [`LRN-020`](#lrn-020) | TASK-034 | `tooling` | Zero-Dependency Local Ollama Code Generation CLI | 2026-08-29 |
| [`LRN-021`](#lrn-021) | TASK-035 | `ui_and_rewards` | Relic Selection Screen Layout and Machinery Composition Preview Specification | 2026-08-29 |
| [`LRN-022`](#lrn-022) | TASK-035 | `ui` | Normalized Polyomino Relic Layout and Kinetic Machinery Preview | 2026-08-29 |
| [`LRN-023`](#lrn-023) | TASK-031 | `ui_and_controls` | Dynamic Grab Offset Preservation on Polyomino Relic In-Flight Rotation | 2026-08-29 |
| [`LRN-024`](#lrn-024) | TASK-031 | `godot_engine` | Drag Controller Overlay Hierarchy and Control Mouse Filter Pass-Through | 2026-08-29 |
| [`LRN-025`](#lrn-025) | TASK-031 | `board_systems` | Baseline Peg Suppression and Restoration Under Movable Polyomino Relics | 2026-08-29 |

---

## Detailed Learnings

### <a id="lrn-001"></a> LRN-001: Headless Preload & Circular Class References
- **Task:** `TASK-027`
- **Category:** `godot_engine`
- **Created:** `2026-08-28T19:53:34.239466`

#### Context & Problem
In Godot 4 headless mode, classes with static factory methods or autoloads that reference class_name types directly can fail to compile due to circular dependency or load order issues.

#### Key Insight & Learning
Godot headless script compilation parses classes before all global class_name symbols are resolved in the cache. Static methods returning self-types or autoloads with typed properties can throw cyclic load or undefined type errors.

#### Actionable Guideline for Future Agents
Use explicit 'const MyType = preload(...)' in autoloads and UI panels when referring to custom resources. In static factory methods (e.g. from_dict), return base Resource or untyped value to avoid circular self-references.

---

### <a id="lrn-002"></a> LRN-002: Sub-Agent Immediate Lifecycle Teardown
- **Task:** `TASK-027`
- **Category:** `subagents`
- **Created:** `2026-08-28T19:53:36.789089`

#### Context & Problem
Sub-agents spawned via invoke_subagent stay in 'idle' or 'waiting_for_dependents' state after finishing their work, waiting for potential follow-up messages.

#### Key Insight & Learning
Sub-agents do not self-destruct by default. If the orchestrator does not explicitly kill them, they consume agent slots and may appear hung to users.

#### Actionable Guideline for Future Agents
Always call manage_subagents(Action='kill_all') or kill specific conversation IDs immediately after receiving and verifying sub-agent deliverables.

---

### <a id="lrn-003"></a> LRN-003: Windows Binary DLL Lock Handling During Worktree Cleanup
- **Task:** `TASK-027`
- **Category:** `worktrees`
- **Created:** `2026-08-28T19:53:39.507669`

#### Context & Problem
When Godot runs tests inside a git worktree on Windows, binary plugins (e.g. libgodot_rapier.dll) may remain locked briefly by the OS process, preventing immediate folder deletion.

#### Key Insight & Learning
Worktree removal can fail with 'Access is denied' or 'Resource busy' if child processes held file handles. The git metadata unlinks cleanly, but the physical folder might have lingering locks.

#### Actionable Guideline for Future Agents
Use 'git worktree prune' to clean up git metadata after worktree operations. If physical directory deletion is locked, allow background handles to close or prune git references first.

---

### <a id="lrn-004"></a> LRN-004: Model Tier Allocation for Fast and Cheap Execution
- **Task:** `TASK-027`
- **Category:** `optimization`
- **Created:** `2026-08-28T19:53:41.939404`

#### Context & Problem
Delegating all tasks to heavy reasoning models increases latency and token costs significantly, while light models may struggle with complex UI layout/drawing logic.

#### Key Insight & Learning
Data models, serialization, and test writing are deterministic and execute rapidly on 'flash' models. Intricate custom UI rendering, drag-and-drop controllers, and math-heavy physics logic succeed best on 'pro' models.

#### Actionable Guideline for Future Agents
Partition tasks into (1) Data/Model layer -> flash, (2) UI/Input/Visuals -> pro, (3) Testing/QA -> flash, (4) Integration/Review -> pro for maximum speed and cost efficiency.

---

### <a id="lrn-005"></a> LRN-005: Multi-Cell Polyomino Coordinate Anchoring & Clockwise Rotation
- **Task:** `TASK-024`
- **Category:** `godot_engine`
- **Created:** `2026-08-28T19:53:44.532082`

#### Context & Problem
Rotating 2D grid polyominoes (rx = -y, ry = x) can produce negative local coordinate offsets, which break standard grid slot indexing (0..N-1).

#### Key Insight & Learning
Standard mathematical 2D rotation around origin maps positive coordinates to negative ones (e.g. (1, 0) rotated 90° CW -> (0, -1) in Godot's Y-down coordinate space, or (0, 1) -> (-1, 0)).

#### Actionable Guideline for Future Agents
Always apply bounding-box offset normalization after rotating: compute min_x and min_y of the rotated cell set, then subtract them (rx - min_x, ry - min_y) so the top-left-most cell is strictly anchored at (0, 0).

---

### <a id="lrn-006"></a> LRN-006: Headless Viewport & Mouse Position Safety
- **Task:** `TASK-025`
- **Category:** `godot_engine`
- **Created:** `2026-08-28T20:04:48.934574`

#### Context & Problem
Calling get_global_mouse_position() on Controls outside the active SceneTree/Viewport causes engine error spam during headless testing.

#### Key Insight & Learning
Controls instantiated directly in headless tests or before add_child() lack a viewport reference, causing get_global_mouse_position() to fail.

#### Actionable Guideline for Future Agents
Always wrap mouse position lookups with a safe helper like 'if is_inside_tree() and get_viewport(): return get_global_mouse_position()' with Vector2.ZERO fallback.

---

### <a id="lrn-007"></a> LRN-007: Hopper Steering and Keybind Separation
- **Task:** `TASK-019`
- **Category:** `controls`
- **Created:** `2026-08-28T21:42:17.515992`

#### Context & Problem
A and D keys were previously intercepted by debug overlay and almanac keybinds in GameCoordinator and Hopper only followed mouse position.

#### Key Insight & Learning
Game controls must not conflict with debug hotkeys. Moving debug toggles to function keys (F3) and letter keys away from WASD ensures unhindered player steering.

#### Actionable Guideline for Future Agents
Reserve WASD and Arrow keys exclusively for player-controlled motion. Use function keys (F1-F12) or modifier combinations for debug tools.

---

### <a id="lrn-008"></a> LRN-008: Headless Node Hierarchy and Lazy Container Initialization
- **Task:** `TASK-026`
- **Category:** `godot_engine`
- **Created:** `2026-08-28T21:47:28.496565`

#### Context & Problem
Standalone nodes instantiated in unit tests without add_child or _ready lack viewport and parent transforms, and child containers initialized in _ready remain null.

#### Key Insight & Learning
In Godot 4 headless tests, nodes created with .new do not run _ready automatically. Container nodes like _modules_container must be lazily initialized when used, and component positions must fall back to local position math when is_inside_tree is false.

#### Actionable Guideline for Future Agents
Lazily initialize child containers on first access in manager and board scripts, and check is_inside_tree before querying global_position to support headless unit tests.

---

### <a id="lrn-009"></a> LRN-009: Live Board Ghost Placement Area Monitoring & Collision Transition
- **Task:** `TASK-020`
- **Category:** `godot_engine`
- **Created:** `2026-08-28T21:58:52.513594`

#### Context & Problem
Placing and moving components during live Plinko ball simulation requires safe non-colliding ghost states to prevent trapping or teleporting balls.

#### Key Insight & Learning
Newly positioned components must start at 50% opacity with collision_layer set to 0. Area monitoring with bounding box margin checks (cell_rect.grow(BALL_RADIUS + 2.0)) allows seamless transition to solid state once all balls exit.

#### Actionable Guideline for Future Agents
Always disable physics collision layers on newly placed components until active ball area checks confirm complete clearance.

---

### <a id="lrn-010"></a> LRN-010: Non-Modal Side Drawers for Dual-Surface Drag-and-Drop
- **Task:** `TASK-028`
- **Category:** `ui`
- **Created:** `2026-08-28T22:10:21.434500`

#### Context & Problem
When implementing inventory containers that transfer items to the board, centered modals obscure the board and intercept mouse clicks.

#### Key Insight & Learning
Using a right-anchored drawer panel with root mouse_filter set to IGNORE keeps the board interactive and visible. Explicitly excluding the drawer panel rect in board coordinate checks prevents false-positive edge drops.

#### Actionable Guideline for Future Agents
Always structure dual-surface drag inventories as docked side drawers with transparent root input filtering.

---

### <a id="lrn-011"></a> LRN-011: Windows GUI Godot Binary Console Redirection
- **Task:** `TASK-028`
- **Category:** `tooling`
- **Created:** `2026-08-28T22:12:30.338547`

#### Context & Problem
On Windows, running Godot GUI binary directly in PowerShell with ampersand does not pipe stdout, masking GDScript parse errors.

#### Key Insight & Learning
Executing Godot headless commands through cmd.exe /c attaches standard I/O streams and reveals all compilation errors and test suite logs.

#### Actionable Guideline for Future Agents
Always run headless Godot tests via cmd.exe /c on Windows to prevent silent test failures.

---

### <a id="lrn-012"></a> LRN-012: Polyomino Relic Database & ID Alias Mapping
- **Task:** `TASK-024`
- **Category:** `godot_engine`
- **Created:** `2026-08-28T22:19:51.267579`

#### Context & Problem
Relics have multiple upgrade categories across boss amplifiers, cross-link wall breaks, single-type enhancements, and chest passives, with minor ID spelling discrepancies in legacy code (e.g. arc_surge_wrench vs chain_surge_wrench).

#### Key Insight & Learning
Using a centralized PolyominoRelicDatabase registry with canonical definitions and an ID alias resolution table ensures both legacy upgrade names and spec-compliant relic IDs resolve cleanly to the correct PolyominoModuleData and JunkBoxItem instances.

#### Actionable Guideline for Future Agents
Always route polyomino module creation through PolyominoRelicDatabase with alias resolution to ensure backwards compatibility across reward handlers, catalogs, and inventory systems.

---

### <a id="lrn-013"></a> LRN-013: Slotted Board Relic Modifiers & Instant Hover Tooltips
- **Task:** `TASK-028`
- **Category:** `godot_engine`
- **Created:** `2026-08-29T07:52:50.756837`

#### Context & Problem
Relic passive effects must not activate immediately upon drafting into the inventory; they must apply only when the module is slotted on the active board grid, deactivate cleanly on unslot, and show instant tooltips on mouse hover.

#### Key Insight & Learning
Binding GameState relic modifier application and reversion directly to Board.place_module() and Board.unslot_module() guarantees state consistency, while KeywordDatabase.show_flyout_custom() provides instant, boundary-clamped hover tooltips for placed board modules.

#### Actionable Guideline for Future Agents
Always tie passive stat buffs and relic modifier lifecycles to physical board placement rather than inventory possession, and use KeywordDatabase for consistent in-game flyout tooltips.

---

### <a id="lrn-014"></a> LRN-014: Unified Board Grid and Relic Mutual Exclusivity Architecture
- **Task:** `TASK-029`
- **Category:** `board_systems`
- **Created:** `2026-08-29T08:06:28.192880`

#### Context & Problem
Defining requirements for aligning the pegboard layout to the polyomino grid and replacing occupied pegs upon relic drop.

#### Key Insight & Learning
A shared orthogonal coordinate system simplifies mutual exclusivity checks and drag-and-drop collision detection between pegs and relics.

#### Actionable Guideline for Future Agents
Always align board peg positions to the same grid cell dimensions and coordinate functions as polyomino relics.

---

### <a id="lrn-015"></a> LRN-015: Relic Audio Attenuation and Boundary Wall Physics Architecture
- **Task:** `TASK-032`
- **Category:** `audio_and_mechanics`
- **Created:** `2026-08-29T08:18:05.426562`

#### Context & Problem
Defining requirements for reducing loud sound playback on kinetic components and adding perimeter boundary walls with internal lane dividers to polyomino relics.

#### Key Insight & Learning
Kinetic polyomino machinery produces rapid audio triggers during high ball volume, requiring dedicated bus attenuation and edge collision segment specifications.

#### Actionable Guideline for Future Agents
Always route machinery audio to dedicated sub-buses with volume limits, and define perimeter walls and internal dividers as explicit edge segment shapes.

---

### <a id="lrn-016"></a> LRN-016: Rectangular Pegboard Layout and Polyomino Grid Alignment
- **Task:** `TASK-029`
- **Category:** `board_systems`
- **Created:** `2026-08-29T09:16:01.625823`

#### Context & Problem
Standard pegboards historically used staggered odd-row offsets and checkerboard gaps, creating mismatch with polyomino relics.

#### Key Insight & Learning
Eliminating row offsets and placing pegs on the unified 16x8 rectangular board grid unifies coordinate conversions across pegs and polyomino tiles.

#### Actionable Guideline for Future Agents
Always position board pegs and polyomino modules on the canonical 16x8 board grid using board_cell_to_world and world_to_board_cell.

---

### <a id="lrn-017"></a> LRN-017: Staggered Checkerboard Peg Lattice on Discrete Rectangular Grid
- **Task:** `TASK-029`
- **Category:** `board_systems`
- **Created:** `2026-08-29T09:20:53.739643`

#### Context & Problem
A dense peg layout places pegs at every grid point, which reduces ball deflection randomness and prevents open spaces.

#### Key Insight & Learning
Gating peg generation by (row + col) % 2 == 0 creates an alternating plinko lattice with 50% empty spots on the same unified 16x8 grid.

#### Actionable Guideline for Future Agents
Use checkerboard gating (row + col) % 2 == 0 on discrete grid coordinates to achieve staggered layout without floating-point row offsets.

---

### <a id="lrn-018"></a> LRN-018: Open-Model Subagent Allocation & Test State Isolation
- **Task:** `TASK-033`
- **Category:** `subagents`
- **Created:** `2026-08-29T09:23:36.894900`

#### Context & Problem
Dispatching subagents with open-source coding models requires explicit role definitions and test clean state isolation.

#### Key Insight & Learning
Qwen3 Coder and GLM 5.2 provide high accuracy for Godot 4 GDScript, and tests must explicitly clear GameState before board instantiations to prevent state leaks.

#### Actionable Guideline for Future Agents
Define specialized subagents with clear Godot 4 constraints and call _ensure_clean_state() in test functions that instantiate Board.

---

### <a id="lrn-019"></a> LRN-019: Relic Machinery Audio Attenuation and Concurrency Throttling
- **Task:** `TASK-032`
- **Category:** `audio_and_mechanics`
- **Created:** `2026-08-29T09:42:05.941172`

#### Context & Problem
Kinetic polyomino machinery caused rapid audio triggers and harsh volume spikes during multi-ball collisions.

#### Key Insight & Learning
Setting default component volume to -16 dB, routing to a dedicated Machinery bus, applying slight pitch modulation [0.95, 1.05], and throttling duplicate triggers within 50ms produces clean acoustic mixing.

#### Actionable Guideline for Future Agents
Always route kinetic machinery audio through dedicated sub-buses with decibel levels below -12 dB, apply pitch variation, and enforce timestamp-based concurrency throttling.

---

### <a id="lrn-020"></a> LRN-020: Zero-Dependency Local Ollama Code Generation CLI
- **Task:** `TASK-034`
- **Category:** `tooling`
- **Created:** `2026-08-29T10:42:56.937507`

#### Context & Problem
Connecting Antigravity to local Qwen 2.5 Coder for offline zero-cost code generation.

#### Key Insight & Learning
Using a standalone standard-library Python CLI script (urllib) avoids external dependencies and enables Antigravity to generate, edit, and test GDScript through local Ollama.

#### Actionable Guideline for Future Agents
Use python scripts/ollama_coder.py [generate|edit|test] to produce GDScript with local Qwen at zero cost.

---

### <a id="lrn-021"></a> LRN-021: Relic Selection Screen Layout and Machinery Composition Preview Specification
- **Task:** `TASK-035`
- **Category:** `ui_and_rewards`
- **Created:** `2026-08-29T11:14:36.424883`

#### Context & Problem
The relic selection screen in major_upgrade_draft_panel needed a visual representation of polyomino relic shapes and machine parts directly underneath the title.

#### Key Insight & Learning
Draft reward cards require compact normalized 2D polyomino shape rendering and distinct machine component glyphs so players see module geometry before drafting.

#### Actionable Guideline for Future Agents
When designing relic reward draft cards, inspect PolyominoRelicDatabase and render multi-cell shapes and component glyphs directly below the card title.

---

### <a id="lrn-022"></a> LRN-022: Normalized Polyomino Relic Layout and Kinetic Machinery Preview
- **Task:** `TASK-035`
- **Category:** `ui`
- **Created:** `2026-08-29T11:34:02.105508`

#### Context & Problem
Relic draft cards required visual multi-cell footprint rendering and kinetic machinery glyphs below the title.

#### Key Insight & Learning
Calculating min and max bounding coordinates centers irregular polyomino shapes cleanly in compact preview controls.

#### Actionable Guideline for Future Agents
Always normalize local cell coordinates and center polyomino bounds horizontally and vertically in UI reward cards.

---

### <a id="lrn-023"></a> LRN-023: Dynamic Grab Offset Preservation on Polyomino Relic In-Flight Rotation
- **Task:** `TASK-031`
- **Category:** `ui_and_controls`
- **Created:** `2026-08-29T13:03:46.937896`

#### Context & Problem
When dragging multi-cell polyomino relics on the board, 90-degree rotations change the local cell offsets of the shape relative to the top-left anchor.

#### Key Insight & Learning
Storing the grabbed cell index and querying the anchored rotated shape at that index keeps the exact grabbed cell pinned to the cursor during in-flight rotation.

#### Actionable Guideline for Future Agents
Always track the grabbed cell index during drag initiation and dynamically compute the rotated cell offset using get_anchored_rotated_cells.

---

### <a id="lrn-024"></a> LRN-024: Drag Controller Overlay Hierarchy and Control Mouse Filter Pass-Through
- **Task:** `TASK-031`
- **Category:** `godot_engine`
- **Created:** `2026-08-29T17:19:00.222062`

#### Context & Problem
When initiating dragging from board Node2D elements, parent container Controls with default mouse_filter MOUSE_FILTER_STOP swallow clicks, and children of hidden UI panels hide visual ghost previews.

#### Key Insight & Learning
Setting mouse_filter to MOUSE_FILTER_IGNORE on layout containers allows clicks through to _input handlers. Parenting drag controllers directly to the top-level CanvasLayer keeps ghost preview overlays visible even when sibling drawer panels are closed.

#### Actionable Guideline for Future Agents
Always set mouse_filter to IGNORE on full-screen container controls and mount global drag preview controllers on top-level CanvasLayers.

---

### <a id="lrn-025"></a> LRN-025: Baseline Peg Suppression and Restoration Under Movable Polyomino Relics
- **Task:** `TASK-031`
- **Category:** `board_systems`
- **Created:** `2026-08-29T17:33:31.002706`

#### Context & Problem
Permanently freeing pegs covered by a polyomino relic causes the board to permanently lose pegs whenever relics are moved or rearranged.

#### Key Insight & Learning
Suppressing pegs (disabling collision, hiding visibility, pausing process) rather than freeing them allows pristine restoration of the baseline board layout when relics are moved or unslotted.

#### Actionable Guideline for Future Agents
Never permanently free baseline board elements under temporary or repositionable overlays; track and suppress them, then unsuppress on removal.

---
