# TASK-089: Automatic Task Creation and Resolution Protocol for User Requests

- **Status:** DONE
- **Priority:** P0
- **Category:** DevOps / Workflow / Orchestration
- **Target Branch:** `feature/auto-task-creation-workflow`
- **Related Tasks:** [TASK-007](TASK-007-pr-workflow-and-version-control.md), [TASK-056](TASK-056-dashboard-task-detail-modal.md), [TASK-061](TASK-061-dashboard-drag-drop-task-status.md)

## Description

Establish a mandatory project rule and workflow requirement: whenever the user asks for something to be fixed, improved, added, or resolved and there is not already an active task packet for it on the dashboard, the agent/system must immediately create a new task packet (`docs/tasks/TASK-XXX-<name>.md`), register it in `docs/tasks/README.md`, regenerate the visual task dashboard (`python scripts/generate_task_dashboard.py`), and then proceed to implement and resolve the work through the standard feature & fix workflow cycle.

---

## Requirements

### 1. Mandatory Task Packet Creation on Ad-Hoc User Requests
- Whenever the user gives instructions to fix, resolve, refactor, or build something without referencing an existing active task packet in `docs/tasks/`, the agent must create a new task packet before starting implementation work.
- The task packet must follow the standard repository template with next sequential ID (`TASK-XXX`), status, priority, category, target branch, related tasks, description, requirements, and acceptance criteria checkboxes.

### 2. Automatic Dashboard and Index Registration
- Register the new task packet immediately in `docs/tasks/README.md` under the Master Task Index table.
- Immediately execute `python scripts/generate_task_dashboard.py` so the task appears on `docs/tasks/dashboard.html` before or as work begins.
- As the task progresses through implementation, PR review, and merge, update the status accordingly (`IN_PROGRESS` -> `IN_REVIEW` -> `DONE`) and regenerate the dashboard at each transition.

### 3. Codification in Project Rules
- Update `AGENTS.md` to define the rule clearly and integrate it into Step 1 of the Mandatory Feature & Fix Workflow Cycle.
- Update `CLAUDE.md` Project Rules section with the automatic task creation mandate.
- Update `.cursor/rules/` (`project-context.mdc` and `godot-path.mdc`) to ensure consistent behavior and correct Godot executable configuration.

### 4. File Length and Lint Constraints
- Keep all modified documentation and script files strictly under the 500-line repository limit.
- Audit file lengths using `python scripts/lint_file_lengths.py`.
- Run `python scripts/generate_directory.py`.

---

## Acceptance Criteria

- [x] `docs/tasks/TASK-089-auto-task-creation-workflow.md` created with clear requirements and acceptance criteria.
- [x] `docs/tasks/README.md` updated with `TASK-089` in the master task table.
- [x] `AGENTS.md` codified with mandatory task creation on user instructions.
- [x] `CLAUDE.md` codified with mandatory task creation project rule.
- [x] `.cursor/rules/godot-path.mdc` updated with correct Godot 4.6.2 executable path.
- [x] `python scripts/generate_task_dashboard.py` executed and `docs/tasks/dashboard.html` regenerated.
- [x] All file lengths verified under 500 lines via `python scripts/lint_file_lengths.py`.
- [x] Headless test suite passes cleanly.
- [x] Pull Request opened, audited by independent PR reviewer sub-agent, and merged into `main`.
