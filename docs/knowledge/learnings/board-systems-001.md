# board-systems

[Learning index](../LEARNINGS.md)

## <a id="lrn-014"></a> LRN-014: Unified Board Grid and Relic Mutual Exclusivity Architecture
- **Task:** TASK-029
- **Category:** board_systems
- **Created:** 2026-08-29T08:06:28.192880
- **Tags:** 

### Context
Defining requirements for aligning the pegboard layout to the polyomino grid and replacing occupied pegs upon relic drop.

### Learning
A shared orthogonal coordinate system simplifies mutual exclusivity checks and drag-and-drop collision detection between pegs and relics.

### Guideline
Always align board peg positions to the same grid cell dimensions and coordinate functions as polyomino relics.

## <a id="lrn-016"></a> LRN-016: Rectangular Pegboard Layout and Polyomino Grid Alignment
- **Task:** TASK-029
- **Category:** board_systems
- **Created:** 2026-08-29T09:16:01.625823
- **Tags:** 

### Context
Standard pegboards historically used staggered odd-row offsets and checkerboard gaps, creating mismatch with polyomino relics.

### Learning
Eliminating row offsets and placing pegs on the unified 16x8 rectangular board grid unifies coordinate conversions across pegs and polyomino tiles.

### Guideline
Always position board pegs and polyomino modules on the canonical 16x8 board grid using board_cell_to_world and world_to_board_cell.

## <a id="lrn-017"></a> LRN-017: Staggered Checkerboard Peg Lattice on Discrete Rectangular Grid
- **Task:** TASK-029
- **Category:** board_systems
- **Created:** 2026-08-29T09:20:53.739643
- **Tags:** 

### Context
A dense peg layout places pegs at every grid point, which reduces ball deflection randomness and prevents open spaces.

### Learning
Gating peg generation by (row + col) % 2 == 0 creates an alternating plinko lattice with 50% empty spots on the same unified 16x8 grid.

### Guideline
Use checkerboard gating (row + col) % 2 == 0 on discrete grid coordinates to achieve staggered layout without floating-point row offsets.

## <a id="lrn-025"></a> LRN-025: Baseline Peg Suppression and Restoration Under Movable Polyomino Relics
- **Task:** TASK-031
- **Category:** board_systems
- **Created:** 2026-08-29T17:33:31.002706
- **Tags:** 

### Context
Permanently freeing pegs covered by a polyomino relic causes the board to permanently lose pegs whenever relics are moved or rearranged.

### Learning
Suppressing pegs (disabling collision, hiding visibility, pausing process) rather than freeing them allows pristine restoration of the baseline board layout when relics are moved or unslotted.

### Guideline
Never permanently free baseline board elements under temporary or repositionable overlays; track and suppress them, then unsuppress on removal.

## <a id="lrn-027"></a> LRN-027: Polyomino Relic Footprint Scaling and Empty Playfield Spacing
- **Task:** TASK-024
- **Category:** board_systems
- **Created:** 2026-08-29T19:45:10.095441
- **Tags:** 

### Context
Relics felt too small and crowded with machinery on every cell, allowing full inventories on the board without strategic layout compromises.

### Learning
Differentiating CellType.EMPTY from active kinetic machinery allows multi-cell relics to occupy realistic pinball widget footprints where balls travel through open corridors between bumpers and gates.

### Guideline
Always reserve full multi-cell footprints on the board grid while skipping machinery instantiation and glyph drawing for CellType.EMPTY cells.

## <a id="lrn-028"></a> LRN-028: Polyomino Relic Exterior Perimeter Wall and Transparent Chassis Drawing
- **Task:** TASK-033
- **Category:** board_systems
- **Created:** 2026-08-29T19:48:36.236273
- **Tags:** 

### Context
Internal connection struts between adjacent cell centers created a wireframe lattice that doubled back and cluttered empty playfield spaces.

### Learning
Checking 4-way cardinal neighbor presence in the module cell set allows drawing walls strictly on exterior boundaries, while drawing a unified translucent fill provides seamless open chambers.

### Guideline
Never draw connection lines between adjacent cell centers; iterate over module cells and draw wall segments only on edges without an adjacent neighbor in the module.

