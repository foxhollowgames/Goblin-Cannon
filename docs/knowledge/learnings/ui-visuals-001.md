# ui-visuals

[Learning index](../LEARNINGS.md)

## <a id="lrn-064"></a> LRN-064: Replace Code-Drawn Cannons with Sprite Assets
- **Task:** TASK-043
- **Category:** ui_visuals
- **Created:** 2026-09-02T10:34:00.994995
- **Tags:** 

### Context
Procedural rect/circle drawing for battlefield cannon and UI cannon widget lacked visual quality and firing indicators

### Learning
Using texture assets (cannonMobile.png) combined with parallel Tweens for recoil displacement and explosion1.png for muzzle flash provides clean visual polish

### Guideline
Preload sprite texture assets for game objects and UI widgets, combining recoil shake Tweens and muzzle flash sprite overlays on firing events.

## <a id="lrn-065"></a> LRN-065: Single Cannon Rendering, Crisp Native Sprite Scale & Cartoon Coffee Fire VFX
- **Task:** TASK-043
- **Category:** ui_visuals
- **Created:** 2026-09-02T10:39:00.774827
- **Tags:** 

### Context
CircularCannonWidget and CannonVisual both drew cannon textures causing duplicate cannon rendering and blurry upscaling

### Learning
Removing texture drawing from widget container and rendering cannonMobile.png at native 43.5x30px in CannonVisual eliminates duplication and retains crisp sprite definition. Animating Impact_Fire_Lv1_spritesheet.png 4x4 region frames on firing signal provides rich fire VFX.

### Guideline
Keep UI widget containers dedicated to panel backgrounds and energy overlays while delegating cannon sprite rendering and fire VFX to CannonVisual at crisp unscaled dimensions.

## <a id="lrn-066"></a> LRN-066: Center-Left Cannon UI Positioning & Right-Aligned Fire VFX
- **Task:** TASK-043
- **Category:** ui_visuals
- **Created:** 2026-09-02T10:41:43.920256
- **Tags:** 

### Context
Cannon position needed to be centered on the left side of the bottom UI container with fire VFX lined up against the right side of the sprite

### Learning
Setting CannonVisual position to Vector2(50, 628) in battlefield_view.tscn and drawing Impact_Fire_Lv1_spritesheet.png at muzzle_right_x = center_x + 21.75 with horizontal recoil (_recoil_offset_x = -12.0) places the sprite cleanly in the center-left UI box and aligns fire VFX against the right edge.

### Guideline
Align rightward-firing cannon sprites at center-left UI container bounds and line up muzzle blast VFX regions directly against the right edge of the sprite.

## <a id="lrn-067"></a> LRN-067: Cannon Charge Overlay & UI Charge State Forwarding
- **Task:** TASK-043
- **Category:** ui_visuals
- **Created:** 2026-09-02T10:45:31.135706
- **Tags:** 

### Context
CannonVisual was reparented to CannonOverlay canvas layer and lacked an explicit charge overlay progress meter

### Learning
Adding set_charge and set_energy methods to CannonVisual and drawing a 54x6px gold/amber progress meter under the cannon sprite in _draw() with set_charge forwarding from center_panel_ui.gd ensures live charge visibility during combat.

### Guideline
Implement explicit set_charge methods on canvas overlay visual nodes and forward charge updates from center_panel_ui to maintain live charge meter overlays.

## <a id="lrn-068"></a> LRN-068: Flying Energy Particle VFX Destination Targeting
- **Task:** TASK-043
- **Category:** ui_visuals
- **Created:** 2026-09-02T10:51:53.950672
- **Tags:** 

### Context
Energy gain VFX particles flew to the center of the widget container box instead of the charge bar under the cannon

### Learning
Querying CannonVisual.global_position + Vector2(0.0, 18.0) in center_panel_ui.gd show_energy_gain ensures flying energy particles stream directly to the charge bar under the cannon sprite.

### Guideline
Calculate energy flow particle destination coordinates using the target visual node position (CannonVisual.global_position + Vector2(0.0, 18.0)) to align flying particles with the charge progress bar.

## <a id="lrn-069"></a> LRN-069: Gain Text Centering Underneath Charge Bar & 2-Stage Catch-Up Bar Animation
- **Task:** TASK-043
- **Category:** ui_visuals
- **Created:** 2026-09-02T11:05:54.879289
- **Tags:** 

### Context
Gain text label overlapped the charge bar and charge energy gains lacked clear visual feedback for jump amounts

### Learning
Setting label_w = 80.0, horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER, and position = end_pos + Vector2(-label_w * 0.5, 8.0) centers gain labels directly underneath the charge bar. Adding _target_ratio white lead bar with 0.35s TRANS_QUAD smooth yellow catch-up tweening gives clear energy jump visual feedback.

### Guideline
Center gain text labels horizontally underneath target UI bars and use a 2-stage white lead bar with smooth yellow catch-up fill animation for energy jumps.

## <a id="lrn-070"></a> LRN-070: Pure White Target Bar Accessibility & Non-Overlapping Segment Drawing
- **Task:** TASK-043
- **Category:** ui_visuals
- **Created:** 2026-09-02T11:09:11.334042
- **Tags:** 

### Context
Semi-transparent white drawn beneath or over yellow bars tint-blended into light yellow

### Learning
Drawing the lead target bar segment from liquid_ratio to _target_ratio separately using solid pure white Color(1.0, 1.0, 1.0, 1.0) with zero overlap over the yellow fill bar ensures pure #FFFFFF contrast for accessibility.

### Guideline
Render lead target bar segments using solid pure white Color(1.0, 1.0, 1.0, 1.0) starting at liquid_ratio to prevent color blending and guarantee high-contrast accessibility.

## <a id="lrn-071"></a> LRN-071: High-Contrast Visual Accessibility for Lead Target Jump Bar
- **Task:** TASK-043
- **Category:** ui_visuals
- **Created:** 2026-09-02T11:13:40.576121
- **Tags:** 

### Context
Adjacent white and yellow bars lacked stark visual contrast for users with visual impairments

### Learning
Rendering the lead target segment as a protruding 12px tall box with solid pure white Color(1.0, 1.0, 1.0, 1.0) fill, solid black outline Color(0.0, 0.0, 0.0, 1.0), and 2px vertical black separator line creates extreme shape and color contrast for visual accessibility.

### Guideline
Combine shape protrusion, black outline borders, and black separator lines around pure white target segments to guarantee extreme visual contrast for accessibility.

## <a id="lrn-072"></a> LRN-072: 0.5-Second Delay for Energy Charge Catch-Up Bar Animation
- **Task:** TASK-043
- **Category:** ui_visuals
- **Created:** 2026-09-02T11:15:26.923267
- **Tags:** 

### Context
The yellow catch-up bar started animating immediately on energy gain without allowing the viewer to register the target jump

### Learning
Adding .set_delay(0.5) to the _catchup_tween in set_energy() holds the high-contrast white lead bar steady for half a second before the yellow bar animates up to meet it.

### Guideline
Use .set_delay(0.5) on catch-up bar fill tweens to pause long enough for viewers to register energy jump amounts before animating.

## <a id="lrn-073"></a> LRN-073: Preserving Catch-Up Tween Delays in Per-Frame Energy Updates
- **Task:** TASK-043
- **Category:** ui_visuals
- **Created:** 2026-09-02T11:17:52.110498
- **Tags:** 

### Context
Calling set_energy every frame with unchanged energy values snapped liquid_ratio = new_ratio and killed active catch-up tweens

### Learning
Only mutating liquid_ratio when new_ratio < _target_ratio (energy reset) and launching tweens when new_ratio > _target_ratio allows tick-by-tick set_energy calls without interrupting running catch-up tween delays.

### Guideline
In per-frame progress bar setters, do not snap the animated fill ratio on same-ratio ticks; allow active delay tweens to run to completion.

