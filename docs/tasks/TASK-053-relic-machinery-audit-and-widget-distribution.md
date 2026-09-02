# TASK-053: Relic Machinery Audit and Widget Distribution

- **Status:** BACKLOG
- **Priority:** P1
- **Category:** Systems / Gameplay / Balance
- **Target Branch:** `feature/relic-widget-distribution`
- **Related Tasks:** [TASK-024](TASK-024-polyomino-relic-shapes-and-sizes.md), [TASK-048](TASK-048-relic-activation-requirements-pinball-widget-rework.md), [TASK-051](TASK-051-componentized-pinball-machinery-roster.md)

## Description

Analyze all Campaign 1 relics and rebalance their internal kinetic machinery components.
Make sure that the 15 pinball widgets have a relatively even distribution across the relic database.
Assign bash toys exclusively to top-tier, high-reward relics.

---

## Requirements

### 1. Relic Roster Audit
Examine all relics across Tier 1, Tier 2, and Tier 3.
Count the usage frequency for all 15 pinball machinery components:
1. Pop Bumper
2. Drop Target
3. Standup Target
4. Spinner
5. Scoop Sinkhole
6. Ball Lock
7. Guide Track
8. Orbit Loop
9. Slingshot Kicker
10. Rollover Switch
11. Captive Ball
12. Mechanical Diverter
13. Vertical Up Kicker
14. Bash Toy
15. Outlane Kickback

### 2. Even Widget Distribution
Reassign component definitions in `polyomino_relic_database.gd`.
Make sure that all 15 mechanical widgets have a balanced distribution across lower and middle tier relics.
Do not repeat the same widget type across adjacent relics in the same tier.

### 3. High Rarity Bash Toy Rule
Assign bash toys exclusively to Tier 3 Boss Amplifiers and high-reward relics.
Make sure that Tier 1 common relics and low-reward relics contain zero bash toys.
Make bash toys fancy with high health and large reward payouts.

### 4. Automated Verification
Write unit tests in `tests/test_relic_widget_distribution.gd`.
Verify that all 15 widget types exist in the database.
Verify that bash toys appear only in Tier 3 or high-reward relics.

---

## Acceptance Criteria

- [ ] All 60+ relics in `polyomino_relic_database.gd` undergo a machinery component audit.
- [ ] The 15 mechanical widgets have an even distribution across the relic roster.
- [ ] Bash toys appear only on Tier 3 or high-reward relics.
- [ ] No Tier 1 common relics contain bash toys.
- [ ] Unit tests pass cleanly in headless mode.
