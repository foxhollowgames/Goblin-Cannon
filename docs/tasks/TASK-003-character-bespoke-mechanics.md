# TASK-003: Character Bespoke Progression Mechanics

- **Status:** READY
- **Priority:** P1
- **Category:** Systems
- **Target Branch:** `feature/character-mechanics`

## Description

Implement unique progression and upgrade systems for each character archetype.
Keep the core pegboard and physics loop constant across all characters.

## Archetype Mechanic Replacements

1. **Goblin:** **Merchant Scrap Shop.** Gold economy with shop restocks, sales, and scrap rerolls.
2. **Necromancer:** **Soul Forge.** Consumes defeated enemy souls to enchant pegs with curse effects and revive expired balls.
3. **Beast Dancer:** **Pack Symbiosis.** Balls act as living familiars that mutate and level up when hitting meat/berry pegs.
4. **Mechanic:** **Modular Grid.** Replaces shop drafting with circuit grid component socketing and wire routing.
5. **Astromancer:** **Constellation Weaving.** Connects star pegs in geometric alignments to trigger celestial effects.
6. **Final Convergence:** **Nexus Synergies.** Combines elements from all five mechanics in the final campaign.

## Acceptance Criteria

- [ ] Each character overrides the reward/shop interface with their bespoke system.
- [ ] Base pegboard physics, collision detection, and energy routing remain functional across all characters.
- [ ] Resource managers handle souls, beast xp, power grids, and star alignments cleanly.
- [ ] Unit tests cover mechanic isolation and calculations.
