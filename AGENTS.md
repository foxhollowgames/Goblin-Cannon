# Agent instructions

Start with [CLAUDE.md](CLAUDE.md). It is a short file map, not a required reading list.
The single workflow policy is [docs/AGENT_WORKFLOW.md](docs/AGENT_WORKFLOW.md).

- Sync with main before changes. Preserve unrelated work. Use a dedicated branch.
- Reuse the task packet; create one for new implementation work. Routine closure uses the existing packet.
- Select light or full verification by risk. Do not run full gameplay audits or spawn reviewers for routine documentation and closure.
- Direct edits are allowed. Local Qwen is optional for proven repetitive jobs.
- Use one implementation owner. Required reviewers receive a small brief and diff, not full conversation history.
- Keep source files within 500 lines, subject to the existing audited baselines. Follow docs/CODING_STANDARDS.md for GDScript.
- Preserve stable IDs, saved data, deterministic gameplay, and observable outcome tests.
- Keep raw test evidence. Regenerate the dashboard after task changes.
- Use included usage only. Follow the workflow's usage checkpoints. Stop owned processes and review agents before handoff.
