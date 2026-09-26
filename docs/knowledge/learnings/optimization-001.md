# optimization

[Learning index](../LEARNINGS.md)

## <a id="lrn-004"></a> LRN-004: Model Tier Allocation for Fast and Cheap Execution
- **Task:** TASK-027
- **Category:** optimization
- **Created:** 2026-08-28T19:53:41.939404
- **Tags:** 

### Context
Delegating all tasks to heavy reasoning models increases latency and token costs significantly, while light models may struggle with complex UI layout/drawing logic.

### Learning
Data models, serialization, and test writing are deterministic and execute rapidly on 'flash' models. Intricate custom UI rendering, drag-and-drop controllers, and math-heavy physics logic succeed best on 'pro' models.

### Guideline
Partition tasks into (1) Data/Model layer -> flash, (2) UI/Input/Visuals -> pro, (3) Testing/QA -> flash, (4) Integration/Review -> pro for maximum speed and cost efficiency.

