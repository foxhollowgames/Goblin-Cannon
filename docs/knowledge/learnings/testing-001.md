# testing

[Learning index](../LEARNINGS.md)

## <a id="lrn-041"></a> LRN-041: Godot Test Runner Parse Failure Isolation
- **Task:** TASK-TEST-FRAMEWORK-PARSE-ISOLATION
- **Category:** testing
- **Created:** 2026-09-01T22:23:52.871539
- **Tags:** 

### Context
Top-level static preloads in test runner files cause full test suite compilation failures when preloaded scripts have syntax errors.

### Learning
Dynamic script loading via load() inside test runner methods isolates script parse failures and prevents whole suite blockages.

### Guideline
Always load test dependencies dynamically inside test methods and include a headless script parse smoke pass in linter tooling.

## <a id="lrn-135"></a> LRN-135: Deliberate Relic Tier Cell Count Constraints and Modular Catalogs
- **Task:** TASK-094
- **Category:** testing
- **Created:** 2026-09-13T18:19:28.475422
- **Tags:** 

### Context
When implementing 42 deliberate relics across 7 archetypes and 3 tiers and hooking into PolyominoRelicDatabase, tier cell count assertions in test_polyomino_relic_shapes.gd caught a mismatch where a Tier 2 definition had 12 cells.

### Learning
Polyomino tier conventions strictly require cell counts to match tier ranges (T1: 4-6, T2: 6-9, T3: 9-14). Defining deliberate relics in an isolated catalog preloaded by the main database prevents huge files (>500 lines) and keeps both catalog and database compliant with Rule 7.

### Guideline
Always audit cell counts against tier boundaries (T1: 4-6, T2: 6-9, T3: 9-14) for any polyomino relic. Keep catalogs modularized into separate files preloaded by PolyominoRelicDatabase to maintain files under 500 lines.

## <a id="lrn-145"></a> LRN-145: Temporary relic ball lifecycle needs outcome tests
- **Task:** TASK-107
- **Category:** testing
- **Created:** 2026-09-24T18:40:57.841918
- **Tags:** 

### Context
The first lifecycle extraction passed mapping and marker tests, but review found that direct spawn tests did not exercise queue allocation, cancellation, capture cleanup, or split behavior.

### Learning
Temporary reward tests must drive queue_reward and controller process ticks, verify cancellation counts and blocked timeouts, route exits through controller cleanup, and assert energy and expiry inheritance for temporary Binary fragments.

### Guideline
For temporary ball changes, add production queue, blocked outlet, one-time collection, capture-owner, and odd-energy conservation tests before marking the task complete. Use the raw Godot exit code and final total as the authority.

