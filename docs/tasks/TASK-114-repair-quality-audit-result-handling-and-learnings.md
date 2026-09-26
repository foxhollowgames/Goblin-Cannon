# TASK-114: Repair quality audit result handling and learnings file length

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** DevOps / Tooling
- **Target Branch:** `fix/quality-audit-baseline`
- **Related Tasks:** TASK-109

## Description

Restore the quality gate without changing gameplay. TASK-109 found two existing audit problems on main.

---

## Requirements

### Approved process improvements
- Generate a short learning index and category pages from SQLite. Preserve every record, stable learning IDs, and old anchors. Keep all generated Markdown files below 500 lines.
- Support targeted retrieval, overlapping tags, and a single-record read. Do not load the full collection by default.
- Run one authoritative Godot process per final full audit. Check its real exit code, script errors, and final assertion total.
- Check the baseline before implementation. Map affected display, save, and data paths before editing. Use focused tests before the final audit.
- Limit local generation to two failed attempts per small change. Prefer bounded edits and file-based prompts. Add language selection for Python tooling.
- Check usage before each work phase and after bounded batches. Record crossed gates once per reset window. Preserve the ban on paid credits and reset redemption.
- Update the agent guide and project skills around one shared workflow. Keep TASK-109 changes in their existing checkout.

### Baseline
- Main revision: 3aff3e8. Existing audit failure: LEARNINGS.md is 2565 lines against a 2500-line allowance.
- Existing audit runner can claim success after a nonzero exit if any suite printed `0 failed`.
- Existing linter invokes the full Godot suite; the outer audit invokes it a second time.
- TASK-109 remains uncommitted in the parent checkout. This task uses the isolated `goblin-cannon-agent-task_114` worktree.

### 1. Scope and Implementation
- Fix scripts/audit_quality.py so a failed raw Godot process cannot pass because an individual suite printed `0 failed`. Require exit code 0, no script errors, and a final total of zero failed assertions.
- Add meaningful tests for a nonzero exit with an earlier passing suite, script errors, a failing final total, and a clean successful run.
- Resolve the generated learnings document length: docs/knowledge/LEARNINGS.md has 2565 lines against the existing 2500-line baseline. Preserve all records and retrieval behavior. Prefer a bounded index/archive design over silently raising the limit.
- Keep this tooling work separate from TASK-109 relic names. Run the full audit and record raw process results.

---

## Acceptance Criteria

- [ ] Requirements implemented and verified.
- [ ] Tests pass cleanly.
- [ ] File lengths adhere to the 500-line repository limit.
- [ ] Pull Request opened, audited by independent PR reviewer, and merged.

## Previous implementation checkpoint

- Worktree: `goblin-cannon-agent-task_114`, branch `fix/quality-audit-baseline`, based on main 3aff3e8. Parent TASK-109 changes were preserved.
- User explicitly approved direct Codex edits after two failed Qwen attempts on the same small change.
- Drafted `docs/AGENT_WORKFLOW.md`; updated `AGENTS.md` and `CLAUDE.md` to link it. Includes targeted reading, early baseline checks, complete path inventory, bounded generation, one final audit, and usage checks before phases and at most ten tool calls/ten minutes apart.
- Changed scripts/ollama_coder.py after two failed local attempts. Attempt 1 returned truncated Python; attempt 2 returned an invalid patch. Used the approved direct-edit fallback. Added language selection, UTF-8 prompt-file input, outer-fence parsing that preserves embedded backticks, and rejection of truncated model responses.
- Verification: python -m py_compile scripts/ollama_coder.py exited 0. CLI --help exited 0 and showed language selection. Behavior tests remain pending. No database records changed.
- Shared Godot runner generation attempt 1 was interrupted at the usage checkpoint; process session 67819 exited 1. Its prompt is runner114-spec.txt in the session visualization folder. Inspect any candidate before reuse. No runner has been added to the checkout.
- Next code changes: build an authoritative Godot process runner; make audit invoke it once and make linter static; generate bounded learning pages and preserve legacy links; add targeted Python tests; update project skills and testing instructions.
- Learning design: SQLite stays authoritative; preserve all fields and IDs; add optional tags for overlap; query defaults to bounded results and show reads one ID; export category pages with automatic parts below 500 lines; keep the short root index and compatibility anchors for existing LRN-001 through LRN-150. New entry links should target their generated category page. Test coverage, exact-once records, stable links, page limits, and safe stale-page cleanup.
- Audit design: process exit 0 AND no SCRIPT ERROR AND a final Total summary with zero failures and positive passed assertions. Missing summary, nonzero exit, timeout, and earlier passing suites must fail. Save raw result logs. Test that a full audit invokes Godot only once and a baseline check invokes it zero times.
- Remaining: implement and verify scripts, generated pages, skills, independent PR review, merge, and post-merge learning. Do not mark complete.
- Usage checkpoint: primary window 52%, reset timestamp 1790406308; weekly 24%; ordinaryUsageAllowed=true. The 50% gate is now handled for this window. Explicit continuation resumes work without stopping at this gate again; the 70% gate remains. No credits or reset were requested.
- The tracked generation session exited 1 after interruption. No test processes or agents were started. System-wide process inspection was denied, so no broader process-state claim is made. No commit or PR created.

## Current checkpoint: 2026-09-26

This section supersedes the previous checkpoint.

- Updated the isolated branch from main to dd07a1f. Saved edits were restored; the dashboard conflict was resolved by regeneration. The retained stash task114-resume-checkpoint is a backup; do not pop it again.
- Implemented shared godot_test_runner.py, audit_quality.py baseline/full modes, and static-by-default lint_gdscript.py. One Godot process per full audit; raw output and result JSON are saved under .godot/audit.
- Implemented learning_export.py and targeted learnings.py query/show/tags. All 150 original records and every original field match learnings114-before.db. SQLite gained only the optional tags column. Generated 39 category pages; the largest has 439 lines. Root links preserve LRN-001 through LRN-150 anchors. Removed the old 2500-line exception.
- Updated AGENTS.md, CLAUDE.md, docs/AGENT_WORKFLOW.md, the three project skills, and .cursor/rules/testing.mdc. Directory links now use portable relative paths instead of worktree-specific file URLs.
- Local generation: runner, exporter, learning CLI, audit, linter, and each test module had two rejected attempts before direct edits under the approved fallback. Defects included ignored requirements, wrong APIs, invalid patches, and tests of mock implementations. The one-line length exception removal and relative link fragment were generated and reviewed.
- Focused command: python -m unittest discover -s scripts/tests -v. Raw exit 0; all 10 tests pass. Covers false passes, raw logs, timeout/error output, audit call counts, record migration, page limits, links, safe cleanup, paging, prompt files, and rejected generation output.
- Final command: python scripts/audit_quality.py. Raw exit 0. Godot: 18249 passed, 0 failed, no SCRIPT ERROR. Python: 10 tests pass. Static file lengths pass. Existing 32 custom-rule warnings remain advisory; optional gdlint is absent. Evidence timestamp: 2026-09-26T14:10:11.367295+00:00.
- First full audit failed due to missing ignored assets and icon imports in the fresh worktree (18128 passed, 6 failed, exit 1). Copied 28 referenced local assets, imported icons with a temporary removal of icons/.gdignore, then restored that marker. The passing run followed this environment repair. Restored an unrelated temporary DLL removed by the editor. No gameplay changes were made.
- No separate physics or rendered game checks apply to these tooling changes. Imports and all tracked test/generation sessions have exited. No agents were started. Parent TASK-109 remains unchanged.
- Remaining: inspect the final diff, resolve the generated DIRECTORY.md extra EOF blank line, prepare PR, run independent pr_reviewer, resolve findings, merge, and record the post-merge learning. No commit or PR yet. Do not rerun the full audit without a source change, failure, or new risk.
- Usage: primary 52%, weekly 39%, reset window 1790448611. The 50% gate is handled for this window; 70% remains. Ordinary usage is available. Pause before PR/review phase. Explicit continuation resumes past the handled gate. No credits or reset were requested.
