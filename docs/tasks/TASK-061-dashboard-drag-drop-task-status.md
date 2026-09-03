# TASK-061: Visual Task Dashboard Drag-and-Drop Task Status Update

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** DevOps / Tooling / UI
- **Target Branch:** `feature/dashboard-drag-drop-task-status`
- **Related Tasks:** [TASK-056](TASK-056-dashboard-task-detail-modal.md)

## Description

Add drag and drop functionality to the task matrix dashboard (`docs/tasks/dashboard.html`).
Cards can be clicked and dragged between status columns (Backlog, Ready, In Progress, Done) in the Kanban board view.
Dropping a card onto a column updates the task status in the task markdown file (`docs/tasks/TASK-*.md`) and the master index (`docs/tasks/README.md`) through a lightweight local server.

---

## Requirements

### 1. Drag and Drop Kanban Cards
- Task cards in the Kanban board can be clicked and dragged (`draggable="true"`).
- Dragging a card does not trigger the task details modal.
- Columns visually highlight when a card is dragged over them.
- Dropping a card into a column updates the status of that task immediately.
- Badge counters and completion progress bars update in real time.

### 2. Local Task Update Server
- Create `scripts/task_server.py` using Python's built-in `http.server`.
- Expose `GET /api/health` and `POST /api/task/update`.
- Update the target task file (`docs/tasks/TASK-XXX-*.md`) status line.
- Update the row in `docs/tasks/README.md`.
- Regenerate `docs/tasks/dashboard.html` automatically after updating files.
- Enable CORS headers to support requests from `file:///` and `http://localhost`.
- Provide a CLI interface for direct updates: `python scripts/task_server.py update <ID> <STATUS>`.

### 3. Client UI Feedback and Fallback
- Show a temporary toast notification when a task status changes or when save succeeds.
- When the local server is offline, show a warning toast explaining how to start the server.
- Add quick status transition buttons to the task details modal.

### 4. File Length and Quality Constraints
- All modified and new files must remain strictly under 500 lines.
- Audit with `python scripts/lint_file_lengths.py`.

---

## Acceptance Criteria

- [x] Kanban cards can be dragged and dropped between columns.
- [x] Dragging does not trigger the task modal.
- [x] Columns display a visible drop indicator while hovering.
- [x] Task server receives update requests and modifies task files on disk.
- [x] `README.md` and `dashboard.html` are refreshed after status updates.
- [x] Modal includes quick status buttons.
- [x] All files comply with the 500-line limit.
- [x] Automated tests pass.
