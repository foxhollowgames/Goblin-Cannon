# Agent instructions

**Start with [`CLAUDE.md`](./CLAUDE.md)** at the repository root. It defines the reading order for this project (Godot config → architecture → tests → optional orchestration workflow) and a compact map of where gameplay code lives.

Do not duplicate long exploration: follow that order before opening unrelated paths.

## Project Rules
1. **Always be up to date with `main`**: Before making any changes in this project, make sure that we're up to date with `main` (`git pull origin main`).
2. **Sub-Agent Lifecycle & Immediate Teardown**: When delegating work to sub-agents, the orchestrating agent must explicitly terminate them (`manage_subagents(Action="kill")` or `manage_subagents(Action="kill_all")`) immediately after their deliverables are received and verified. Never leave finished sub-agents lingering in `idle` or `waiting_for_dependents` states.
3. **Clean Process Exits**: Ensure test scripts and background processes exit cleanly without holding DLL or file locks open.
4. **Post-Merge Evaluation & Learning Loop**: At the end of merging any feature/task into `main`, run an evaluation loop on lessons learned (engine quirks, math edge-cases, delegation patterns). Record them in the knowledge base via `python scripts/learnings.py add --task <TASK_ID> --category <CAT> --topic <TOPIC> --context <CTX> --learning <INSIGHT> --guideline <RULE>`, which automatically synchronizes [`docs/knowledge/LEARNINGS.md`](./docs/knowledge/LEARNINGS.md) and [`docs/knowledge/learnings.db`](./docs/knowledge/learnings.db).
5. **Pre-Task Knowledge Retrieval**: Before beginning complex tasks or sub-agent delegation, query existing learnings via `python scripts/learnings.py query <topic>` or read [`docs/knowledge/LEARNINGS.md`](./docs/knowledge/LEARNINGS.md) to maximize execution speed and cost efficiency.


