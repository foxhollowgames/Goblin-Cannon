# refactoring

[Learning index](../LEARNINGS.md)

## <a id="lrn-096"></a> LRN-096: Removal of minion systems and dead combat references
- **Task:** TASK-045
- **Category:** refactoring
- **Created:** 2026-09-03T10:05:13.757062
- **Tags:** 

### Context
Minions were deprecated in favor of a direct siege combat loop against fortifications and walls, leaving unused minion files and color constants.

### Learning
Removing deprecated gameplay entity scripts and scenes requires auditing autoload constants, architecture documentation, and test suites to prevent dangling references.

### Guideline
When removing deprecated gameplay mechanics, audit autoloads for orphaned helper methods and constants, update architecture docs, regenerate AI directory, and verify the full test suite.

