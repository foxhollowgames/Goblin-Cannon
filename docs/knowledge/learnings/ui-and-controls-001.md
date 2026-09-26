# ui-and-controls

[Learning index](../LEARNINGS.md)

## <a id="lrn-023"></a> LRN-023: Dynamic Grab Offset Preservation on Polyomino Relic In-Flight Rotation
- **Task:** TASK-031
- **Category:** ui_and_controls
- **Created:** 2026-08-29T13:03:46.937896
- **Tags:** 

### Context
When dragging multi-cell polyomino relics on the board, 90-degree rotations change the local cell offsets of the shape relative to the top-left anchor.

### Learning
Storing the grabbed cell index and querying the anchored rotated shape at that index keeps the exact grabbed cell pinned to the cursor during in-flight rotation.

### Guideline
Always track the grabbed cell index during drag initiation and dynamically compute the rotated cell offset using get_anchored_rotated_cells.

