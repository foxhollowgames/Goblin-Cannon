# TASK-062: Visual Task Dashboard Parked Ideas Column

- **Status:** DONE
- **Priority:** P1
- **Category:** DevOps / Tooling / UI
- **Target Branch:** `feature/dashboard-parked-ideas-column`
- **Related Tasks:** [TASK-061](TASK-061-dashboard-drag-drop-task-status.md)

## Description

Add a dedicated "Parked Ideas" column to the visual task board in `docs/tasks/dashboard.html`.
Tasks with status `PARKED` represent ideas, experiments, or future proposals that are on hold.
Cards can be dragged into and out of the Parked Ideas column.
The server (`scripts/task_server.py`) recognizes `PARKED` as a valid status and updates task files and README.md accordingly.

---

## Requirements

### 1. Dedicated Parked Ideas Column
- Add a column to the Kanban board grid for `PARKED` tasks.
- Support drag-and-drop into and out of the `PARKED` column (`handleDrop(event, 'PARKED')`).
- Show counter badge for parked tasks.
- Style `badge-parked` with a distinct purple color scheme.

### 2. Task Server and Generator Updates
- Add `PARKED` to `VALID_STATUSES` in `scripts/task_server.py`.
- Update `scripts/generate_task_dashboard.py` to parse, count, and render `PARKED` status.
- Add `PARKED` option to the status filter dropdown.
- Add a "Parked" quick status button to the task details modal.

### 3. Documentation and Standards
- Document `PARKED` workflow state in `docs/tasks/README.md`.
- Ensure all files remain strictly under 500 lines.
- Verify with automated tests.

---

## Acceptance Criteria

- [x] Parked Ideas column appears on the Kanban board.
- [x] Cards can be dragged into and out of Parked Ideas column.
- [x] Task server accepts `PARKED` status and saves to disk.
- [x] Filter dropdown includes `PARKED`.
- [x] Modal includes "Parked" action button.
- [x] All files comply with the 500-line limit.
- [x] Automated tests pass.
