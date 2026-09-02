# TASK-045: Remove Minion System and Mechanics

- **Status:** BACKLOG
- **Priority:** P2
- **Category:** Refactoring / Cleanup
- **Target Branch:** `feature/remove-minion-system`
- **Related Tasks:** [TASK-040](TASK-040-asset-pack-sprite-audit-and-replacement.md)

## Description

Remove all minion entities, spawning logic, attack states, and minion references across battlefield visual controllers and combat management systems.

---

## Requirements

### 1. Minion Code Removal
- Remove `scenes/combat/minion.gd`, `scenes/combat/minion.tscn`, and `scenes/combat/minion.gd.uid`.
- Remove minion spawning, tracking, damage dealing, and status tick handlers in `scenes/main/combat_manager.gd` and `scenes/combat/battlefield_view.gd`.

### 2. Cleanup & Test Updating
- Remove obsolete minion assertions from combat test suites.
- Verify game builds and all headless tests pass cleanly without minion references.

---

## Acceptance Criteria

- [ ] `minion.gd` and `minion.tscn` removed from the repository.
- [ ] Battlefield controllers and combat managers cleaned of minion logic.
- [ ] Headless unit tests updated and passing cleanly.
