# visual-effects

[Learning index](../LEARNINGS.md)

## <a id="lrn-129"></a> LRN-129: Intervention Visuals
- **Task:** TASK-088
- **Category:** Visual Effects
- **Created:** 2026-09-10T21:03:52.278228
- **Tags:** 

### Context
Replacing procedural graphics on event pegs with high-quality sprites and animated spritesheets

### Learning
Preload dedicated asset sprites and spritesheets in preview and break effect nodes. Delegate complex peg draw routines to PegKindDrawing to keep peg.gd and board.gd below line limits.

### Guideline
Keep visual effect scenes self-contained with explicit type annotations, and manage memory with queue_free on timers.

