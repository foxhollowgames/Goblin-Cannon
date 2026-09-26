# systems

[Learning index](../LEARNINGS.md)

## <a id="lrn-116"></a> LRN-116: Standup Target Machinery Removal
- **Task:** TASK-077
- **Category:** systems
- **Created:** 2026-09-09T18:38:58.901626
- **Tags:** 

### Context
Standup target components had poor visual clarity on a top-down 2D pinball board.

### Learning
Removing standup targets required migrating relics to drop targets or bumpers and updating test suite widget assertions.

### Guideline
When removing machinery types, migrate relics to readable top-down components and update showcase test catalog counts.

## <a id="lrn-117"></a> LRN-117: Outlane Kickback Machinery Removal
- **Task:** TASK-078
- **Category:** systems
- **Created:** 2026-09-09T18:44:03.525039
- **Tags:** 

### Context
Outlane kickback solenoids did not fit a top-down 2D pinball pegboard.

### Learning
Removing outlane kickbacks required migrating tactical rebound relics to slingshots and updating rotation unit tests.

### Guideline
When removing directional impulser components, update rotation test suites and migrate affected relics to tactile rebound kickers.

## <a id="lrn-118"></a> LRN-118: Mana Siphon Machinery Component Removal
- **Task:** TASK-079
- **Category:** systems
- **Created:** 2026-09-09T18:50:22.980497
- **Tags:** 

### Context
Mana siphons lacked physical kinetic impact in pinball gameplay.

### Learning
Removing permeable sensors required migrating relics to active physical widgets and updating showcase and preview unit tests.

### Guideline
When removing passive permeable components, verify all preview, audio, showcase, and placement tests update to active pinball machinery.

## <a id="lrn-119"></a> LRN-119: Directional Deflector Machinery Removal
- **Task:** TASK-081
- **Category:** systems
- **Created:** 2026-09-09T18:55:21.866995
- **Tags:** 

### Context
Directional deflector baffles imposed rigid unnatural trajectories that clashed with pegboard ball physics.

### Learning
Removing directional deflectors required migrating relics to natural kinetic kickers and bumpers and updating showcase test catalog counts.

### Guideline
When removing rigid directional override components, replace them with reactive physical kickers or bumpers and verify all test counts update cleanly.

## <a id="lrn-126"></a> LRN-126: Rename Scoop Sinkhole to Ball Trap
- **Task:** TASK-084
- **Category:** Systems
- **Created:** 2026-09-10T14:03:29.011804
- **Tags:** 

### Context
Renamed ScoopSinkhole machinery to BallTrap to simplify pinball terminology for players

### Learning
When renaming a global Godot class with class_name, update .godot/global_script_class_cache.cfg or use script preloads to prevent parse errors across test runners

### Guideline
Keep backwards compatibility aliases when renaming CellType enum members or machinery classes

## <a id="lrn-127"></a> LRN-127: Multi-Peg Orbit Loop Turnaround Physics
- **Task:** TASK-085
- **Category:** Systems
- **Created:** 2026-09-10T14:34:02.357181
- **Tags:** 

### Context
Reworking single-peg Orbit Loop component into multi-peg turnaround shapes (3-peg V, 5-peg U, 7-peg U)

### Learning
Multi-cell orbit loops require waypoints connected across adjacent cells to guide balls along custom turnaround tracks. Bidirectional ports must track travel directions and apply exit impulse along the opposite port direction.

### Guideline
When configuring multi-cell machinery trajectories, build ordered waypoints from adjacency graphs and ensure entry at Port A exits with Port B orientation, and entry at Port B exits with Port A orientation.

