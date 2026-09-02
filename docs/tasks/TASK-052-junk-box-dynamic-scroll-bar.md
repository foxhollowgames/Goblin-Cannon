# TASK-052: Junk Box Dynamic Scroll Bar Visibility

- **Status:** DONE

- **Priority:** P1
- **Category:** UI / Polish
- **Target Branch:** `feature/junk-box-dynamic-scroll-bar`
- **Related Tasks:** [TASK-027](TASK-027-junk-box-backpack-inventory-system.md), [TASK-028](TASK-028-junk-box-ui-opening-and-board-transfer.md), [TASK-039](TASK-039-junk-box-sidebar-integration-and-pegboard-display.md)

## Description

Change the Junk Box scroll container behavior.
Hide the scroll bar when all items fit inside the view area.
Show the scroll bar only when items go off the page.

---

## Requirements

### 1. Dynamic Scroll Bar Visibility
- Configure the vertical scroll bar mode for the Junk Box panel.
- Hide the scroll bar when items fit inside the view panel without overflow.
- Show the scroll bar when item count or item positions extend past the visible area.

### 2. Container Layout Adjustment
- Adjust container margins dynamically when the scroll bar shows or hides.
- Keep the layout clean without visual jitter during scroll bar changes.

### 3. Automated Tests
- Add unit tests in `tests/test_junk_box_dynamic_scroll.gd`.
- Verify that the scroll bar hides when item count is below the overflow limit.
- Verify that the scroll bar shows when item count goes above the overflow limit.

---

## Acceptance Criteria

- [x] The scroll bar stays hidden while Junk Box items fit inside the view container.
- [x] The scroll bar appears when Junk Box items extend past the container edge.
- [x] The Junk Box layout updates smoothly during scroll bar state changes.
- [x] Headless unit tests verify dynamic scroll bar visibility logic.

