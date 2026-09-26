# visuals

[Learning index](../LEARNINGS.md)

## <a id="lrn-128"></a> LRN-128: Lower right battlefield wall, cannonball projectile, and impact VFX
- **Task:** TASK-087
- **Category:** Visuals
- **Created:** 2026-09-10T14:59:31.227672
- **Tags:** 

### Context
Added horizontal projectile flight and wall visual opposite cannon in BattlefieldView

### Learning
Aligning lower right wall and cannon muzzle at y=628.0 creates clear horizontal combat visual. Guarding get_tree() with is_inside_tree() prevents headless test engine crashes when scripts are tested outside scene tree.

### Guideline
Always guard get_tree() access with is_inside_tree() in view scripts that can be instantiated directly by unit tests. Keep battlefield projectile travel paths aligned along horizontal target axis.

