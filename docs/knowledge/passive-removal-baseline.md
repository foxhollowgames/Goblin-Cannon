# Passive removal baseline and migration

Task: TASK-101. Work in progress.

## Scope inventory

- Acquisition: milestone stats, wall-break synergy entries, chest numeric upgrades, boss amplifiers, debug stores, and scenario overrides.
- Placement: PolyominoRelicDatabase registers relic IDs as upgrade stacks when Board slots a device.
- Consumers: Board peg-hit, explosion, chain, drain, split, gold, and return-to-hopper paths; Peg durability and recovery; cannon threshold and damage; EnergyManager; conduit timing; hopper width.
- Display: reward catalog descriptions, inventory stat panels, almanac counts, debug event text, and glossary terms.

## Migration rule

Keep physical relic items and their active goal rewards. Keep ordinary ball abilities and special pegs.
Old passive scalar inputs and registries accept writes but discard them. They have no stored effect state.
Old apply-stat and add-upgrade entry points cannot change gameplay.
Campaign persistence already writes campaign progress only. Legacy scenario passive fields are ignored.
Relic ownership must come from physical inventory and board items, not passive stacks.

## Baseline for TASK-104

Use the existing base cannon damage, charge threshold, ball energy, peg durability, and recovery values.
Do not add compensating bonuses. Keep active relic payouts unchanged until TASK-100 is approved.
Measure the loss of passive output separately from the later temporary-ball redesign.
Compare matched seeds, permanent balls, peg layouts, and wall timers before changing balance.

## Verification targets

Inject legacy IDs and scalar values. Check cannon damage, charge, peg durability, recovery, and leech output remain at baseline.
Place, rotate, move, remove, and return physical relics. Check inventory conservation and absent global bonuses.
Check physical activation still pays its current reward. Check ordinary ball effects still work.
Check all normal and debug catalogs show active device effects only.

## Recorded starting values

- Main cannon charge: 100 display energy, or 10,000 internal units.
- Main cannon damage: 10 wall damage per shot.
- Default ball starting energy: 3 display energy.
- Ordinary peg hit: 1 display energy before ordinary ball or peg mechanics.
- Leech: 1 display energy per second for 10 seconds.
- Energize: existing maximum of three peg-durability stacks.

These values come from the current constants, ball definition, Board, and cannon.
They are a measurement baseline, not a new balance target. Special pegs and physical device rewards can produce different output.
