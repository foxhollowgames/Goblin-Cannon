# TASK-004: Right Panel UI and Comic Cutout Vignettes

- **Status:** READY
- **Priority:** P1
- **Category:** UI/VFX
- **Target Branch:** `feature/comic-panel-ui`

## Description

Transform the right-side battlefield panel into a high-clarity combat telemetry monitor.
Add comic cutout action bubbles that show animated mini-cutscenes when weapons fire.

## Requirements

1. **Right Panel Telemetry:**
   - Real-time DPS meter and damage type breakdown.
   - Energy routing gauges (Cannon, Sidearms, Shields).
   - Enemy wave composition and fortification health bars.
   - Status effect duration indicators (Fire, Frozen, Lightning).

2. **Comic Action Bubbles:**
   - Pop-in panel vignette triggers on main cannon and heavy sidearm fire.
   - Animated comic art illustrates the character firing and the shell impacting the wall.
   - Halftone action lines and comic typography ("KAPOW!", "BOOM!").
   - Multi-state visuals reflect real-time health and stress states (Goblin expression, cannon heat, wall damage).

## Acceptance Criteria

- [ ] Telemetry displays accurate, live combat numbers without UI lag.
- [ ] Comic popup triggers correctly on firing events and dismisses without blocking input.
- [ ] Multi-state sprites switch based on actual entity health values.
- [ ] UI scales cleanly across target display resolutions.
