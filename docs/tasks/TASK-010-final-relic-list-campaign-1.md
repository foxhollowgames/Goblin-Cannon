# TASK-010: Final Relic List and Passive Modifiers for Campaign 1

- **Status:** BACKLOG
- **Priority:** P1
- **Category:** Design
- **Target Branch:** `feature/final-relic-list-campaign-1`

## Description

Define and implement the final roster of relics and passive modifiers for the first campaign.
Relics support and scale the synergy archetypes defined in [TASK-008](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-008-build-archetypes-and-synergies.md).

## Core Requirements

1. **Relic Inventory Architecture:**
   - Define passive item items that alter gameplay rules, status durations, and damage calculations.
   - Categorize relics by rarity, cost, and acquisition source (Merchant Shop and Wall Conquest drafts).

2. **Synergy Scaling:**
   - Create relics that specifically empower individual ball synergies (e.g. burn damage multipliers, freeze duration extensions, energy routing bonuses).

---

## AI Ideas & Proposals (Optional / Pending User Decision)

> [!NOTE]
> - **Potential Relic Archetypes:**
>   - *Tinker's Overcharger:* Increases main cannon damage by 25% but adds a 1-second recharge heat delay.
>   - *Brimstone Catalyst:* Pegs hit by fire balls ignite neighboring pegs for 3 seconds.
>   - *Cryo Condenser:* Frozen enemies take 50% extra impact damage from heavy balls.
>   - *Greed Magnet:* Pegs hit by gold balls yield double scrap for the Merchant Shop.

---

## Acceptance Criteria

- [ ] Complete relic roster for Campaign 1 documented with exact modifier equations.
- [ ] Relic data structures implemented as Godot `Resource` files.
- [ ] Automated tests verify passive relic triggers, stack calculations, and shop inventory integration.
