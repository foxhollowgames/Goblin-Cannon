# TASK-022: Wall Health Exponential Scaling and Campaign Pacing Model

- **Status:** DONE
- **Priority:** P1
- **Category:** Math / Balance
- **Parent Task:** [TASK-001](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-001-gameplay-loop-and-pacing.md)
- **Target Branch:** `feature/exponential-scaling-pacing-model`

## Description

Design and implement the mathematical scaling curve for wall health and reward payouts.
Calibrate the model for a 45-to-60-minute single campaign playthrough.

## Requirements

1. **Exponential Wall Health Curve:**
   - Define the mathematical formula: $\text{Health}(n) = \text{BaseHP} \times (\text{Multiplier})^{n}$.
   - Calibrate base values and exponents so early walls fall quickly and later walls demand synergy optimization.

2. **Scrap and Gold Payout Curve:**
   - Scale resource rewards from wall hits and wall breaches to keep pace with component upgrade costs.

3. **Data-Driven Configuration:**
   - Store balance constants in a configuration resource or `autoloads/constants.gd`.

## Acceptance Criteria

- [x] Formula balances progression for a target 45-to-60-minute complete campaign run.
- [x] Wall health values scale predictably without arithmetic overflow.
- [x] Headless unit tests verify scaling formulas across all campaign stages.
