# TASK-003: Character Bespoke Progression Mechanics

- **Status:** DONE
- **Priority:** P1
- **Category:** Systems
- **Target Branch:** `feature/character-mechanics`

## Description

Implement unique progression systems for each character archetype.
The core pegboard and physics simulation remain identical across all playthroughs.
Each character swaps out a major piece of the game experience for their upgrades.

## Core Rules

1. **The Pegboard Core:**
   - Peg collision physics, ball drop dynamics, and base energy routing remain constant.
2. **The Main Goblin Upgrade System:**
   - The **Merchant Shop** is unique to the main character goblin (Runs 1 and 6).
3. **Secondary Character Upgrade Systems:**
   - The Necromancer, Beastmancer, Mechanic, and 4th character receive upgrades through different bespoke methods instead of the merchant shop.

---

## AI Ideas & Proposals (Optional / Pending User Decision)

> [!NOTE]
> - **Necromancer Mechanism Idea:** *Soul Forge.* Defeated enemies grant souls that players spend to resurrect spent balls or enchant pegs with status curses.
> - **Beastmancer Mechanism Idea:** *Monster/Animal Breeding or Mutation.* Balls or minions gain animal traits when interacting with beast pegs.
> - **Mechanic Mechanism Idea:** *Circuit Grid.* Replaces drafting with a modular wire puzzle where players socket components to boost cannon power.
> - **5th Character Mechanism Idea:** *Constellation Linking.* Connecting special star pegs in geometric alignments triggers celestial blasts.

---

## Acceptance Criteria

- [x] The Merchant Shop is active for the Goblin and hidden for secondary characters.
- [x] Each secondary character archetype connects to a dedicated upgrade interface or system.
- [x] Base pegboard physics, collision detection, and energy routing function identically for all characters.
- [x] Automated tests verify mechanic isolation and calculations.
