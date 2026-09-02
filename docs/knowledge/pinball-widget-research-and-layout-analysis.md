# Pinball Layout Research & Digital Relic Adaptation

This document analyzes pinball playfield components and adapts them for Goblin Cannon.
It includes an exhaustive table of every onboard mechanic in the codebase with plain-text explanations.

---

## 1. Complete Table of Onboard Mechanics in Goblin Cannon

Below is the complete list of all 15 onboard kinetic mechanics and cell types in Goblin Cannon, alongside plain-text explanations:

| Mechanic Name | Type Identifier | Plain-Text Explanation |
| :--- | :--- | :--- |
| **Open Corridor** | `EMPTY` | An open cell inside a relic footprint that lets cannonballs travel through freely. |
| **Guide Rail** | `GUIDE_RAIL` | A metallic rail that guides cannonballs along a fixed track without losing speed. |
| **Catch Funnel** | `FUNNEL` | A wide chute that collects incoming cannonballs and channels them down a specific lane. |
| **Kinetic Bumper** | `BUMPER` | A reactive bumper that repels cannonballs on contact, bouncing them away with extra speed. |
| **Speed Accelerator** | `ACCELERATOR` | A motorized roller pad that launches cannonballs forward with an immediate directional speed boost. |
| **Rotary Booster** | `ROTARY_BOOSTER` | A spinning hub that accelerates cannonballs radially and triggers energy pulses when struck. |
| **Mana Siphon** | `MANA_SIPHON` | A siphon cell that absorbs kinetic energy from passing cannonballs to generate mana for casting spells. |
| **Directional Deflector**| `DIRECTIONAL_DEFLECTOR`| An angled deflector plate that ricochets cannonballs at a specific output direction (Up, Down, Left, Right). |
| **Rollover Switch** | `ROLLOVER_SWITCH` | A floor sensor triggered when a cannonball rolls over it. Completing switch sets lights up element bonuses. |
| **Pop Bumper** | `POP_BUMPER` | A solenoid-powered bumper that violently blasts cannonballs away with high impulse force and bonus energy. |
| **Drop Target Bank** | `DROP_TARGET` | A target plate that drops flat after 3 hits. Clearing a bank unlocks board energy multipliers upon reset. |
| **Wire Gate** | `WIRE_GATE` | A hinged wire gate that lets cannonballs pass through in one direction but blocks backward movement. |
| **Slingshot Rebounder** | `SLINGSHOT` | An active triangular rubber band mechanism that launches cannonballs sideways across the board on impact. |
| **Digital Scoop Reservoir**| `MULTIBALL_RESERVOIR` | A relic module that captures cannonballs, stores copies of their stats, and launches a massive multiball blast. |
| **Interactive Bash Toy** | `TARGET_BANK` | A heavy central target that absorbs direct cannonball hits and triggers explosive area-of-effect shockwaves. |

---

## 2. High-Value Digital Relic Concepts for Goblin Cannon

### 2.1 The Digital Scoop Reservoir (Ball Cloner & Multiball Launcher)
*   **Concept:** A relic grid module that captures cannonballs during play.
*   **Digital Mechanics:** When a cannonball rolls into the Scoop Relic, the relic absorbs the ball and stores a copy of its stats.
*   **Massive Blast Activation:** When charged or triggered by player input, the Scoop Relic releases a massive blast of all stored cannonballs simultaneously across the playfield!
*   **Polyomino Shape:** L-Shape (3 cells) or 2x2 Block.

### 2.2 Interactive Bash Toys (Central High-Impact Relics)
*   **Concept:** Heavy central targets inspired by pinball bash toys (Castle Gates, Flying Saucers).
*   **Digital Mechanics:** Placed in central grid zones. They absorb direct cannonball impacts, display visual damage stages, and trigger explosive shockwaves when destroyed.
*   **Polyomino Shape:** 2x2 Block or T-Shape (4 cells).

---

## 3. Iconic Table Case Studies & Community Sentiment

### 3.1 Attack from Mars (Bally, 1995)
*   **Core Feature:** Central Flying Saucer Bash Toy.
*   **Player Sentiment:** Rated #3 on Pinside. Players love bashing the central flying saucer target until it wobbles and explodes.
*   **Community Quote:** *"Bashing the flying saucer in the center until it explodes is one of the most satisfying feelings in arcades."*

### 3.2 Medieval Madness (Williams, 1997)
*   **Core Feature:** Exploding Castle Gate & Drawbridge Bash Toy.
*   **Player Sentiment:** Rated #1 on Pinside. Players praise the destructive feedback of breaking down physical barriers.
*   **Community Quote:** *"Lowering the drawbridge and smashing open the castle gate provides peak physical reward."*

### 3.3 Twilight Zone (Bally, 1993)
*   **Core Feature:** Gumball Machine & Ceramic Powerball.
*   **Player Sentiment:** Rated #4 on Pinside. Players love complex ball-storing toys and high-speed ball variations.

---

## 4. Mechanical Pinball Hardware Glossary (Background Reference)

Physical pinball machines use under-board solenoids and switches.
This mechanical jargon is included below for background reference:

*   **Scoop (Physical):** A hole cut into wooden playfield boards where balls fall into subterranean channels.
*   **Ball Lock (Physical):** A trough or trough switch holding physical steel balls under the table.
*   **VUK (Vertical Up Kicker):** An under-board solenoid piston that kicks balls vertically up through holes.
*   **Drop Target Bank:** Vertical plastic plates that fall below the playfield wood when struck.
*   **Habitrail Wireform:** Stainless steel wire tracks elevated above the playfield to return balls to flippers.
