# worktrees

[Learning index](../LEARNINGS.md)

## <a id="lrn-003"></a> LRN-003: Windows Binary DLL Lock Handling During Worktree Cleanup
- **Task:** TASK-027
- **Category:** worktrees
- **Created:** 2026-08-28T19:53:39.507669
- **Tags:** 

### Context
When Godot runs tests inside a git worktree on Windows, binary plugins (e.g. libgodot_rapier.dll) may remain locked briefly by the OS process, preventing immediate folder deletion.

### Learning
Worktree removal can fail with 'Access is denied' or 'Resource busy' if child processes held file handles. The git metadata unlinks cleanly, but the physical folder might have lingering locks.

### Guideline
Use 'git worktree prune' to clean up git metadata after worktree operations. If physical directory deletion is locked, allow background handles to close or prune git references first.

