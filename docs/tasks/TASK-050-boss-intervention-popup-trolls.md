# TASK-050: Boss Intervention Pop-Up Targets

- **Status:** BACKLOG
- **Priority:** P1
- **Category:** Systems / Gameplay
- **Target Branch:** `feature/boss-intervention-popup-trolls`
- **Related Tasks:** [TASK-021](TASK-021-wall-siege-timer-and-pushback.md), [TASK-036](TASK-036-pinball-kinetic-machinery-and-lane-switches.md), [TASK-051](TASK-051-componentized-pinball-machinery-roster.md)

## Description

Implement dynamic boss intervention pop-up defender targets that emerge on the active pegboard during wall sieges.
Pop-up trolls obstruct ball paths, absorb siege damage, and challenge the player's hopper steering until knocked down by direct ball collisions or bomb blasts.

---

## Requirements

### 1. Pop-Up Target Mechanics & Spawning
- Spawn pop-up defender troll targets at designated pegboard cell positions during boss sieges.
- Pop-up targets emerge with spring animations and become solid physics colliders.
- Targets deflect dropping balls and absorb incoming projectile damage.

### 2. Knockdown & Boss Weakness States
- Direct hits from balls or bomb explosions inflict damage to pop-up targets.
- Knocking down all active pop-up targets triggers a vulnerable state on the defending wall or boss.
- Defenders re-emerge after a timed recovery interval if the wall is not breached.

### 3. Automated Tests
- Write unit tests in `tests/test_boss_popup_targets.gd`.
- Verify pop-up target spawning, physics collision state transitions, and knockdown triggers.
- Verify wall vulnerability modifiers apply when all pop-up targets are down.

---

## Acceptance Criteria

- [ ] Boss pop-up troll targets appear dynamically on pegboard cells during boss sieges.
- [ ] Pop-up targets collide with balls, deflect trajectory, and absorb damage.
- [ ] Knocking down targets exposes boss weaknesses and modifies siege progress.
- [ ] Unit tests pass cleanly in headless mode.
