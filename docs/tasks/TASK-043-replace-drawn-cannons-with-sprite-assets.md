# TASK-043: Replace Drawn Cannons with Library Sprite Assets

- **Status:** DONE
- **Priority:** P1
- **Category:** UI / Visuals / Art Production
- **Target Branch:** `feature/replace-drawn-cannons-with-assets`
- **Related Tasks:** [TASK-004](TASK-004-right-panel-and-comic-cutouts.md), [TASK-040](TASK-040-asset-pack-sprite-audit-and-replacement.md)

## Description

Replace procedural code-drawn cannon visuals in `CannonVisual` and `CircularCannonWidget` with sprite assets from the project library.

---

## Requirements

### 1. Asset Selection & Integration
- Load the cannon sprite asset from `assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Pirate Pack/PNG/Retina/Ship parts/cannonMobile.png`.
- Replace procedural shape drawing in `scenes/combat/cannon_visual.gd` with texture rendering.
- Replace procedural shape drawing in `scenes/ui/circular_cannon_widget.gd` with texture rendering.

### 2. Visual Alignment, Recoil & Firing VFX
- Align sprite texture scale and position so muzzle points match cannon firing VFX positions.
- Add firing recoil tween animation (kick back on fire and smoothly return) to both `CannonVisual` and `CircularCannonWidget`.
- Add muzzle flash and particle smoke blast out from the front of the cannon barrel on firing.
- Preserve liquid energy fill overlays in `CircularCannonWidget`.
- Preserve status effect overlays (fire, ice, lightning) in `CannonVisual`.

### 3. Automated Verification
- Create unit tests in `tests/test_cannon_sprite_visuals.gd`.
- Verify that both visual nodes load the cannon texture asset correctly.
- Verify recoil animation triggers on firing signal/event.
- Verify headless unit tests pass.

---

## Acceptance Criteria

- [x] `CannonVisual` renders the library cannon sprite asset instead of procedural shapes.
- [x] `CircularCannonWidget` renders the library cannon sprite asset inside the liquid energy panel.
- [x] Cannon sprite triggers recoil shake tween and muzzle particle blast upon firing.
- [x] Muzzle firing positions and status effect overlays align with the sprite texture.
- [x] Headless unit tests pass.
