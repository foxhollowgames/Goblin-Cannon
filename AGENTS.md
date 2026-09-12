# Agent instructions

**Start with [`CLAUDE.md`](./CLAUDE.md)** at the repository root. It defines the reading order for this project (Godot config → architecture → tests → optional orchestration workflow) and a compact map of where gameplay code lives.

Do not duplicate long exploration: follow that order before opening unrelated paths.

## Project Rules
1. **Always be up to date with `main`**: Before making any changes in this project, make sure that we're up to date with `main` (`git pull origin main`).
2. **Automatic Task Packet Creation on User Requests**: Whenever the user asks for something to be fixed, improved, added, or resolved and there is no existing task packet in `docs/tasks/`, the agent MUST immediately create a new task packet (`docs/tasks/TASK-XXX-<name>.md`), register it in `docs/tasks/README.md`, and regenerate the task dashboard (`python scripts/generate_task_dashboard.py`) before beginning implementation. Never handle ad-hoc user instructions without creating and tracking a dashboard task packet.
3. **Sub-Agent Lifecycle & Immediate Teardown**: When delegating work to sub-agents, the orchestrating agent must explicitly terminate them (`manage_subagents(Action="kill")` or `manage_subagents(Action="kill_all")`) immediately after their deliverables are received and verified. Never leave finished sub-agents lingering in `idle` or `waiting_for_dependents` states.
4. **Clean Process Exits**: Ensure test scripts and background processes exit cleanly without holding DLL or file locks open.
5. **Mandatory Feature & Fix Workflow Cycle**: For any bug fix, improvement, or feature work:
   1. Task Packet Verification/Creation (if none exists, create `docs/tasks/TASK-XXX-<name>.md`, register in `docs/tasks/README.md`, run `python scripts/generate_task_dashboard.py`).
   2. Pre-Task Knowledge Retrieval (`python scripts/learnings.py query <topic>`).
   3. Branch and implement changes on a dedicated feature branch (`feature/...` or `fix/...`).
   4. Update AI directory (`python scripts/generate_directory.py`) if files or signatures changed.
   5. Run GDScript quality & length linter (`python scripts/lint_gdscript.py`).
   6. Verify headless test suite passes (`godot --headless -s tests/run_tests.gd`).
   7. Open a GitHub Pull Request (`gh pr create`).
   8. Invoke an independent `pr_reviewer` sub-agent to audit code quality and test coverage.
   9. Resolve any findings, get approval, and merge into `main` (`gh pr merge`).
   10. Terminate all sub-agents immediately (`manage_subagents(Action="kill_all")`).
   11. Run the post-merge learning loop (`python scripts/learnings.py add`).
6. **Mandatory Local Ollama Code Generation**: For all code generation, editing, and test authoring, use `python scripts/ollama_coder.py [generate|edit|test]` with local Qwen 2.5 Coder.
7. **Maximum File Length (500 lines)**: Source files must not exceed 500 lines. Run `python scripts/lint_file_lengths.py` to audit file lengths across the repository.
8. **Directory Maintenance & Coding Standards**: Follow `docs/CODING_STANDARDS.md`. Maintain `docs/DIRECTORY.md` via `python scripts/generate_directory.py`.
9. **Automatic Task Dashboard Maintenance**: Any time a task is created, updated, status-changed, or deleted (CRUD operations), you MUST run `python scripts/generate_task_dashboard.py` to regenerate the visual task board (`docs/tasks/dashboard.html`).



