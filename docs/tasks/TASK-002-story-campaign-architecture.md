# TASK-002: Six-Playthrough Story Campaign Architecture

- **Status:** READY
- **Priority:** P1
- **Category:** Narrative
- **Target Branch:** `feature/story-campaign-arch`

## Description

Design and implement the campaign progression system across six distinct character playthroughs.
The narrative reveals the backstory of the world and the main character goblin across the runs.

## Campaign Order and Narrative Arc

1. **Run 1 — The Main Goblin (The Breakdown):**
   - Starts as a happy-go-lucky, zany goblin who loves explosions.
   - The player views this as a silly cartoon game.
   - Rewards the first Infinity Gem style McGuffin.

2. **Runs 2 to 5 — The Four Secondary Characters:**
   - Playthroughs provide context into what happened to the world and the main character goblin.
   - The player sees that society trampled, suppressed, and destroyed everything the goblin had.
   - The player experiences an empathetic realization that the first run occurred right after a severe psychotic breakdown due to extreme tragedy.
   - **Roster:**
     - **The Necromancer**
     - **The Beastmancer:** Focuses on animals or monsters as the primary mechanic.
     - **The Mechanic**
     - **Character 4 (Undecided)**
   - Each run awards an Infinity Gem style McGuffin.

3. **Run 6 — The Final Campaign (The Convergence):**
   - Begins with the main character before the tragedy.
   - Showcases the tragedy event.
   - All collected McGuffins activate, bringing the other characters through timelines and dimensions to support the main character.
   - The main character makes the correct choice for the final battle.

---

## AI Ideas & Proposals (Optional / Pending User Decision)

> [!NOTE]
> - **5th Character Archetype Proposals:**
>   - *The Astromancer / Celestial Weaver:* Observes the timeline fractures through ancient astral devices.
>   - *The Exiled Archivist / Runesmith:* Documents the true suppressed history of the kingdoms.
> - **Cutscene Delivery Idea:** Use comic speech panel overlays at the beginning and ending of each city sector to deliver narrative beats without interrupting combat flow.

---

## Acceptance Criteria

- [ ] `GameState` stores campaign run index (1 to 6) and unlocked McGuffins.
- [ ] Completing a run saves progress to user profile data.
- [ ] Starting a new run initializes the corresponding character archetype and narrative context.
- [ ] Run 6 triggers the prologue and the convergence event sequence.
- [ ] Automated tests verify campaign save and load functionality.
