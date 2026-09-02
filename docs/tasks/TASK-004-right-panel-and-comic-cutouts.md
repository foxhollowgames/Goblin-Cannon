# TASK-004: Right Panel UI and Comic Cutout Vignettes

- **Status:** DONE
- **Priority:** P1
- **Category:** UI/VFX
- **Target Branch:** `feature/comic-panel-ui`

## Description

Transform the right side panel into a communicative UI.
Implement a cutout bubble that triggers when the cannon fires, showing a mini cutscene of the cannon firing and hitting the wall.

## Core Requirements

1. **Right Panel Communication UI:**
   - Transform the right panel so the player notices and reads combat information easily.

2. **Comic Action Cutout Bubbles:**
   - When the cannon fires, a cutout bubble appears on the screen.
   - A tiny mini-cutscene plays in the cutout showing the cannon firing and hitting the active wall.
   - The goblin is part of the mini-cutscene.
   - The visual states of the goblin, cannon, and wall represent actual live health and damage values.
   - Multi-state assets: Goblin states, cannon states, and wall degradation states.

---

## AI Ideas & Proposals (Optional / Pending User Decision)

> [!NOTE]
> - **Telemetry Dashboard Ideas:** Include energy routing meters, damage per second (DPS), and active status effect timers in the right panel.
> - **Cutout Transition:** Use quick spring pop-in animations with comic speech bubble tails pointing toward the cannon.

---

## Acceptance Criteria

- [x] Right side panel is redesigned into a communicative interface.
- [x] Cannon firing triggers the cutout bubble mini-cutscene.
- [x] Goblin, cannon, and wall visual assets reflect real-time health values.
- [x] Cutout bubble dismisses cleanly and does not block board interaction.
