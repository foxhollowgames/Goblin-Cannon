# TASK-042: Hopper Repositioning, Top UI Bar & Debug Menu Integration

- **Status:** READY
- **Priority:** P1
- **Category:** UI / Layout / Controls
- **Target Branch:** `feature/hopper-top-bar-debug-menu`
- **Related Tasks:** [TASK-019](TASK-019-hopper-steering-controls.md), [TASK-041](TASK-041-remove-hopper-mouse-control.md)

## Description

Move the hopper down below the top gold counter to reserve the top bar area exclusively for UI elements.
Consolidate all loose debug buttons on screen into a structured debug menu option housed within the reserved top bar space.

---

## Requirements

### 1. Hopper Repositioning & Top Bar UI Reservation
- Shift the hopper spawn location and horizontal steering boundaries down below the gold counter and top header UI area.
- Reserve the top screen bar space exclusively for header UI elements (gold counter, resource indicators, and utility menus).
- Ensure ball release trajectory and hopper collision checks remain accurate from the updated y-position.

### 2. Debug Menu Integration
- Add a dedicated Debug Menu button / panel inside the top UI header bar.
- Move all loose debug buttons (ball spawn tools, board clearing controls, wall health adjustments, and test state triggers) inside the top bar debug menu.
- Provide collapsible or popup display functionality for the debug menu so debug controls do not clutter the active playfield.

### 3. Automated Verification
- Create automated unit tests in `tests/test_hopper_top_bar_debug_menu.gd`.
- Verify that the hopper spawn position and movement boundary y-coordinates sit strictly beneath the top UI bar height.
- Verify that all debug control buttons exist as child elements within the top UI bar debug menu.

---

## Acceptance Criteria

- [ ] The hopper is positioned and moves strictly beneath the gold counter and top header bar.
- [ ] Top screen bar area is reserved exclusively for header UI panels.
- [ ] All debug buttons are consolidated inside a collapsible debug menu housed in the top UI bar.
- [ ] Debug controls remain fully operational from within the top UI debug menu.
- [ ] Headless unit tests pass.
