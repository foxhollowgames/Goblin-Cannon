# Goblin Cannon file map

Read [docs/AGENT_WORKFLOW.md](docs/AGENT_WORKFLOW.md) once when starting implementation. On resume, read the current task checkpoint and changed instructions only.

| Need | Read |
|---|---|
| Current task | Relevant docs/tasks/TASK-*.md; docs/tasks/README.md for discovery only |
| Find source | Search with rg; consult relevant docs/DIRECTORY.md entries |
| Gameplay change | Relevant project.godot settings and docs/ARCHITECTURE.md sections |
| GDScript edit | docs/CODING_STANDARDS.md |
| Test setup | .cursor/rules/testing.mdc and .cursor/rules/godot-path.mdc |
| Past findings | python scripts/learnings.py query <specific-topic> |
| Multi-task planning | docs/agent-orchestration.md, only when needed |

Gameplay lives in scenes/ and resources/. Shared state lives in autoloads/.
Tests run through tests/run_tests.gd. Tooling lives in scripts/.
Do not load the full directory, architecture, learning collection, or roadmap for a small fix.
