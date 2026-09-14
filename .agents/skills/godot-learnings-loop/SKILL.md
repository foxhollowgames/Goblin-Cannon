---
name: godot-learnings-loop
description: >-
  Standardizes pre-task knowledge retrieval and post-merge learning database
  recording for Goblin Cannon. Use before starting any task packet to retrieve
  past learnings, and after merging pull requests into main to record new insights.
---

# Godot Learnings Loop Skill

This skill guides querying the institutional learnings database before starting work and recording new findings after merging pull requests.

---

## When to Use

Activate this skill:
1. **Pre-Task Retrieval:** Before writing code, query relevant historical learnings so you avoid repeated mistakes or anti-patterns.
2. **Post-Merge Loop:** After merging a pull request into `main`, record architectural guidelines, unexpected quirks, or physics findings.

---

## Pre-Task Knowledge Retrieval

Query the knowledge database by topic or keyword:

```bash
python scripts/learnings.py query "<keyword>"
```

### Common Search Topics:
- `python scripts/learnings.py query "physics"`
- `python scripts/learnings.py query "ball"`
- `python scripts/learnings.py query "relic"`
- `python scripts/learnings.py query "ui"`
- `python scripts/learnings.py query "lint"`
- `python scripts/learnings.py query "tooling"`

---

## Post-Merge Learning Recording

After merging a PR into `main`:

```bash
python scripts/learnings.py add
```

### Standard Tags Taxonomy:
- `physics`: Ball trajectories, collisions, bounces, gravity, energy states.
- `machinery`: Kinetic devices, bumpers, wire gates, kickers, loops, traps.
- `ui`: HUD, junk box, modal dialogs, layouts, anchors, tooltips.
- `architecture`: Class decomposition, signals, state management, file length limits.
- `tooling`: Dashboards, linters, generators, test runners, git workflows.
- `optimization`: Performance, rendering, cleanup, resource lifecycle.

### Quality Criteria for New Learnings:
- Keep the summary punchy and actionable (1 sentence).
- Frame the guideline as a general rule ("Always do X when Y" or "Avoid A because B").
- Link code pointers to canonical files.
- Mention the related task ID (e.g. `TASK-095`).
