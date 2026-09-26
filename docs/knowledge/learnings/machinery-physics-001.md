# machinery-physics

[Learning index](../LEARNINGS.md)

## <a id="lrn-115"></a> LRN-115: relic-machinery-contact-debounce
- **Task:** TASK-074
- **Category:** Machinery / Physics
- **Created:** 2026-09-09T18:32:35.469849
- **Tags:** 

### Context
Continuous ball contact across physics ticks caused repeated activations on machinery components.

### Learning
PolyominoMachineryComponent now maintains ball contact state and exit ticks. PolyominoModuleNode.check_ball_collision gates activation on initial contact entry and clears contact on exit.

### Guideline
Always enforce contact debounce and exit cooldowns on continuous physical ball contact with pinball machinery components.

