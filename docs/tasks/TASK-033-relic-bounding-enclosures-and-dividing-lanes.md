# TASK-033: Relic Bounding Enclosures, Perimeter Walls, and Dividing Lanes

- **Status:** READY
- **Priority:** P1
- **Category:** Systems / Gameplay / Physics
- **Target Branch:** `feature/relic-bounding-enclosures`
- **Related Tasks:** [TASK-024](TASK-024-polyomino-relic-shapes-and-sizes.md), [TASK-026](TASK-026-polyomino-internal-machinery-and-bumpers.md), [TASK-030](TASK-030-relic-placement-peg-replacement-and-overlap-prevention.md)

## Description

Define perimeter wall enclosures, guide funnels, and internal dividing lanes for polyomino relics.
Enable relics to guide, channel, or divide ball movement physically across the board grid.

---

## Requirements

### 1. Wall and Enclosure Data Model
- Add boundary and wall definitions to `PolyominoModuleData` and `PolyominoRelicDatabase`.
- Support multiple enclosure architectures:
  - `OPEN_FRAME`: Open edges on all sides with unconstrained ball access.
  - `FULL_ENCLOSURE`: Solid perimeter walls surrounding all outer cell boundaries.
  - `DIRECTIONAL_FUNNEL`: Solid side walls with designated top and bottom openings.
  - `DIVIDED_LANES`: Internal partition walls between cell columns or rows to create distinct channels.

### 2. Edge Collision Segment Generation
- Generate static physics collision segments along configured outer edges and internal dividers.
- Ensure that edge colliders rotate accurately with module rotation steps (0 to 3).
- Align edge coordinates with the standard board grid cell boundaries.

### 3. Visual Wall and Divider Rendering
- Draw bold comic style outline borders on all solid perimeter walls.
- Draw distinct dividing lines between internal lanes.
- Render visible entry and exit ports on funnel enclosures.

### 4. Ball Physics Interaction
- Ensure that active balls bounce cleanly off solid outer walls and internal partition dividers.
- Ensure that funnel relics channel incoming balls through intended paths.

### 5. Automated Tests
- Add headless unit tests in `tests/test_relic_enclosures.gd`.
- Test that wall configurations load and rotate accurately.
- Test that collision segments generate on the correct cell boundaries.

---

## Acceptance Criteria

- [ ] Relic definitions specify outer wall enclosures and internal dividing lines.
- [ ] Edge collision segments generate on solid borders and rotate cleanly.
- [ ] Funnel relics guide balls through entrance and exit openings.
- [ ] Visual comic outlines render on all solid wall boundaries.
- [ ] Headless unit tests verify enclosure definitions and collision generation.
