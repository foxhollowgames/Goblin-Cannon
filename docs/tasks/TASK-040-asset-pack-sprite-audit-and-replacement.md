# TASK-040: Asset Pack Sprite Audit and Replacement

- **Status:** BACKLOG
- **Priority:** P2
- **Category:** Art Production
- **Target Branch:** `feature/asset-pack-sprite-replacement`

## Description

Examine existing asset packs and select suitable replacement sprites for characters, goblins, walls, visual effects, and UI elements.
Available asset resource pools include:
- In-repo assets: `assets/Kenney Game Assets All-in-1 3.4.0`
- External local asset directory: `C:\Users\josep\Desktop\Games\Essentials VFX Spritesheets`

## Core Requirements

1. **Asset Pack Audit:**
   - Search the Kenney Game Assets collection in `assets/` for green characters, goblins, and medieval monsters.
   - Search `C:\Users\josep\Desktop\Games\Essentials VFX Spritesheets` for particle effects, explosions, impacts, and projectile animations.
   - Search for stone walls, castle fortifications, and gate structures.
2. **Goblin Sprite Replacement:**
   - Identify suitable goblin or green monster sprites for hero character states.
   - Replace placeholder programmer art with selected asset pack sprites.
3. **Wall and Fortification Sprite Replacement:**
   - Identify wall tiles, gates, and fortification textures.
   - Replace temporary wall graphics across battlefield scenes.
4. **VFX and Particle Enhancement:**
   - Integrate sprite sheets from `C:\Users\josep\Desktop\Games\Essentials VFX Spritesheets` into Godot AnimatedSprite2D and GPUParticles2D nodes.
5. **UI and Item Asset Integration:**
   - Select matching buttons, frames, and icons from asset packs for UI scenes.

---

## AI Ideas & Proposals (Optional / Pending User Decision)

> [!NOTE]
> - **Color Adjustments:** Use Godot CanvasItem shaders to adjust sprite tint if needed.
> - **Sprite Sheet Slicing:** Create Godot AtlasTextures to extract individual tiles from sheet assets.

---

## Acceptance Criteria

- [ ] Kenney asset packs and `Essentials VFX Spritesheets` audited for goblin, wall, and VFX graphics.
- [ ] Suitable goblin and creature sprites assigned to character placeholders.
- [ ] Wall and fortification sprites assigned to battlefield wall nodes.
- [ ] Particle and impact animations sourced from `Essentials VFX Spritesheets`.
- [ ] All replaced assets render cleanly in game scenes without scale issues.
