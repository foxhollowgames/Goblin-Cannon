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
