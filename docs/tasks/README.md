# Goblin Cannon — Master Task Management Board

This directory contains the canonical task packets and backlog for Goblin Cannon.
All tasks use structured Markdown with status, priority, and clear acceptance criteria.

---

## 1. Task Workflow States

- **BACKLOG:** Task is defined and scheduled for future development.
- **READY:** Task requirements and acceptance criteria are complete. Ready for implementation.
- **IN_PROGRESS:** Active development on a dedicated feature branch.
- **IN_REVIEW:** Pull Request is open on GitHub awaiting review or test validation.
- **DONE:** Pull Request is merged into `main` and all tests pass.

---

## 2. Master Task Index

| Task ID | Title | Category | Priority | Status | Branch |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [TASK-001](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-001-gameplay-loop-and-pacing.md) | Gameplay Loop & Incremental Pacing | Gameplay | P1 | READY | `feature/gameplay-loop-pacing` |
| [TASK-002](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-002-story-campaign-architecture.md) | Six-Playthrough Story Campaign Architecture | Narrative | P1 | READY | `feature/story-campaign-arch` |
| [TASK-003](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-003-character-bespoke-mechanics.md) | Character Bespoke Progression Mechanics | Systems | P1 | READY | `feature/character-mechanics` |
| [TASK-004](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-004-right-panel-and-comic-cutouts.md) | Right Panel UI & Comic Cutout Vignettes | UI/VFX | P1 | READY | `feature/comic-panel-ui` |
| [TASK-005](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-005-full-screen-conquest-cutscenes.md) | Full-Screen Wall Break Conquest Cinematics | UI/Cinematics | P2 | BACKLOG | `feature/conquest-cinematics` |
| [TASK-006](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-006-comic-book-feel-art-style.md) | Comic Book Feel — Art Style Not Determined | Art Direction | P2 | BACKLOG | `feature/comic-book-feel` |
| [TASK-007](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-007-pr-workflow-and-version-control.md) | Git Branch and Pull Request Protocol | DevOps | P0 | DONE | `feature/roadmap-and-task-management` |

---

## 3. Sub-Agent PR Review Protocol

Every pull request must complete an independent sub-agent review cycle:
1. Push the branch and open a GitHub Pull Request (`gh pr create`).
2. Invoke an independent `pr_reviewer` sub-agent without conversational context.
3. If the sub-agent reports major findings, address them and repeat review.
4. Merge the Pull Request into `main` after receiving approval.
