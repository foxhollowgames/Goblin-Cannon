# godot-engine

[Learning index](../LEARNINGS.md)

## <a id="lrn-001"></a> LRN-001: Headless Preload & Circular Class References
- **Task:** TASK-027
- **Category:** godot_engine
- **Created:** 2026-08-28T19:53:34.239466
- **Tags:** 

### Context
In Godot 4 headless mode, classes with static factory methods or autoloads that reference class_name types directly can fail to compile due to circular dependency or load order issues.

### Learning
Godot headless script compilation parses classes before all global class_name symbols are resolved in the cache. Static methods returning self-types or autoloads with typed properties can throw cyclic load or undefined type errors.

### Guideline
Use explicit 'const MyType = preload(...)' in autoloads and UI panels when referring to custom resources. In static factory methods (e.g. from_dict), return base Resource or untyped value to avoid circular self-references.

## <a id="lrn-005"></a> LRN-005: Multi-Cell Polyomino Coordinate Anchoring & Clockwise Rotation
- **Task:** TASK-024
- **Category:** godot_engine
- **Created:** 2026-08-28T19:53:44.532082
- **Tags:** 

### Context
Rotating 2D grid polyominoes (rx = -y, ry = x) can produce negative local coordinate offsets, which break standard grid slot indexing (0..N-1).

### Learning
Standard mathematical 2D rotation around origin maps positive coordinates to negative ones (e.g. (1, 0) rotated 90° CW -> (0, -1) in Godot's Y-down coordinate space, or (0, 1) -> (-1, 0)).

### Guideline
Always apply bounding-box offset normalization after rotating: compute min_x and min_y of the rotated cell set, then subtract them (rx - min_x, ry - min_y) so the top-left-most cell is strictly anchored at (0, 0).

## <a id="lrn-006"></a> LRN-006: Headless Viewport & Mouse Position Safety
- **Task:** TASK-025
- **Category:** godot_engine
- **Created:** 2026-08-28T20:04:48.934574
- **Tags:** 

### Context
Calling get_global_mouse_position() on Controls outside the active SceneTree/Viewport causes engine error spam during headless testing.

### Learning
Controls instantiated directly in headless tests or before add_child() lack a viewport reference, causing get_global_mouse_position() to fail.

### Guideline
Always wrap mouse position lookups with a safe helper like 'if is_inside_tree() and get_viewport(): return get_global_mouse_position()' with Vector2.ZERO fallback.

## <a id="lrn-008"></a> LRN-008: Headless Node Hierarchy and Lazy Container Initialization
- **Task:** TASK-026
- **Category:** godot_engine
- **Created:** 2026-08-28T21:47:28.496565
- **Tags:** 

### Context
Standalone nodes instantiated in unit tests without add_child or _ready lack viewport and parent transforms, and child containers initialized in _ready remain null.

### Learning
In Godot 4 headless tests, nodes created with .new do not run _ready automatically. Container nodes like _modules_container must be lazily initialized when used, and component positions must fall back to local position math when is_inside_tree is false.

### Guideline
Lazily initialize child containers on first access in manager and board scripts, and check is_inside_tree before querying global_position to support headless unit tests.

## <a id="lrn-009"></a> LRN-009: Live Board Ghost Placement Area Monitoring & Collision Transition
- **Task:** TASK-020
- **Category:** godot_engine
- **Created:** 2026-08-28T21:58:52.513594
- **Tags:** 

### Context
Placing and moving components during live Plinko ball simulation requires safe non-colliding ghost states to prevent trapping or teleporting balls.

### Learning
Newly positioned components must start at 50% opacity with collision_layer set to 0. Area monitoring with bounding box margin checks (cell_rect.grow(BALL_RADIUS + 2.0)) allows seamless transition to solid state once all balls exit.

### Guideline
Always disable physics collision layers on newly placed components until active ball area checks confirm complete clearance.

## <a id="lrn-012"></a> LRN-012: Polyomino Relic Database & ID Alias Mapping
- **Task:** TASK-024
- **Category:** godot_engine
- **Created:** 2026-08-28T22:19:51.267579
- **Tags:** 

### Context
Relics have multiple upgrade categories across boss amplifiers, cross-link wall breaks, single-type enhancements, and chest passives, with minor ID spelling discrepancies in legacy code (e.g. arc_surge_wrench vs chain_surge_wrench).

### Learning
Using a centralized PolyominoRelicDatabase registry with canonical definitions and an ID alias resolution table ensures both legacy upgrade names and spec-compliant relic IDs resolve cleanly to the correct PolyominoModuleData and JunkBoxItem instances.

### Guideline
Always route polyomino module creation through PolyominoRelicDatabase with alias resolution to ensure backwards compatibility across reward handlers, catalogs, and inventory systems.

## <a id="lrn-013"></a> LRN-013: Slotted Board Relic Modifiers & Instant Hover Tooltips
- **Task:** TASK-028
- **Category:** godot_engine
- **Created:** 2026-08-29T07:52:50.756837
- **Tags:** 

### Context
Relic passive effects must not activate immediately upon drafting into the inventory; they must apply only when the module is slotted on the active board grid, deactivate cleanly on unslot, and show instant tooltips on mouse hover.

### Learning
Binding GameState relic modifier application and reversion directly to Board.place_module() and Board.unslot_module() guarantees state consistency, while KeywordDatabase.show_flyout_custom() provides instant, boundary-clamped hover tooltips for placed board modules.

### Guideline
Always tie passive stat buffs and relic modifier lifecycles to physical board placement rather than inventory possession, and use KeywordDatabase for consistent in-game flyout tooltips.

## <a id="lrn-024"></a> LRN-024: Drag Controller Overlay Hierarchy and Control Mouse Filter Pass-Through
- **Task:** TASK-031
- **Category:** godot_engine
- **Created:** 2026-08-29T17:19:00.222062
- **Tags:** 

### Context
When initiating dragging from board Node2D elements, parent container Controls with default mouse_filter MOUSE_FILTER_STOP swallow clicks, and children of hidden UI panels hide visual ghost previews.

### Learning
Setting mouse_filter to MOUSE_FILTER_IGNORE on layout containers allows clicks through to _input handlers. Parenting drag controllers directly to the top-level CanvasLayer keeps ghost preview overlays visible even when sibling drawer panels are closed.

### Guideline
Always set mouse_filter to IGNORE on full-screen container controls and mount global drag preview controllers on top-level CanvasLayers.

## <a id="lrn-029"></a> LRN-029: Polyomino Relic Pinball Goals and Reward Dispatching
- **Task:** TASK-049
- **Category:** godot_engine
- **Created:** 2026-08-29T23:07:06.524921
- **Tags:** 

### Context
Relics need self-contained pinball objectives and board rewards without bloating board.gd line limits.

### Learning
PolyominoModuleNode tracks cell hits and progress counters locally while delegating reward execution to PolyominoGoalRewardHandler, keeping Board.gd well under line limits.

### Guideline
Keep Board.gd lean by delegating specialized mechanic triggers to standalone handlers and use PolyominoModuleNode runtime state for compound shape tracking.

## <a id="lrn-031"></a> LRN-031: Board Scene Sub-Manager Decomposition and VFX Pooling Lifecycle
- **Task:** TASK-BOARD-DECOMP-01
- **Category:** godot_engine
- **Created:** 2026-08-31T22:22:05.866330
- **Tags:** 

### Context
Extracting large script responsibilities into modular sub-managers requires strict pooling lifecycle management and explicit scene setup API calls.

### Learning
When preallocating UI nodes or VFX objects in sub-managers, call set_process(false), bind set_pool_release(release_cb), and reset modulate/transform on release and reuse to prevent auto-destruction and color contamination.

### Guideline
Always wire object pool release callbacks during preallocation in sub-managers and reset instance properties in get_from_pool.

## <a id="lrn-032"></a> LRN-032: GameCoordinator Sub-Manager Decomposition
- **Task:** TASK-COORD-DECOMP-01
- **Category:** godot_engine
- **Created:** 2026-09-01T08:38:03.790138
- **Tags:** 

### Context
Extracting coordinator responsibilities into debug, ball manager, and flow controller sub-managers.

### Learning
Sub-manager scripts that do not render 2D content must extend Node not Node2D. Always verify callback method names match the actual parent script signatures before wiring delegation calls.

### Guideline
Use find_child for dynamically-instantiated modal lookups instead of fixed node paths.

## <a id="lrn-033"></a> LRN-033: Peg Drawing Static Class Extraction
- **Task:** TASK-PEG-DECOMP-01
- **Category:** godot_engine
- **Created:** 2026-09-01T08:43:36.541289
- **Tags:** 

### Context
Peg drawing methods run on the same CanvasItem and cannot move to a child Node.

### Learning
Use static RefCounted classes (PegKindDrawing, PegDrawing) that accept the CanvasItem as a parameter to extract draw routines without breaking the Godot _draw() lifecycle.

### Guideline
For CanvasItem draw extraction, prefer static utility classes that accept ci: CanvasItem rather than composition nodes.

## <a id="lrn-034"></a> LRN-034: RewardDraftPanel UI Component Extraction via Ollama
- **Task:** TASK-REWARD-DRAFT-01
- **Category:** godot_engine
- **Created:** 2026-09-01T15:28:08.377561
- **Tags:** 

### Context
Extracting UI component markers and static card builders from RewardDraftPanel.

### Learning
Dynamic script loading (load()) for static helper classes prevents class_name symbol resolution cache errors during headless unit test execution.

### Guideline
Use dynamic script loading for extracted RefCounted UI builders to ensure zero symbol cache conflicts.

## <a id="lrn-035"></a> LRN-035: GameCoordinator UI Sub-Manager Extraction
- **Task:** TASK-COORD-UI-01
- **Category:** godot_engine
- **Created:** 2026-09-01T15:47:13.912272
- **Tags:** 

### Context
Extracting UI creation and modal toggle methods from GameCoordinator.

### Learning
GameCoordinator UI sub-managers reduce coordinator responsibilities by delegating modal toggles and UI creation callbacks.

### Guideline
Keep UI creation and modal management logic in GameCoordinatorUI.

## <a id="lrn-036"></a> LRN-036: GameCoordinator Full Sub-Manager Refactoring
- **Task:** TASK-COORD-DECOMP-02
- **Category:** godot_engine
- **Created:** 2026-09-01T16:00:49.081229
- **Tags:** 

### Context
Decomposing GameCoordinator into modular sub-managers.

### Learning
GameCoordinator can delegate UI, screen building, input, signals, test scenarios, and ball inventory to sub-managers to achieve full modularity.

### Guideline
Keep sub-manager responsibilities tightly scoped to maintain source files under 500 lines.

## <a id="lrn-038"></a> LRN-038: Shop card VBox attachment and marker script path
- **Task:** FIX-SHOP-ICONS
- **Category:** godot_engine
- **Created:** 2026-09-01T18:45:19.156318
- **Tags:** 

### Context
Shop cards displayed empty frames without title, icon, or description rendering

### Learning
RewardCardBuilder.make_shop_card_layer omitted layer.add_child(card_vbox), leaving card_vbox un-parented in the scene tree

### Guideline
Always ensure container layout builder functions attach created child VBoxContainer nodes to their parent layer before returning.

## <a id="lrn-040"></a> LRN-040: GDScript Void Return Parse Errors
- **Task:** FIX-POLYOMINO-PARSER
- **Category:** godot_engine
- **Created:** 2026-09-01T22:07:23.753398
- **Tags:** 

### Context
A void return function returning a value in GDScript causes a parse error that breaks preloaded scripts across the engine.

### Learning
Functions returning void must return cleanly without returning values.

### Guideline
Check that functions returning void do not return expressions, especially when modifying array parameters by reference.

## <a id="lrn-087"></a> LRN-087: hopper_ball_cascade_physics
- **Task:** TASK-042
- **Category:** godot_engine
- **Created:** 2026-09-02T16:09:12.243290
- **Tags:** 

### Context
Balls dropped vertically at exact center with 0 velocity stacked in a rigid 1D column inside the hopper.

### Learning
Symmetrical 2D circle physics with zero X velocity and high linear damp freezes balls in a vertical stack without rolling.

### Guideline
Randomize ball spawn X offsets, apply small horizontal velocity nudges, and use low linear damp inside the hopper bin to ensure 2D cascading.

## <a id="lrn-088"></a> LRN-088: On-Board Relic Tooltip Simplification
- **Task:** TASK-049
- **Category:** godot_engine
- **Created:** 2026-09-02T16:17:19.150466
- **Tags:** 

### Context
Reworking hover tooltips for polyomino relics on active pegboard layout

### Learning
On-board hover tooltips should omit detailed specs like tier, size, and shape properties to avoid visual clutter

### Guideline
Format on-board relic hover tooltips to show only activation requirements and relic effects while preserving full specs in shop and inventory cards.

## <a id="lrn-093"></a> LRN-093: Stationary combat terrain with synchronized wall advance tweens
- **Task:** TASK-046
- **Category:** godot_engine
- **Created:** 2026-09-02T19:19:01.542528
- **Tags:** 

### Context
Implementing scrolling terrain and cannon breach movement for the right-panel BattlefieldView where combat must remain stationary, and animating Node tweens in headless unit tests

### Learning
1) In Godot 4, Tween objects created on nodes outside the SceneTree automatically pause; nodes must be attached to the SceneTree root for custom_step() to step tweens synchronously in unit tests. 2) Custom properties tweened on stationary CanvasItems do not trigger _draw() unless queue_redraw() is conditionally polled in _process() while the tween is running. 3) Cannon positioning in BattlefieldView must support both reparented CanvasLayers and local node hierarchies for standalone/test support.

### Guideline
When unit testing Tweens synchronously in headless test scripts, attach the test node to the active scene tree root (e.g. Engine.get_main_loop().root.add_child) and use autofree. When animating custom Node2D drawing properties via Tween, monitor tween.is_running() in _process to dispatch queue_redraw() even when overall movement speed is zero.

## <a id="lrn-094"></a> LRN-094: Pinball kinetic machinery subclass lifecycle and bonus energy dispatching
- **Task:** TASK-051
- **Category:** godot_engine
- **Created:** 2026-09-02T19:34:18.586500
- **Tags:** 

### Context
Implementing missing pinball machinery subclasses (standup_target, spinner, orbit_loop, captive_ball, bash_toy) extending PolyominoMachineryComponent, ensuring super._process decay and full bonus energy propagation

### Learning
1) When extending custom components that animate properties in _process (like _spring_scale decay and _spark_progress in PolyominoMachineryComponent), always call super._process(delta) in subclass overrides to avoid permanent visual distortion or frozen sparks. 2) When awarding bonus energy on breaking multi-hit targets (BashToy), temporarily boost base_energy before invoking super.trigger_activation() so ball.add_peg_energy(), component_activated signal emission, and result dictionaries all receive the full bonus consistently. 3) Initialize default component export properties in _init() as well as _ready() so unit tests that instantiate nodes outside the SceneTree immediately read correct values.

### Guideline
Always invoke super._process(delta) in kinetic machinery subclasses to ensure base spring and spark decay animations run. Temporarily adjust base_energy for super.trigger_activation calls to ensure all downstream energy receivers and signals capture the total energy granted.

## <a id="lrn-102"></a> LRN-102: RichTextLabel Flyout Tooltip BBCode Formatting
- **Task:** TASK-057
- **Category:** godot_engine
- **Created:** 2026-09-03T13:48:36.086344
- **Tags:** 

### Context
KeywordDatabase flyout tooltip used a plain Label for _flyout_body which showed raw [u] and other BBCode markup tags when displaying board relic descriptions.

### Learning
RichTextLabel with bbcode_enabled=true and fit_content=true parses BBCode tags like [u] and [b] cleanly while get_parsed_text strips tags for clean string assertion.

### Guideline
Use RichTextLabel with bbcode_enabled=true, fit_content=true, and MOUSE_FILTER_IGNORE for hover tooltip bodies that display formatted headers or highlighted keywords.

## <a id="lrn-109"></a> LRN-109: Junk Box Manual Relic Placement and Controller Lifecycle
- **Task:** TASK-066
- **Category:** godot_engine
- **Created:** 2026-09-03T15:09:02.068092
- **Tags:** 

### Context
Relics in the Junk Box could not move internally due to cell size mismatch and multiple active drag controllers in headless tests.

### Learning
JunkBoxDragController must calculate positions from JunkBoxGridView cell size and clean up child controllers when JunkBoxPanel exits the scene tree.

### Guideline
Always retrieve cell size from the grid view and free auxiliary controllers during _exit_tree.

## <a id="lrn-131"></a> LRN-131: Idle hopper ball duplication and Area2D/exit lifecycles
- **Task:** TASK-090
- **Category:** godot_engine
- **Created:** 2026-09-12T16:06:42.372569
- **Tags:** 

### Context
During idle runs, balls multiplied from 10 to 50+ in the hopper. Falling balls crossing Area2D boundaries near the hopper gate re-triggered bin overlap checks, while Board._active_balls appended balls without uniqueness checks and GameBallManager handled bottom exits without checking is_queued_for_deletion.

### Learning
Area2D overlap syncing must distinguish actively released rigidbodies to prevent re-entering storage lists. Furthermore, ball exit handlers and active collections in Board must check is_queued_for_deletion() and guard against duplicate exit events with metadata flags, ensuring flags like is_exiting_board are reset if mechanics like Fragment Echo recycle the ball.

### Guideline
Always track released physics bodies when using Area2D boundary triggers, guard on_ball_exited callbacks against is_queued_for_deletion and repeat calls via node metadata, and clean up metadata when recycling bodies.

## <a id="lrn-132"></a> LRN-132: Headless texture preloading and GDScript match pattern constants
- **Task:** TASK-091
- **Category:** godot_engine
- **Created:** 2026-09-12T16:20:57.874959
- **Tags:** 

### Context
Preloading unimported asset pack PNGs or referencing autoload members in GDScript match statements causes compile-time parse failures.

### Learning
Godot headless execution requires preloaded assets to have generated .ctex files in .godot/imported. Additionally, GDScript match statements only accept compile-time literals and local script const values, not autoload singleton member accesses.

### Guideline
Always verify textures are compiled in .godot/imported before using preload(), and use local script constants (const CONST_NAME = ...) instead of Autoload.CONST in match patterns.

## <a id="lrn-133"></a> LRN-133: Orphan Fallback Widget Instantiation and 2D CanvasItem Layering
- **Task:** TASK-092
- **Category:** godot_engine
- **Created:** 2026-09-12T21:00:40.459977
- **Tags:** 

### Context
When moving UI widgets into a top bar layout, an orphan fallback block dynamically created CircularCannonWidget at (0,0) on UILayer drawing a green border (#5d7545). Additionally, the Hopper world node (z_index=10) overlapped the top banner.

### Learning
Dynamically instantiating fallback UI controls on CanvasLayer can create ghost panels if layout scenes are reworked. For layering 2D scene items against playfield elements, explicitly configure z_index (e.g. BattlefieldView z_index=20 > Hopper z_index=10) so dividing ledges cleanly mask lower items.

### Guideline
Audit all dynamic UI coordinator instantiation paths when deprecating or moving UI widgets. Use CanvasItem z_index ordering to ensure top-bar framing renders in front of playfield physics elements.

## <a id="lrn-134"></a> LRN-134: Diegetic pinball machinery and component state isolation
- **Task:** TASK-093
- **Category:** godot_engine
- **Created:** 2026-09-13T16:59:58.382232
- **Tags:** 

### Context
PolyominoDiegeticRenderer previously queried internal private module node dictionaries (_dropped_targets, _lit_rollovers) which caused fatal crashes when rendering drop targets and rollover switches, and duplicate text rendering between components and diegetic overlays.

### Learning
Subcomponents such as DropTarget, RolloverSwitch, and WireGate already encapsulate and manage their own live states (is_dropped, is_lit, retained_balls). Querying component-level properties directly prevents coupling and crashes. Letter rendering should be owned solely by the component body to avoid blurry double-draws.

### Guideline
When authoring diegetic visual overlays, always inspect typed component properties directly rather than module-level shadow dictionaries, ensure components exclusively own their local glyph drawing, and write automated tests that trigger NOTIFICATION_DRAW to catch drawing crashes.

## <a id="lrn-138"></a> LRN-138: Polyomino shop card preview and description formatting
- **Task:** TASK-097
- **Category:** godot_engine
- **Created:** 2026-09-17T11:04:35.467197
- **Tags:** 

### Context
Relic shop cards lacked polyomino shape previews and consistent kinetic machinery descriptions.

### Learning
Embedding RelicLayoutPreview in CenterContainer with clamped cell sizes (7-13px) and 160px card height eliminates text and graphic clipping across diverse polyomino footprints.

### Guideline
Use RewardCardBuilder.make_relic_shop_preview with CenterContainer and PolyominoRelicDatabase.get_relic_shop_description for shop relic cards.

