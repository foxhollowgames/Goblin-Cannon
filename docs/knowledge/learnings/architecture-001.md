# architecture

[Learning index](../LEARNINGS.md)

## <a id="lrn-037"></a> LRN-037: game_coordinator_decomposition
- **Task:** Decompose large source files
- **Category:** Architecture
- **Created:** 2026-09-01T16:18:09.032806
- **Tags:** 

### Context
All repository source files required to be under 500 lines

### Learning
Decomposed GameCoordinator, RewardHandler, and RewardDraftPanel into modular static helpers and sub-managers

### Guideline
Keep source files under 500 lines by delegating specialized sub-tasks to dedicated helper classes

## <a id="lrn-143"></a> LRN-143: Separate physical relic ownership from passive effects
- **Task:** TASK-101
- **Category:** architecture
- **Created:** 2026-09-23T00:37:36.403350
- **Tags:** 

### Context
Relic placement registered legacy upgrade stacks; UI quantities depended on those stacks.

### Learning
Inert legacy inputs prevent old data from restoring bonuses. Physical inventory and board items are the ownership source.

### Guideline
Remove passive consumers and offers together. Count physical items across inventory and board; test sibling scene lookups and update glossary text.

