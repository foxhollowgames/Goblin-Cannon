# Goblin Cannon - UI Wireframe and Screen Layout Specification

## 1. Executive Summary & Canvas Architecture

This document defines the spatial wireframes, coordinate zones, and visual hierarchy for the Goblin Cannon user interface.
The interface uses a native resolution of **1280 x 720 pixels** with Godot `canvas_items` stretch mode.

### Canvas Zone Boundaries

| Zone Name | X Coordinate Range | Y Coordinate Range | Dimensions (W x H) | CanvasLayer |
| :--- | :--- | :--- | :--- | :--- |
| **Primary Playfield** | 0 px to 960 px | 0 px to 720 px | 960 x 720 px | Layer 0 (World / Board) |
| **Top Header Bar** | 0 px to 960 px | 0 px to 56 px | 960 x 56 px | Layer 10 (UILayer) |
| **Right Telemetry Sidebar**| 960 px to 1280 px | 0 px to 720 px | 320 x 720 px | Layer 10 (UILayer) |
| **Cannon Visual Overlay** | 680 px to 960 px | 440 px to 720 px | 280 x 280 px | Layer 15 (CannonOverlay) |
| **Modal & Pause Dialogs** | 0 px to 1280 px | 0 px to 720 px | 1280 x 720 px | Layer 20 (ModalLayer) |
| **Keyword Flyout Tooltip** | Viewport Clamped | Viewport Clamped | Dynamic | Layer 125 (FlyoutLayer) |

---

## 2. Primary Gameplay Screen Wireframe

```
0 px                      960 px                       1280 px
+---------------------------+----------------------------+ 0 px
| [||] [Debug]  WALL HEALTH | [COMBAT TELEMETRY MONITOR] |
|               [GOLD] [05] |   - Fortification Status   |
+---------------------------+   - Animated Mini-Vignette |
| === HOPPER TRACK ======== |                            | 56 px
|      \  [HOPPER]  /      |                            |
|       \__________/       +----------------------------+
|                           | [CANNON CHARGE & CONTROLS] | 220 px
|     .   *   .   *   .     |   - Radial Power Orb       |
|   *   .   [RELIC] .   *   |   - Volley Trigger Button  |
|     .   *   .   *   .     +----------------------------+
|   *   .   *   .   *   .   | [JUNK BOX INVENTORY]       | 328 px
|     .   *   .   *   .     |   - 6xN Grid View          |
|                           |   - Relic Storage Tiles    |
|                           |   - Drag & Drop Modules    |
+---------------------------+   - Hotkey Auto-Pack (B/I) |
| [B1]  [B2]  [B3]  [B4]    |                            | 620 px
+---------------------------+----------------------------+ 720 px
```

### Coordinate Mapping & Anchors

1. **Top Header Bar (`UILayer / LeftPanel / TopHeaderBarBg`)**:
   - `Position`: (0, 0) to (960, 56) px.
   - `Pause & Menu Button`: (16, 12) px, Size: (36 x 32) px.
   - `Debug Menu Button`: (60, 12) px, Size: (72 x 32) px.
   - `Wall Health Bar`: (280, 8) to (680, 28) px, Size: (400 x 20) px.
   - `Gold Counter Badge`: (380, 32) to (480, 52) px, Size: (100 x 20) px.
   - `Siege Wave Countdown`: (500, 32) to (580, 52) px, Size: (80 x 20) px.
   - `Wall Break Status Label`: (700, 12) to (940, 44) px.

2. **Hopper Movement Track (`Board / Hopper`)**:
   - `Spawn Y-Coordinate`: Y = 78 px (clears 56 px top bar with 22 px margin).
   - `Steering Boundaries`: X = 200 px (Left limit) to X = 760 px (Right limit).
   - `Funnel Drop Mouth`: Width = 64 px to 128 px (scaled by hopper upgrades).

3. **Active Pegboard Playfield (`Board / BoardGrid`)**:
   - `Grid Origin`: (116, 130) px.
   - `Columns`: 15 columns, 48 px horizontal spacing (Total width = 720 px, centered in 960 px zone).
   - `Rows`: 10 rows, 44 px vertical spacing (Total height = 440 px).
   - `Y-Bounds`: Y = 130 px to Y = 570 px.

4. **Return Buckets & Energy Collectors (`Board / Buckets`)**:
   - `Y-Position`: Y = 620 px to Y = 690 px.
   - `Bucket Count`: 4 standard energy capture buckets with drop multipliers.

5. **Right Sidebar Container (`UILayer / RightSidebar / SidebarPanel`)**:
   - `Position`: (960, 0) to (1280, 720) px.
   - `Margin Padding`: 8 px left/right, 8 px top/bottom. Usable content width: 304 px.
   - `Zone 1: Combat Mini-Vignette`: (968, 8) to (1272, 216) px (Height: 208 px).
   - `Zone 2: Cannon Gauge & Power`: (968, 224) to (1272, 320) px (Height: 96 px).
   - `Zone 3: Junk Box Drawer`: (968, 328) to (1272, 712) px (Height: 384 px).

---

## 3. Modal and Overlay Screen Wireframes

### 3.1 Milestone Shop & Major Upgrade Draft Modal (CanvasLayer 20)

```
0 px                                                         1280 px
+------------------------------------------------------------------+
|                    [BACKGROUND BLUR SHADER]                      |
|                                                                  |
|        +------------------------------------------------+        | 150 px
|        |           CHOOSE A MAJOR UPGRADE / RELIC       |        |
|        |                                                |        |
|        |  +--------------+ +--------------+ +---------+ |        |
|        |  |  CARD SLOT 1 | |  CARD SLOT 2 | | CARD 3  | |        |
|        |  |  (210x290px) | |  (210x290px) | |         | |        |
|        |  |              | |              | |         | |        |
|        |  |  ★ Relic Goal| |  ★ Relic Goal| | ★ Goal  | |        |
|        |  |  Kinetic Map | |  Kinetic Map | | Map     | |        |
|        |  |  Description | |  Description | | Desc    | |        |
|        |  |  [ SELECT ]  | |  [ SELECT ]  | | [SELECT]| |        |
|        |  +--------------+ +--------------+ +---------+ |        |
|        |                                                |        |
|        |                   [ SKIP ]                     |        |
|        +------------------------------------------------+        | 570 px
|                                                                  |
+------------------------------------------------------------------+
```

- `Modal Dimensions`: 760 px width x 420 px height.
- `Centered Origin`: (260, 150) px.
- `Card Dimensions`: 210 px width x 290 px height with 10 px inter-card separation.

### 3.2 Fullscreen Comic Cutscene Takeover (CanvasLayer 20)

```
0 px                                                         1280 px
+------------------------------------------------------------------+
| COMIC TITLE BANNER                                [ SKIP (ESC) ] |
+------------------------------------------------------------------+
| +-------------------------+ +----------------------------------+ |
| |                         | |                                  | |
| |  PANEL 1: THE DISCOVERY | |  PANEL 2: SIEGE MOBILIZATION     | |
| |  (580 x 310 px)         | |  (640 x 310 px)                  | |
| |                         | |                                  | |
| +-------------------------+ +----------------------------------+ |
| +--------------------------------------------------------------+ |
| |                                                              | |
| |  PANEL 3: FORTRESS IMPACT (WIDE CLIMAX)                      | |
| |  (1240 x 290 px)                                             | |
| |                                                              | |
| +--------------------------------------------------------------+ |
+------------------------------------------------------------------+ 720 px
```

- `Fullscreen Layout`: 1280 x 720 px with 16 px border gutters.
- `Ink Borders`: 4 px solid comic ink borders with rounded 6 px corners.

### 3.3 Pause and Settings Dialog (CanvasLayer 20)

- `Modal Dimensions`: 480 px width x 420 px height.
- `Centered Origin`: (400, 150) px.
- `Content List`:
  - Audio Master Volume (Slider, 280 px).
  - Sound Effects Volume (Slider, 280 px).
  - Music Volume (Slider, 280 px).
  - Screen Mode Toggle (Windowed / Borderless / Fullscreen).
  - Resume Game Button (Height: 40 px).
  - Abandon Run Button (Height: 40 px).

### 3.4 Victory & Run Defeat Telemetry Summary (CanvasLayer 20)

- `Modal Dimensions`: 820 px width x 520 px height.
- `Centered Origin`: (230, 100) px.
- `Layout Sections`:
  - Banner Header (Victory / Defeat graphic + Run time).
  - 2-Column Telemetry Table: Total Walls Destroyed, Energy Generated, Peak Volley Damage, Gold Collected.
  - Relic Grid Showcase (Shows all active relics slotted during the run).
  - Primary Action Buttons: `Continue to Next City` (Victory) or `Retry Run` (Defeat).

---

## 4. Visual Hierarchy, Ergonomics, and Padding Standards

### 4.1 Grid System & Padding Rules

- **Base Unit**: 8 px grid.
- **Micro Padding**: 4 px between tight label headers and values.
- **Component Padding**: 8 px inside buttons, input cells, and panel borders.
- **Container Separation**: 16 px between distinct UI panels and viewports.

### 4.2 Interactive Hit Targets

- **Primary Buttons**: Minimum 36 px vertical hit box.
- **Utility Buttons (Pause / Close / Sort)**: Minimum 32 x 32 px hit area.
- **Junk Box Grid Cells**: 46 x 46 px with 2 px internal padding for accurate mouse grabs.
- **Relic Rotation Trigger**: Right click or `R` keyboard shortcut with instant feedback.
