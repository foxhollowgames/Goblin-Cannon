# TASK-069: In-Game Machinery Components Dashboard

- **Status:** IN_PROGRESS
- **Priority:** P1
- **Category:** Documentation / UI / Tooling
- **Target Branch:** `feature/in-game-components-dashboard`
- **Related Tasks:** [TASK-047](TASK-047-pinball-widget-research-and-machine-layout-analysis.md), [TASK-051](TASK-051-componentized-pinball-machinery-roster.md)

## Description

Create an interactive dashboard that corresponds to the physical components dashboard.
The dashboard must show the in-game art, the component name, and a description of the component behavior for each game component.

---

## Requirements

### 1. In-Game Component Roster Coverage
- Include all pinball machinery components from the game roster.
- Cover components such as pop bumpers, drop targets, standup targets, spinners, and scoops.
- Cover ball locks, guide tracks, orbit loops, slingshots, and rollover switches.
- Cover captive balls, mechanical diverters, vertical up kickers, bash toys, and outlane kickbacks.

### 2. In-Game Art Presentation
- Show the visual art for each component as it appears in the game.
- Use high-resolution previews, rendered sprites, or interactive canvas elements.
- Make sure that each image shows the exact art style of the project.

### 3. Component Details and Game Behavior
- State the canonical in-game name of each component.
- Give a clear description of the component purpose in the game.
- Explain how the component behaves during gameplay.
- Detail the collision physics, impulse forces, energy rewards, and trigger events.

### 4. Interactive Dashboard Structure
- Create an HTML dashboard in `docs/knowledge/` that matches the style of `pinball-research-dashboard.html`.
- Give filter controls, search controls, and image expansion dialogs.
- Link the dashboard in `docs/knowledge/` documentation and project navigation.

---

## Acceptance Criteria

- [x] An interactive HTML dashboard exists in `docs/knowledge/`.
- [x] The dashboard shows in-game art for all game machinery components.
- [x] Each component entry shows the name, description, and game behavior.
- [x] The dashboard layout matches the visual design of the physical components dashboard.
- [x] The master task index references the new dashboard.
