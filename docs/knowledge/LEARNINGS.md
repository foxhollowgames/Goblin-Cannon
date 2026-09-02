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
| [`LRN-026`](#lrn-026) | TASK-LINT-01 | `tooling` | File Length Limit (500 lines) and Baseline Allowlist | 2026-08-29 |
| [`LRN-027`](#lrn-027) | TASK-024 | `board_systems` | Polyomino Relic Footprint Scaling and Empty Playfield Spacing | 2026-08-29 |
| [`LRN-028`](#lrn-028) | TASK-033 | `board_systems` | Polyomino Relic Exterior Perimeter Wall and Transparent Chassis Drawing | 2026-08-29 |
| [`LRN-029`](#lrn-029) | TASK-049 | `godot_engine` | Polyomino Relic Pinball Goals and Reward Dispatching | 2026-08-29 |
| [`LRN-030`](#lrn-030) | TASK-DIRECTORY-01 | `tooling` | AI Codebase Directory and Automated Quality Tooling | 2026-08-31 |
| [`LRN-031`](#lrn-031) | TASK-BOARD-DECOMP-01 | `godot_engine` | Board Scene Sub-Manager Decomposition and VFX Pooling Lifecycle | 2026-08-31 |
| [`LRN-032`](#lrn-032) | TASK-COORD-DECOMP-01 | `godot_engine` | GameCoordinator Sub-Manager Decomposition | 2026-09-01 |
| [`LRN-033`](#lrn-033) | TASK-PEG-DECOMP-01 | `godot_engine` | Peg Drawing Static Class Extraction | 2026-09-01 |
| [`LRN-034`](#lrn-034) | TASK-REWARD-DRAFT-01 | `godot_engine` | RewardDraftPanel UI Component Extraction via Ollama | 2026-09-01 |
| [`LRN-035`](#lrn-035) | TASK-COORD-UI-01 | `godot_engine` | GameCoordinator UI Sub-Manager Extraction | 2026-09-01 |
| [`LRN-036`](#lrn-036) | TASK-COORD-DECOMP-02 | `godot_engine` | GameCoordinator Full Sub-Manager Refactoring | 2026-09-01 |
| [`LRN-037`](#lrn-037) | Decompose large source files | `Architecture` | game_coordinator_decomposition | 2026-09-01 |
| [`LRN-038`](#lrn-038) | FIX-SHOP-ICONS | `godot_engine` | Shop card VBox attachment and marker script path | 2026-09-01 |
| [`LRN-039`](#lrn-039) | TASK-033 | `physics` | polyomino relic enclosures | 2026-09-01 |
| [`LRN-040`](#lrn-040) | FIX-POLYOMINO-PARSER | `godot_engine` | GDScript Void Return Parse Errors | 2026-09-01 |
| [`LRN-041`](#lrn-041) | TASK-TEST-FRAMEWORK-PARSE-ISOLATION | `testing` | Godot Test Runner Parse Failure Isolation | 2026-09-01 |

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

### <a id="lrn-026"></a> LRN-026: File Length Limit (500 lines) and Baseline Allowlist
- **Task:** `TASK-LINT-01`
- **Category:** `tooling`
- **Created:** `2026-08-29T18:21:15.131579`

#### Context & Problem
Files were growing too large without an automated check, requiring an audit and lint rule.

#### Key Insight & Learning
A Python lint tool and a Godot headless test ensure all new files stay under 500 lines while pinning legacy files to baseline limits.

#### Actionable Guideline for Future Agents
Run python scripts/lint_file_lengths.py or headless tests to audit file lengths before merging.

---

### <a id="lrn-027"></a> LRN-027: Polyomino Relic Footprint Scaling and Empty Playfield Spacing
- **Task:** `TASK-024`
- **Category:** `board_systems`
- **Created:** `2026-08-29T19:45:10.095441`

#### Context & Problem
Relics felt too small and crowded with machinery on every cell, allowing full inventories on the board without strategic layout compromises.

#### Key Insight & Learning
Differentiating CellType.EMPTY from active kinetic machinery allows multi-cell relics to occupy realistic pinball widget footprints where balls travel through open corridors between bumpers and gates.

#### Actionable Guideline for Future Agents
Always reserve full multi-cell footprints on the board grid while skipping machinery instantiation and glyph drawing for CellType.EMPTY cells.

---

### <a id="lrn-028"></a> LRN-028: Polyomino Relic Exterior Perimeter Wall and Transparent Chassis Drawing
- **Task:** `TASK-033`
- **Category:** `board_systems`
- **Created:** `2026-08-29T19:48:36.236273`

#### Context & Problem
Internal connection struts between adjacent cell centers created a wireframe lattice that doubled back and cluttered empty playfield spaces.

#### Key Insight & Learning
Checking 4-way cardinal neighbor presence in the module cell set allows drawing walls strictly on exterior boundaries, while drawing a unified translucent fill provides seamless open chambers.

#### Actionable Guideline for Future Agents
Never draw connection lines between adjacent cell centers; iterate over module cells and draw wall segments only on edges without an adjacent neighbor in the module.

---

### <a id="lrn-029"></a> LRN-029: Polyomino Relic Pinball Goals and Reward Dispatching
- **Task:** `TASK-049`
- **Category:** `godot_engine`
- **Created:** `2026-08-29T23:07:06.524921`

#### Context & Problem
Relics need self-contained pinball objectives and board rewards without bloating board.gd line limits.

#### Key Insight & Learning
PolyominoModuleNode tracks cell hits and progress counters locally while delegating reward execution to PolyominoGoalRewardHandler, keeping Board.gd well under line limits.

#### Actionable Guideline for Future Agents
Keep Board.gd lean by delegating specialized mechanic triggers to standalone handlers and use PolyominoModuleNode runtime state for compound shape tracking.

---

### <a id="lrn-030"></a> LRN-030: AI Codebase Directory and Automated Quality Tooling
- **Task:** `TASK-DIRECTORY-01`
- **Category:** `tooling`
- **Created:** `2026-08-31T21:44:23.298306`

#### Context & Problem
AI agents needed a single reference for repo file locations, signal wiring, and GDScript standards without doing expensive grep passes.

#### Key Insight & Learning
Generating docs/DIRECTORY.md via python scripts/generate_directory.py and verifying freshness in python scripts/lint_gdscript.py keeps AI navigation accurate and prevents drift.

#### Actionable Guideline for Future Agents
Run python scripts/generate_directory.py whenever creating, renaming, or refactoring files, and run python scripts/lint_gdscript.py before opening PRs.

---

### <a id="lrn-031"></a> LRN-031: Board Scene Sub-Manager Decomposition and VFX Pooling Lifecycle
- **Task:** `TASK-BOARD-DECOMP-01`
- **Category:** `godot_engine`
- **Created:** `2026-08-31T22:22:05.866330`

#### Context & Problem
Extracting large script responsibilities into modular sub-managers requires strict pooling lifecycle management and explicit scene setup API calls.

#### Key Insight & Learning
When preallocating UI nodes or VFX objects in sub-managers, call set_process(false), bind set_pool_release(release_cb), and reset modulate/transform on release and reuse to prevent auto-destruction and color contamination.

#### Actionable Guideline for Future Agents
Always wire object pool release callbacks during preallocation in sub-managers and reset instance properties in get_from_pool.

---

### <a id="lrn-032"></a> LRN-032: GameCoordinator Sub-Manager Decomposition
- **Task:** `TASK-COORD-DECOMP-01`
- **Category:** `godot_engine`
- **Created:** `2026-09-01T08:38:03.790138`

#### Context & Problem
Extracting coordinator responsibilities into debug, ball manager, and flow controller sub-managers.

#### Key Insight & Learning
Sub-manager scripts that do not render 2D content must extend Node not Node2D. Always verify callback method names match the actual parent script signatures before wiring delegation calls.

#### Actionable Guideline for Future Agents
Use find_child for dynamically-instantiated modal lookups instead of fixed node paths.

---

### <a id="lrn-033"></a> LRN-033: Peg Drawing Static Class Extraction
- **Task:** `TASK-PEG-DECOMP-01`
- **Category:** `godot_engine`
- **Created:** `2026-09-01T08:43:36.541289`

#### Context & Problem
Peg drawing methods run on the same CanvasItem and cannot move to a child Node.

#### Key Insight & Learning
Use static RefCounted classes (PegKindDrawing, PegDrawing) that accept the CanvasItem as a parameter to extract draw routines without breaking the Godot _draw() lifecycle.

#### Actionable Guideline for Future Agents
For CanvasItem draw extraction, prefer static utility classes that accept ci: CanvasItem rather than composition nodes.

---

### <a id="lrn-034"></a> LRN-034: RewardDraftPanel UI Component Extraction via Ollama
- **Task:** `TASK-REWARD-DRAFT-01`
- **Category:** `godot_engine`
- **Created:** `2026-09-01T15:28:08.377561`

#### Context & Problem
Extracting UI component markers and static card builders from RewardDraftPanel.

#### Key Insight & Learning
Dynamic script loading (load()) for static helper classes prevents class_name symbol resolution cache errors during headless unit test execution.

#### Actionable Guideline for Future Agents
Use dynamic script loading for extracted RefCounted UI builders to ensure zero symbol cache conflicts.

---

### <a id="lrn-035"></a> LRN-035: GameCoordinator UI Sub-Manager Extraction
- **Task:** `TASK-COORD-UI-01`
- **Category:** `godot_engine`
- **Created:** `2026-09-01T15:47:13.912272`

#### Context & Problem
Extracting UI creation and modal toggle methods from GameCoordinator.

#### Key Insight & Learning
GameCoordinator UI sub-managers reduce coordinator responsibilities by delegating modal toggles and UI creation callbacks.

#### Actionable Guideline for Future Agents
Keep UI creation and modal management logic in GameCoordinatorUI.

---

### <a id="lrn-036"></a> LRN-036: GameCoordinator Full Sub-Manager Refactoring
- **Task:** `TASK-COORD-DECOMP-02`
- **Category:** `godot_engine`
- **Created:** `2026-09-01T16:00:49.081229`

#### Context & Problem
Decomposing GameCoordinator into modular sub-managers.

#### Key Insight & Learning
GameCoordinator can delegate UI, screen building, input, signals, test scenarios, and ball inventory to sub-managers to achieve full modularity.

#### Actionable Guideline for Future Agents
Keep sub-manager responsibilities tightly scoped to maintain source files under 500 lines.

---

### <a id="lrn-037"></a> LRN-037: game_coordinator_decomposition
- **Task:** `Decompose large source files`
- **Category:** `Architecture`
- **Created:** `2026-09-01T16:18:09.032806`

#### Context & Problem
All repository source files required to be under 500 lines

#### Key Insight & Learning
Decomposed GameCoordinator, RewardHandler, and RewardDraftPanel into modular static helpers and sub-managers

#### Actionable Guideline for Future Agents
Keep source files under 500 lines by delegating specialized sub-tasks to dedicated helper classes

---

### <a id="lrn-038"></a> LRN-038: Shop card VBox attachment and marker script path
- **Task:** `FIX-SHOP-ICONS`
- **Category:** `godot_engine`
- **Created:** `2026-09-01T18:45:19.156318`

#### Context & Problem
Shop cards displayed empty frames without title, icon, or description rendering

#### Key Insight & Learning
RewardCardBuilder.make_shop_card_layer omitted layer.add_child(card_vbox), leaving card_vbox un-parented in the scene tree

#### Actionable Guideline for Future Agents
Always ensure container layout builder functions attach created child VBoxContainer nodes to their parent layer before returning.

---

### <a id="lrn-039"></a> LRN-039: polyomino relic enclosures
- **Task:** `TASK-033`
- **Category:** `physics`
- **Created:** `2026-09-01T22:06:22.817285`

#### Context & Problem
Implementing wall enclosures and funnel collision

#### Key Insight & Learning
Polyomino module wall enclosures generate cell boundary edge line segments rotated via posmod steps.

#### Actionable Guideline for Future Agents
Use get_solid_edge_segments to calculate edge colliders for polyomino enclosures.

---

### <a id="lrn-040"></a> LRN-040: GDScript Void Return Parse Errors
- **Task:** `FIX-POLYOMINO-PARSER`
- **Category:** `godot_engine`
- **Created:** `2026-09-01T22:07:23.753398`

#### Context & Problem
A void return function returning a value in GDScript causes a parse error that breaks preloaded scripts across the engine.

#### Key Insight & Learning
Functions returning void must return cleanly without returning values.

#### Actionable Guideline for Future Agents
Check that functions returning void do not return expressions, especially when modifying array parameters by reference.

---

### <a id="lrn-041"></a> LRN-041: Godot Test Runner Parse Failure Isolation
- **Task:** `TASK-TEST-FRAMEWORK-PARSE-ISOLATION`
- **Category:** `testing`
- **Created:** `2026-09-01T22:23:52.871539`

#### Context & Problem
Top-level static preloads in test runner files cause full test suite compilation failures when preloaded scripts have syntax errors.

#### Key Insight & Learning
Dynamic script loading via load() inside test runner methods isolates script parse failures and prevents whole suite blockages.

#### Actionable Guideline for Future Agents
Always load test dependencies dynamically inside test methods and include a headless script parse smoke pass in linter tooling.

---
