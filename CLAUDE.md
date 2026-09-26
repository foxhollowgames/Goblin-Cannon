# Goblin Cannon — LLM navigation (read this first)

Use this file as the **single entry point**. Do not explore the repo at random until you have skimmed the steps below.

## Project Rules
- **Always be up to date with `main`**: Before making any changes in this project, make sure that we're up to date with `main` (`git pull origin main`).
- **Automatic Task Packet Creation on User Requests**: Whenever the user asks for something to be fixed, improved, added, or resolved and there isn't already a task packet in `docs/tasks/`, the agent MUST immediately create a new task packet (`docs/tasks/TASK-XXX-<name>.md`), register it in `docs/tasks/README.md`, and regenerate the task dashboard (`python scripts/generate_task_dashboard.py`) before beginning implementation. Never work on ad-hoc user instructions without creating and tracking a dashboard task packet.
- **Sub-Agent Immediate Teardown**: When delegating work to sub-agents, the orchestrator agent must explicitly terminate them (`manage_subagents(Action="kill")` or `manage_subagents(Action="kill_all")`) immediately after their deliverables are received and verified.
- **Mandatory PR Review & Learning Loop**: Every fix and feature must complete the full cycle: (1) Task packet verification/creation, (2) Knowledge retrieval, (3) Feature branch, (4) Headless tests pass, (5) PR creation (`gh pr create`), (6) Independent `pr_reviewer` sub-agent review pass, (7) PR merge (`gh pr merge`), (8) Sub-agent teardown, (9) Post-merge learning loop (`python scripts/learnings.py add`).
- **Bounded local generation**: Use local Qwen first with the correct language and a prompt file. After two failed attempts on the same small change, record the failure and use direct Codex edits, as approved by the user. Follow [docs/AGENT_WORKFLOW.md](docs/AGENT_WORKFLOW.md).
- **Maximum File Length (500 lines)**: Source files must not exceed 500 lines. Run `python scripts/lint_file_lengths.py` to audit file lengths.
- **GDScript Quality & Directory Maintenance**: All code must follow `docs/CODING_STANDARDS.md`. Run `python scripts/generate_directory.py` and `python scripts/lint_gdscript.py` before submitting a PR.
- **Task Dashboard Maintenance**: Any task packet CRUD operation (create, update, status change, delete) MUST be followed by running `python scripts/generate_task_dashboard.py` to refresh `docs/tasks/dashboard.html`.


## Reading order (by task)

| Order | File | Purpose |
|------:|------|---------|
| 1 | **`project.godot`** | Main scene, autoloads, display, physics (small file). |
| 2 | **`docs/ARCHITECTURE.md`** | Game design: pipeline, signals, managers, determinism, folder intent. |
| 3 | **`docs/DIRECTORY.md`** | AI codebase map: every file, signal, system, and "where to find it" reference. |
| 4 | **`docs/CODING_STANDARDS.md`** | GDScript style, type annotations, 45-line func limit, docstrings, region tags. |
| 5 | **Targeted learning query** | Run `python scripts/learnings.py query <specific-topic>`; read matching entries with `show <ID>`. Use `docs/knowledge/LEARNINGS.md` only to locate categories. Do not read the full collection. |
| 6 | **`.cursor/rules/testing.mdc`** | When and how to run headless tests (`tests/run_tests.gd`). |
| 7 | **`.cursor/rules/godot-path.mdc`** | Full path to the Godot executable on this machine (for running tests). |
| 8 | **`docs/ROADMAP.md`** | Master roadmap: 6-playthrough story campaign, incremental loop, comic UI. |
| 9 | **`docs/tasks/README.md`** | Master task board: active tasks, workflow states, and priorities. |


**Only if** the user is doing **backlog / planner / multi-step agent workflow** (not normal gameplay coding): **`docs/agent-orchestration.md`** — conventions for planning vs implementation, isolation, quality loop.

**Do not** treat **`docs/cursor-orchestration-plan.md`** as a second spec — it is a short pointer to the canonical orchestration doc (avoids duplicate reading).

Read only the relevant sections in this order. For tooling-only tasks, skip gameplay details that cannot affect the change. Follow [the shared task workflow](docs/AGENT_WORKFLOW.md) for early baseline checks, usage gates, and one final audit. Keep a compact work map and do not repeat unchanged exploration.


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
