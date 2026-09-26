# orchestration

[Learning index](../LEARNINGS.md)

## <a id="lrn-130"></a> LRN-130: Automatic Task Packet Creation on User Instructions
- **Task:** TASK-089
- **Category:** orchestration
- **Created:** 2026-09-12T15:38:18.770553
- **Tags:** 

### Context
Users frequently provide ad-hoc instructions or issue reports without referencing a task packet, risking untracked changes on the dashboard

### Learning
Enforcing immediate task packet creation and dashboard regeneration before implementation ensures all work is visually tracked and prioritized

### Guideline
Whenever the user provides instructions to fix, resolve, or build something without an existing task packet, create docs/tasks/TASK-XXX-<name>.md, register in docs/tasks/README.md, and run python scripts/generate_task_dashboard.py before beginning code changes

