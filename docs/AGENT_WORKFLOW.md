# Efficient task workflow

## Start with a small work map

1. Read CLAUDE.md, the task packet, and the relevant directory entries. Search with `rg` before opening files. Read only the sections needed for the task. Do not repeat unchanged reads.
2. Query learnings with a specific topic. Read individual matching entries. Use the category index only when the topic is unclear. Do not load all learning pages by default.
3. Check Git status and included usage. Preserve unrelated edits in another branch or worktree.
4. Check the baseline before editing. Run `python scripts/audit_quality.py --baseline`. Record the revision, command, result, and existing failures in the task packet. Reuse a recorded baseline for the same revision and environment. Do not repeat the full suite merely to establish a known baseline.
5. List the source of truth, affected callers, saved-data paths, and display paths. For naming changes, include cards, inventory, tooltips, debug lists, and completion banners. Define the smallest observable test before editing.

## Bound local generation

- Use local Qwen first for each small code change. Supply specifications with `--prompt-file`; select the correct `--language`. Prefer one function or bounded edit over a full-file rewrite.
- Write generated candidates to a scratch location. Review the diff and syntax before applying them. Never let a truncated response replace a working file.
- Count incorrect, truncated, or unusable responses as failed attempts. Allow at most two attempts for the same change. Renaming the prompt or splitting it into trivial fragments does not reset this count.
- After two failures, record the failure and use direct Codex edits for that change. The user approved this fallback. Run the relevant check immediately. Do not spend more local calls repairing the same output.
- Local generation is free of API charges, but agent supervision still consumes included usage. Use neither paid/API credits nor reset redemption.

## Implement one complete example

- Complete one representative source, output path, and outcome test before expansion.
- For catalog changes, establish the complete data table first. Apply the remaining data changes in one bounded batch after the example passes.
- Keep one implementation owner per shared code area. Use independent agents for the required review, not competing edits.
- Stop and register a follow-up task when the fix requires unrelated architecture or tooling work. Record the dependency instead of hiding a failing check or enlarging the current feature.

## Verify once at each necessary level

1. Run focused tests for the changed behavior.
2. Run real-physics checks when the change affects physics or ball ownership. Record why they do not apply to text-only or tooling work.
3. For a visible change, inspect one representative rendered view, including the longest or most constrained content. Expand visual checks only if that reveals a problem.
4. Run `python scripts/audit_quality.py` once after the final source changes. Its linter is static; the audit owns the one full Godot run. Do not run a separate full suite before or after a successful audit without a new failure, source change, or uncovered risk.
5. Accept Godot success only when the real process exits 0, no script errors occur, and the final summary reports zero failures and at least one passing assertion. Missing summaries, timeouts, and nonzero exits fail the run. An earlier passing suite never overrides these failures.
6. Keep the raw exit code and summary in the task packet. Keep full logs as local artifacts and retrieve only relevant failure lines in conversation.

## Check usage before it becomes a blocker

- Check included usage at task start, before each new phase, after a failed generation pair, and after at most ten tool calls or ten minutes of work, whichever comes first.
- Record the reset window, used percentage, and gates already handled in the task packet. Usage is shared across tasks; do not treat a change in the account total as an exact cost for this task.
- At the first observed crossing of 50% and 70% in a window, checkpoint and stop unless only small, verified closing work remains. Check early enough to avoid crossing a gate during a large batch.
- An explicit user continuation resumes a saved checkpoint. Do not stop again just because usage remains above the same handled gate. A new reset window starts a new gate record.
- Stop before a batch that is likely to exhaust included usage. Never continue after the usage tool says ordinary usage is unavailable.

## Close the task

- Open the PR after the change and verification are concrete. Request the required independent review. Resolve findings and verify the affected scope.
- End review agents with the lifecycle tools available in the session. If a kill tool is absent, interrupt the finished agent and do not schedule more work for it. Do not invent unsupported tool calls.
- Merge only when required checks and review are satisfied. Record post-merge learnings in SQLite, regenerate its category pages, and update the dashboard.
- In a fresh worktree, check ignored asset dependencies and import caches before the full audit. Wait for the actual editor process to finish. A GUI launcher returning is not proof of import completion.
- Before any pause, record changed files, raw test results, known failures, remaining scope, and running processes. Remove rejected scratch outputs from the checkout.
