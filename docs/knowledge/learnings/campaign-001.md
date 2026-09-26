# campaign

[Learning index](../LEARNINGS.md)

## <a id="lrn-046"></a> LRN-046: Six-Playthrough Story Campaign Architecture
- **Task:** TASK-002
- **Category:** campaign
- **Created:** 2026-09-01T22:32:06.197821
- **Tags:** 

### Context
GameState tracks 6 distinct campaign runs, character archetypes, unlocked McGuffins, and convergence triggers.

### Learning
start_campaign_run and complete_campaign_run handle sequential unlock gating across all 6 playthroughs, automatically setting convergence_active on run 6.

### Guideline
Use GameState.start_campaign_run, complete_campaign_run, and save_campaign_progress/load_campaign_progress for multi-run campaign state management.

