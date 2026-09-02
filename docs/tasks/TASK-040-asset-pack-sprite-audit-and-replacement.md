# TASK-040: Asset Pack Sprite Audit and Replacement

- **Status:** BACKLOG
- **Priority:** P2
- **Category:** Art Production
- **Target Branch:** `feature/asset-pack-sprite-replacement`

## Description

Examine existing asset packs and select suitable replacement sprites for characters, goblins, walls, and UI elements.

## Core Requirements

1. **Asset Pack Audit:**
   - Search the Kenney Game Assets collection in `assets/` for green characters, goblins, and medieval monsters.
   - Search for stone walls, castle fortifications, and gate structures.
2. **Goblin Sprite Replacement:**
   - Identify suitable goblin or green monster sprites for hero character states.
   - Replace placeholder programmer art with selected asset pack sprites.
3. **Wall and Fortification Sprite Replacement:**
   - Identify wall tiles, gates, and fortification textures.
   - Replace temporary wall graphics across battlefield scenes.
4. **UI and Item Asset Integration:**
   - Select matching buttons, frames, and icons from asset packs for UI scenes.

---

## AI Ideas & Proposals (Optional / Pending User Decision)

> [!NOTE]
> - **Color Adjustments:** Use Godot CanvasItem shaders to adjust sprite tint if needed.
> - **Sprite Sheet Slicing:** Create Godot AtlasTextures to extract individual tiles from sheet assets.

---

## Acceptance Criteria

- [ ] Kenney asset packs audited for goblin and wall graphics.
- [ ] Suitable goblin and creature sprites assigned to character placeholders.
- [ ] Wall and fortification sprites assigned to battlefield wall nodes.
- [ ] All replaced assets render cleanly in game scenes without scale issues.
