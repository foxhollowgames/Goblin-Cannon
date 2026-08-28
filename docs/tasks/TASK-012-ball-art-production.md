# TASK-012: Ball Sprite and Visual State Asset Production

- **Status:** BACKLOG
- **Priority:** P2
- **Category:** Art Production
- **Target Branch:** `feature/ball-art-production`

## Description

Produce visual sprites, particle trails, and active glow states for all ball types in Campaign 1.

## Core Requirements

1. **Ball Sprites:**
   - 2D circular textures with comic line art and stylized shading.
   - Distinct icons or elemental motifs for Flame, Frost, Lightning, Split, Leech, and Gold balls.
2. **Visual States:**
   - Idle state, high-velocity motion blur, and peg collision impact flash.
3. **Particle VFX:**
   - Elemental trail effects for fire, ice, spark, and phantom balls.

---

## AI Ideas & Proposals (Optional / Pending User Decision)

> [!NOTE]
> - **Visual Tiering:** Add subtle golden or colored metallic outer rings to indicate Tier 2 and Tier 3 ball variants.
> - **Glow Shaders:** Implement lightweight Godot 2D canvas shaders for pulsing elemental auras.

---

## Acceptance Criteria

- [ ] Sprites created for all confirmed Tier 1 and Tier 2 ball definitions.
- [ ] Collision and trail VFX render cleanly without frame drops during multi-ball releases.
- [ ] Sprites assigned to ball resource definitions in the Godot project.
