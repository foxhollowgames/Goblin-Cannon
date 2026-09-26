# inventory-and-ui-systems

[Learning index](../LEARNINGS.md)

## <a id="lrn-108"></a> LRN-108: Junk Box Manual Relic Placement and Self-Exclusion
- **Task:** TASK-066
- **Category:** inventory_and_ui_systems
- **Created:** 2026-09-03T15:08:39.720779
- **Tags:** 

### Context
Repositioning polyomino relics inside junk box inventory requires in-flight rotation, accurate grid cell sizing (46px), and collision self-exclusion.

### Learning
When moving a relic to a nearby cell, target cells can overlap its own origin cells. Supplying the item instance ID to can_place_item excludes the item from self-collision, and querying get_cell_size aligns the ghost preview.

### Guideline
Always pass the active item instance ID to inventory can_place_item to allow self-exclusion, and fetch the cell dimension dynamically from JunkBoxGridView.get_cell_size.

