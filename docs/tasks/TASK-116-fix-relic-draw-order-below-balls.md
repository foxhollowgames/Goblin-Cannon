# TASK-116: Fix relic draw order below balls

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** UI / Visuals
- **Target Branch:** `fix/relic-draw-order`
- **Related Tasks:** 

## Description

Fix relic draw order below balls

---

## Requirements

### 1. Scope and Implementation
- Implement specifications for Fix relic draw order below balls.

---

## Acceptance Criteria

- [x] Requirements implemented and verified.
- [x] Raw tests: exit 0, no script errors, zero failed assertions. Existing resource leak warnings remain.
- [ ] File lengths adhere to the 500-line repository limit.
- [ ] Pull Request opened, audited by independent PR reviewer, and merged.

## Implementation and checkpoint

- Status: Implemented locally; full quality audit is blocked.
- Changed gameplay file: scenes/balls/ball.tscn. Set the root ball z_index to 3.
- Draw order: pegs 0, placed relics 2, ball bodies 3. Physics is unchanged.
- The local Qwen coder made the scene edit. Independent reviewer found no actionable issues.
- Raw test command: Godot_v4.6.1-stable_win64.exe --headless -s tests/run_tests.gd.
- Verified in the main working copy: raw exit 0, 20613 passed, 0 failed, no SCRIPT ERROR entries. Existing resource leak warnings remain.
- Isolated worktree static audit: lint timed out at 60 seconds; docs/knowledge/LEARNINGS.md has 2565 lines against its 2500-line limit. No source file was added.
- The isolated worktree lacks ignored art assets. Its runtime check timed out. The working-copy check succeeded after allowing access to Godot user logs.
- No test processes started by this task remain. Review agent completed and was interrupted for teardown; no kill tool is available.
- Remaining scope: resolve existing audit blockers through their own task, then open and merge the fix PR and record the post-merge learning.
- Fix branch: fix/relic-draw-order in .worktrees/relic-draw-order. The same scene edit is applied in the main working copy for immediate use.

## Pull request preparation

- Main is current as of this resumed check.
- Publish a draft PR with the known TASK-114 audit blockers. Do not merge until the required audit passes.


- Draft PR #90: https://github.com/foxhollowgames/Goblin-Cannon/pull/90. Final reviewer confirmed the code and requested moving the README row into its table; corrected. Merge remains blocked by TASK-114.
