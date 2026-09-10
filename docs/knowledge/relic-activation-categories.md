# Diegetic Relic Activation Categories and Physical Machinery System

## 1. Overview

This document defines the physical pinball mini-mission archetypes for polyomino relics in Goblin-Cannon.
Relic activations match real pinball board machinery.
Players can see the activation status directly on the board components without opening tooltips.

---

## 2. Pinball Mini-Mission Archetypes

The table below lists the twelve pinball mini-mission categories and their diegetic board cues:

| Archetype | Internal ID | Physical Pinball Component | Diegetic Visual Cue |
| :--- | :--- | :--- | :--- |
| **Drop Target Bank** | `TARGET_BANK` | Drop Target (`DROP_TARGET`) | Target physically recesses into the playfield board slot. |
| **Rollover Spellout** | `ROLLOVER_SPELL` | Rollover Switch (`ROLLOVER_SWITCH`) | In-line rune lamp illuminates with glowing yellow aura. |
| **Orbit Loop Flow** | `ORBIT_FLOW` | Orbit Loop (`ORBIT_LOOP`) | Directional rail chevron lamps illuminate sequentially. |
| **Scoop Sinkhole Lock** | `SINKHOLE_LOCK` | Scoop Sinkhole (`SCOOP_SINKHOLE`), Ball Lock (`BALL_LOCK`) | Captured metallic balls appear inside scoop cup rim. |
| **Spinner Tachometer** | `SPINNER_RPM` | Spinner (`SPINNER`) | Arc tachometer fill needle charges clockwise around spinner axle. |
| **Bash Toy Demolition** | `BASH_DEMOLITION` | Bash Toy (`BASH_TOY`), Captive Ball (`CAPTIVE_BALL`) | Impact pip or crack fracture pips fill around perimeter. |
| **Super Jets Cluster** | `SUPER_JETS` | Pop Bumper (`POP_BUMPER`) | Jet bumper skirts flash with colored high-voltage aura. |
| **Tactical Rebound** | `TACTICAL_REBOUND` | Slingshot (`SLINGSHOT`), Outlane Kickback (`OUTLANE_KICKBACK`) | Solenoid arm illuminates with charged spring tension. |
| **Launch Ramp Pot** | `LAUNCH_RAMP` | Vertical Up Kicker (`VERTICAL_UP_KICKER`) | Launch cup pot pulses with vertical trajectory arrow. |
| **Diverter Switch** | `DIVERTER_SWITCH` | Mechanical Diverter (`MECHANICAL_DIVERTER`) | Diverter gate arm physically snaps into the opposite channel. |
| **Hurry-Up Frenzy** | `HURRY_UP_FRENZY` | Any Component | Module perimeter border flashes red with countdown pulse. |

---

## 3. Campaign 1 Relic Mapping Rules

Every relic in `polyomino_relic_database.gd` maps directly to its physical component layout:
- Relics with drop targets knock down all drop targets.
- Relics with rollovers illuminate all rollover switches.
- Relics with orbit loops complete loop traversals.
- Relics with spinners track cumulative spins.
- Relics with bash toys track repeated mechanical impacts.
- Relics with scoops sink balls into the cup.

---

## 4. Diegetic Feedback Protocol

Visual board states update instantly when a ball contacts a machinery component:
1. Contact event increments component hit counter.
2. `PolyominoDiegeticRenderer` renders visual indicators on the canvas.
3. Upon reaching the threshold, the module displays a comic reward banner.
4. The goal completion signal triggers board rewards (multiballs, supercharge, or energy surges).
