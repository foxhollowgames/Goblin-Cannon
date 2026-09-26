# TASK-115: Fix temporary ball rewards to spawn in hopper

- **Status:** IN_REVIEW
- **Priority:** P1
- **Category:** Systems / Gameplay
- **Target Branch:** `fix/temporary-ball-reward-hopper`
- **Related Tasks:** 

## Description

Fix temporary ball rewards to spawn in hopper

---

## Requirements

### 1. Scope and Implementation
- Implement specifications for Fix temporary ball rewards to spawn in hopper.

---

## Acceptance Criteria

- [ ] Requirements implemented and verified.
- [ ] Tests pass cleanly.
- [ ] File lengths adhere to the 500-line repository limit.
- [ ] Pull Request opened, audited by independent PR reviewer, and merged.

## Required behavior

- Temporary ball rewards spawn in the hopper by default.
- Spawn at the relic or another location only when the reward explicitly states that exception.
- Preserve reward counts, ball types, lifetime, and ownership rules.
- Add outcome tests for the hopper default and an explicit location exception.

## Checkpoint — 2026-09-25

Paused before implementation under project rule 13: five-hour usage is 82%, above the 70% gate. No code or tests changed for this task. No tests run. No task processes running.

Main sync: `git pull origin main` succeeded; already up to date. Current branch is `feature/thematic-and-descriptive-relic-names`, with existing uncommitted work. Preserve that work and use a dedicated branch for implementation.

Changed for this task: this packet, `docs/tasks/README.md`, and `docs/tasks/dashboard.html`.

Remaining scope: complete required project reading and learning query; inspect reward spawn routing; use local Ollama for code and tests; verify focused outcomes, physics tests, and full quality audit; open PR; obtain independent review; merge; record learning. No implementation failures are known because implementation has not started.


Resumed with user approval after the usage limit question. Implementation uses the isolated .worktrees/task-115 checkout. Existing working changes remain in the original checkout.

## Implementation and verification

- Default temporary rewards enter the hopper at its current position for each emission. They do not join active board play until the hopper releases them.
- An explicit serialized `spawn_at_relic` option keeps device outlet behavior. Old records without that field use the hopper.
- Hopper references are removed when a temporary ball expires, is discarded, or is collected.
- Changed gameplay files: `resources/polyomino/relic_ball_reward.gd`, `scenes/board/temporary_relic_ball_controller.gd`, `scenes/hopper/hopper.gd`.
- Tests: new `tests/test_temporary_reward_hopper.gd` and `tests/run_temporary_hopper_physics.gd`; updated outlet tests and main suite registration.
- Focused runner: 286 passed, zero failed, raw exit 0, no script errors.
- `godot --headless -s tests/run_temporary_hopper_physics.gd`: zero failures, raw exit 0, no script errors. Covers closed gate, real release, and one-time collection.
- `godot --headless -s tests/run_tests.gd`: 18,249 passed, zero failed, raw exit 0, no script errors. Existing engine warnings report concave shapes, certificate store access, and exit resource leaks.
- File length audit: existing `docs/knowledge/LEARNINGS.md` is 2,565 lines against its 2,500-line baseline. No changed source file exceeds 500 lines. This separate audit problem is tracked by TASK-114 in the original checkout.
- The static checker reports 32 existing function-length warnings. The first wrapped test run stalled and was stopped; the direct raw Godot result above is authoritative.
- Local generation used `scripts/ollama_coder.py` with Qwen 2.5 Coder. The larger model stalled on memory allocation; the smaller installed model completed generation after a server restart.
- Pending: independent PR review, merge, and post-merge learning record.


The quality checker completed outside the sandbox. Its Godot test and parse pass succeeded. Its overall exit was 1 due to the existing learning-document length limit and directory regeneration using worktree-specific absolute links. The generated directory links were restored to the canonical project path.
