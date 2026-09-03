# TASK-009: Final Ball List and Abilities for Campaign 1

- **Status:** BACKLOG
- **Priority:** P1
- **Category:** Design
- **Target Branch:** `feature/final-ball-list-campaign-1`

## Description

Define and implement the final roster of ball types for the first campaign.
The ball roster derives directly from the build archetypes and synergies established in [TASK-008](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-008-build-archetypes-and-synergies.md).

## Core Requirements

1. **Roster Definition:**
   - Specify the complete set of Tier 1 and Tier 2 balls for Campaign 1 (Halfling Shire).
   - Define exact physical properties: restitution, weight, collision radius, and hit cooldowns.
   - Define ability triggers: on peg hit, on duration, on bounce count, and on reaching hopper bottom.

2. **Rarity and Draft Distribution:**
   - Establish drop weights for Common, Uncommon, Rare, and Epic ball variants in the milestone drafts.

---

## AI Ideas & Proposals (Optional / Pending User Decision)

> [!NOTE]
> - **Ball Category Distribution:**
>   - *Elemental Direct:* Flame, Frost, Lightning, Volt.
>   - *Kinetic & Physics:* Bounce, Heavy Iron, Rubbery, Trampoline Catalyst.
>   - *Multipliers & Clones:* Split, Echo Twin, Cluster Nova.
>   - *Support & Economy:* Siphon Leech, Gold Nugget, Energize Conduit.

---

## Acceptance Criteria

- [ ] Complete ball roster for Campaign 1 documented with stats and triggers.
- [ ] Ball definitions integrated into Godot `Resource` files under `data/balls/`.
- [ ] Automated tests verify ball spawning, physics interactions, and milestone drafting.
