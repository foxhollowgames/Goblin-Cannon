# TASK-088: Rework Intervention Visual Effects and Peg Presentation

- **Status:** READY
- **Priority:** P1
- **Category:** UI / Visuals / VFX
- **Target Branch:** `feature/rework-intervention-visual-effects`
- **Related Tasks:** [TASK-040](TASK-040-asset-pack-sprite-audit-and-replacement.md), [TASK-050](TASK-050-boss-intervention-popup-trolls.md), [TASK-087](TASK-087-lower-right-wall-cannonball-and-impact-vfx.md)

## Description

This task replaces procedural shapes on board intervention pegs with high quality assets.
Currently, the merchant peg, buffet table, and other interventions use simple procedural lines and circles.
These visuals look temporary and unpolished.
This task upgrades the spawn previews, peg sprites, and break visual effects with textures from our asset packs.

---

## Requirements

### 1. Merchant Peg Visual Overhaul
- Replace the procedural money bag drawings with dedicated item sprites from the Kenney asset packs.
- Add an animated sparkle or aura spritesheet from the VFX pack to `board_event_preview.gd`.
- Show an animated gold shimmer effect around the active merchant peg.
- Trigger a coin burst visual effect when a ball activates the merchant shop.

### 2. Buffet Table Visual Overhaul
- Replace procedural table drawings with food and feast sprites from the asset library.
- Upgrade `buffet_table_preview.gd` with animated steam puff spritesheet effects.
- Upgrade `buffet_table_break_effect.gd` with food particle bursts and impact debris.
- Enhance the rumble feast sequence while balls stick to the table before release.

### 3. Additional Intervention Peg Upgrades
- Replace the procedural chest drawings in `treasure_chest_preview.gd` with chest sprite assets.
- Add sparkle bursts when the player breaks the treasure chest peg.
- Upgrade `sticky_slime_preview.gd` and slime peg graphics with slime splat and bubble textures.
- Upgrade black hole vortex visuals with animated swirl spritesheet assets.

### 4. Node Lifecycle and Asset Management
- Make sure that all spawned visual effect nodes free memory cleanly after playback.
- Maintain separate visual layers so sprites do not hide ball collisions.
- Keep all modified GDScript files under the 500-line repository limit.

### 5. Automated Tests and Verification
- Create automated unit tests in `tests/test_intervention_visual_effects.gd`.
- Verify that the intervention preview nodes load valid textures from the asset directory.
- Verify that the break effect nodes instantiate and free cleanly.
- Make sure that all headless unit tests pass.

---

## Acceptance Criteria

- [ ] The merchant peg uses dedicated sprite assets instead of procedural lines.
- [ ] The merchant spawn preview uses an animated VFX spritesheet.
- [ ] The buffet table uses food and table sprite assets.
- [ ] The buffet table break effect uses asset pack particle bursts.
- [ ] Treasure chest, sticky slime, and black hole interventions use asset pack graphics.
- [ ] Automated headless unit tests verify visual node instantiation and texture loading.
- [ ] All modified source files remain under the 500-line project limit.
