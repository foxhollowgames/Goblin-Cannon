---
name: godot-quality-audit
description: >-
  Runs the complete pre-PR verification pipeline for Goblin Cannon: codebase directory
  sync, GDScript multi-pass linting, file length audits, and headless Godot tests.
  Use before opening a pull request or submitting code changes.
---

# Godot Quality Audit Skill

This skill guides the multi-pass verification and quality enforcement pipeline required before committing changes or opening a pull request.

---

## When to Use

Activate this skill when:
- You finish implementing a feature, fix, or refactor.
- You need to verify that code builds, tests pass, and coding standards are met.
- You are preparing to open a pull request (`gh pr create`).

---

## Quick Automation Command

Execute the consolidated audit suite:

Follow [the shared workflow](../../../docs/AGENT_WORKFLOW.md).
Run focused tests first. Run the full audit once after the final source changes.
Do not also run the full Godot suite through the linter or a separate command.

```bash
python scripts/audit_quality.py
```

### CLI Options:
- `--baseline`: Record static results and the environment in `.godot/audit/baseline.json`. Does not run Godot.
- `--skip-tests`: Run only static checks (directory generation, GDScript lint, and file lengths).
- `--skip-directory`: Skip directory file regeneration if only tests or non-signature docs changed.

---

## Audit Passes Explained

1. **Pass 1: AI Codebase Directory Generation**
   - Script: `scripts/generate_directory.py`
   - Updates `docs/DIRECTORY.md` with indexed scenes, classes, signals, and methods.

2. **Pass 2: GDScript Multi-Pass Linter**
   - Script: `scripts/lint_gdscript.py`
   - Runs static checks. Existing custom-rule warnings remain advisory. Missing optional gdlint is reported as skipped.
   - Script parsing occurs in the one full Godot run. Standalone lint can opt in with `--with-tests`.

3. **Pass 3: File Length Audit**
   - Script: `scripts/lint_file_lengths.py`
   - Enforces 500 lines for new files and the listed limits for existing baseline files.

4. **Pass 4: Headless Godot Unit Test Suite**
   - Script: `tests/run_tests.gd`
   - Discovers and runs all test suites headlessly via the Godot executable.
   - Requires process exit 0, no SCRIPT ERROR, and a final Total with zero failures and positive passed assertions.
   - Keeps stdout, stderr, result.json, and audit.json under `.godot/audit/`.
   - Missing summaries and timeouts fail. A passing line never overrides a failed process.
   - The audit also runs the focused Python tooling tests before Godot.

---

## Failure Resolution Runbook

- **File Length Exceeded:** Keep changes within the task scope. Put broad extraction in a separate task.
- **Missing Return Type:** Add explicit return type annotations (`-> void`, `-> int`, etc.) to public methods.
- **Function Exceeds 45 Lines:** Break large functions into smaller descriptive sub-functions.
- **Godot Test Failure:** Inspect the raw failure, fix it, and run focused tests before repeating the audit.
