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

## Scope and Usage Guardrails

10. **Separate feature work from refactoring**: A feature task may add only the smallest seams needed for its behavior. Broad extraction, renaming, file movement, and cleanup belong in a separate task packet with its own acceptance tests.
11. **Vertical slice before expansion**: Start with one representative source, one output path, and one complete outcome test. Do not add more ball types, relic families, UI surfaces, or acquisition sources until that slice passes.
12. **One implementation owner**: Use one coding agent for a shared gameplay slice. Review agents may inspect completed work, but multiple agents must not edit the same gameplay files at the same time.
13. **Review at usage gates**: Check included usage before work, at 50% of the five-hour window, and at 70%. Stop at a gate to checkpoint unless the remaining work is small and already verified. Never use paid/API credits or reset redemption.
14. **Focused verification order**: Run focused outcome tests first, then real-physics tests, then the full quality audit. Do not spend a full audit run on a slice whose focused tests already fail.
15. **Raw test result is authoritative**: Accept a test pass only when the raw Godot process exits with code 0, has no script errors, and reports zero failed assertions. Wrapper output that contains a misleading pass string is not evidence.
16. **Outcome tests before breadth**: Every new gameplay path must test its observable result, including exact counts, energy conservation, ownership cleanup, expiry, population limits, and one-time collection. A parser check or signal emission alone is insufficient.
17. **Checkpoint on architectural drift**: Stop and create a follow-up task when a feature begins changing unrelated combat, UI, acquisition, or save systems. Record the reason and the last verified state in the active task packet.
18. **Clean handoff**: Before pausing or switching agents, record changed files, test command and raw result, known failures, running processes, and remaining scope in the task packet. Remove rejected scratch outputs and stop delegated agents.



