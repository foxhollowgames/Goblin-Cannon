# TASK-026: Polyomino Internal Kinetic Machinery and Bumper Mechanics

- **Status:** READY
- **Priority:** P1
- **Category:** Gameplay / Physics
- **Target Branch:** `feature/polyomino-internal-machinery`

## Description

Implement the kinetic contraptions and interactive mechanisms embedded inside polyomino relic modules.

## Requirements

1. **Kinetic Machinery Sub-Components:**
   - **Pinball Bumpers:** Apply an outward force impulse and generate bonus mana when struck by a ball.
   - **Speed Boost Wheels:** Accelerate balls in a set vector upon contact.
   - **Mana Siphons:** Generate bonus energy per bounce without deflecting ball trajectories.
   - **Directional Deflectors:** Funnel balls into specific board columns or adjacent synergy pegs.

2. **Compound Module Scenes:**
   - Create Godot scene templates for multi-cell polyomino modules containing internal colliders and animated machinery.
   - Modules scale their internal component layout to match their polyomino shape.

3. **Audio and Visual Feedback:**
   - Trigger spring compression animations, sparks, and comic impact sounds when machinery activates.

## Acceptance Criteria

- [ ] Bumpers and speed wheels apply deterministic physics impulses to colliding balls.
- [ ] Internal machinery generates correct energy amounts to weapon pools.
- [ ] Visual animations and impact audio play reliably on ball contact.
- [ ] Headless unit tests pass with `tests/run_tests.gd`.
