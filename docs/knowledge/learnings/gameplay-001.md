# gameplay

[Learning index](../LEARNINGS.md)

## <a id="lrn-042"></a> LRN-042: Wall Siege Timer and Defender Pushback Logic
- **Task:** TASK-021
- **Category:** gameplay
- **Created:** 2026-09-01T22:27:32.250353
- **Tags:** 

### Context
Wall siege failures need consistent defender pushback state transitions and 120s timer configuration.

### Learning
CombatManager owns wall siege timers and defender pushback transitions, emitting pushback_occurred signals to reset wall HP and decrement wall index.

### Guideline
Always handle wall timer expirations via CombatManager.apply_defender_pushback and ensure WALL_PHASE_TIME_SECONDS is set to 120.

## <a id="lrn-113"></a> LRN-113: multi_peg_machinery
- **Task:** TASK-072
- **Category:** gameplay
- **Created:** 2026-09-04T15:41:54.061619
- **Tags:** 

### Context
Multi-cell polyomino machinery size variations and unified collision

### Learning
Multi-peg pinball machinery uses MachineryLayoutMode.UNIFIED to spawn single centered components with dynamic radius and segment collision shapes.

### Guideline
When configuring multi-peg machinery, scale impulse and visual radii according to cell counts while keeping PolyominoModuleNode under the 500-line limit.

## <a id="lrn-137"></a> LRN-137: Merchant Relic Focus
- **Task:** TASK-096
- **Category:** gameplay
- **Created:** 2026-09-17T10:44:52.478212
- **Tags:** 

### Context
Merchant shop transition from balls and stats to deliberate relics and pegs

### Learning
Directing shop offerings to deliberate relics rather than balls/stats strengthens core pinball identity. Filtering generation on allow_ball_upgrades=false cleanly isolates merchant inventory without regressing other draft sources.

### Guideline
Keep ball upgrades out of standard merchant generation. Default shop relics to lowest tier (Tier 1) for current city to preserve high-tier excitement for wall break rewards.

## <a id="lrn-144"></a> LRN-144: Gate relic tiers across every normal source
- **Task:** TASK-102
- **Category:** gameplay
- **Created:** 2026-09-23T05:41:01.269750
- **Tags:** 

### Context
Third-city merchant tiers were capped at2 while legacy boss and wall pools could offer Tier3 early.

### Learning
A shared eligibility filter and complete physical roster give every retained Tier3 item a reachable city3 route. Free wall rewards avoid depending on uncertain gold income.

### Guideline
Test every normal reward source, every retained high-tier ID, and actual purchase flow. Distinguish acquisition probability from guaranteed income, and use small reviewed Qwen fragments for local code generation.

