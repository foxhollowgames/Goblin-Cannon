# ui-and-visuals

[Learning index](../LEARNINGS.md)

## <a id="lrn-141"></a> LRN-141: Single Source of Truth Polyomino Relic UI Rendering
- **Task:** TASK-099
- **Category:** ui_and_visuals
- **Created:** 2026-09-18T20:04:10.824222
- **Tags:** 

### Context
UI panels (JunkBoxGridView, drag ghost controller, and RelicLayoutPreview) previously relied on separate schematic canvas drawing methods (PolyominoMachineryVisuals, chevrons, circles) that omitted authentic board visual elements like flow conduit paths, port arrows, rollover switch letters, and triangle bumpers.

### Learning
Instantiating PolyominoModuleNode in ghost mode (set_ghost_state(true, alpha)) with collision disabled (collision_layer = 0) and scaling to cell dimensions provides 100% pixel-perfect equivalence to the live board with zero duplicate visual code.

### Guideline
Never maintain separate drawing or glyph routines for relics; always instantiate PolyominoModuleNode in ghost mode scaled to the container cell bounds for inventory, previews, and drag feedback.

