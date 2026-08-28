# TASK-006: Comic Book Feel — Art Style Not Determined

- **Status:** BACKLOG
- **Priority:** P2
- **Category:** Art Direction
- **Target Branch:** `feature/comic-book-feel`

## Description

Establish the general comic book presentation for the game.
The visual design must feel like a comic book with panels, action cutouts, and dynamic framing.
The specific art style is currently undecided (*Slots & Daggers* is under consideration as a reference).

## Core Requirements

1. **Comic Book Feel:**
   - Panel frames, comic typography, and dynamic sound effect overlays ("BOOM!", "KRAK!").
   - Action cutout bubbles that pop into view during cannon fire events.
   - Full-screen comic takeover cutscenes when major walls collapse.

2. **Asset Damage States:**
   - Multiple versions of the goblin, cannon, and wall assets in different states of health and damage.
   - Initial base assets may be drawn by hand, with state variants made by hand or with AI assistance.

---

## AI Ideas & Proposals (Optional / Pending User Decision)

> [!NOTE]
> - **Shader Exploration:** Prototype a Godot 2D halftone screen shader and ink wash post-process filter to enhance the comic book feel.
> - **Style Moodboard:** Create test mockups contrasting high-contrast ink (*Slots & Daggers* style) with vibrant cel-shaded color palettes.

---

## Acceptance Criteria

- [ ] Visual style decision finalized between hand-drawn or hybrid generation.
- [ ] Cutout bubble framing and comic typography integrated into UI assets.
- [ ] Multi-state asset pipeline documented and tested with sample sprites.
