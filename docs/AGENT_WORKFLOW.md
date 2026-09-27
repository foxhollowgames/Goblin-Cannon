# Efficient task workflow

## Choose the smallest safe workflow

| Class | Examples | Required verification |
|---|---|---|
| Light | Documentation, status, display text, one scene draw setting, isolated developer tooling | Diff review and relevant focused checks. Render a representative view for a visible change. Test tooling with Python tests. No mandatory full Godot audit or independent reviewer. |
| Full | Gameplay, physics, rewards, ownership, save behavior, shared runtime logic, broad refactoring | Focused outcome tests; real-physics checks when applicable; one final full audit; one independent review before merge. |

Classify by impact, not line count. A one-line reward or save change is full. If impact is uncertain, inspect the affected callers before choosing. Escalate when evidence reveals broader risk. This policy controls the scope of project audit and review skills.

## Start and read only what is needed

- Check Git state and sync main before edits. Preserve unrelated changes. Use a dedicated feature or fix branch.
- Reuse the task packet. Create and register a packet for new implementation work with scripts/create_task.py. Routine status updates and closure stay in their existing packet.
- Read CLAUDE.md as a map. Search with rg before opening files. Query a specific learning topic; use show <ID> only for relevant entries.
- Keep a short current checkpoint: source of truth, affected paths, last verified revision, test evidence, remaining work, owned processes. Replace stale current-state notes instead of growing a transcript.
- On resume, use the checkpoint. Do not reread unchanged rules or rerun a valid baseline. Establish a new baseline only for unknown state or an environment change.
- Keep tool output bounded: summaries, relevant matches, and failure excerpts. Save long logs locally. Avoid repeated broad searches.

## Edit and prepare the environment

- Direct Codex edits are the default. Qwen is optional for proven repetitive work. Use file-based prompts and the correct language; stop after the first unusable result and edit directly. Do not spend calls repairing speculative generated code.
- Use one implementation owner. Keep feature scope separate from unrelated cleanup. Complete one representative outcome before expanding a gameplay path.
- Prefer a prepared checkout for sequential work when no other task owns it. Create a worktree only for isolation or concurrent work. Use the ignored goblin-cannon-agent-task_* location.
- Before tests in another checkout, confirm required raw assets, import metadata, caches, and extensions are available. Import only what is needed and wait for the actual process to exit. Avoid scanning entire unused asset packs.
- Do not share writable Godot import caches between running editors. Copy required cache files when appropriate.
- Update docs/DIRECTORY.md only when files or public signatures change.

## Verify and review once

- Run the checks from the chosen class. Do not rerun successful checks without changed source, a failure, or a specific uncovered risk.
- For full work, run python scripts/audit_quality.py after focused tests. It owns the single full Godot run. Keep stdout, stderr, exit code, and final assertion count.
- A Godot pass requires raw exit 0, no SCRIPT ERROR, and a final summary with zero failures and positive passed assertions. Wrapper PASS text alone is insufficient.
- New gameplay paths need observable outcome checks, including applicable counts, energy, cleanup, expiry, population limits, and one-time collection.
- Keep source files within 500 lines, subject to existing listed baselines. Avoid broad refactoring to resolve unrelated existing warnings.
- Full work requires one independent reviewer. Use fork_turns="none" and provide the repository path, base/head revisions, requirements, changed paths, and test summary. Let the reviewer inspect the diff. Do not send full chat history.
- Reuse approval when source is unchanged. Re-review only substantive fixes to findings. Do not spawn a reviewer for closure records, generated dashboards, or post-merge learning notes.
- End reviewers immediately after their result is checked. If no kill tool exists, interrupt the finished agent.

## Publish and close without another review cycle

- Implementation goes through one PR. Merge after the chosen checks pass and, for full work, review approval is recorded.
- Run `python scripts/close_task.py TASK-XXX --pr NUMBER --validation "Checks and raw results"` after merge. It verifies GitHub merge evidence and updates the packet, index, and dashboard in one command.
- Add a learning only for a reusable new finding, using scripts/learnings.py add. Do not create entries that repeat known guidance.
- Routine closure and learning records may be committed directly to up-to-date main after diff review. If remote protection requires a PR, use one documentation PR with no new gameplay audit or review agent. Do not change branch protections.
- Keep user changes and safety backups intact. Stop owned processes. Report the outcome and material limits briefly.

## Usage and handoff

- Check included usage at start and before substantial new phases, or after ten tool calls/ten minutes of sustained work. Do not add usage polling between trivial closure steps.
- Handle the 50% and 70% gates once per reset window. Checkpoint and stop unless only small verified closing work remains. Explicit continuation resumes the saved gate; a new window resets it.
- Never use paid/API credits or reset redemption. Stop when ordinary usage is unavailable.
- When pausing, save the compact checkpoint and refresh the dashboard. Prefer a new task with this brief for unrelated future work; keep closely related fixes together when they share validation.
