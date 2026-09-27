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

## Resumed checkpoint — 2026-09-26

- Merged main revision 2ff43dc, including TASK-114, into this branch. Merge commit: 69082cb. Regenerated the dashboard to resolve its only conflict.
- Independent reviewer approved the one-line scene change again with no actionable findings. Reviewer completed and was interrupted for teardown.
- Static baseline: python scripts/audit_quality.py --baseline passed, including lengths and 11 tooling tests. Existing custom-rule warnings remain advisory; optional gdlint is absent.
- A subsequent full audit was blocked by sandbox access to temporary test directories before Godot ran. Run the final audit with normal host access. Do not treat that attempt as a test pass.
- Imported art assets into this isolated checkout. Import reached DONE and the launched process has exited. The assets directory is a junction to the primary checkout assets.
- Worktree moved to C:/Users/josep/Desktop/Games/Goblin-Cannon/goblin-cannon-agent-task_116 so the main checkout length audit does not scan it as project source.
- Remaining: run final full audit, update PR #90, mark ready, merge, record post-merge learning, and set DONE. No new gameplay changes are required.
- Usage checkpoint: 54% five-hour usage; reset timestamp 1790474412. The 50% gate is handled. No task-owned processes or active review agents remain.

## Final audit and review — 2026-09-26

- Restored 17 missing imported art cache files and 11 icon import records from the primary checkout. These ignored local files are not part of the PR.
- Final python scripts/audit_quality.py passed. Raw Godot exit 0, 18249 passed, 0 failed, no SCRIPT ERROR. Static lint, file lengths, and 11 tooling tests passed. Logs are in .godot/audit/.
- Independent PR review approved the one-line draw-order change with no actionable findings. Physics settings are unchanged; no separate physics check is required.
- All prior blockers are resolved. Ready to merge PR #90. No task-owned processes or active review agents remain.
