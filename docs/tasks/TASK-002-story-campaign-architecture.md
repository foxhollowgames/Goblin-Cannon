# TASK-002: Six-Playthrough Story Campaign Architecture

- **Status:** READY
- **Priority:** P1
- **Category:** Narrative
- **Target Branch:** `feature/story-campaign-arch`

## Description

Design and implement the campaign progression system across six distinct character playthroughs.
Track story milestones, McGuffin shards, and character unlock states.

## Campaign Order

1. **Run 1 — The Goblin:** Chaotic explosion fanatic. Psychological breakdown is hidden beneath cartoon exterior.
2. **Run 2 — The Necromancer:** Explores civilian casualties and the cemetery outskirts. Unlocks McGuffin 2.
3. **Run 3 — The Beast Dancer:** Explores wild nature and displaced wildlife. Unlocks McGuffin 3.
4. **Run 4 — The Mechanic:** Explores guild exploitation and stolen inventions. Unlocks McGuffin 4.
5. **Run 5 — The Astromancer:** Explores multiverse timelines and cosmic destiny. Unlocks McGuffin 5.
6. **Run 6 — The Final Campaign:** Prologue before the tragedy, timeline convergence of all allies, and the ultimate siege.

## Acceptance Criteria

- [ ] `GameState` stores campaign run index (1 to 6) and unlocked McGuffins.
- [ ] Completing a run saves progress to user profile data.
- [ ] Starting a new run initializes the corresponding character archetype and narrative context.
- [ ] Run 6 triggers the prologue and the convergence event sequence.
- [ ] Automated tests verify campaign save and load functionality.
