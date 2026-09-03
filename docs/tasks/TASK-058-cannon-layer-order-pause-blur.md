# TASK-058: Cannon Layer Order and Pause Blur Hierarchy

- **Status:** READY
- **Priority:** P1
- **Category:** UI / Visuals
- **Target Branch:** `feature/cannon-layer-order-pause-blur`
- **Related Tasks:** [TASK-042](TASK-042-hopper-positioning-top-ui-bar-and-debug-menu.md), [TASK-043](TASK-043-replace-drawn-cannons-with-sprite-assets.md), [TASK-044](TASK-044-pause-game-for-comic-overlay-scenes.md)

## Description

Move the cannon visuals and its overlay to an appropriate canvas layer order.
Currently, `CannonOverlay` is configured at `layer = 15` while reward draft modals and pause blur layers (`ModalLayer`) are at `layer = 10`.
When the game pauses for conquest rewards or upgrade drafting, the background blur shader and dim overlay do not cover the cannon.
The cannon sprite and charge bar render unblurred and on top of the pause blur layer.

---

## Requirements

### 1. Canvas Layer Order Correction
- Adjust the canvas layering hierarchy so full-screen pause blur layers and modal windows cover the cannon.
- Make sure `RewardsManager` modal layer (`_modal_layer`) and pause overlay screens render on a higher layer (such as `layer = 20`, matching `FullscreenComicTakeover`), or adjust `CannonOverlay` to sit below modals.
- When the game pauses with a blur backdrop, the cannon and charge bar must be blurred and dimmed behind the modal window.

### 2. Gameplay Visual Layering
- The cannon sprite, charge bar, and muzzle blast animations must continue to render correctly over sidebar backgrounds during normal gameplay.
- Flying energy particle effects must continue to travel from the board to the cannon without clipping or hidden states.

### 3. Automated Tests and Verification
- Update layer assertions in `tests/test_hopper_top_bar_debug_menu.gd`.
- Add test cases verifying that `_modal_layer` or modal dialogs have a higher layer index than `CannonOverlay`.
- Run the full test suite (`godot --headless -s tests/run_tests.gd`) to confirm zero regressions.

---

## Acceptance Criteria

- [ ] Modal draft windows and pause blur overlays render above the cannon.
- [ ] Cannon sprite and charge bar are blurred and dimmed when pause modal is active.
- [ ] Cannon visuals remain fully visible and correctly layered over sidebar backgrounds during active play.
- [ ] All unit tests pass in headless mode.