# TASK-095: Implement Workspace Agent Skills and Progressive Disclosure Architecture

- **Status:** IN_REVIEW
- **Priority:** P1
- **Category:** DevOps / Tooling / Agent Skills
- **Target Branch:** `feature/workspace-agent-skills`
- **Related Tasks:** [TASK-007](TASK-007-pr-workflow-and-version-control.md), [TASK-089](TASK-089-auto-task-creation-workflow.md)

## Description

Implement three project workspace agent skills in `.agents/skills/` to automate recurring development workflows:
1. `godot-task-manager`: Automate task packet creation, index registration, and HTML task dashboard regeneration via `scripts/create_task.py`.
2. `godot-quality-audit`: Automate multi-step code quality verification (directory generation, GDScript linting, file length audit, and headless tests) via `scripts/audit_quality.py`.
3. `godot-learnings-loop`: Standardize pre-task knowledge retrieval and post-merge learning database management.

Verify that all skills use progressive disclosure with concise YAML frontmatter descriptions and modular reference instructions.

---

## Requirements

### 1. Progressive Disclosure Architecture
- Each skill must reside in `.agents/skills/<name>/SKILL.md`.
- Each `SKILL.md` must provide YAML frontmatter (`name` and `description`).
- Keep frontmatter descriptions concise so agent system prompt discovery overhead is minimal.
- Detailed step-by-step procedures, commands, and options must reside in the markdown body and referenced scripts.

### 2. `godot-task-manager` Skill & Helper Script
- Create `.agents/skills/godot-task-manager/SKILL.md`.
- Implement `scripts/create_task.py`:
  - Calculate next sequential `TASK-XXX` ID from `docs/tasks/`.
  - Accept title, category, priority, and optional target branch.
  - Create standardized markdown task packet.
  - Append task entry into `docs/tasks/README.md` master index table.
  - Automatically run `python scripts/generate_task_dashboard.py` to regenerate `docs/tasks/dashboard.html`.

### 3. `godot-quality-audit` Skill & Helper Script
- Create `.agents/skills/godot-quality-audit/SKILL.md`.
- Implement `scripts/audit_quality.py`:
  - Execute directory generator (`python scripts/generate_directory.py`).
  - Execute GDScript linter (`python scripts/lint_gdscript.py`).
  - Execute file length auditor (`python scripts/lint_file_lengths.py`).
  - Execute headless Godot test suite (`godot --headless -s tests/run_tests.gd`).
  - Print consolidated pass/fail results.

### 4. `godot-learnings-loop` Skill
- Create `.agents/skills/godot-learnings-loop/SKILL.md`.
- Document pre-task knowledge query workflows and post-merge learning entry workflows.
- Provide tag taxonomies and learning record templates.

### 5. Automated Tests & Quality Enforcement
- Provide automated Python unit test suite `tests/test_workspace_skills.py` validating task creation, quality audit scripts, and skill definitions.
- Maintain all files strictly under the 500-line repository limit.
- Run quality checks and ensure headless test suite passes.

---

## Acceptance Criteria

- [x] `docs/tasks/TASK-095-implement-workspace-agent-skills.md` created and registered in `docs/tasks/README.md`.
- [x] `docs/tasks/dashboard.html` regenerated and displaying `TASK-095`.
- [x] `.agents/skills/godot-task-manager/SKILL.md` created with YAML frontmatter.
- [x] `scripts/create_task.py` implemented and verified under 500 lines.
- [x] `.agents/skills/godot-quality-audit/SKILL.md` created with YAML frontmatter.
- [x] `scripts/audit_quality.py` implemented and verified under 500 lines.
- [x] `.agents/skills/godot-learnings-loop/SKILL.md` created with YAML frontmatter.
- [x] `tests/test_workspace_skills.py` written and passing cleanly.
- [x] All file lengths verified under 500 lines via `python scripts/lint_file_lengths.py`.
- [ ] Pull request opened, reviewed by independent sub-agent, and merged into `main`.

