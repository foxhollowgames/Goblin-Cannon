# TASK-011: Character Art Asset Production

- **Status:** BACKLOG
- **Priority:** P2
- **Category:** Art Production
- **Target Branch:** `feature/character-art-production`

## Description

Produce character sprites and portraits for the main goblin and secondary characters.
All assets must express the comic book feel and include multiple stress and damage states.

## Core Requirements

1. **Main Goblin Assets:**
   - Base idle sprite, firing pose, victory pose, and defeat pose.
   - Multi-state emotional visuals: Confident/Happy -> Stressed/Angry -> Manic/Unstable.
2. **Secondary Character Concept Portraits:**
   - Necromancer, Beastmancer, Mechanic, and 4th character dialogue and selection portraits.
3. **Enemy and Boss Sprites:**
   - Shire guards, archers, and village boss character sprites.

---

## AI Ideas & Proposals (Optional / Pending User Decision)

> [!NOTE]
> - **Asset Generation Method:** Hand-draw the hero base poses, then use image generation tools for multi-state facial expressions and variation cleanup.
> - **Animation Standard:** 2D cutout / skeletal animation with Godot `AnimationPlayer` or sprite sheet flipbooks.

---

## Acceptance Criteria

- [ ] Character sprites delivered in high-resolution PNG format with transparent backgrounds.
- [ ] Sprites imported cleanly into Godot with appropriate texture filter settings.
- [ ] Multi-state character portraits switch dynamically based on player health state.
