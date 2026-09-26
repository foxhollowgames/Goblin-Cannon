# inventory-and-board-systems

[Learning index](../LEARNINGS.md)

## <a id="lrn-089"></a> LRN-089: relic_junk_box_return
- **Task:** TASK-054
- **Category:** inventory_and_board_systems
- **Created:** 2026-09-02T18:28:06.182119
- **Tags:** 

### Context
Returning board polyomino relics to junk box inventory while cleanly clearing grid cells, restoring suppressed pegs, and removing passive effects.

### Learning
Board.unslot_module must unsuppress pegs, clear cell occupancy, remove GameState passives, and reuse the original JunkBoxItem instance to retain level metadata.

### Guideline
Always route board-to-inventory relic returns through Board.return_module_to_junk_box to ensure atomic peg restoration, passive cleanup, and metadata retention without duplicate items.

