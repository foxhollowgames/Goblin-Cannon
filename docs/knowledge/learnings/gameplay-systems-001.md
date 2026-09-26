# gameplay-systems

[Learning index](../LEARNINGS.md)

## <a id="lrn-097"></a> LRN-097: Relic Pinball Widget Activation Binding and Charge Progress Telemetry
- **Task:** TASK-048
- **Category:** gameplay_systems
- **Created:** 2026-09-03T10:35:51.408287
- **Tags:** 

### Context
Connecting polyomino relic trigger conditions directly to kinetic hits on integrated pinball machinery widgets while keeping tooltips uncluttered and file lengths strictly <= 500 lines.

### Learning
Per-widget hit counts must be accumulated in PolyominoModuleNode and evaluated against explicit activation thresholds before triggering rewards and resetting counters. Drop targets knock down on hit, so bank evaluation must target distinct drop target components. In tooltips, slotted relics on the board should display concise live charge progress (X / Y) without duplicating inventory shape metadata.

### Guideline
Store activation_requirement, required_widget_type, and activation_threshold in PolyominoModuleData with serialization. Draw dynamic radial arc gauges on interactive widgets during combat simulation. Keep PolyominoModuleNode <= 500 lines by compressing component instantiation match patterns.

