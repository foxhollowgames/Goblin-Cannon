# Goblin Cannon — LLM navigation (read this first)

Use this file as the **single entry point**. Do not explore the repo at random until you have skimmed the steps below.

## Project Rules
- **Always be up to date with `main`**: Before making any changes in this project, make sure that we're up to date with `main` (`git pull origin main`).
- **Sub-Agent Immediate Teardown**: When delegating work to sub-agents, the orchestrator agent must explicitly terminate them (`manage_subagents(Action="kill")` or `manage_subagents(Action="kill_all")`) immediately after their deliverables are received and verified.
- **Mandatory PR Review & Learning Loop**: Every fix and feature must complete the full cycle: (1) Knowledge retrieval, (2) Feature branch, (3) Headless tests pass, (4) PR creation (`gh pr create`), (5) Independent `pr_reviewer` sub-agent review pass, (6) PR merge (`gh pr merge`), (7) Sub-agent teardown, (8) Post-merge learning loop (`python scripts/learnings.py add`).


## Reading order (by task)

| Order | File | Purpose |
|------:|------|---------|
| 1 | **`project.godot`** | Main scene, autoloads, display, physics (small file). |
| 2 | **`docs/ARCHITECTURE.md`** | Game design: pipeline, signals, managers, determinism, folder intent. |
| 3 | **`docs/knowledge/LEARNINGS.md`** | Historical learnings & Gotchas database (`python scripts/learnings.py query`). |
| 4 | **`.cursor/rules/testing.mdc`** | When and how to run headless tests (`tests/run_tests.gd`). |
| 5 | **`.cursor/rules/godot-path.mdc`** | Full path to the Godot executable on this machine (for running tests). |
| 6 | **`docs/ROADMAP.md`** | Master roadmap: 6-playthrough story campaign, incremental loop, comic UI. |
| 7 | **`docs/tasks/README.md`** | Master task board: active tasks, workflow states, and priorities. |


**Only if** the user is doing **backlog / planner / multi-step agent workflow** (not normal gameplay coding): **`docs/agent-orchestration.md`** — conventions for planning vs implementation, isolation, quality loop.

**Do not** treat **`docs/cursor-orchestration-plan.md`** as a second spec — it is a short pointer to the canonical orchestration doc (avoids duplicate reading).


---

## Where code lives

| Area | Path |
|------|------|
| Run scene | `res://scenes/main/main.tscn` (`run/main_scene` in `project.godot`) |
| Autoloads | `autoloads/game_state.gd`, `autoloads/constants.gd`, `autoloads/test_scenario.gd` |
| Gameplay | `scenes/` |
| Headless tests | `tests/` · runner `tests/run_tests.gd` |

**Conventions (one line):** signal up, call down; integer energy for gameplay; full rules in `docs/ARCHITECTURE.md`.

**Optional tooling:** `orchestration/` — local Node/TS helper for agent workflows; **not** required to open or run the game in the Godot editor.
