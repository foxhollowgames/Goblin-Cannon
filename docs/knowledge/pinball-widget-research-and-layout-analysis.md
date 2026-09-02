# Pinball Layout Research & Digital Relic Adaptation

This document analyzes pinball playfield components and adapts them for Goblin Cannon.
It prioritizes digital game design concepts such as Bash Toys and Ball-Cloning Scoop Reservoirs.
It places physical mechanical pinball jargon at the bottom for background reference.

---

## 1. High-Value Digital Relic Concepts for Goblin Cannon

Physical pinball tables rely on mechanical solenoids.
Goblin Cannon adapts these ideas into digital polyomino relic grid modules.

### 1.1 The Digital Scoop Reservoir (Ball Cloner & Multiball Launcher)
*   **Concept:** A relic grid module that captures cannonballs during play.
*   **Digital Mechanics:** When a cannonball rolls into the Scoop Relic, the relic absorbs the ball and stores a copy of its stats.
*   **Massive Blast Activation:** When charged or triggered by player input, the Scoop Relic releases a massive blast of all stored cannonballs simultaneously across the playfield!
*   **Polyomino Shape:** L-Shape (3 cells) or 2x2 Block.

### 1.2 Interactive Bash Toys (Central High-Impact Relics)
*   **Concept:** Heavy central targets inspired by pinball bash toys (Castle Gates, Flying Saucers).
*   **Digital Mechanics:** Placed in central grid zones. They absorb direct cannonball impacts, display visual damage stages, and trigger explosive area-of-effect shockwaves when destroyed.
*   **Polyomino Shape:** 2x2 Block or T-Shape (4 cells).

### 1.3 Kinetic Energy Converters & Flow Controllers
*   **Pop Bumper Banks (2x2 Square):** Repels incoming cannonballs with high impulse velocity and generates bonus energy.
*   **Spinning Targets (1x1 Single):** Spins rapidly when cannonballs pass through, converting speed into rapid ticks of mana.
*   **Electromagnet Cores (2x2 Block):** Captures cannonballs in a gravitational field, then releases them along curved trajectories.

---

## 2. Iconic Table Case Studies & Community Sentiment

### 2.1 Attack from Mars (Bally, 1995)
*   **Core Feature:** Central Flying Saucer Bash Toy.
*   **Player Sentiment:** Rated #3 on Pinside. Players love bashing the central flying saucer target until it wobbles and explodes.
*   **Community Quote:** *"Bashing the flying saucer in the center until it explodes is one of the most satisfying feelings in arcades."*

### 2.2 Medieval Madness (Williams, 1997)
*   **Core Feature:** Exploding Castle Gate & Drawbridge Bash Toy.
*   **Player Sentiment:** Rated #1 on Pinside. Players praise the destructive feedback of breaking down physical barriers.
*   **Community Quote:** *"Lowering the drawbridge and smashing open the castle gate provides peak physical reward."*

### 2.3 Twilight Zone (Bally, 1993)
*   **Core Feature:** Gumball Machine & Ceramic Powerball.
*   **Player Sentiment:** Rated #4 on Pinside. Players love complex ball-storing toys and high-speed ball variations.

---

## 3. Polyomino Relic Grid Mapping Table

| Relic Component | Polyomino Shape | Grid Footprint | Goblin Cannon Mechanics |
| :--- | :--- | :--- | :--- |
| **Digital Scoop Reservoir** | L-Shape (3 cell) | 3 Cells | Stores copies of captured cannonballs. Releases a massive multiball blast when activated. |
| **Central Bash Toy** | 2x2 Block | 4 Cells | Heavy central target. Absorbs impacts and triggers area-of-effect shockwaves. |
| **Pop Bumper Bank** | 2x2 Square | 4 Cells | Repels incoming cannonballs with high velocity. Grants bonus energy on hit. |
| **Spinning Target** | 1x1 Single | 1 Cell | Rotates on pass-through. Converts ball momentum into rapid ticks of mana. |
| **Electromagnet Core** | 2x2 Block | 4 Cells | Traps ball in a magnetic field, then releases it along a curved trajectory. |

---

## 4. Mechanical Pinball Hardware Glossary (Background Reference)

Physical pinball machines use under-board solenoids and switches.
This mechanical jargon is included below for historical reference:

*   **Scoop (Physical):** A hole cut into wooden playfield boards where balls fall into subterranean channels.
*   **Ball Lock (Physical):** A trough or trough switch holding physical steel balls under the table.
*   **VUK (Vertical Up Kicker):** An under-board solenoid piston that kicks balls vertically up through holes.
*   **Drop Target Bank:** Vertical plastic plates that fall below the playfield wood when struck.
*   **Habitrail Wireform:** Stainless steel wire tracks elevated above the playfield to return balls to flippers.
