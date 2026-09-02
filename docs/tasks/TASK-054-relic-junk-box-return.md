# TASK-054: Relic Junk Box Return Inventory System

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** UI / Gameplay / Systems
- **Target Branch:** `feature/relic-junk-box-return`
- **Related Tasks:** [TASK-027](TASK-027-junk-box-backpack-inventory-system.md), [TASK-028](TASK-028-junk-box-ui-opening-and-board-transfer.md), [TASK-031](TASK-031-board-relic-repositioning-and-dragging.md)

## Description

Make sure that players can send relics from the board back into the junk box inventory.
Make sure that returning a relic restores original pegboard cells and pegs cleanly.

---

## Requirements

### 1. Return Relics to Junk Box Inventory
- Allow players to drag or send an active relic from the board back into the junk box.
- Unslot the relic from all occupied board cells upon return.
- Put the returned relic item back into the available junk box inventory list.

### 2. Pegboard Grid Restoration
- Restore empty grid cells and original pegs under the returned relic.
- Re-enable peg physics and collision shapes at the cleared board locations.
- Remove active relic passives and modifiers from the game state upon return.

### 3. Inventory State Management
- Update the junk box UI to display the returned relic item.
- Retain item metadata and level when returning a relic to inventory.
- Prevent duplicate item creation during board-to-inventory transfers.

### 4. Automated Tests
- Write unit tests in `tests/test_relic_junk_box_return.gd`.
- Test returning a placed relic to the junk box inventory.
- Test that board cells and pegs reset after relic removal.
- Test that relic passive effects stop after item return.

---

## Acceptance Criteria

- [ ] Players can drag or send active board relics into the junk box inventory.
- [ ] Relic removal restores original pegboard grid cells and pegs.
- [ ] Junk box UI updates to display the returned relic item.
- [ ] Relic passives and modifiers stop when the relic leaves the board.
- [ ] Unit tests pass cleanly in headless mode.
