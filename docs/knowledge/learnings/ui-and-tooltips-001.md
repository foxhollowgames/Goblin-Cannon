# ui-and-tooltips

[Learning index](../LEARNINGS.md)

## <a id="lrn-110"></a> LRN-110: Relic Tooltip Simplification and Metadata Removal
- **Task:** TASK-067
- **Category:** ui_and_tooltips
- **Created:** 2026-09-03T18:50:32.733551
- **Tags:** 

### Context
Relic tooltips in Junk Box and on board previously showed redundant metadata text such as tier, size, shape, components, and machinery descriptions.

### Learning
Removing redundant technical metadata keeps tooltips clean and focused on essential gameplay details: relic title, activation requirement, and relic effect.

### Guideline
Format relic tooltips to show only the relic title, activation requirement, and relic effect, while delegating tier display to visual styling.

## <a id="lrn-121"></a> LRN-121: Campaign 1 Relic Hover Tooltips Audit
- **Task:** TASK-075
- **Category:** ui_and_tooltips
- **Created:** 2026-09-09T19:03:56.954198
- **Tags:** 

### Context
TASK-075 required auditing and refining all relic activation requirements and effects in PolyominoRelicDatabase.

### Learning
Ensuring consistent activation language and verifying all relics via automated iteration catches inconsistencies with component configurations early.

### Guideline
Always audit relic tooltips with comprehensive test loops that assert non-empty, component-aligned activation text across all database items.

