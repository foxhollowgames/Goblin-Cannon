# Goblin Cannon — LLM navigation (read this first)

Use this file as the **single entry point**. Do not explore the repo at random until you have skimmed the steps below.

## Reading order (by task)

| Order | File | Purpose |
|------:|------|---------|
| 1 | **`project.godot`** | Main scene, autoloads, display, physics (small file). |
| 2 | **`docs/ARCHITECTURE.md`** | Game design: pipeline, signals, managers, determinism, folder intent. |
| 3 | **`.cursor/rules/testing.mdc`** | When and how to run headless tests (`tests/run_tests.gd`). |
| 4 | **`.cursor/rules/godot-path.mdc`** | Full path to the Godot executable on this machine (for running tests). |
| 5 | **`docs/ROADMAP.md`** | Master roadmap: 6-playthrough story campaign, incremental loop, comic UI. |
| 6 | **`docs/tasks/README.md`** | Master task board: active tasks, workflow states, and priorities. |


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
