# characters

[Learning index](../LEARNINGS.md)

## <a id="lrn-047"></a> LRN-047: Character Bespoke Progression Mechanics
- **Task:** TASK-003
- **Category:** characters
- **Created:** 2026-09-01T22:32:38.351538
- **Tags:** 

### Context
CharacterProgressionManager provides character-specific passive perks and multiplier calculations for all 6 playthrough archetypes.

### Learning
CharacterProgressionManager computes wall damage, peg energy bonuses, revive chances, and booster speed multipliers based on character_archetype, with goblin_convergence combining peak values from all archetypes.

### Guideline
Use CharacterProgressionManager.get_perks_for_archetype and compute_* helper functions to query character-specific perks during run execution.

