# Agent instructions

**Start with [`CLAUDE.md`](./CLAUDE.md)** at the repository root. It defines the reading order for this project (Godot config → architecture → tests → optional orchestration workflow) and a compact map of where gameplay code lives.

Do not duplicate long exploration: follow that order before opening unrelated paths.

## Project Rules
1. **Always be up to date with `main`**: Before making any changes in this project, make sure that we're up to date with `main` (`git pull origin main`).
2. **Sub-Agent Lifecycle & Immediate Teardown**: When delegating work to sub-agents, the orchestrating agent must explicitly terminate them (`manage_subagents(Action="kill")` or `manage_subagents(Action="kill_all")`) immediately after their deliverables are received and verified. Never leave finished sub-agents lingering in `idle` or `waiting_for_dependents` states.
3. **Clean Process Exits**: Ensure test scripts and background processes exit cleanly without holding DLL or file locks open.
4. **Mandatory Feature & Fix Workflow Cycle**: For any bug fix, improvement, or feature work:
   1. Pre-Task Knowledge Retrieval (`python scripts/learnings.py query <topic>`).
   2. Branch and implement changes on a dedicated feature branch (`feature/...` or `fix/...`).
   3. Update AI directory (`python scripts/generate_directory.py`) if files or signatures changed.
   4. Run GDScript quality & length linter (`python scripts/lint_gdscript.py`).
   5. Verify headless test suite passes (`godot --headless -s tests/run_tests.gd`).
   6. Open a GitHub Pull Request (`gh pr create`).
   7. Invoke an independent `pr_reviewer` sub-agent to audit code quality and test coverage.
   8. Resolve any findings, get approval, and merge into `main` (`gh pr merge`).
   9. Terminate all sub-agents immediately (`manage_subagents(Action="kill_all")`).
   10. Run the post-merge learning loop (`python scripts/learnings.py add`).
5. **Mandatory Local Ollama Code Generation**: For all code generation, editing, and test authoring, use `python scripts/ollama_coder.py [generate|edit|test]` with local Qwen 2.5 Coder.
6. **Maximum File Length (500 lines)**: Source files must not exceed 500 lines. Run `python scripts/lint_file_lengths.py` to audit file lengths across the repository.
7. **Directory Maintenance & Coding Standards**: Follow `docs/CODING_STANDARDS.md`. Maintain `docs/DIRECTORY.md` via `python scripts/generate_directory.py`.



