# physics

[Learning index](../LEARNINGS.md)

## <a id="lrn-039"></a> LRN-039: polyomino relic enclosures
- **Task:** TASK-033
- **Category:** physics
- **Created:** 2026-09-01T22:06:22.817285
- **Tags:** 

### Context
Implementing wall enclosures and funnel collision

### Learning
Polyomino module wall enclosures generate cell boundary edge line segments rotated via posmod steps.

### Guideline
Use get_solid_edge_segments to calculate edge colliders for polyomino enclosures.

## <a id="lrn-140"></a> LRN-140: Exclusive ball control and shared passage geometry
- **Task:** TASK-093
- **Category:** physics
- **Created:** 2026-09-17T13:36:20.115132
- **Tags:** 

### Context
Review of PR 76 found overlapping track captures and orbit mouths missing from placement checks.

### Learning
Two devices can capture one ball before the first reaches its outlet. The second then saves zero gravity and can leave the released ball weightless. Device ports must also come from the same route used at runtime.

### Guideline
Use one shared owner per captured ball. Restore physics state on release or removal. Derive preview ports and placement checks from runtime geometry. Test adjacent device handoffs with real physics, one completion each, and restored gravity. See relic_ball_flow.gd, relic_flow_geometry.gd, and run_relic_flow_physics.gd.

