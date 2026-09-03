# Goblin Cannon — Master Task Management Board

This directory contains the canonical task packets and backlog for Goblin Cannon.
All tasks use structured Markdown with status, priority, and clear acceptance criteria.

---

## Interactive Visual Task Dashboard

Open [`docs/tasks/dashboard.html`](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/dashboard.html) in your browser for an interactive visual task dashboard (Kanban Board, Category Matrix, Search, and Status Filters).

To update the HTML dashboard after editing task files, run:
```bash
python scripts/generate_task_dashboard.py
```

---

## 1. Task Workflow States

- **PARKED:** Idea or proposal on hold for future review.
- **BACKLOG:** Task is defined and scheduled for future development.
- **READY:** Task requirements and acceptance criteria are complete. Ready for implementation.
- **IN_PROGRESS:** Active development on a dedicated feature branch.
- **IN_REVIEW:** Pull Request is open on GitHub awaiting review or test validation.
- **DONE:** Pull Request is merged into `main` and all tests pass.

---

## 2. Master Task Index

| Task ID | Title | Category | Priority | Status | Branch |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [TASK-001](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-001-gameplay-loop-and-pacing.md) | Gameplay Loop & Incremental Pacing | Gameplay | P1 | DONE | `feature/gameplay-loop-pacing` |
| [TASK-002](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-002-story-campaign-architecture.md) | Six-Playthrough Story Campaign Architecture | Narrative | P1 | DONE | `feature/story-campaign-arch` |
| [TASK-003](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-003-character-bespoke-mechanics.md) | Character Bespoke Progression Mechanics | Systems | P1 | DONE | `feature/character-mechanics` |
| [TASK-004](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-004-right-panel-and-comic-cutouts.md) | Right Panel UI & Comic Cutout Vignettes | UI/VFX | P1 | DONE | `feature/comic-panel-ui` |
| [TASK-005](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-005-full-screen-conquest-cutscenes.md) | Full-Screen Wall Break Conquest Cinematics | UI/Cinematics | P2 | BACKLOG | `feature/conquest-cinematics` |
| [TASK-006](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-006-comic-book-feel-art-style.md) | Comic Book Feel — Art Style Not Determined | Art Direction | P2 | BACKLOG | `feature/comic-book-feel` |
| [TASK-007](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-007-pr-workflow-and-version-control.md) | Git Branch and Pull Request Protocol | DevOps | P0 | DONE | `feature/roadmap-and-task-management` |
| [TASK-008](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-008-build-archetypes-and-synergies.md) | Build Archetypes & Synergy Design | Design/Systems | P1 | DONE | `feature/build-synergies-design` |
| [TASK-009](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-009-final-ball-list-campaign-1.md) | Final Ball List & Abilities for Campaign 1 | Design | P1 | BACKLOG | `feature/final-ball-list-campaign-1` |
| [TASK-010](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-010-final-relic-list-campaign-1.md) | Final Relic List & Modifiers for Campaign 1 | Design | P1 | BACKLOG | `feature/final-relic-list-campaign-1` |
| [TASK-011](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-011-character-art-production.md) | Character Art Asset Production | Art Production | P2 | BACKLOG | `feature/character-art-production` |
| [TASK-012](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-012-ball-art-production.md) | Ball Sprite & Visual State Asset Production | Art Production | P2 | BACKLOG | `feature/ball-art-production` |
| [TASK-013](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-013-wall-art-production.md) | Wall & Fortification Multi-State Art Production | Art Production | P2 | BACKLOG | `feature/wall-art-production` |
| [TASK-014](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-014-cutscene-art-production.md) | Comic Cutout & Takeover Cutscene Art | Art Production | P2 | BACKLOG | `feature/cutscene-art-production` |
| [TASK-015](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-015-relic-art-production.md) | Relic Icon & Item Visual Asset Production | Art Production | P2 | BACKLOG | `feature/relic-art-production` |
| [TASK-016](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-016-typography-and-text-effects.md) | Typography & Comic Text Effect Specifications | Art/UI | P2 | BACKLOG | `feature/comic-typography` |
| [TASK-017](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-017-ui-art-and-telemetry-panels.md) | UI Art, Frames, and Telemetry Terminal Production | UI/Art | P2 | BACKLOG | `feature/ui-art-production` |
| [TASK-018](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-018-tetromino-module-crafting-and-fusion.md) | Tetromino Module Combining and Fusion Design | Systems/Gameplay | P1 | DONE | `feature/tetromino-module-fusion` |
| [TASK-019](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-019-hopper-steering-controls.md) | Hopper Steering and Active Aiming Controls | Controls | P1 | DONE | `feature/hopper-steering-controls` |
| [TASK-020](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-020-live-board-ghost-placement.md) | Live Board Ghost State and Placement Physics | Physics/Systems | P1 | DONE | `feature/live-board-ghost-placement` |
| [TASK-021](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-021-wall-siege-timer-and-pushback.md) | Wall Siege Timer, Auto-Progression, and Defender Pushback | Gameplay/Logic | P1 | DONE | `feature/wall-siege-timer-and-pushback` |
| [TASK-022](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-022-exponential-scaling-pacing-model.md) | Wall Health Exponential Scaling and Campaign Pacing Model | Math/Balance | P1 | DONE | `feature/exponential-scaling-pacing-model` |
| [TASK-023](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-023-emergency-tinkering-minigames-design.md) | Emergency Tinkering and Machine Breakdown Minigames Design | Design/Systems | P2 | PARKED | `feature/emergency-tinkering-minigames` |
| [TASK-024](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-024-polyomino-relic-shapes-and-sizes.md) | Polyomino Relic Shapes, Sizes, and Data Definitions | Systems/Data | P1 | DONE | `feature/polyomino-relic-shapes` |
| [TASK-025](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-025-polyomino-drag-drop-and-grid-snapping.md) | Polyomino Drag-and-Drop, Rotation, and Grid Snapping | UI/Controls | P1 | DONE | `feature/polyomino-drag-and-drop` |
| [TASK-026](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-026-polyomino-internal-machinery-and-bumpers.md) | Polyomino Internal Kinetic Machinery and Bumper Mechanics | Gameplay/Physics | P1 | DONE | `feature/polyomino-internal-machinery` |
| [TASK-027](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-027-junk-box-backpack-inventory-system.md) | Junk Box Backpack Inventory System | UI/Systems | P1 | DONE | `feature/junk-box-backpack-inventory` |
| [TASK-028](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-028-junk-box-ui-opening-and-board-transfer.md) | Junk Box UI Opening, Representation, and Board Item Transfer | UI/Gameplay | P1 | DONE | `feature/junk-box-ui-and-board-transfer` |
| [TASK-029](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-029-peg-and-relic-unified-grid-alignment.md) | Peg and Relic Unified Grid Alignment | Systems/Board Physics | P1 | DONE | `feature/peg-and-relic-unified-grid-alignment` |
| [TASK-030](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-030-relic-placement-peg-replacement-and-overlap-prevention.md) | Relic Placement Peg Replacement and Mutual Exclusivity | Systems/Gameplay | P1 | DONE | `feature/relic-placement-peg-replacement` |
| [TASK-031](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-031-board-relic-repositioning-and-dragging.md) | Board Relic Repositioning and In-Place Dragging | UI/Controls | P1 | DONE | `feature/board-relic-repositioning` |
| [TASK-032](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-032-relic-audio-level-balancing-and-attenuation.md) | Relic Audio Level Balancing and Volume Attenuation | Audio/Balance | P1 | DONE | `feature/relic-audio-balancing` |
| [TASK-033](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-033-relic-bounding-enclosures-and-dividing-lanes.md) | Relic Bounding Enclosures, Perimeter Walls, and Dividing Lanes | Systems/Physics | P1 | DONE | `feature/relic-bounding-enclosures` |
| [TASK-034](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-034-repetitive-sfx-pitch-randomization.md) | Repetitive Sound Effect Pitch Randomization | Audio/Polish | P1 | DONE | `feature/repetitive-sfx-pitch-randomization` |
| [TASK-035](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-035-relic-selection-layout-and-machinery-preview.md) | Relic Selection Screen Layout and Machine Composition Preview | UI/Visuals | P1 | DONE | `feature/relic-selection-preview` |
| [TASK-036](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-036-pinball-kinetic-machinery-and-lane-switches.md) | Pinball Kinetic Machinery, Rollover Lane Switches, and Device Roster Revision | Systems/Gameplay | P1 | DONE | `feature/pinball-kinetic-machinery` |
| [TASK-037](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-037-relic-passive-removal-and-board-trigger-mechanisms.md) | Relic Passive Removal and Board Trigger Mechanisms | Systems/Gameplay/Design | P1 | DONE | `feature/relic-passive-removal-board-triggers` |
| [TASK-038](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-038-tooltip-text-and-language-refinement.md) | Tooltip Text and Language Refinement | UI/Polish | P1 | DONE | `feature/tooltip-text-refinement` |
| [TASK-039](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-039-junk-box-sidebar-integration-and-pegboard-display.md) | Junk Box Sidebar Integration and Pegboard Display Equivalence | UI/Controls/Gameplay | P1 | DONE | `feature/junk-box-sidebar-and-pegboard-display` |
| [TASK-040](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-040-asset-pack-sprite-audit-and-replacement.md) | Asset Pack Sprite Audit and Replacement | Art Production | P2 | DONE | `feature/asset-pack-sprite-replacement` |
| [TASK-041](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-041-remove-hopper-mouse-control.md) | Remove Hopper Mouse Control | Controls | P1 | DONE | `feature/remove-hopper-mouse-control` |
| [TASK-042](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-042-hopper-positioning-top-ui-bar-and-debug-menu.md) | Hopper Repositioning, Top UI Bar & Debug Menu Integration | UI/Layout | P1 | DONE | `feature/hopper-top-bar-debug-menu` |
| [TASK-043](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-043-replace-drawn-cannons-with-sprite-assets.md) | Replace Drawn Cannons with Library Sprite Assets | UI/Visuals | P1 | DONE | `feature/replace-drawn-cannons-with-assets` |
| [TASK-044](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-044-pause-game-for-comic-overlay-scenes.md) | Pause Game State for Full Comic Overlay Cinematics | Gameplay/Systems/UI | P1 | DONE | `feature/pause-game-comic-overlays` |
| [TASK-045](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-045-remove-minion-system.md) | Remove Minion System and Mechanics | Refactoring/Cleanup | P2 | DONE | `feature/remove-minion-system` |
| [TASK-046](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-046-cannon-scrolling-terrain-animation.md) | Cannon Scrolling Terrain Animation & Right-Widget Wall Transition | UI/Visuals | P1 | DONE | `feature/cannon-scrolling-terrain-animation` |
| [TASK-047](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-047-pinball-widget-research-and-machine-layout-analysis.md) | Pinball Widget Research & Machine Layout Analysis | Research/Design | P1 | DONE | `feature/pinball-widget-research` |
| [TASK-048](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-048-relic-activation-requirements-pinball-widget-rework.md) | Relic Activation Requirements Pinball Widget Rework | Systems/Gameplay | P1 | DONE | `feature/relic-pinball-activation-rework` |
| [TASK-049](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-049-on-board-relic-tooltip-rework.md) | On-Board Relic Tooltip Information Rework | UI/Polish | P1 | DONE | `feature/on-board-relic-tooltip-rework` |
| [TASK-050](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-050-boss-intervention-popup-trolls.md) | Boss Intervention Pop-Up Targets | Design | P1 | PARKED | `feature/boss-intervention-popup-trolls` |
| [TASK-051](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-051-componentized-pinball-machinery-roster.md) | Componentized Pinball Machinery Roster | Systems/Gameplay/Physics | P1 | DONE | `feature/pinball-machinery-componentization` |
| [TASK-052](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-052-junk-box-dynamic-scroll-bar.md) | Junk Box Dynamic Scroll Bar Visibility | UI/Polish | P1 | DONE | `feature/junk-box-dynamic-scroll-bar` |
| [TASK-053](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-053-relic-machinery-audit-and-widget-distribution.md) | Relic Machinery Audit and Widget Distribution | Systems/Gameplay/Balance | P1 | DONE | `feature/relic-widget-distribution` |
| [TASK-054](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-054-relic-junk-box-return.md) | Relic Junk Box Return Inventory System | UI/Gameplay/Systems | P1 | DONE | `feature/relic-junk-box-return` |
| [TASK-055](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-055-relic-directional-machinery-rotation.md) | Relic Directional Machinery Rotation Compliance | Systems/Gameplay/Physics | P1 | DONE | `feature/relic-directional-machinery-rotation` |
| [TASK-056](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-056-dashboard-task-detail-modal.md) | Visual Task Dashboard Expandable Task Details Modal | DevOps/Tooling/UI | P1 | DONE | `feature/dashboard-task-detail-modal` |
| [TASK-057](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-057-board-relic-tooltip-bbcode-rendering.md) | Board Relic Tooltip BBCode Formatting and Text Styling | UI/Polish | P1 | READY | `fix/board-relic-tooltip-bbcode-rendering` |
| [TASK-058](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-058-cannon-layer-order-pause-blur.md) | Cannon Layer Order and Pause Blur Hierarchy | UI/Visuals | P1 | READY | `feature/cannon-layer-order-pause-blur` |
| [TASK-059](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-059-remove-backpack-button-from-hud.md) | Remove Backpack Button from HUD Header Bar | UI/Cleanup | P1 | READY | `feature/remove-backpack-button-hud` |
| [TASK-060](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-060-tooltip-rewrite-and-keyword-tag-hover-audit.md) | In-Game Tooltip Rewrite and Keyword Tag Hover Audit | UI/Polish/Design | P1 | READY | `feature/tooltip-rewrite-and-keyword-tag-hover-audit` |
| [TASK-061](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-061-dashboard-drag-drop-task-status.md) | Visual Task Dashboard Drag-and-Drop Task Status Update | DevOps/Tooling/UI | P1 | DONE | `feature/dashboard-drag-drop-task-status` |
| [TASK-062](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-062-dashboard-parked-ideas-column.md) | Visual Task Dashboard Parked Ideas Column | DevOps/Tooling/UI | P1 | DONE | `feature/dashboard-parked-ideas-column` |
| [TASK-063](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-063-junk-box-relic-display-and-tooltip-fix.md) | Junk Box Relic Display Equivalence and Hover Tooltip Fix | UI/Polish/Gameplay | P1 | READY | `fix/junk-box-relic-display-and-tooltips` |
| [TASK-064](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-064-dashboard-card-category-chips.md) | Visual Task Dashboard Card Category Chips and File Path Removal | DevOps/Tooling/UI | P1 | DONE | `feature/dashboard-card-category-chips` |
| [TASK-065](file:///c:/Users/josep/Desktop/Games/Goblin-Cannon/docs/tasks/TASK-065-ui-wireframe-redesign.md) | UI Wireframe and Screen Layout Redesign | UI/Layout/Design | P1 | READY | `feature/ui-wireframe-redesign` |








---

## 3. Sub-Agent PR Review Protocol

Every pull request must complete an independent sub-agent review cycle:
1. Push the branch and open a GitHub Pull Request (`gh pr create`).
2. Invoke an independent `pr_reviewer` sub-agent without conversational context.
3. If the sub-agent reports major findings, address them and repeat review.
4. Merge the Pull Request into `main` after receiving approval.
