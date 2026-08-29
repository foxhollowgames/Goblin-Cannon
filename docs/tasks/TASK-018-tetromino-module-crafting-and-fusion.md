# TASK-018: Tetromino Module Combining and Fusion Design

- **Status:** READY
- **Priority:** P1
- **Category:** Systems / Gameplay
- **Target Branch:** `feature/tetromino-module-fusion`

## Description

Design the upgrade, combination, and crafting systems for spatial Tetromino Relic Modules.
Define how players combine duplicate or weak modules into powerful, high-tier kinetic contraptions.

## Core Objectives

1. **Evaluate Module Upgrade Mechanics:**
   - **Tier Merging (Auto-Battler Style):** Combine two identical modules of the same tier to produce a Tier+1 module.
   - **Rarity Fusion (Transmutation):** Combine any two modules of the same rarity to roll a random module of higher rarity.
   - **Recipe Blueprints (Crafting):** Combine specific prerequisite modules (for example: *Spring Bumper* + *Spark Coil* = *Lightning Dynamo*) to assemble unique legendary contraptions.

2. **Inventory Management and Scrap Loop:**
   - Define scrap costs or workbench constraints for combining modules.
   - Ensure surplus and duplicate modules provide exciting progression choices.

3. **Spatial Grid Balancing:**
   - Determine if higher tier modules change spatial dimensions or increase kinetic power within the same footprint.

## Acceptance Criteria

- [ ] Select and document the primary combination mechanic (tier merging, rarity fusion, or recipe blueprints).
- [ ] Document the rule set for upgrading duplicate and low-tier modules.
- [ ] Define the UI flow for dragging and combining modules in the scrapbox toolbox.
