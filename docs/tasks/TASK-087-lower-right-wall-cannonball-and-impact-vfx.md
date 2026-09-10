# TASK-087: Lower Right Battlefield Wall Sprite, Cannonball Projectile, and Impact VFX

- **Status:** READY
- **Priority:** P1
- **Category:** UI / Visuals / VFX
- **Target Branch:** `feature/lower-right-wall-cannonball-impact-vfx`
- **Related Tasks:** [TASK-004](TASK-004-right-panel-and-comic-cutouts.md), [TASK-013](TASK-013-wall-art-production.md), [TASK-043](TASK-043-replace-drawn-cannons-with-sprite-assets.md), [TASK-046](TASK-046-cannon-scrolling-terrain-animation.md)

## Description

This task adds the wall sprite opposite the cannon in the lower right battlefield area.
Currently, the cannon fires into empty space without an opposing target.
This task also adds a dedicated cannonball sprite and impact visual effects.
When the cannon fires, a cannonball travels horizontally from the muzzle to the wall.
When the cannonball hits the wall, an impact effect plays and damages the wall.

---

## Requirements

### 1. Lower Right Wall Sprite Presentation
- Position a wall sprite opposite the cannon on the right side of the lower battlefield area.
- Use castle wall or medieval stone wall texture assets from the project library.
- Make sure that the wall sprite aligns vertically with the cannon muzzle.
- Support hit flash and rumble reactions when a cannonball strikes the wall.

### 2. Cannonball Sprite Projectile
- Replace procedural drawn shapes with a cannonball sprite asset.
- Use the cannonball texture asset from the pirate pack (`cannonBall.png`).
- Spawn the cannonball at the muzzle coordinates of the cannon.
- Animate horizontal travel from the cannon muzzle to the wall impact point.

### 3. Wall Impact Visual Effects (VFX)
- Trigger a dynamic impact explosion when the cannonball reaches the wall.
- Use spritesheet impact VFX textures from the project library (such as `Impact_Cartoon Hit` or `Impact_Hit_Lv1`).
- Play particle sparks and debris scattering upon impact.
- Remove the cannonball projectile node cleanly upon impact.

### 4. Event Synchronization and Signal Integration
- Connect projectile launch to the cannon firing signal (`cannon_fired_at_wall` or `main_fired`).
- Synchronize projectile travel duration with wall damage events and health bar updates.
- Support wall destruction sequences when wall health reaches zero.

### 5. Automated Tests and Verification
- Create automated unit tests in `tests/test_lower_right_wall_combat_visuals.gd`.
- Test that the wall sprite and cannonball sprite load asset textures correctly.
- Test that firing triggers the cannonball travel sequence towards the wall.
- Test that impact VFX instantiate at the wall impact coordinates.
- Make sure that all headless unit tests pass cleanly.

---

## Acceptance Criteria

- [ ] A wall sprite displays opposite the cannon in the lower right battlefield panel.
- [ ] The cannonball uses a sprite texture asset instead of procedural code drawing.
- [ ] The cannonball travels horizontally from the cannon muzzle to the wall.
- [ ] Impact VFX play when the cannonball collides with the wall.
- [ ] Wall hit flash and damage reactions trigger in sync with projectile impact.
- [ ] Automated headless unit tests verify visual instantiation and event flow.
- [ ] Source files remain under the 500-line project limit.
