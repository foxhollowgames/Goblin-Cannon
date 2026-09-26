# asset-resources

[Learning index](../LEARNINGS.md)

## <a id="lrn-052"></a> LRN-052: External Asset Pools and VFX Spritesheet Storage
- **Task:** TASK-040
- **Category:** asset_resources
- **Created:** 2026-09-02T09:29:34.649549
- **Tags:** 

### Context
Agents require knowledge of external local asset packs for graphics and particle effects.

### Learning
External asset pack directory C:\Users\josep\Desktop\Games\Essentials VFX Spritesheets contains VFX spritesheets for particle effects, explosions, and impact animations alongside in-repo Kenney assets.

### Guideline
When sourcing visual assets and particle effects, inspect both assets/ and C:\Users\josep\Desktop\Games\Essentials VFX Spritesheets.

## <a id="lrn-074"></a> LRN-074: Preloaded Asset Pack Tile and VFX Spritesheet Integration
- **Task:** TASK-040
- **Category:** asset_resources
- **Created:** 2026-09-02T11:56:31.004823
- **Tags:** 

### Context
Replacing programmer shapes with Kenney stone wall tiles and Essentials VFX explosion sheets across combat scenes

### Learning
Preloading Texture2D assets and drawing textured rects inside CanvasItem _draw() ensures crisp asset rendering across battlefields and particle bursts while avoiding runtime allocations

### Guideline
Preload stone wall tiles and VFX spritesheets at file load time and render them inside CanvasItem _draw() using explicit region rects for animation frames

## <a id="lrn-098"></a> LRN-098: Goblin Mood and Reset Hand Sprite Integration
- **Task:** TASK-040
- **Category:** asset_resources
- **Created:** 2026-09-03T10:42:06.468547
- **Tags:** 

### Context
Replacing placeholder goblin art in comic vignette panels and reset effects.

### Learning
Preloading Kenney Zombie character poses for mood states and Monster Builder arm sprites for grab effects provides rich visual feedback while retaining procedural draw fallbacks.

### Guideline
Preload character pose textures in UI panels and monster limb sprites in custom effects, updating TextureRect or draw_texture_rect with procedural fallbacks.

