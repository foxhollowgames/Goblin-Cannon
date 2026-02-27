# Rapier Physics Integration

The project uses [Godot Rapier Physics](https://github.com/appsinacup/godot-rapier-physics) as the **2D physics engine** (Rapier2D). Collision and `move_and_collide()` for the ball and pegs are handled by Rapier instead of the default Godot 2D physics.

## Why Rapier

- **Determinism** – Aligns with ARCHITECTURE §1.4 (deterministic sim). Use the “Cross Platform Deterministic” build if you need identical results across platforms.
- **Stability** – Better stacking and fewer vibrations; helps plinko pegs and ball.
- **No ghost collisions** – Reduces spurious or duplicate contacts.
- **Drop-in** – Same nodes (`CharacterBody2D`, `StaticBody2D`, `move_and_collide()`) work; only the engine behind them changes.

## What stays the same

- **Ball motion** is still driven by our **sim tick** (§1.5, §1.10): the Board calls `ball.step_one_sim_tick()` once per sim tick; we do **not** use `_physics_process` for gameplay. Gravity and bounce are applied in code; Rapier is used for **collision detection** and the collision normal when we call `move_and_collide()`.
- **Pegs** remain `StaticBody2D` with circle shapes; Rapier simulates them.
- **project.godot**: `physics/2d/physics_engine = "Rapier2D"`.

## Install

See **addons/README_RAPIER.md** for install steps (AssetLib or manual). The project will not run with Rapier until the addon is installed and the plugin enabled.

## Optional: Rapier project settings

In **Project Settings** → **Physics** → **Rapier** you can adjust:

- **Presets**: Performance vs Stability.
- **Num Iterations**: e.g. 4–8 for plinko (more = more stable, slower).
- **Length Unit 2D**: Default 100 (100 px ≈ 1 m); leave as-is unless you change scale.

Determinism is documented here: [Rapier – Determinism](https://godot.rapier.rs/docs/documentation/determinism/).
