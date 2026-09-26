# balance

[Learning index](../LEARNINGS.md)

## <a id="lrn-043"></a> LRN-043: Exponential Wall HP and Gold Scaling Model
- **Task:** TASK-022
- **Category:** balance
- **Created:** 2026-09-01T22:28:20.208636
- **Tags:** 

### Context
Wall HP scaling and breach rewards need predictable mathematical curves to maintain pacing across 45-60 minute runs.

### Learning
Exponential formulas Health(n) = BaseHP * (1.35)^n and Gold(n) = BaseGold * (1.25)^n keep progression pacing calibrated while preventing arithmetic overflow.

### Guideline
Use CityDefinition.get_wall_hp_max_for_index and get_wall_breach_gold_reward for all wall health and resource payout calculations.

