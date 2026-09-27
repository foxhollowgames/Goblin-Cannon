---
name: godot-quality-audit
description: Run the full Goblin Cannon audit for gameplay, physics, saved-data, shared runtime, or broad structural changes. Routine documentation, closure, and isolated tooling use focused checks under docs/AGENT_WORKFLOW.md.
---

# Godot quality audit

Use the light/full classification in [the workflow](../../../docs/AGENT_WORKFLOW.md). Do not run a full audit merely because a PR is being opened.

For full work, run focused tests first, then `python scripts/audit_quality.py` once after final source changes. The audit covers directory generation, static lint, file lengths, Python tooling tests, and one Godot run. Existing custom warnings are advisory; missing optional gdlint is reported.

Options: `--baseline` records static evidence without Godot; `--skip-tests` runs static and tooling checks; `--skip-directory` preserves the directory when no index change is needed. Reuse known baselines.

Accept Godot success only with raw exit 0, no SCRIPT ERROR, and a final summary with zero failures and positive passed assertions. Evidence is in `.godot/audit/`. Inspect failures before repeating checks. Keep fixes in scope; do not refactor unrelated baseline debt.
