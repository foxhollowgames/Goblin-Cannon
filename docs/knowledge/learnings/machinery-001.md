# machinery

[Learning index](../LEARNINGS.md)

## <a id="lrn-044"></a> LRN-044: Pinball Kinetic Machinery and Rollover Bank Completion
- **Task:** TASK-036
- **Category:** machinery
- **Created:** 2026-09-01T22:30:16.136168
- **Tags:** 

### Context
Kinetic pinball devices (rollovers, pop bumpers, drop targets, wire gates, slingshots) require distinct component scripts and rollover bank triggers.

### Learning
RolloverSwitch devices emit bank_completed signals on full bank illumination when set_lit is updated prior to trigger_activation signal emissions.

### Guideline
Use PolyominoModuleData.CellType for pinball component types and verify rollover bank state via cell_type matching in PolyominoModuleNode.

## <a id="lrn-090"></a> LRN-090: rotation
- **Task:** TASK-055
- **Category:** machinery
- **Created:** 2026-09-02T18:29:46.442226
- **Tags:** 

### Context
Relic Machinery Rotation and Direction Vector Synchronization

### Learning
Internal machinery components like GuideTrack, VerticalUpKicker, OutlaneKickback, ScoopSinkhole, BallLock, and MechanicalDiverter must transform exit offsets and launch vectors matching parent relic rotation.

### Guideline
Always sync internal component direction properties when polyomino modules rotate, updating launch, eject, and offset vectors as well as ghost hover preview chevrons.

## <a id="lrn-112"></a> LRN-112: pop_bumper_energy_tuning
- **Task:** TASK-070
- **Category:** machinery
- **Created:** 2026-09-04T09:25:49.869037
- **Tags:** 

### Context
The Pop Bumper granted 8 energy upon collision, which was too high for combat balance.

### Learning
Setting base_energy in both _init and _ready initializes component properties consistently for in-tree and out-of-tree nodes.

### Guideline
Initialize machinery component base_energy and type properties in both _init and _ready to support all test cases.

## <a id="lrn-120"></a> LRN-120: Wire Gate Downward Retention and Cascade Release
- **Task:** TASK-080
- **Category:** machinery
- **Created:** 2026-09-09T18:59:56.351894
- **Tags:** 

### Context
TASK-080 required changing the wire gate from a one-way backflow blocker into a retentive holding barrier with cascade release.

### Learning
Holding cup components require continuous position anchoring during physics process and explicit exit debounce ticks.

### Guideline
When building retentive holding machinery, hold trapped ball positions explicitly in process and clear exit records on cascade release.

## <a id="lrn-125"></a> LRN-125: wire gate holding cup
- **Task:** TASK-083
- **Category:** machinery
- **Created:** 2026-09-10T13:55:12.014912
- **Tags:** 

### Context
Reworking wire gate to serve as component holding cup with activation requirement gate control

### Learning
Connecting wire gate release directly to module activation requirements allows multi-cell components to store balls safely during play without pinning them to a single point, then cascade release upon goal satisfaction

### Guideline
Always constrain retained balls using soft boundary checks rather than fixing coordinates to a single point, and link gate opening to module goal completion

## <a id="lrn-139"></a> LRN-139: Slingshot triangle bumper rotational geometry transformation
- **Task:** TASK-098
- **Category:** machinery
- **Created:** 2026-09-17T11:19:11.975556
- **Tags:** 

### Context
Triangle bumpers inside polyomino modules remained in static orientation when the module was rotated.

### Learning
Polyomino modules rotate via 90-degree clockwise steps. Preserving immutable base vertices and computing segment_p1, segment_p2, and corner_p3 using (x, y) -> (-y, x) ensures triangle borders, visual polygons, collision SegmentShape2D, and impulse vectors rotate synchronously with polyomino modules.

### Guideline
Pass rotation_step to all child components in PolyominoModuleNode and transform base segment and corner vertices using 90-degree step rotation.

