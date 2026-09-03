# TASK-059: Remove Backpack Button from HUD Header Bar

- **Status:** READY
- **Priority:** P1
- **Category:** UI / Cleanup
- **Target Branch:** `feature/remove-backpack-button-hud`
- **Related Tasks:** [TASK-028](TASK-028-junk-box-ui-opening-and-board-transfer.md), [TASK-039](TASK-039-junk-box-sidebar-integration-and-pegboard-display.md), [TASK-042](TASK-042-hopper-positioning-top-ui-bar-and-debug-menu.md)

## Description

Remove the loose backpack / bag button and its badge from the top HUD header bar.
The Junk Box now lives directly in the right sidebar panel, and keyboard shortcuts (`I`, `B`, `Esc`) open and close the drawer.
The HUD bag button is redundant and clutters the reserved top bar space.

---

## Requirements

### 1. Game Coordinator HUD Cleanup
- Remove the bag button creation call `_inventory_btn = _build_bag_button()` in `scenes/main/game_coordinator.gd`.
- Remove the child addition `left_panel.add_child(_inventory_btn)` from `scenes/main/game_coordinator.gd`.
- Remove the badge update signal connection and `_update_bag_button_badge()` method in `scenes/main/game_coordinator.gd`.
- Remove the unused `_inventory_btn` variable.

### 2. UI Builder and Helper Cleanup
- Remove or deprecate `build_bag_button()`, `update_bag_button_badge()`, and `create_bag_icon_image()` in `scenes/main/game_coordinator_ui.gd`.
- Ensure `GameState.junk_box` continues normal inventory operations without UI badge overhead.
- Ensure keyboard shortcuts (`I`, `B`, `Esc`) still toggle the Junk Box correctly.

### 3. Automated Tests
- Update `tests/test_ui_buttons_audit.gd` to remove or adjust the bag button test case.
- Add or update test coverage to verify that the top header bar does not contain the bag button.
- Run the full headless test suite to verify no regressions occur.

---

## Acceptance Criteria

- [ ] The top HUD header bar does not contain the backpack / bag button.
- [ ] No errors occur when `GameState.junk_box` emits the `inventory_changed` signal.
- [ ] Keyboard input keys (`I`, `B`, `Esc`) still toggle the Junk Box.
- [ ] Automated headless tests pass cleanly without failures.
