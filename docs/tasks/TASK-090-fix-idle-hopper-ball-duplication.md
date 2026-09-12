# TASK-090: Fix Idle Hopper Ball Duplication

- **Status:** IN_REVIEW
- **Priority:** P1
- **Category:** Systems / Gameplay / Physics
- **Target Branch:** `fix/idle-hopper-ball-duplication`
- **Related Tasks:** [TASK-001](TASK-001-gameplay-loop-and-pacing.md), [TASK-019](TASK-019-hopper-steering-controls.md), [TASK-086](TASK-086-audit-energy-calculation-and-reset-ball-energy-state.md)

## Description

When running the game without user interaction (idle run), the number of balls in the hopper grows uncontrollably (e.g. escalating to 50 balls from the initial 10). The ball lifecycle between leaving the hopper, navigating the board, exiting at the bottom, and re-entering the hopper must preserve ball conservation unless legitimate gameplay rewards trigger. Furthermore, milestone event peg completions during idle runs must not passively dump free balls into the hopper without player draft/reward selection.

---

## Requirements

### 1. Fix Ball Lifecycle Tracking & Duplication Safeguards
- Ensure `board.gd:spawn_ball_at_start()` safeguards `_active_balls` so that a ball node cannot be appended multiple times (`if not _active_balls.has(ball)`).
- Ensure `hopper.gd` does not double-emit `ball_entered_board` or re-add balls erroneously during bin syncing, gate transitions, or ball returns.
- Ensure `GameBallManager.on_ball_exited_board()` correctly handles ball lifecycle transitions, preventing duplicate exit processing or duplicate queued re-spawns.

### 2. Milestone Event Reward Policy Audit
- Audit milestone event peg completion in idle runs: milestone rewards should require player action or not flood basic balls into the hopper during idle simulation.
- Verify whether `notify_milestone_reward_from_board()` should trigger draft UI or if milestone peg rewards should only occur intentionally.

### 3. Automated Regression Tests
- Create automated headless regression tests validating ball conservation across repeated hopper drops and board exits.
- Ensure initial 10 balls remain exactly 10 balls over idle simulation cycles.

### 4. File Length and Lint Constraints
- Keep all modified files strictly under 500 lines.
- Run `python scripts/lint_file_lengths.py`, `python scripts/lint_gdscript.py`, and `python scripts/generate_directory.py`.
- Run full headless test suite.

---

## Acceptance Criteria

- [x] `docs/tasks/TASK-090-fix-idle-hopper-ball-duplication.md` created and registered in `docs/tasks/README.md`.
- [x] Visual task dashboard regenerated via `python scripts/generate_task_dashboard.py`.
- [x] Root causes of ball duplication identified and eliminated.
- [x] Ball conservation verified: idle run preserves ball count without unwanted escalation.
- [x] Automated regression test authoring and verification.
- [x] Full headless test suite passes.
- [ ] Code changes reviewed by sub-agent `pr_reviewer` and merged into `main`.
- [ ] Post-merge learning added via `python scripts/learnings.py add`.
- [ ] Task dashboard marked DONE.
