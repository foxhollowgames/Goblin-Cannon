# TASK-041: Remove Hopper Mouse Control

- **Status:** BACKLOG
- **Priority:** P1
- **Category:** Controls
- **Target Branch:** `feature/remove-hopper-mouse-control`

## Description

Remove mouse motion tracking for hopper horizontal movement.
The hopper must move with keyboard input or explicit API functions only.

## Requirements

1. **Remove Mouse Input:**
   - Remove mouse event handling in `scenes/hopper/hopper.gd`.
   - Remove the `_mouse_control_active` state variable.
   - Remove mouse position tracking from physics calculations.

2. **Keyboard and Script Steering:**
   - Keep horizontal keyboard movement with `A`, `D`, and arrow keys.
   - Keep programmatic steering functions (`steer` and `set_steer_input`).

3. **Test Updates:**
   - Update tests in `tests/test_hopper_steering.gd`.
   - Verify mouse movement does not change the hopper position.

## Acceptance Criteria

- [ ] Mouse movement does not move the hopper.
- [ ] Keyboard keys (`A`, `D`, `Left Arrow`, `Right Arrow`) move the hopper.
- [ ] Functions `steer` and `set_steer_input` work without mouse input.
- [ ] Headless unit tests pass.
