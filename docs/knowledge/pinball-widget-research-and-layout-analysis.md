# Pinball Widget Research and Machine Layout Analysis

This document provides a comprehensive research reference for pinball playfield components and layout architectures.
It synthesizes community discourse from Pinside, Reddit, and video reviews.
It analyzes how playfield components create player experience, kinetic momentum, and target goals.
Finally, it adapts classic pinball mechanics into modular polyomino relic patterns for Goblin Cannon.

---

## 1. Primary Sources and Methodology

We examined public community discourse, competitive play guides, and machine reviews.
Key sources include:
*   **Pinside Community Database:** Playfield ratings, mechanical teardowns, and user reviews for top-rated tables.
*   **Reddit (r/pinball):** Player discussions on layout flow, shot satisfaction, and component chaos.
*   **PAPA & Bowen Kerins Video Tutorials:** Advanced breakdown of shot geometry, ball trajectories, and game rules.
*   **Todd Tuckey & Coastline Pinball Reviews:** Mechanical inspection of solenoid mechanisms, diverters, and physical toys.

---

## 2. Plain English Jargon Demystification

Pinball jargon can be obscure. Below are direct, plain-English definitions of common terms:

### 2.1 Scoop
*   **Plain English:** A literal hole cut into the wooden board.
*   **Function:** When a ball rolls into a scoop, it drops into a channel underneath the table. The game pauses, awards points or starts a mode, and then a solenoid kicker pops the ball back out to the flippers.

### 2.2 Ball Lock
*   **Plain English:** A physical trap inside the machine.
*   **Function:** Holds a ball inside the machine instead of returning it to play. When a player locks 1, 2, or 3 balls, the game releases all locked balls simultaneously to trigger high-energy Multi-Ball Mode.

### 2.3 Slot Machine Scoop Ball Lock
*   **Plain English:** A target hole styled like a slot machine.
*   **Function:** Shooting a ball into this hole drops it under the playfield (Scoop), traps the ball for multi-ball (Ball Lock), and spins a random prize on the score display.

### 2.4 Bash Toy
*   **Plain English:** A heavy physical target in the center of the board.
*   **Function:** Players hit it directly with maximum force to make it shake, open, or trigger explosive visual feedback (e.g., Castle Gates, Flying Saucer).

### 2.5 VUK (Vertical Up Kicker)
*   **Plain English:** An under-board elevator piston.
*   **Function:** Shoots a ball straight up through a hole in the board onto an overhead wire ramp track.

---

## 3. Iconic Machine Case Studies & Player Quotes

### 3.1 Twilight Zone (Bally, 1993 - Pat Lawlor)
*   **Layout Style:** Stop-and-Go Tactical Layout (Pinside Rank: #4).
*   **Key Features:** Gumball Machine VUK, Powerfield magnetic playfield, Ceramic "Powerball", Slot Machine scoop.
*   **Bulk Player Sentiment:** Celebrated as the ultimate tactical board. Players praise its dense mechanical variety where every shot does something physically distinct.
*   **Community Quotes:**
    > *"Pat Lawlor's masterpiece. Every single shot on the board triggers a distinct physical mechanism. The Gumball Machine is the coolest toy in pinball history."* — Pinside Collector Review
    > *"The ceramic Powerball moves so fast and ignores magnets — it changes your reflexes instantly during play."* — Reddit r/pinball

### 3.2 Attack from Mars (Bally, 1995 - Brian Eddy)
*   **Layout Style:** Classic Fan Layout (Pinside Rank: #3).
*   **Key Features:** Central Flying Saucer bash toy, dual stroke ramps, outer orbits, 3-bank drop targets.
*   **Bulk Player Sentiment:** Revered as the gold standard of kinetic flow. Features wide, clear shot paths with no clunky stops.
*   **Community Quotes:**
    > *"Attack from Mars is pure pinball perfection. Bashing the flying saucer in the center until it wobbles and explodes never gets old."* — Pinside Review
    > *"The ultimate 'one more game' machine. Easy for beginners to understand, but fast enough for tournament pros."* — Pinball Arcade Forum

### 3.3 Medieval Madness (Williams, 1997 - Brian Eddy)
*   **Layout Style:** Objective-Driven Fan Layout (Pinside Rank: #1).
*   **Key Features:** Exploding Castle drawbridge and gate, Catapult VUK, Troll pop-up targets.
*   **Bulk Player Sentiment:** Ranked #1 on Pinside for decades. Players praise its physical destructive feedback.
*   **Community Quotes:**
    > *"Lowering the drawbridge, smashing open the castle gate, and watching the castle explode is peak physical reward."* — Pinside #1 Review
    > *"Pop-up trolls add instant tension when they rise out of the playfield wood."* — Reddit r/pinball

---

## 4. Playfield Component Taxonomy

This analysis excludes bottom flippers and ball launchers.
It focuses exclusively on components that interact with the ball in flight.

### 4.1 Pop Bumpers (Jet / Mushroom Bumpers)
*   **Mechanism:** Active cylindrical bumpers with solenoid rings under the playfield.
*   **Physics Impact:** They inject sudden kinetic energy and random ball trajectories.
*   **Gameplay Role:** Clusters of three pop bumpers create high chaos. Rubber boundaries maintain fast ball movement.

### 4.2 Rollover Lanes & Switch Clusters
*   **Mechanism:** Narrow channels with microswitches or optical sensors.
*   **Physics Impact:** They guide ball direction without stopping ball speed.
*   **Gameplay Role:** Top lanes reward light-sequence collection. Inlanes and outlanes control ball return paths.

### 4.3 Drop Targets & Standup Target Banks
*   **Mechanism:** Vertical plastic plates that drop below the playfield surface when struck.
*   **Physics Impact:** Sticking a drop target absorbs ball energy and triggers immediate bounces.
*   **Gameplay Role:** Completing a bank unlocks new game modes or multipliers. Reset solenoids raise targets back up.

### 4.4 Ramps & Wireform Habitrails
*   **Mechanism:** Molded plastic paths and stainless steel wire tracks above the playfield.
*   **Physics Impact:** They elevate the ball, convert speed into potential energy, and deliver smooth gravity returns.
*   **Gameplay Role:** Ramps form the backbone of playfield flow. They safely feed the ball back to specific playfield zones.

### 4.5 Scoops, Sinkholes, and VUKs
*   **Mechanism:** Holes in the playfield surface that catch the ball and eject it via solenoid kickers.
*   **Physics Impact:** They stop ball momentum completely to allow player decision-making.
*   **Gameplay Role:** Scoops pause action to display mode information or lock balls for multi-ball modes.

---

## 5. Polyomino Relic Grid Adaptation for Goblin Cannon

In Goblin Cannon, pinball board components manifest as polyomino relic modules.
Players arrange these relic shapes on the board grid to build custom playfields.

### 5.1 Component Relic Mapping Table

| Relic Component | Polyomino Shape | Grid Footprint | Mechanical Behavior in Goblin Cannon |
| :--- | :--- | :--- | :--- |
| **Pop Bumper Bank** | 2x2 Square | 4 Cells | Repels incoming cannonballs with high velocity. Grants bonus energy on hit. |
| **Drop Target Bank** | 1x3 Straight | 3 Cells | Absorbs 3 impacts to collapse. Unlocks board multipliers upon completion. |
| **Rollover Lane Cluster**| 1x2 Line | 2 Cells | Detects ball passage. Triggers element alignment when all lanes light up. |
| **Spinning Target** | 1x1 Single | 1 Cell | Rotates on pass-through. Converts ball momentum into rapid ticks of mana. |
| **Scoop & VUK** | L-Shape (3 cell) | 3 Cells | Traps cannonball for 1 second. Ejects ball towards high-value targets. |
| **Captive Ball Target** | T-Shape (4 cell) | 4 Cells | Transfers kinetic energy through static relic cells to damage distant targets. |
| **Electromagnet Core** | 2x2 Block | 4 Cells | Traps ball in a magnetic field, then releases it along a curved trajectory. |
