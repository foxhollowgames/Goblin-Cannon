# TASK-056: Visual Task Dashboard Expandable Task Details Modal

- **Status:** DONE
- **Priority:** P1
- **Category:** DevOps / Tooling / UI
- **Target Branch:** `feature/dashboard-task-detail-modal`
- **Related Tasks:** [TASK-007](TASK-007-pr-workflow-and-version-control.md)

## Description

Make the dashboard tasks expandable when clicked across all dashboard views (Kanban Board, Category Matrix, and Detailed List).
Clicking any task card or table row pops up an interactive, styled modal displaying comprehensive task details including description, requirements, acceptance criteria, branch, status, priority, and metadata, with easy dismissal and navigation options.

---

## Requirements

### 1. Interactive Expandable Cards and Rows
- In Kanban Board, Category Matrix, and Detailed List views, cards and table rows should be interactive and visually indicate clickability (`cursor-pointer`, hover border/bg highlight, subtle expand icon).
- Clicking any card or row opens the task details modal for that task.

### 2. Comprehensive Task Details Modal
- Modal appears as a centered dialog with a darkened backdrop blur.
- Header displays Task ID, Title, Status badge, Priority badge, Category, and Domain.
- Metadata strip displays Target Branch (with copy-to-clipboard button), Last Modified date/time, and link to task markdown file.
- Body displays formatted content parsed from the task packet: Description, Requirements, and Acceptance Criteria (with styled status checkboxes).
- Footer provides Previous Task / Next Task navigation buttons and a Close button.

### 3. Smooth Dismissal and Keyboard Navigation
- Modal can be closed via Close button (`✕`), clicking the backdrop outside the dialog, or pressing the `Escape` key.
- Pressing `Left Arrow` and `Right Arrow` keys navigates between previous and next tasks while modal is open.
- Opening the modal disables background body scrolling and restoring scrolling upon closure.

### 4. File Length and Quality Constraints
- Both `scripts/generate_task_dashboard.py` and `docs/tasks/dashboard.html` must strictly adhere to the project 500-line limit.
- Audit with `python scripts/lint_file_lengths.py`.

---

## Acceptance Criteria

- [x] Cards in Kanban view open task details modal on click.
- [x] Cards in Category Matrix view open task details modal on click.
- [x] Rows in Detailed List view open task details modal on click.
- [x] Modal displays full task packet details (description, requirements, acceptance criteria, branch, status, priority).
- [x] Modal closes via close button, backdrop click, or Escape key.
- [x] Modal supports Previous / Next task navigation buttons.
- [x] `scripts/generate_task_dashboard.py` and `docs/tasks/dashboard.html` remain under 500 lines.

