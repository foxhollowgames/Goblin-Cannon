# TASK-013: Wall and Fortification Multi-State Art Production

- **Status:** BACKLOG
- **Priority:** P2
- **Category:** Art Production
- **Target Branch:** `feature/wall-art-production`

## Description

Produce multi-state art assets for city fortifications, gates, and walls.
The visual state of the wall must reflect actual health and damage values.

## Core Requirements

1. **City 1 Fortifications (Halfling Shire):**
   - Wall 1: Village Gate.
   - Wall 2: Mill Gate.
   - Wall 3: Town Hall / City Boss Fortification.
2. **Multi-State Damage Progression:**
   - State 1: Pristine / Intact (100% HP).
   - State 2: Superficial Damage (75% HP).
   - State 3: Heavy Fractures and Cracks (50% HP).
   - State 4: Critical Structural Breach and Smoke (25% HP).
   - State 5: Total Collapse and Rubble (0% HP).

---

## AI Ideas & Proposals (Optional / Pending User Decision)

> [!NOTE]
> - **Debris Particles:** Trigger falling stone fragments and dust plumes when transitioning between damage states.
> - **Turret Mounts:** Add destructible wooden defense turrets on top of the walls.

---

## Acceptance Criteria

- [ ] Multi-state wall textures delivered for all City 1 wall segments.
- [ ] Battlefield view transitions smoothly between damage textures based on live HP thresholds.
- [ ] Assets scale and fit the battlefield viewport accurately.
