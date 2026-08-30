# TASK-036: Pinball Kinetic Machinery, Rollover Lane Switches, and Device Roster Revision

- **Status:** READY
- **Priority:** P1
- **Category:** Systems / Gameplay / Design
- **Target Branch:** \eature/pinball-kinetic-machinery- **Related Tasks:** [TASK-024](TASK-024-polyomino-relic-shapes-and-sizes.md), [TASK-026](TASK-026-polyomino-internal-machinery-and-bumpers.md), [TASK-033](TASK-033-relic-bounding-enclosures-and-dividing-lanes.md)

## Description

Revise and finalize the complete roster of internal kinetic machinery devices for polyomino relics.
Incorporate classic pinball mechanics: rollover lane switches, bank completion rewards, pop bumpers, drop targets, and one-way wire gates.
Remove or rework devices that do not fit the pinball tactile theme (such as static bomb cores).

---

## Requirements

### 1. Device Roster Audit and Pinball Revisions
- Remove or replace incongruous devices (e.g., static bomb modules) with authentic kinetic pinball elements.
- Establish core pinball machine components:
  - **Rollover Lane Switches:** Narrow lanes with sensor switches. Passing through lights the switch. Lighting all switches in a bank or sequence triggers a bonus reward (mana burst, cannon charge, or score multiplier).
  - **Pop Bumpers (Kickers):** Active electrified bumpers with pop rings that forcefully fling the ball away on contact and award energy.
  - **Drop Target Banks:** Targets that retract or register on hit. Clearing all targets in the bank resets them and grants jackpot energy.
  - **One-Way Wire Gates / Spinners:** Directional swing gates that allow ball passage in one direction or spin rapidly on pass-through to build momentum and power.
  - **Slingshot Kickers:** Triangular angled kickers positioned along open edges to bounce balls across open relic chambers.

### 2. Rollover Lane Bank & Completion Logic
- Support grouping of lane switches within a polyomino module.
- Track lit state per switch during active ball simulation ticks.
- Trigger signal \ank_completed(bank_id: StringName, reward_type: int, reward_value: int)\ when all switches in a group are lit.
- Reset lit states on round completion or when bank resets.

### 3. Visual & Audio Feedback
- Visual lights/bulbs on switches and targets that turn bright neon when lit.
- Rollover click / chime sound effects with pitch progression as sequential lanes are lit.
- Jackpot fanfare chime on full bank completion.

### 4. Data Model Integration
- Register new device types in \PolyominoModuleData.CellType\.
- Update \PolyominoRelicDatabase\ to integrate rollover lanes and target banks across thematic relics.
- Update \RelicLayoutPreview\ to render distinct pinball component glyphs.

### 5. Automated Tests
- Unit tests in \	ests/test_pinball_machinery.gd\ validating:
  - Rollover lane hit detection and state changes.
  - Full bank completion triggers and jackpot rewards.
  - Drop target hit registration and reset cycles.
  - Directional passage through one-way gates.

---

## Acceptance Criteria

- [ ] Rollover lane switches record hits and illuminate individually.
- [ ] Bank completion logic triggers bonus rewards when all grouped switches are lit.
- [ ] Incongruous non-pinball devices are removed or converted to tactile pinball mechanics.
- [ ] Visual indicators and audio cues show active switch states.
- [ ] Headless unit tests verify all new kinetic pinball components.
