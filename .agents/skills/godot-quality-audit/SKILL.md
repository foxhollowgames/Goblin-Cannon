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

```bash
python scripts/audit_quality.py
```

### CLI Options:
- `--skip-tests`: Run only static checks (directory generation, GDScript lint, and file lengths).
- `--skip-directory`: Skip directory file regeneration if only tests or non-signature docs changed.

---

## Audit Passes Explained

1. **Pass 1: AI Codebase Directory Generation**
   - Script: `scripts/generate_directory.py`
   - Updates `docs/DIRECTORY.md` with indexed scenes, classes, signals, and methods.

2. **Pass 2: GDScript Multi-Pass Linter**
   - Script: `scripts/lint_gdscript.py`
   - Verifies explicit return types on public functions, maximum function lengths (<= 45 lines), and script syntax.

3. **Pass 3: File Length Audit**
   - Script: `scripts/lint_file_lengths.py`
   - Strictly enforces the repository architectural rule: no source file may exceed 500 lines.

4. **Pass 4: Headless Godot Unit Test Suite**
   - Script: `tests/run_tests.gd`
   - Discovers and runs all test suites headlessly via the Godot executable.
   - Asserts 0 failures and 0 script compilation errors.

---

## Failure Resolution Runbook

- **File Length Exceeded:** Decompose the script by delegating logic to helper classes or sub-components.
- **Missing Return Type:** Add explicit return type annotations (`-> void`, `-> int`, etc.) to public methods.
- **Function Exceeds 45 Lines:** Break large functions into smaller descriptive sub-functions.
- **Godot Test Failure:** Inspect the failed assertion backtrace, fix the issue, and rerun `python scripts/audit_quality.py`.
