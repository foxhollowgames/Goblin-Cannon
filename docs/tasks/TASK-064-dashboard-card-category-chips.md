# TASK-064: Visual Task Dashboard Card Category Chips and File Path Removal

- **Status:** DONE
- **Priority:** P1
- **Category:** DevOps / Tooling / UI
- **Target Branch:** `feature/dashboard-card-category-chips`
- **Related Tasks:** [TASK-056](TASK-056-dashboard-task-detail-modal.md), [TASK-061](TASK-061-dashboard-drag-drop-task-status.md)

## Description

Refine the visual task cards on the dashboard (`docs/tasks/dashboard.html`):
1. Remove the truncated branch/file path from the bottom right of all task cards.
2. Condense the verbose raw categories into simplified high-level discipline chips: UX, UI, Art, Design, Coding, and Planning.
3. Color-code each category chip with distinct background and border styles so categories are instantly recognizable at a glance.

---

## Requirements

### 1. File Path Removal from Cards
- Remove the branch/path string from the bottom-right of task cards in `renderCard(t)`.
- Keep the full branch and copy button in the task details modal where it is useful and readable.

### 2. Simplified Category Chips
- Map raw task categories into one of six standard disciplines:
  - **UX**: Controls, input, interaction, steering, drag-drop
  - **UI**: Interface, layouts, HUD, typography, tooltips
  - **Art**: Visual assets, sprites, animations, cutscenes
  - **Design**: Game mechanics, synergies, balance, pacing
  - **Planning**: Research, documentation, roadmaps, campaigns
  - **Coding**: Logic, physics, engines, systems, devops, tooling
- Color each chip with distinct color styles:
  - UX: Cyan
  - UI: Blue
  - Art: Pink
  - Design: Amber
  - Coding: Emerald
  - Planning: Purple

### 3. File Length and Standards
- Keep `scripts/generate_task_dashboard.py` and `docs/tasks/dashboard.html` strictly under 500 lines.
- Verify with `python scripts/lint_file_lengths.py` and automated test suites.

---

## Acceptance Criteria

- [x] File path is removed from the bottom right of task cards.
- [x] Category chips are condensed into simplified states (UX, UI, Art, Design, Coding, Planning).
- [x] Each category chip uses distinct theme colors.
- [x] Modal retains full branch information and copy action.
- [x] All files comply with the 500-line limit.
- [x] Automated tests pass.
