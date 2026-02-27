# Rapier Physics (2D) – Installation

This project is configured to use **Rapier2D** as the 2D physics engine for better stability, determinism, and no ghost collisions.

## Install the addon

1. **From Godot Asset Library (recommended)**  
   - Open Godot → **Project** → **AssetLib**.  
   - Search for **Rapier Physics**.  
   - Install one of:
     - **Rapier Physics 2D – Fast Version with Parallel SIMD Solver** (general use)
     - **Rapier Physics 2D – Slower Version with Cross Platform Deterministic** (if you need cross‑platform determinism)
   - Restart the editor if prompted.

2. **Manual install**  
   - Download the latest release from [github.com/appsinacup/godot-rapier-physics/releases](https://github.com/appsinacup/godot-rapier-physics/releases).  
   - From the release zip, copy the **addons** contents (e.g. `godot-rapier2d`) into this project’s `addons/` folder.

## No plugin toggle

**Rapier does not appear in Project → Project Settings → Plugins.** That’s normal. It’s a GDExtension that registers a physics engine when the project loads; there is no editor plugin to enable. You don’t need to turn anything on in the Plugins tab.

## Verify Rapier is active

- **Project** → **Project Settings** → enable **Advanced** (top right).  
- Go to **Physics** → **2D**.  
- **Physics Engine** should be **Rapier2D** (this is already set in `project.godot`).  
- If the dropdown shows Rapier2D and the project runs without physics errors, Rapier is in use.

## Docs and presets

- Docs: [godot.rapier.rs](https://godot.rapier.rs)  
- In **Project Settings** → **Physics** → **Rapier** you can choose **Performance** or **Stability** presets and tune solver/contact settings.
