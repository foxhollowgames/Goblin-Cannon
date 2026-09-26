# controls

[Learning index](../LEARNINGS.md)

## <a id="lrn-007"></a> LRN-007: Hopper Steering and Keybind Separation
- **Task:** TASK-019
- **Category:** controls
- **Created:** 2026-08-28T21:42:17.515992
- **Tags:** 

### Context
A and D keys were previously intercepted by debug overlay and almanac keybinds in GameCoordinator and Hopper only followed mouse position.

### Learning
Game controls must not conflict with debug hotkeys. Moving debug toggles to function keys (F3) and letter keys away from WASD ensures unhindered player steering.

### Guideline
Reserve WASD and Arrow keys exclusively for player-controlled motion. Use function keys (F1-F12) or modifier combinations for debug tools.

