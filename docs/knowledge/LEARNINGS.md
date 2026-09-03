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
| [`LRN-042`](#lrn-042) | TASK-021 | `gameplay` | Wall Siege Timer and Defender Pushback Logic | 2026-09-01 |
| [`LRN-043`](#lrn-043) | TASK-022 | `balance` | Exponential Wall HP and Gold Scaling Model | 2026-09-01 |
| [`LRN-044`](#lrn-044) | TASK-036 | `machinery` | Pinball Kinetic Machinery and Rollover Bank Completion | 2026-09-01 |
| [`LRN-045`](#lrn-045) | TASK-039 | `ui` | Junk Box Sidebar Integration and Pegboard Display Equivalence | 2026-09-01 |
| [`LRN-046`](#lrn-046) | TASK-002 | `campaign` | Six-Playthrough Story Campaign Architecture | 2026-09-01 |
| [`LRN-047`](#lrn-047) | TASK-003 | `characters` | Character Bespoke Progression Mechanics | 2026-09-01 |
| [`LRN-048`](#lrn-048) | TASK-018 | `polyomino` | Tetromino Module Combining and Fusion System | 2026-09-01 |
| [`LRN-049`](#lrn-049) | TASK-008 | `synergies` | Build Archetypes and Synergy Linkages | 2026-09-01 |
| [`LRN-050`](#lrn-050) | TASK-004 | `ui` | Right Panel UI and Comic Cutout Vignettes | 2026-09-01 |
| [`LRN-051`](#lrn-051) | TASK-004 | `ui` | Live Main Scene UI Integration | 2026-09-02 |
| [`LRN-052`](#lrn-052) | TASK-040 | `asset_resources` | External Asset Pools and VFX Spritesheet Storage | 2026-09-02 |
| [`LRN-053`](#lrn-053) | TASK-004 | `ui` | Right Sidebar Junk Box and Circular Cannon Orb Layout | 2026-09-02 |
| [`LRN-054`](#lrn-054) | TASK-005 | `flow` | Takeover Cutscene Reward Sequencing | 2026-09-02 |
| [`LRN-055`](#lrn-055) | TASK-039 | `ui` | JunkBoxPanel Sidebar Width Containment | 2026-09-02 |
| [`LRN-056`](#lrn-056) | TASK-039 | `ui` | Godot Scene Instantiation and Onready Initialization Order | 2026-09-02 |
| [`LRN-057`](#lrn-057) | TASK-039 | `ui` | CenterPanel Scene Anchors in main.tscn | 2026-09-02 |
| [`LRN-058`](#lrn-058) | TASK-039 | `ui` | JunkBoxPanel Grid Cell Scaling for 320px Sidebar Width | 2026-09-02 |
| [`LRN-059`](#lrn-059) | TASK-039 | `ui` | JunkBoxPanel Header Title Sizing | 2026-09-02 |
| [`LRN-060`](#lrn-060) | TASK-039 | `ui` | Godot VBoxContainer Orientation Exception Prevention | 2026-09-02 |
| [`LRN-061`](#lrn-061) | TASK-039 | `verification` | Playwright Chromium UI Verification | 2026-09-02 |
| [`LRN-062`](#lrn-062) | TASK-042 | `ui` | UI Layout and Centering | 2026-09-02 |
| [`LRN-063`](#lrn-063) | TASK-004 | `ui` | Square Cannon UI Panel Layout | 2026-09-02 |
| [`LRN-064`](#lrn-064) | TASK-043 | `ui_visuals` | Replace Code-Drawn Cannons with Sprite Assets | 2026-09-02 |
| [`LRN-065`](#lrn-065) | TASK-043 | `ui_visuals` | Single Cannon Rendering, Crisp Native Sprite Scale & Cartoon Coffee Fire VFX | 2026-09-02 |
| [`LRN-066`](#lrn-066) | TASK-043 | `ui_visuals` | Center-Left Cannon UI Positioning & Right-Aligned Fire VFX | 2026-09-02 |
| [`LRN-067`](#lrn-067) | TASK-043 | `ui_visuals` | Cannon Charge Overlay & UI Charge State Forwarding | 2026-09-02 |
| [`LRN-068`](#lrn-068) | TASK-043 | `ui_visuals` | Flying Energy Particle VFX Destination Targeting | 2026-09-02 |
| [`LRN-069`](#lrn-069) | TASK-043 | `ui_visuals` | Gain Text Centering Underneath Charge Bar & 2-Stage Catch-Up Bar Animation | 2026-09-02 |
| [`LRN-070`](#lrn-070) | TASK-043 | `ui_visuals` | Pure White Target Bar Accessibility & Non-Overlapping Segment Drawing | 2026-09-02 |
| [`LRN-071`](#lrn-071) | TASK-043 | `ui_visuals` | High-Contrast Visual Accessibility for Lead Target Jump Bar | 2026-09-02 |
| [`LRN-072`](#lrn-072) | TASK-043 | `ui_visuals` | 0.5-Second Delay for Energy Charge Catch-Up Bar Animation | 2026-09-02 |
| [`LRN-073`](#lrn-073) | TASK-043 | `ui_visuals` | Preserving Catch-Up Tween Delays in Per-Frame Energy Updates | 2026-09-02 |
| [`LRN-074`](#lrn-074) | TASK-040 | `asset_resources` | Preloaded Asset Pack Tile and VFX Spritesheet Integration | 2026-09-02 |
| [`LRN-075`](#lrn-075) | TASK-047 | `game_design` | pinball_layout_mapping | 2026-09-02 |
| [`LRN-076`](#lrn-076) | TASK-042 | `ui` | Hopper Repositioning and Top Bar Debug Menu | 2026-09-02 |
| [`LRN-077`](#lrn-077) | TASK-044 | `ui` | Full-Screen Comic Overlay Game Pause Behavior | 2026-09-02 |
| [`LRN-078`](#lrn-078) | TASK-042 | `ui` | Top Header UI Bar Background and Ball Spawn Masking | 2026-09-02 |
| [`LRN-079`](#lrn-079) | TASK-004 | `ui` | gold_counter_repositioning | 2026-09-02 |
| [`LRN-080`](#lrn-080) | TASK-042 | `ui` | hopper_top_bar_clearance | 2026-09-02 |
| [`LRN-081`](#lrn-081) | TASK-042 | `ui` | High-Layer CanvasLayer for Top UI Header Bar and Non-Overlapping Control Layout | 2026-09-02 |
| [`LRN-082`](#lrn-082) | TASK-042 | `ui` | UI Button Layering Order and Hopper Outline Geometry | 2026-09-02 |
| [`LRN-083`](#lrn-083) | TASK-042 | `ui` | Cannon Overlay Layering Order and Sidebar Widget Texture Rendering | 2026-09-02 |
| [`LRN-084`](#lrn-084) | TASK-042 | `ui` | Single Canonical Node Rendering vs Duplicate Static Texture Drawing | 2026-09-02 |
| [`LRN-085`](#lrn-085) | TASK-052 | `ui` | Junk Box Dynamic Scroll Bar Visibility | 2026-09-02 |
| [`LRN-086`](#lrn-086) | TASK-053 | `game_balance` | relic_machinery | 2026-09-02 |
| [`LRN-087`](#lrn-087) | TASK-042 | `godot_engine` | hopper_ball_cascade_physics | 2026-09-02 |
| [`LRN-088`](#lrn-088) | TASK-049 | `godot_engine` | On-Board Relic Tooltip Simplification | 2026-09-02 |
| [`LRN-089`](#lrn-089) | TASK-054 | `inventory_and_board_systems` | relic_junk_box_return | 2026-09-02 |
| [`LRN-090`](#lrn-090) | TASK-055 | `machinery` | rotation | 2026-09-02 |
| [`LRN-091`](#lrn-091) | TASK-TOOLING | `tooling` | Dashboard Task Chronological Sorting | 2026-09-02 |
| [`LRN-092`](#lrn-092) | TASK-056 | `tooling` | Interactive Task Details Modal and Branch Command Sanitization | 2026-09-02 |
| [`LRN-093`](#lrn-093) | TASK-046 | `godot_engine` | Stationary combat terrain with synchronized wall advance tweens | 2026-09-02 |
| [`LRN-094`](#lrn-094) | TASK-051 | `godot_engine` | Pinball kinetic machinery subclass lifecycle and bonus energy dispatching | 2026-09-02 |
| [`LRN-095`](#lrn-095) | TASK-046 | `ui` | Embedding animated terrain art inside corner cannon widget | 2026-09-03 |
| [`LRN-096`](#lrn-096) | TASK-045 | `refactoring` | Removal of minion systems and dead combat references | 2026-09-03 |
| [`LRN-097`](#lrn-097) | TASK-048 | `gameplay_systems` | Relic Pinball Widget Activation Binding and Charge Progress Telemetry | 2026-09-03 |
| [`LRN-098`](#lrn-098) | TASK-040 | `asset_resources` | Goblin Mood and Reset Hand Sprite Integration | 2026-09-03 |
| [`LRN-099`](#lrn-099) | TASK-061 | `tooling` | Dashboard Kanban Drag and Drop Task Progression | 2026-09-03 |

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

### <a id="lrn-042"></a> LRN-042: Wall Siege Timer and Defender Pushback Logic
- **Task:** `TASK-021`
- **Category:** `gameplay`
- **Created:** `2026-09-01T22:27:32.250353`

#### Context & Problem
Wall siege failures need consistent defender pushback state transitions and 120s timer configuration.

#### Key Insight & Learning
CombatManager owns wall siege timers and defender pushback transitions, emitting pushback_occurred signals to reset wall HP and decrement wall index.

#### Actionable Guideline for Future Agents
Always handle wall timer expirations via CombatManager.apply_defender_pushback and ensure WALL_PHASE_TIME_SECONDS is set to 120.

---

### <a id="lrn-043"></a> LRN-043: Exponential Wall HP and Gold Scaling Model
- **Task:** `TASK-022`
- **Category:** `balance`
- **Created:** `2026-09-01T22:28:20.208636`

#### Context & Problem
Wall HP scaling and breach rewards need predictable mathematical curves to maintain pacing across 45-60 minute runs.

#### Key Insight & Learning
Exponential formulas Health(n) = BaseHP * (1.35)^n and Gold(n) = BaseGold * (1.25)^n keep progression pacing calibrated while preventing arithmetic overflow.

#### Actionable Guideline for Future Agents
Use CityDefinition.get_wall_hp_max_for_index and get_wall_breach_gold_reward for all wall health and resource payout calculations.

---

### <a id="lrn-044"></a> LRN-044: Pinball Kinetic Machinery and Rollover Bank Completion
- **Task:** `TASK-036`
- **Category:** `machinery`
- **Created:** `2026-09-01T22:30:16.136168`

#### Context & Problem
Kinetic pinball devices (rollovers, pop bumpers, drop targets, wire gates, slingshots) require distinct component scripts and rollover bank triggers.

#### Key Insight & Learning
RolloverSwitch devices emit bank_completed signals on full bank illumination when set_lit is updated prior to trigger_activation signal emissions.

#### Actionable Guideline for Future Agents
Use PolyominoModuleData.CellType for pinball component types and verify rollover bank state via cell_type matching in PolyominoModuleNode.

---

### <a id="lrn-045"></a> LRN-045: Junk Box Sidebar Integration and Pegboard Display Equivalence
- **Task:** `TASK-039`
- **Category:** `ui`
- **Created:** `2026-09-01T22:31:13.044453`

#### Context & Problem
JunkBoxPanel sidebar layout and pegboard UI previews must match live playfield dimensions without obscuring active combat.

#### Key Insight & Learning
Setting JunkBoxGridView CELL_WIDTH=52 and CELL_HEIGHT=56 aligns preview grid cells with live PolyominoModuleNode dimensions, and integrate_into_sidebar mounts the panel directly into the right UI container.

#### Actionable Guideline for Future Agents
Use JunkBoxPanel.integrate_into_sidebar and JunkBoxGridView.get_peg_preview_parameters for sidebar placement and pegboard UI preview scaling.

---

### <a id="lrn-046"></a> LRN-046: Six-Playthrough Story Campaign Architecture
- **Task:** `TASK-002`
- **Category:** `campaign`
- **Created:** `2026-09-01T22:32:06.197821`

#### Context & Problem
GameState tracks 6 distinct campaign runs, character archetypes, unlocked McGuffins, and convergence triggers.

#### Key Insight & Learning
start_campaign_run and complete_campaign_run handle sequential unlock gating across all 6 playthroughs, automatically setting convergence_active on run 6.

#### Actionable Guideline for Future Agents
Use GameState.start_campaign_run, complete_campaign_run, and save_campaign_progress/load_campaign_progress for multi-run campaign state management.

---

### <a id="lrn-047"></a> LRN-047: Character Bespoke Progression Mechanics
- **Task:** `TASK-003`
- **Category:** `characters`
- **Created:** `2026-09-01T22:32:38.351538`

#### Context & Problem
CharacterProgressionManager provides character-specific passive perks and multiplier calculations for all 6 playthrough archetypes.

#### Key Insight & Learning
CharacterProgressionManager computes wall damage, peg energy bonuses, revive chances, and booster speed multipliers based on character_archetype, with goblin_convergence combining peak values from all archetypes.

#### Actionable Guideline for Future Agents
Use CharacterProgressionManager.get_perks_for_archetype and compute_* helper functions to query character-specific perks during run execution.

---

### <a id="lrn-048"></a> LRN-048: Tetromino Module Combining and Fusion System
- **Task:** `TASK-018`
- **Category:** `polyomino`
- **Created:** `2026-09-01T22:33:27.001827`

#### Context & Problem
PolyominoFusionSystem provides tier-based module merging and recipe blueprint crafting.

#### Key Insight & Learning
PolyominoFusionSystem checks tier equivalence and RECIPE_BLUEPRINTS to combine lower-tier or prerequisite items into higher tier or blueprint output modules.

#### Actionable Guideline for Future Agents
Use PolyominoFusionSystem.can_fuse and PolyominoFusionSystem.fuse_modules for module combining and crafting operations.

---

### <a id="lrn-049"></a> LRN-049: Build Archetypes and Synergy Linkages
- **Task:** `TASK-008`
- **Category:** `synergies`
- **Created:** `2026-09-01T22:34:05.295100`

#### Context & Problem
BuildSynergyDatabase calculates synergy multipliers for 4 core build archetypes (pyro, cryo, voltage, swarm).

#### Key Insight & Learning
BuildSynergyDatabase.get_synergy_multiplier evaluates ball and peg combinations to boost weapon energy routing and damage based on archetype focus.

#### Actionable Guideline for Future Agents
Use BuildSynergyDatabase.get_synergy_multiplier to scale damage and energy routing during combat calculations.

---

### <a id="lrn-050"></a> LRN-050: Right Panel UI and Comic Cutout Vignettes
- **Task:** `TASK-004`
- **Category:** `ui`
- **Created:** `2026-09-01T22:34:43.998475`

#### Context & Problem
ComicVignettePanel displays comic cutout bubbles when the main cannon fires.

#### Key Insight & Learning
ComicVignettePanel.trigger_firing_vignette calculates wall degradation ratio and goblin reaction mood states, auto-dismissing after animation without blocking board mouse events.

#### Actionable Guideline for Future Agents
Use ComicVignettePanel with mouse_filter MOUSE_FILTER_IGNORE to render live combat cutout vignettes over UI panels.

---

### <a id="lrn-051"></a> LRN-051: Live Main Scene UI Integration
- **Task:** `TASK-004`
- **Category:** `ui`
- **Created:** `2026-09-02T08:36:04.920443`

#### Context & Problem
Connected ComicVignettePanel and JunkBoxPanel into game_coordinator_ui.gd.

#### Key Insight & Learning
ComicVignettePanel connects to CombatManager.cannon_fired_at_wall signal while JunkBoxPanel integrates directly into UILayer/CenterPanel.

#### Actionable Guideline for Future Agents
Wire UI overlay panels inside game_coordinator_ui.gd create_inventory_ui method to attach them to live scene runtime.

---

### <a id="lrn-052"></a> LRN-052: External Asset Pools and VFX Spritesheet Storage
- **Task:** `TASK-040`
- **Category:** `asset_resources`
- **Created:** `2026-09-02T09:29:34.649549`

#### Context & Problem
Agents require knowledge of external local asset packs for graphics and particle effects.

#### Key Insight & Learning
External asset pack directory C:\Users\josep\Desktop\Games\Essentials VFX Spritesheets contains VFX spritesheets for particle effects, explosions, and impact animations alongside in-repo Kenney assets.

#### Actionable Guideline for Future Agents
When sourcing visual assets and particle effects, inspect both assets/ and C:\Users\josep\Desktop\Games\Essentials VFX Spritesheets.

---

### <a id="lrn-053"></a> LRN-053: Right Sidebar Junk Box and Circular Cannon Orb Layout
- **Task:** `TASK-004`
- **Category:** `ui`
- **Created:** `2026-09-02T09:29:45.523426`

#### Context & Problem
Restructured right sidebar layout to host JunkBoxPanel permanently.

#### Key Insight & Learning
CircularCannonWidget renders rising liquid energy fill in the bottom-right corner while TopWallContainer displays wall health above Gold.

#### Actionable Guideline for Future Agents
Keep right sidebar reserved for JunkBoxPanel and position top status bars cleanly inside LeftPanel.

---

### <a id="lrn-054"></a> LRN-054: Takeover Cutscene Reward Sequencing
- **Task:** `TASK-005`
- **Category:** `flow`
- **Created:** `2026-09-02T09:34:04.851333`

#### Context & Problem
Sequenced reward selection modal popups after full-screen comic takeover cutscenes.

#### Key Insight & Learning
GameCoordinatorFlow.handle_wall_destroyed plays FullscreenComicTakeover first, connecting takeover_completed signal to handle_wall_break_transition_finished.

#### Actionable Guideline for Future Agents
Chain cutscene takeover completion signals before dispatching reward modal popups.

---

### <a id="lrn-055"></a> LRN-055: JunkBoxPanel Sidebar Width Containment
- **Task:** `TASK-039`
- **Category:** `ui`
- **Created:** `2026-09-02T09:35:29.545122`

#### Context & Problem
Restructured JunkBoxPanel scene node layout from HBoxContainer to VBoxContainer.

#### Key Insight & Learning
HBoxContainer with size_flags_horizontal SIZE_EXPAND_FILL inside JunkBoxPanel forced the panel to expand across the full screen. Stacking controls vertically in VBoxContainer confines the scene strictly within 320px sidebar width.

#### Actionable Guideline for Future Agents
Use vertical VBoxContainer stacking for sub-panels inside 320px wide sidebars to prevent horizontal expansion over the main playfield.

---

### <a id="lrn-056"></a> LRN-056: Godot Scene Instantiation and Onready Initialization Order
- **Task:** `TASK-039`
- **Category:** `ui`
- **Created:** `2026-09-02T09:37:08.684977`

#### Context & Problem
Resolved JunkBoxPanel layout failure caused by pre-SceneTree node reference evaluation.

#### Key Insight & Learning
Calling custom layout functions on an instantiated scene before adding it to the SceneTree evaluates @onready variables as null. Re-applying layout configurations inside _ready ensures node references are populated.

#### Actionable Guideline for Future Agents
Always invoke layout configuration methods in _ready() or re-evaluate @onready nodes using get_node_or_null() if called before add_child().

---

### <a id="lrn-057"></a> LRN-057: CenterPanel Scene Anchors in main.tscn
- **Task:** `TASK-039`
- **Category:** `ui`
- **Created:** `2026-09-02T09:39:43.041280`

#### Context & Problem
Removed conflicting anchors_preset = 15 override from CenterPanel node in main.tscn.

#### Key Insight & Learning
Overriding CenterPanel with anchors_preset = 15 inside main.tscn caused the entire sidebar container to stretch from x=4 to x=1276 across the screen. Preserving anchors_preset = 0 keeps CenterPanel at x=960 to x=1280.

#### Actionable Guideline for Future Agents
Verify main.tscn container nodes do not contain duplicate anchors_preset overrides that expand sidebar panels across the entire playfield.

---

### <a id="lrn-058"></a> LRN-058: JunkBoxPanel Grid Cell Scaling for 320px Sidebar Width
- **Task:** `TASK-039`
- **Category:** `ui`
- **Created:** `2026-09-02T09:52:01.003694`

#### Context & Problem
Adjusted JunkBoxGridView CELL_WIDTH/HEIGHT to 46px to keep panel total width at 292px.

#### Key Insight & Learning
A 6-column grid with 52px cells produces a 312px grid, which plus 16px margins equals 328px and overflows a 320px sidebar by 8px. Reducing cell size to 46px produces a 276px grid, leaving 16px padding on both sides with zero cutoff.

#### Actionable Guideline for Future Agents
Calculate grid column counts and cell padding so total sub-container width is less than 304px inside 320px sidebars.

---

### <a id="lrn-059"></a> LRN-059: JunkBoxPanel Header Title Sizing
- **Task:** `TASK-039`
- **Category:** `ui`
- **Created:** `2026-09-02T09:53:31.102710`

#### Context & Problem
Adjusted Title font size and set custom_minimum_size on SortBtn in junk_box_panel.tscn.

#### Key Insight & Learning
Label with SIZE_EXPAND_FILL inside a 304px MarginContainer squished the Auto-Pack button to 88px, truncating it as Auto-Pa... Setting SortBtn custom_minimum_size to Vector2(84, 24) and font_size to 12 prevents button truncation.

#### Actionable Guideline for Future Agents
Explicitly set custom_minimum_size on header action buttons inside narrow sidebar containers.

---

### <a id="lrn-060"></a> LRN-060: Godot VBoxContainer Orientation Exception Prevention
- **Task:** `TASK-039`
- **Category:** `ui`
- **Created:** `2026-09-02T09:54:53.391188`

#### Context & Problem
Resolved runtime C++ exception when attempting set_vertical on a VBoxContainer node.

#### Key Insight & Learning
Calling .vertical = true on a Node typed as BoxContainer when the actual instance is already a VBoxContainer throws a C++ runtime exception ('Can\'t change orientation of VBoxContainer') and aborts script execution. Explicitly checking 'hbox is HBoxContainer' avoids the exception.

#### Actionable Guideline for Future Agents
Check node type using 'is HBoxContainer' before mutating .vertical on BoxContainer nodes.

---

### <a id="lrn-061"></a> LRN-061: Playwright Chromium UI Verification
- **Task:** `TASK-039`
- **Category:** `verification`
- **Created:** `2026-09-02T10:00:26.342326`

#### Context & Problem
Added Python Playwright Chromium capture script to verify HTML dashboard and visual task matrix.

#### Key Insight & Learning
Python Playwright Chromium (sync_api) can launch headless browser instances to capture pixel-perfect 1280x720 full-page screenshots of local HTML visual dashboards.

#### Actionable Guideline for Future Agents
Use python -m playwright to capture automated visual dashboard snapshots during automated UI verification.

---

### <a id="lrn-062"></a> LRN-062: UI Layout and Centering
- **Task:** `TASK-042`
- **Category:** `ui`
- **Created:** `2026-09-02T10:10:19.572956`

#### Context & Problem
UI overlapping, right sidebar overflow, board uncentered

#### Key Insight & Learning
RunGold label repositioning, 6-col Junk Box grid width, 15-col 116px start offset board centering

#### Actionable Guideline for Future Agents
Keep sidebar panel minimum width <= 304px for 320px containers and use 15 cols with 116px start X for 960px board centering.

---

### <a id="lrn-063"></a> LRN-063: Square Cannon UI Panel Layout
- **Task:** `TASK-004`
- **Category:** `ui`
- **Created:** `2026-09-02T10:20:34.284271`

#### Context & Problem
Cannon UI floating circle over junk box grid

#### Key Insight & Learning
Embedding CircularCannonWidget inside junk_box_panel.tscn at bottom of sidebar provides clean non-overlapping layout

#### Actionable Guideline for Future Agents
Place sidebar widgets as embedded children within sidebar containers rather than hardcoding global screen coordinates

---

### <a id="lrn-064"></a> LRN-064: Replace Code-Drawn Cannons with Sprite Assets
- **Task:** `TASK-043`
- **Category:** `ui_visuals`
- **Created:** `2026-09-02T10:34:00.994995`

#### Context & Problem
Procedural rect/circle drawing for battlefield cannon and UI cannon widget lacked visual quality and firing indicators

#### Key Insight & Learning
Using texture assets (cannonMobile.png) combined with parallel Tweens for recoil displacement and explosion1.png for muzzle flash provides clean visual polish

#### Actionable Guideline for Future Agents
Preload sprite texture assets for game objects and UI widgets, combining recoil shake Tweens and muzzle flash sprite overlays on firing events.

---

### <a id="lrn-065"></a> LRN-065: Single Cannon Rendering, Crisp Native Sprite Scale & Cartoon Coffee Fire VFX
- **Task:** `TASK-043`
- **Category:** `ui_visuals`
- **Created:** `2026-09-02T10:39:00.774827`

#### Context & Problem
CircularCannonWidget and CannonVisual both drew cannon textures causing duplicate cannon rendering and blurry upscaling

#### Key Insight & Learning
Removing texture drawing from widget container and rendering cannonMobile.png at native 43.5x30px in CannonVisual eliminates duplication and retains crisp sprite definition. Animating Impact_Fire_Lv1_spritesheet.png 4x4 region frames on firing signal provides rich fire VFX.

#### Actionable Guideline for Future Agents
Keep UI widget containers dedicated to panel backgrounds and energy overlays while delegating cannon sprite rendering and fire VFX to CannonVisual at crisp unscaled dimensions.

---

### <a id="lrn-066"></a> LRN-066: Center-Left Cannon UI Positioning & Right-Aligned Fire VFX
- **Task:** `TASK-043`
- **Category:** `ui_visuals`
- **Created:** `2026-09-02T10:41:43.920256`

#### Context & Problem
Cannon position needed to be centered on the left side of the bottom UI container with fire VFX lined up against the right side of the sprite

#### Key Insight & Learning
Setting CannonVisual position to Vector2(50, 628) in battlefield_view.tscn and drawing Impact_Fire_Lv1_spritesheet.png at muzzle_right_x = center_x + 21.75 with horizontal recoil (_recoil_offset_x = -12.0) places the sprite cleanly in the center-left UI box and aligns fire VFX against the right edge.

#### Actionable Guideline for Future Agents
Align rightward-firing cannon sprites at center-left UI container bounds and line up muzzle blast VFX regions directly against the right edge of the sprite.

---

### <a id="lrn-067"></a> LRN-067: Cannon Charge Overlay & UI Charge State Forwarding
- **Task:** `TASK-043`
- **Category:** `ui_visuals`
- **Created:** `2026-09-02T10:45:31.135706`

#### Context & Problem
CannonVisual was reparented to CannonOverlay canvas layer and lacked an explicit charge overlay progress meter

#### Key Insight & Learning
Adding set_charge and set_energy methods to CannonVisual and drawing a 54x6px gold/amber progress meter under the cannon sprite in _draw() with set_charge forwarding from center_panel_ui.gd ensures live charge visibility during combat.

#### Actionable Guideline for Future Agents
Implement explicit set_charge methods on canvas overlay visual nodes and forward charge updates from center_panel_ui to maintain live charge meter overlays.

---

### <a id="lrn-068"></a> LRN-068: Flying Energy Particle VFX Destination Targeting
- **Task:** `TASK-043`
- **Category:** `ui_visuals`
- **Created:** `2026-09-02T10:51:53.950672`

#### Context & Problem
Energy gain VFX particles flew to the center of the widget container box instead of the charge bar under the cannon

#### Key Insight & Learning
Querying CannonVisual.global_position + Vector2(0.0, 18.0) in center_panel_ui.gd show_energy_gain ensures flying energy particles stream directly to the charge bar under the cannon sprite.

#### Actionable Guideline for Future Agents
Calculate energy flow particle destination coordinates using the target visual node position (CannonVisual.global_position + Vector2(0.0, 18.0)) to align flying particles with the charge progress bar.

---

### <a id="lrn-069"></a> LRN-069: Gain Text Centering Underneath Charge Bar & 2-Stage Catch-Up Bar Animation
- **Task:** `TASK-043`
- **Category:** `ui_visuals`
- **Created:** `2026-09-02T11:05:54.879289`

#### Context & Problem
Gain text label overlapped the charge bar and charge energy gains lacked clear visual feedback for jump amounts

#### Key Insight & Learning
Setting label_w = 80.0, horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER, and position = end_pos + Vector2(-label_w * 0.5, 8.0) centers gain labels directly underneath the charge bar. Adding _target_ratio white lead bar with 0.35s TRANS_QUAD smooth yellow catch-up tweening gives clear energy jump visual feedback.

#### Actionable Guideline for Future Agents
Center gain text labels horizontally underneath target UI bars and use a 2-stage white lead bar with smooth yellow catch-up fill animation for energy jumps.

---

### <a id="lrn-070"></a> LRN-070: Pure White Target Bar Accessibility & Non-Overlapping Segment Drawing
- **Task:** `TASK-043`
- **Category:** `ui_visuals`
- **Created:** `2026-09-02T11:09:11.334042`

#### Context & Problem
Semi-transparent white drawn beneath or over yellow bars tint-blended into light yellow

#### Key Insight & Learning
Drawing the lead target bar segment from liquid_ratio to _target_ratio separately using solid pure white Color(1.0, 1.0, 1.0, 1.0) with zero overlap over the yellow fill bar ensures pure #FFFFFF contrast for accessibility.

#### Actionable Guideline for Future Agents
Render lead target bar segments using solid pure white Color(1.0, 1.0, 1.0, 1.0) starting at liquid_ratio to prevent color blending and guarantee high-contrast accessibility.

---

### <a id="lrn-071"></a> LRN-071: High-Contrast Visual Accessibility for Lead Target Jump Bar
- **Task:** `TASK-043`
- **Category:** `ui_visuals`
- **Created:** `2026-09-02T11:13:40.576121`

#### Context & Problem
Adjacent white and yellow bars lacked stark visual contrast for users with visual impairments

#### Key Insight & Learning
Rendering the lead target segment as a protruding 12px tall box with solid pure white Color(1.0, 1.0, 1.0, 1.0) fill, solid black outline Color(0.0, 0.0, 0.0, 1.0), and 2px vertical black separator line creates extreme shape and color contrast for visual accessibility.

#### Actionable Guideline for Future Agents
Combine shape protrusion, black outline borders, and black separator lines around pure white target segments to guarantee extreme visual contrast for accessibility.

---

### <a id="lrn-072"></a> LRN-072: 0.5-Second Delay for Energy Charge Catch-Up Bar Animation
- **Task:** `TASK-043`
- **Category:** `ui_visuals`
- **Created:** `2026-09-02T11:15:26.923267`

#### Context & Problem
The yellow catch-up bar started animating immediately on energy gain without allowing the viewer to register the target jump

#### Key Insight & Learning
Adding .set_delay(0.5) to the _catchup_tween in set_energy() holds the high-contrast white lead bar steady for half a second before the yellow bar animates up to meet it.

#### Actionable Guideline for Future Agents
Use .set_delay(0.5) on catch-up bar fill tweens to pause long enough for viewers to register energy jump amounts before animating.

---

### <a id="lrn-073"></a> LRN-073: Preserving Catch-Up Tween Delays in Per-Frame Energy Updates
- **Task:** `TASK-043`
- **Category:** `ui_visuals`
- **Created:** `2026-09-02T11:17:52.110498`

#### Context & Problem
Calling set_energy every frame with unchanged energy values snapped liquid_ratio = new_ratio and killed active catch-up tweens

#### Key Insight & Learning
Only mutating liquid_ratio when new_ratio < _target_ratio (energy reset) and launching tweens when new_ratio > _target_ratio allows tick-by-tick set_energy calls without interrupting running catch-up tween delays.

#### Actionable Guideline for Future Agents
In per-frame progress bar setters, do not snap the animated fill ratio on same-ratio ticks; allow active delay tweens to run to completion.

---

### <a id="lrn-074"></a> LRN-074: Preloaded Asset Pack Tile and VFX Spritesheet Integration
- **Task:** `TASK-040`
- **Category:** `asset_resources`
- **Created:** `2026-09-02T11:56:31.004823`

#### Context & Problem
Replacing programmer shapes with Kenney stone wall tiles and Essentials VFX explosion sheets across combat scenes

#### Key Insight & Learning
Preloading Texture2D assets and drawing textured rects inside CanvasItem _draw() ensures crisp asset rendering across battlefields and particle bursts while avoiding runtime allocations

#### Actionable Guideline for Future Agents
Preload stone wall tiles and VFX spritesheets at file load time and render them inside CanvasItem _draw() using explicit region rects for animation frames

---

### <a id="lrn-075"></a> LRN-075: pinball_layout_mapping
- **Task:** `TASK-047`
- **Category:** `game_design`
- **Created:** `2026-09-02T12:06:06.394443`

#### Context & Problem
Researching pinball playfield components and adapting them for polyomino grid relics

#### Key Insight & Learning
Pinball playfield mechanics can be systematically mapped to polyomino relic grid modules by preserving kinetic flow and chaos.

#### Actionable Guideline for Future Agents
Map pinball board components to specific polyomino shape footprints to balance kinetic flow and unpredictable chaos in Goblin Cannon.

---

### <a id="lrn-076"></a> LRN-076: Hopper Repositioning and Top Bar Debug Menu
- **Task:** `TASK-042`
- **Category:** `ui`
- **Created:** `2026-09-02T13:18:25.171075`

#### Context & Problem
Hopper and loose debug buttons overlapped top UI header bar and playfield area.

#### Key Insight & Learning
Consolidating debug controls into a collapsible top bar panel reserves playfield space while keeping debug tools accessible.

#### Actionable Guideline for Future Agents
Position the hopper strictly beneath top header UI elements (Y > 50). Consolidate loose debug buttons into a collapsible top bar panel to reserve playfield space.

---

### <a id="lrn-077"></a> LRN-077: Full-Screen Comic Overlay Game Pause Behavior
- **Task:** `TASK-044`
- **Category:** `ui`
- **Created:** `2026-09-02T13:19:59.192879`

#### Context & Problem
Full-screen comic overlay cutscenes (wall breaks, boss victories, cinematics) needed to pause game state without pausing bottom-right cannon animations.

#### Key Insight & Learning
Setting GameState.paused = true in FullscreenComicTakeover play_takeover() and GameState.paused = false in dismiss_takeover() pauses board physics and timers while keeping process_mode = PROCESS_MODE_ALWAYS active.

#### Actionable Guideline for Future Agents
In FullscreenComicTakeover, manage GameState.paused on play_takeover and dismiss_takeover, and leave bottom-right cannon widgets (ComicVignettePanel, CircularCannonWidget) unpaused.

---

### <a id="lrn-078"></a> LRN-078: Top Header UI Bar Background and Ball Spawn Masking
- **Task:** `TASK-042`
- **Category:** `ui`
- **Created:** `2026-09-02T13:31:59.051144`

#### Context & Problem
Balls spawned above the hopper transparently in open space behind top UI labels.

#### Key Insight & Learning
Adding a solid top UI header bar background and setting SPAWN_Y_OFFSET behind the header bar masks the spawn origin so balls emerge cleanly from beneath the header bar.

#### Actionable Guideline for Future Agents
Mask ball spawn origins behind solid header bar panels (SPAWN_Y_OFFSET <= header_bar_bottom) to keep ball emergence visually clean.

---

### <a id="lrn-079"></a> LRN-079: gold_counter_repositioning
- **Task:** `TASK-004`
- **Category:** `ui`
- **Created:** `2026-09-02T13:42:43.749710`

#### Context & Problem
Top UI header layout and gold counter visual presentation

#### Key Insight & Learning
Padding out TopWallContainer vertically allows hosting both WallHealthBar and GoldContainer with a gold coin icon texture.

#### Actionable Guideline for Future Agents
Position the gold counter inside TopWallContainer directly underneath WallHealthBar, replacing the text label prefix with a coin_gold.png HUD icon texture asset.

---

### <a id="lrn-080"></a> LRN-080: hopper_top_bar_clearance
- **Task:** `TASK-042`
- **Category:** `ui`
- **Created:** `2026-09-02T13:53:51.776246`

#### Context & Problem
Top UI header bar padding vs Hopper node position

#### Key Insight & Learning
Setting Hopper position Y to 135 ensures its top rim (local offset Y = -80, global Y = 55) clears the 54px top header UI bar without overlap.

#### Actionable Guideline for Future Agents
Position the Hopper node at Y = 135 in main.tscn so that its bin top rim (Y = 55) sits cleanly below the 54px top header UI bar.

---

### <a id="lrn-081"></a> LRN-081: High-Layer CanvasLayer for Top UI Header Bar and Non-Overlapping Control Layout
- **Task:** `TASK-042`
- **Category:** `ui`
- **Created:** `2026-09-02T13:59:39.409238`

#### Context & Problem
Hopper 2D world nodes bled through transparent top UI header, and timer text overlapped debug buttons.

#### Key Insight & Learning
Placing top UI header background panels in a high CanvasLayer (layer=10) with 100% solid opacity blocks all 2D world nodes behind Y <= 54, while separating utility buttons, stats, and health containers across dedicated X zones eliminates UI control overlaps.

#### Actionable Guideline for Future Agents
Place top UI header bars in high CanvasLayer layers (layer >= 10) with 100% opacity to mask world nodes, and enforce strict non-overlapping X coordinate zones for utility buttons, timer, gold, and health bars.

---

### <a id="lrn-082"></a> LRN-082: UI Button Layering Order and Hopper Outline Geometry
- **Task:** `TASK-042`
- **Category:** `ui`
- **Created:** `2026-09-02T14:32:20.926698`

#### Context & Problem
Separate top CanvasLayer overlaid UI controls, and default Line2D white outline drew a bar across the hopper opening.

#### Key Insight & Learning
Keep top bar background panel as child 0 inside UILayer (layer=10) so UI controls draw on top of it, and omit closing top points in Line2D outline to keep bin openings open.

#### Actionable Guideline for Future Agents
Place header background panels as child 0 of the UI CanvasLayer, and omit top closing line segments from hopper Line2D outlines.

---

### <a id="lrn-083"></a> LRN-083: Cannon Overlay Layering Order and Sidebar Widget Texture Rendering
- **Task:** `TASK-042`
- **Category:** `ui`
- **Created:** `2026-09-02T14:40:53.725931`

#### Context & Problem
CannonOverlay layer was below UILayer layer 10 hiding CannonVisual, and CircularCannonWidget lacked cannon texture rendering.

#### Key Insight & Learning
Set CannonOverlay layer to 15 (above UILayer layer 10) so main cannon visuals render on top of the UI, and render cannonMobile.png inside CircularCannonWidget._draw() to guarantee crisp cannon rendering in the sidebar.

#### Actionable Guideline for Future Agents
Keep CannonOverlay layer higher than UILayer (layer=15 > layer=10), and ensure custom Control widget _draw() methods explicitly draw texture assets.

---

### <a id="lrn-084"></a> LRN-084: Single Canonical Node Rendering vs Duplicate Static Texture Drawing
- **Task:** `TASK-042`
- **Category:** `ui`
- **Created:** `2026-09-02T14:43:58.911654`

#### Context & Problem
Both CannonVisual and CircularCannonWidget rendered cannon sprite assets simultaneously in the bottom right panel.

#### Key Insight & Learning
Avoid duplicate asset texture rendering in container controls when a dedicated animated Node2D (CannonVisual) is reparented to an overlay layer for the same UI area.

#### Actionable Guideline for Future Agents
Rely on single primary animated nodes (e.g. CannonVisual) on overlay layers rather than drawing duplicate static textures inside parent container widgets.

---

### <a id="lrn-085"></a> LRN-085: Junk Box Dynamic Scroll Bar Visibility
- **Task:** `TASK-052`
- **Category:** `ui`
- **Created:** `2026-09-02T14:57:44.115349`

#### Context & Problem
ScrollContainer showed vertical scrollbar constantly even when inventory items were empty or fit within visible space.

#### Key Insight & Learning
ScrollContainer calculates scrollbar visibility by comparing child custom_minimum_size against container size. By calculating grid rows dynamically based on occupied cells and container viewport height, scrollbar toggles automatically.

#### Actionable Guideline for Future Agents
Use JunkBoxGridView.update_grid_size to dynamically calculate minimum row height and JunkBoxPanel.update_scroll_bar_visibility to toggle scrollbar mode and container margin padding.

---

### <a id="lrn-086"></a> LRN-086: relic_machinery
- **Task:** `TASK-053`
- **Category:** `game_balance`
- **Created:** `2026-09-02T16:05:33.087999`

#### Context & Problem
Audited relic machinery distribution across Tier 1, Tier 2, and Tier 3 relics.

#### Key Insight & Learning
Bash toys are high-reward elements that should be reserved for top tier relics.

#### Actionable Guideline for Future Agents
Assign high-rarity bash toys exclusively to Tier 3 relics while maintaining an even distribution of all 15 pinball widgets across lower tier relics.

---

### <a id="lrn-087"></a> LRN-087: hopper_ball_cascade_physics
- **Task:** `TASK-042`
- **Category:** `godot_engine`
- **Created:** `2026-09-02T16:09:12.243290`

#### Context & Problem
Balls dropped vertically at exact center with 0 velocity stacked in a rigid 1D column inside the hopper.

#### Key Insight & Learning
Symmetrical 2D circle physics with zero X velocity and high linear damp freezes balls in a vertical stack without rolling.

#### Actionable Guideline for Future Agents
Randomize ball spawn X offsets, apply small horizontal velocity nudges, and use low linear damp inside the hopper bin to ensure 2D cascading.

---

### <a id="lrn-088"></a> LRN-088: On-Board Relic Tooltip Simplification
- **Task:** `TASK-049`
- **Category:** `godot_engine`
- **Created:** `2026-09-02T16:17:19.150466`

#### Context & Problem
Reworking hover tooltips for polyomino relics on active pegboard layout

#### Key Insight & Learning
On-board hover tooltips should omit detailed specs like tier, size, and shape properties to avoid visual clutter

#### Actionable Guideline for Future Agents
Format on-board relic hover tooltips to show only activation requirements and relic effects while preserving full specs in shop and inventory cards.

---

### <a id="lrn-089"></a> LRN-089: relic_junk_box_return
- **Task:** `TASK-054`
- **Category:** `inventory_and_board_systems`
- **Created:** `2026-09-02T18:28:06.182119`

#### Context & Problem
Returning board polyomino relics to junk box inventory while cleanly clearing grid cells, restoring suppressed pegs, and removing passive effects.

#### Key Insight & Learning
Board.unslot_module must unsuppress pegs, clear cell occupancy, remove GameState passives, and reuse the original JunkBoxItem instance to retain level metadata.

#### Actionable Guideline for Future Agents
Always route board-to-inventory relic returns through Board.return_module_to_junk_box to ensure atomic peg restoration, passive cleanup, and metadata retention without duplicate items.

---

### <a id="lrn-090"></a> LRN-090: rotation
- **Task:** `TASK-055`
- **Category:** `machinery`
- **Created:** `2026-09-02T18:29:46.442226`

#### Context & Problem
Relic Machinery Rotation and Direction Vector Synchronization

#### Key Insight & Learning
Internal machinery components like GuideTrack, VerticalUpKicker, OutlaneKickback, ScoopSinkhole, BallLock, and MechanicalDiverter must transform exit offsets and launch vectors matching parent relic rotation.

#### Actionable Guideline for Future Agents
Always sync internal component direction properties when polyomino modules rotate, updating launch, eject, and offset vectors as well as ghost hover preview chevrons.

---

### <a id="lrn-091"></a> LRN-091: Dashboard Task Chronological Sorting
- **Task:** `TASK-TOOLING`
- **Category:** `tooling`
- **Created:** `2026-09-02T18:45:13.077114`

#### Context & Problem
Users expect kanban boards and task matrix columns to display the most recently updated tasks at the top rather than requiring scrolling down past older completed tasks.

#### Key Insight & Learning
Tracking task file mtime with task index/number fallback allows automatic chronological ordering in both generated static HTML and interactive browser client views without manual reordering in master markdown tables.

#### Actionable Guideline for Future Agents
In visual task boards, default to descending sort by modification timestamp and task ID so newly created and updated tasks are immediately visible at the top of each column.

---

### <a id="lrn-092"></a> LRN-092: Interactive Task Details Modal and Branch Command Sanitization
- **Task:** `TASK-056`
- **Category:** `tooling`
- **Created:** `2026-09-02T19:09:50.762025`

#### Context & Problem
When adding interactive task modals to the HTML visual task board that display packet details and allow copying checkout commands, raw markdown backticks around branch names break terminal shell execution in bash/zsh command substitution.

#### Key Insight & Learning
Always strip markdown formatting backticks from parsed branch names before generating clipboard shell commands and displaying branch labels, and provide graceful clipboard promise error handling for non-secure contexts.

#### Actionable Guideline for Future Agents
When parsing tabular metadata from markdown files for dashboard shell integrations, sanitize command strings by stripping backticks and wrapping clipboard write calls with error handlers.

---

### <a id="lrn-093"></a> LRN-093: Stationary combat terrain with synchronized wall advance tweens
- **Task:** `TASK-046`
- **Category:** `godot_engine`
- **Created:** `2026-09-02T19:19:01.542528`

#### Context & Problem
Implementing scrolling terrain and cannon breach movement for the right-panel BattlefieldView where combat must remain stationary, and animating Node tweens in headless unit tests

#### Key Insight & Learning
1) In Godot 4, Tween objects created on nodes outside the SceneTree automatically pause; nodes must be attached to the SceneTree root for custom_step() to step tweens synchronously in unit tests. 2) Custom properties tweened on stationary CanvasItems do not trigger _draw() unless queue_redraw() is conditionally polled in _process() while the tween is running. 3) Cannon positioning in BattlefieldView must support both reparented CanvasLayers and local node hierarchies for standalone/test support.

#### Actionable Guideline for Future Agents
When unit testing Tweens synchronously in headless test scripts, attach the test node to the active scene tree root (e.g. Engine.get_main_loop().root.add_child) and use autofree. When animating custom Node2D drawing properties via Tween, monitor tween.is_running() in _process to dispatch queue_redraw() even when overall movement speed is zero.

---

### <a id="lrn-094"></a> LRN-094: Pinball kinetic machinery subclass lifecycle and bonus energy dispatching
- **Task:** `TASK-051`
- **Category:** `godot_engine`
- **Created:** `2026-09-02T19:34:18.586500`

#### Context & Problem
Implementing missing pinball machinery subclasses (standup_target, spinner, orbit_loop, captive_ball, bash_toy) extending PolyominoMachineryComponent, ensuring super._process decay and full bonus energy propagation

#### Key Insight & Learning
1) When extending custom components that animate properties in _process (like _spring_scale decay and _spark_progress in PolyominoMachineryComponent), always call super._process(delta) in subclass overrides to avoid permanent visual distortion or frozen sparks. 2) When awarding bonus energy on breaking multi-hit targets (BashToy), temporarily boost base_energy before invoking super.trigger_activation() so ball.add_peg_energy(), component_activated signal emission, and result dictionaries all receive the full bonus consistently. 3) Initialize default component export properties in _init() as well as _ready() so unit tests that instantiate nodes outside the SceneTree immediately read correct values.

#### Actionable Guideline for Future Agents
Always invoke super._process(delta) in kinetic machinery subclasses to ensure base spring and spark decay animations run. Temporarily adjust base_energy for super.trigger_activation calls to ensure all downstream energy receivers and signals capture the total energy granted.

---

### <a id="lrn-095"></a> LRN-095: Embedding animated terrain art inside corner cannon widget
- **Task:** `TASK-046`
- **Category:** `ui`
- **Created:** `2026-09-03T08:01:38.807445`

#### Context & Problem
The Task 46 scrolling terrain was initially rendered on layer 0 in BattlefieldView, which was fully obscured by the opaque Junk Box panel on UILayer (layer 10), leaving the corner cannon widget drawing a flat dark rectangle.

#### Key Insight & Learning
1) Embedding a configurable ScrollingTerrain child inside CircularCannonWidget with show_behind_parent=true and clip_contents=true renders rich terrain art directly behind the cannon sprite without bleeding. 2) Synchronizing advance/stop signals via GameCoordinatorUI preserves Call-Down, Signal-Up architecture without cross-branch scene tree queries.

#### Actionable Guideline for Future Agents
Embed animated terrain or visual backdrops directly into UI container widgets with show_behind_parent=true and wire transition events through top-level coordinator signals instead of querying unrelated scene branches.

---

### <a id="lrn-096"></a> LRN-096: Removal of minion systems and dead combat references
- **Task:** `TASK-045`
- **Category:** `refactoring`
- **Created:** `2026-09-03T10:05:13.757062`

#### Context & Problem
Minions were deprecated in favor of a direct siege combat loop against fortifications and walls, leaving unused minion files and color constants.

#### Key Insight & Learning
Removing deprecated gameplay entity scripts and scenes requires auditing autoload constants, architecture documentation, and test suites to prevent dangling references.

#### Actionable Guideline for Future Agents
When removing deprecated gameplay mechanics, audit autoloads for orphaned helper methods and constants, update architecture docs, regenerate AI directory, and verify the full test suite.

---

### <a id="lrn-097"></a> LRN-097: Relic Pinball Widget Activation Binding and Charge Progress Telemetry
- **Task:** `TASK-048`
- **Category:** `gameplay_systems`
- **Created:** `2026-09-03T10:35:51.408287`

#### Context & Problem
Connecting polyomino relic trigger conditions directly to kinetic hits on integrated pinball machinery widgets while keeping tooltips uncluttered and file lengths strictly <= 500 lines.

#### Key Insight & Learning
Per-widget hit counts must be accumulated in PolyominoModuleNode and evaluated against explicit activation thresholds before triggering rewards and resetting counters. Drop targets knock down on hit, so bank evaluation must target distinct drop target components. In tooltips, slotted relics on the board should display concise live charge progress (X / Y) without duplicating inventory shape metadata.

#### Actionable Guideline for Future Agents
Store activation_requirement, required_widget_type, and activation_threshold in PolyominoModuleData with serialization. Draw dynamic radial arc gauges on interactive widgets during combat simulation. Keep PolyominoModuleNode <= 500 lines by compressing component instantiation match patterns.

---

### <a id="lrn-098"></a> LRN-098: Goblin Mood and Reset Hand Sprite Integration
- **Task:** `TASK-040`
- **Category:** `asset_resources`
- **Created:** `2026-09-03T10:42:06.468547`

#### Context & Problem
Replacing placeholder goblin art in comic vignette panels and reset effects.

#### Key Insight & Learning
Preloading Kenney Zombie character poses for mood states and Monster Builder arm sprites for grab effects provides rich visual feedback while retaining procedural draw fallbacks.

#### Actionable Guideline for Future Agents
Preload character pose textures in UI panels and monster limb sprites in custom effects, updating TextureRect or draw_texture_rect with procedural fallbacks.

---

### <a id="lrn-099"></a> LRN-099: Dashboard Kanban Drag and Drop Task Progression
- **Task:** `TASK-061`
- **Category:** `tooling`
- **Created:** `2026-09-03T10:57:54.669944`

#### Context & Problem
Adding interactive drag-and-drop to the dashboard to update task status in TASK-*.md and README.md

#### Key Insight & Learning
Using HTML5 drag events on cards with drop zones on Kanban columns connected to a local Python HTTP server allows browser-based task updates with zero dependencies and instant visual feedback.

#### Actionable Guideline for Future Agents
When adding local file write actions from a web dashboard, provide a lightweight localhost HTTP server with CORS headers so direct file:/// and localhost browser sessions can update project markdown files safely.

---
