---
name: godot-task-manager
description: >-
  Automates task packet creation, README index registration, and visual dashboard
  updates for Goblin Cannon. Use whenever creating or registering a new task packet
  in docs/tasks/ for ad-hoc user requests or planned features.
---

# Godot Task Manager Skill

This skill guides the automatic creation, tracking, and dashboard synchronization of task packets in Goblin Cannon.

---

## When to Use

Activate this skill when:
- The user requests a bug fix, feature, refactor, or optimization without referencing an active task packet.
- You need to add a new task packet to `docs/tasks/`.
- You need to synchronize `docs/tasks/README.md` and `docs/tasks/dashboard.html`.

---

## Quick Automation Command

Run the automated Python helper script:

```bash
python scripts/create_task.py "Short Descriptive Task Title" --category "Systems / Gameplay" --priority P1
```

### CLI Arguments:
- `title` (positional): The name/title of the task.
- `--category`: Task category (e.g. `Systems / Gameplay`, `UI / Visuals`, `DevOps / Tooling`, `Physics / Systems`). Default: `Systems / Gameplay`.
- `--priority`: Priority level (`P0`, `P1`, `P2`, `P3`). Default: `P1`.
- `--status`: Initial status (`BACKLOG`, `READY`, `IN_PROGRESS`). Default: `READY`.
- `--branch`: Target branch name (e.g. `feature/my-task`). Defaults to `feature/<slug>` or `fix/<slug>`.
- `--skip-dashboard`: Skip regenerating `docs/tasks/dashboard.html`.

---

## What the Automation Does

1. **Calculates Next Task ID:** Scans `docs/tasks/` for the highest existing `TASK-XXX` number and increments it.
2. **Creates Task Packet:** Generates `docs/tasks/TASK-XXX-<slug>.md` with canonical Markdown template and acceptance criteria.
3. **Updates Master Index:** Appends the new row into the table in `docs/tasks/README.md`.
4. **Regenerates Dashboard:** Executes `python scripts/generate_task_dashboard.py` to refresh `docs/tasks/dashboard.html`.

---

## Manual Fallback Procedure

Follow [the shared workflow](../../../docs/AGENT_WORKFLOW.md) for scope, usage gates, and checkpoint content. Reuse an existing task packet when it already covers the request. Record the last verified state before pausing and regenerate the dashboard after each task update.

If running scripts is unavailable:
1. Examine `docs/tasks/` to identify the next sequential number (`TASK-XXX`).
2. Create `docs/tasks/TASK-XXX-<slug>.md` using the standard header (Status, Priority, Category, Target Branch).
3. Add the row to the table in `docs/tasks/README.md`.
4. Run `python scripts/generate_task_dashboard.py`.
