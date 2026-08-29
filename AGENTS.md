# Agent instructions

**Start with [`CLAUDE.md`](./CLAUDE.md)** at the repository root. It defines the reading order for this project (Godot config → architecture → tests → optional orchestration workflow) and a compact map of where gameplay code lives.

Do not duplicate long exploration: follow that order before opening unrelated paths.

## Project Rules
1. **Always be up to date with `main`**: Before making any changes in this project, make sure that we're up to date with `main` (`git pull origin main`).
2. **Sub-Agent Lifecycle & Immediate Teardown**: When delegating work to sub-agents, the orchestrating agent must explicitly terminate them (`manage_subagents(Action="kill")` or `manage_subagents(Action="kill_all")`) immediately after their deliverables are received and verified. Never leave finished sub-agents lingering in `idle` or `waiting_for_dependents` states.
3. **Clean Process Exits**: Ensure test scripts and background processes exit cleanly without holding DLL or file locks open.

