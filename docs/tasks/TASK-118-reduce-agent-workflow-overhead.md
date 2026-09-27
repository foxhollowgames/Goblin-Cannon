# TASK-118: Reduce agent workflow overhead

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** DevOps / Tooling
- **Target Branch:** `fix/reduce-agent-workflow-overhead`

## Description

Reduce repeated agent setup, generation retries, full audits, and closure reviews. Apply the user-approved light workflow without weakening gameplay and save validation.

## Acceptance Criteria

- [x] Define light and full checks by risk in one workflow policy.
- [x] Allow direct edits and make local Qwen optional.
- [x] Require small reviewer briefs instead of full conversation history.
- [x] Prefer prepared checkouts and verify imports before testing.
- [x] Shorten entry instructions and align skills, testing rules, and task templates.
- [x] Add one command to verify a merged PR and update task, index, and dashboard.
- [x] Cover closure rejection, repeat calls, and rollback with focused tests.
- [ ] Merge implementation PR and publish the verified task closure.

## Verification

- Light workflow: documentation and isolated Python tooling only. No gameplay changes; no full Godot run or review agent is needed.
- Prior run: all 15 Python tooling tests passed, raw exit 0. File lengths passed with zero violations.
- New source: scripts/close_task.py and scripts/tests/test_close_task.py. The command requires merge evidence and validation text; it does not commit, merge, or change billing settings.
- Standard mode and connections remain unchanged. Earlier usage interruption is resolved; ordinary usage is available on resume.
- No owned background processes or review agents remain.
