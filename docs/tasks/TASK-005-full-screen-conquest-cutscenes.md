# TASK-005: Full-Screen Wall Break Conquest Cinematics

- **Status:** BACKLOG
- **Priority:** P2
- **Category:** UI/Cinematics
- **Target Branch:** `feature/conquest-cinematics`

## Description

Implement full-screen comic takeover cutscenes when major walls are breached (Wall 1, Wall 2, City Boss).

## Requirements

1. **Trigger Condition:**
   - Wall HP reaches 0 on Wall 1, Wall 2, or City Boss.
   - Gameplay pauses cleanly.

2. **Cinematic Sequence:**
   - Full-screen comic panel overlay appears.
   - 3-panel dynamic comic sequence:
     1. Wall explosion / breach.
     2. Enemy retreat or surrender.
     3. Conquest reward chest presentation.
   - Player taps or clicks to dismiss and select the conquest upgrade.
   - Transition seamlessly into the next sector or city.

## Acceptance Criteria

- [ ] Cinematic triggers reliably when wall HP reaches zero.
- [ ] Visual transition does not desynchronize the physics simulation or reward state.
- [ ] Player can skip or advance panels with keyboard or mouse input.
- [ ] Memory frees properly after cutscene dismiss.
