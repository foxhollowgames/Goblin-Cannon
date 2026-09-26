# subagents

[Learning index](../LEARNINGS.md)

## <a id="lrn-002"></a> LRN-002: Sub-Agent Immediate Lifecycle Teardown
- **Task:** TASK-027
- **Category:** subagents
- **Created:** 2026-08-28T19:53:36.789089
- **Tags:** 

### Context
Sub-agents spawned via invoke_subagent stay in 'idle' or 'waiting_for_dependents' state after finishing their work, waiting for potential follow-up messages.

### Learning
Sub-agents do not self-destruct by default. If the orchestrator does not explicitly kill them, they consume agent slots and may appear hung to users.

### Guideline
Always call manage_subagents(Action='kill_all') or kill specific conversation IDs immediately after receiving and verifying sub-agent deliverables.

## <a id="lrn-018"></a> LRN-018: Open-Model Subagent Allocation & Test State Isolation
- **Task:** TASK-033
- **Category:** subagents
- **Created:** 2026-08-29T09:23:36.894900
- **Tags:** 

### Context
Dispatching subagents with open-source coding models requires explicit role definitions and test clean state isolation.

### Learning
Qwen3 Coder and GLM 5.2 provide high accuracy for Godot 4 GDScript, and tests must explicitly clear GameState before board instantiations to prevent state leaks.

### Guideline
Define specialized subagents with clear Godot 4 constraints and call _ensure_clean_state() in test functions that instantiate Board.

