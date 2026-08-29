# TASK-024: Polyomino and Irregular Relic Shapes, Sizes, and Data Definitions

- **Status:** DONE
- **Priority:** P1
- **Category:** Systems / Data
- **Target Branch:** `feature/polyomino-relic-shapes`

## Description

Define the spatial polyomino and irregular module shapes for all relic items in Campaign 1.
Map every relic to a multi-cell footprint and internal kinetic mechanism to serve as balance levers.

---

## Spatial Geometry Rules

```
[ Tier 0: Pegs Only (1×1) ]
  [■] -> Single board pegs only (Bomb, Gold, Trampoline, Normal).

[ Tier 1: Compact Modules (2 to 3 Cells) ]
  [■][■]             [■]                  [■]   [■]
  Domino (1×2)       [■][■] Rhombus / Skew   [■][■] V-Chevron (3-cell)

[ Tier 2: Synergy Modules & Cross-Links (3 to 5 Cells) ]
    [■]                [■][■]                 [■]
  [■][■][■] T-Shape      [■][■] Z-Shape     [■][■][■] Cross (5-cell)
                                              [■]

[ Tier 3: Mega-Contraptions & Boss Amplifiers (5 to 9 Cells — 3×3 Bounding Box) ]
  [■][■][■]            [■][■][■]            [■]   [■]
  [■][■][■] 3×3 Solid  [■]   [■] 3×3 Ring   [■][■][■] 3×3 Archway (7-cell)
  [■][■][■]            [■][■][■]            [■]   [■]
```

1. **Tier 0 (1×1 Cell):** Only individual pegs occupy a 1×1 footprint. Relics never occupy a single 1×1 cell.
2. **Tier 1 (2 to 3 Cells):** Compact shapes (dominos, 2-cell rhombuses, 3-cell V-chevrons). Used for onboard passives and single-ball upgrades.
3. **Tier 2 (3 to 5 Cells):** Angular and irregular shapes (T-shapes, Z-shapes, 5-cell crosses, stepped diagonals). Used for dual-synergy wall breaks.
4. **Tier 3 (5 to 9 Cells / 3×3 Bounding Box):** Mega-contraptions (solid 3×3 blocks, 3×3 hollow rings, 3×3 archways, 3×3 corner fortresses). Used for boss amplifiers.

---

## 1. Boss Amplifiers (3×3 Mega-Contraption Tier)

| Relic Name & Upgrade ID | Shape Geometry | Footprint | Internal Kinetic Machinery | Balance & Placement Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Cascade Reactor**<br>`cascade_reactor` | **3×3 Solid Block** | 9 Cells | 4 Corner Tesla Coils + Central Energy Siphon + 4 Bounce Rails | Massive 3-way synergy (Energize + Chain + Leech). Solid 3×3 block occupies major peg space. |
| **Perpetual Engine**<br>`perpetual_engine` | **3×3 Hollow Ring** | 8 Cells (Center Hole) | Top Catch Chute + Circular Boost Ring + Bottom Emitter | Continuously spawns Phantom balls. Balls drop through center hole to trigger speed boosters. |
| **Storm of Fragments**<br>`storm_of_fragments` | **3×3 5-Cell Cross** | 5 Cells | Central Splitter Core + 4 Spark Deflector Nodes | Fires lightning from fragments. 4 outward prongs launch fragments into four quadrants. |
| **Explosive Contagion**<br>`explosive_contagion` | **3×3 Giant Z-Ramp** | 6 Cells | 3 Concussive Vents + 3 Spore Dispersal Chambers | Explosions spread Drain across pegs. Jagged 3×3 diagonal forces zigzag ball paths. |
| **Superconductor**<br>`superconductor` | **3×3 Corner Fortress** | 7 Cells (L-Block) | Dual Spark Rails + 2 Corner Pinball Bumpers | Doubles lightning coverage. Thick L-frame wraps around the outer edge of the pegboard. |
| **Rubber Storm**<br>`rubber_storm` | **3×3 Pinball Chamber** | 8 Cells (Hollow Core) | 4 Corner High-Tension Bumpers + 4 Edge Accelerator Rollers | Discharges lightning on high-speed bounces. Hollow chamber traps balls for rapid ricochets. |
| **Fragment Swarm**<br>`fragment_swarm` | **3×3 Giant Archway** | 7 Cells (U-Shape) | Top Ball Catch Funnel + 3 Fragment Diverter Chutes | Splits balls into 3 fragments. Wide arch captures balls and disperses fragments widely. |
| **Overdrive Cascade**<br>`overdrive_cascade` | **3×3 Diamond Rhombus** | 5 Cells | Central Overdrive Sensor + 4 Angled Deflector Plates | Grants +1 energy per hit to all balls at Overdrive 5. Diagonal edges deflect balls across center pegs. |
| **Goblin Width Tempest**<br>`goblin_width_tempest` | **3×3 Stepped Pyramid** | 6 Cells | Wide Return Funnel + Upward Launch Spring | Widens hopper greatly. Wide base mounts directly above the bottom drain zone. |
| **Blood Tithe**<br>`blood_tithe` | **3×3 Horseshoe Arch** | 5 Cells | Dual High-Volume Drain Siphons + Catch Gate | Drains +1 energy per second per peg. Open horseshoe catches falling balls into drain chambers. |
| **Crown Ricochet**<br>`crown_ricochet` | **3×3 Corner Fortress** | 6 Cells | 2 Heavy Pinball Bumpers + 1 Vector Boost Ramp | Rewards Overdrive 5 plain bounces. Heavy corner reflects balls back into dense peg zones. |
| **Twin Mandate**<br>`twin_mandate` | **3×3 Diagonal Bar** | 5 Cells (Stairs) | 3 Fragment Speed Rollers + 2 Energy Siphons | Gives +18% fragment energy. Diagonal staircase cuts across multiple peg rows. |
| **Velocity Dividend**<br>`velocity_dividend` | **3×3 Plus Core** | 5 Cells | High-Speed Impact Gate + 4 Shock Absorbers | High-speed hits grant +3 energy. Central plus core catches fast vertical drops. |
| **Phase Sovereign**<br>`phase_sovereign` | **3×3 Spectral Tunnel** | 7 Cells (Open Slot) | Permeable Siphon Rails + Ghost Sensor | Phantom passes generate +22% energy. Phantom balls phase directly through solid structure. |
| **Resonant Well**<br>`resonant_well` | **3×3 Hollow Ring** | 8 Cells (Center Hole) | Resonator Ring + Energize Amplifiers | Amplifies all hits on energized pegs. Balls bounce through hollow well. |
| **Renewal Pact**<br>`renewal_pact` | **3×3 Stepped Chevron** | 5 Cells | 3 Pulse Solenoids + 2 Repair Nodes | Broken pegs recover +12% faster. Wide V-frame covers multiple peg columns. |
| **Gilded Covenant**<br>`gilded_covenant` | **3×3 Vault Gate** | 6 Cells | Gold Coin Vacuum + 2 Vault Bumpers | Awards run Gold. Wide gate captures balls and funnels them toward Gold pegs. |
| **Iron Bloom**<br>`iron_bloom` | **3×3 Giant Solenoid** | 6 Cells | Dual Magnetic Core Wheels + Field Emitter | Ambient magnetic pull +35%. Large magnetic field alters ball paths across the whole board. |
| **Echoes of the Wrench**<br>`echoes_of_wrench` | **3×3 T-Beam** | 5 Cells | Repair Capacitor Array + 2 Shock Plates | Wrench repairs +5 extra pegs. T-shape spans across the top row to protect lower pegs. |
| **Stormgrid Coupling**<br>`stormgrid_coupling` | **3×3 Corner Cradle** | 6 Cells | Magnetic Stabilizer Track + Arc Terminal | Stabilizes ball orbits near Magnet pegs with high magnetic force. |

---

## 2. Cross-Link Wall-Break Relics (Dual Synergy Tier: 3 to 5 Cells)

| Relic Name & Upgrade ID | Shape Geometry | Footprint | Internal Kinetic Machinery | Balance & Placement Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Supernova Peg**<br>`supernova_peg` | **2×2 Box** (O-Shape) | 4 Cells | Central Embedded Bomb Core + 4 Spark Pins | Triggers large explosion from energized pegs. Dense 2×2 block creates hazard zone. |
| **Chain Conduction**<br>`chain_conduction` | **4×1 Straight Rail** (I-Shape) | 4 Cells | Linear Lightning Rail + 4 Contact Pins | Hits all energized pegs. Long straight bar bridges distant peg lanes. |
| **Overcharged Drain**<br>`overcharged_drain` | **4-Cell L-Shape** | 4 Cells | 2 Leech Siphons + 1 Overcharge Bumper + 1 Funnel | Doubles drain energy on energized pegs. L-shape traps balls inside leeched pockets. |
| **Final Arc Detonation**<br>`final_arc_detonation` | **3-Cell V-Chevron** | 3 Cells | Spark Sensor + Angled Blast Cap | Adds explosion on final jump. Angled V-shape wedges neatly between three adjacent pegs. |
| **Energy Collapse**<br>`energy_collapse` | **4-Cell Z-Shape** | 4 Cells | Volatile Drain Siphon + Concussive Spring | Explodes heavily drained pegs. Jagged Z-shape guides balls into drain sectors. |
| **Shrapnel Split**<br>`shrapnel_split` | **4-Cell T-Shape** | 4 Cells | Fragment Deflector + Bomb Trigger Plate | Directs split fragments into Bomb pegs. T-arms divert fragments left and right. |
| **Energized Fragments**<br>`energized_fragments` | **3-Cell Skew Rhombus** | 3 Cells | Dual Energize Rollers + Contact Plate | Applies Energize on fragment contact. Diagonal rhombus matches diagonal plinko paths. |
| **Arc Twins**<br>`arc_twins` | **4×1 Gap Rail** | 4 Cells (Center Pass) | Dual Spark Terminals + Open Center Gap | Lightning jumps between active fragments. Center gap lets balls pass while arcs fire across. |
| **Phase Siphon**<br>`phase_siphon` | **3-Cell V-Chevron** | 3 Cells | Permeable Siphon Core + Energy Drain Plate | Drains Energize for +50% energy. Permeable body allows Phantom balls to pass through. |
| **Phase Detonation**<br>`phase_detonation` | **4-Cell Hook** | 4 Cells | Phantom Detection Gate + Blast Chamber | Explodes at board bottom after 5 passes. Hook shape fits along bottom border. |
| **Spectral Conduit**<br>`spectral_conduit` | **4-Cell Stepped Diagonal** | 4 Cells | Spectral Trail Rail + Spark Guide | Creates electrical highway across stepped peg rows. |
| **Impact Burst**<br>`impact_burst` | **4-Cell T-Shape** | 4 Cells | Heavy Kinetic Bumper + Impact Sensor | High-speed Rubbery hits trigger blasts. 3 bumper faces give wide bounce coverage. |
| **Kinetic Charge**<br>`kinetic_charge` | **3-Cell Skew Rhombus** | 3 Cells | Speed Boost Wheel + Energize Battery | Accelerates Rubbery balls on energized bounces. Slanted shape accelerates balls diagonally. |
| **Static Bounce**<br>`static_bounce` | **3-Cell L-Tromino** | 3 Cells | Overdrive Sensor + Tesla Spark Node | Discharges lightning at Overdrive 4. Corner shape mounts around high-bounce zones. |
| **Parasitic Arc**<br>`parasitic_arc` | **3-Cell V-Chevron** | 3 Cells | Arc Spreader + Drain Mist Nozzle | Spreads Drain via lightning. Angled V-shape bridges two peg columns. |
| **Draining Fragments**<br>`draining_fragments` | **3-Cell Skew Rhombus** | 3 Cells | Fragment Siphon Needle Array | Applies short Drain on fragment hits. Diagonal shape catches falling fragments. |
| **Resonant Bounce**<br>`resonant_bounce` | **3-Cell Straight Bar** | 3 Cells | Resonance Tuning Plate | Grants bonus energy to plain balls on energized pegs. Flat bar spans 3 peg columns. |
| **Ricochet Blast**<br>`ricochet_blast` | **4-Cell L-Shape** | 4 Cells | Overdrive Sensor + Concussive Bumper | Triggers blast at Overdrive 6. Corner plate catches high-speed ricochets. |
| **Blast Launch**<br>`blast_launch` | **3-Cell V-Chevron** | 3 Cells | Blast Deflector + Upward Spring Ramp | Blasts launch balls upward. Place directly adjacent to Trampoline pegs. |
| **Arc Surge Wrench**<br>`arc_surge_wrench` | **3-Cell Straight Bar** | 3 Cells | Repair Pulse Solenoid + Wire Harness | Lightning on Wrench repairs 10 pegs. Mounts beside Wrench pegs. |
| **Goblin Surge Chute**<br>`goblin_width_pulse` | **3-Cell Skew Rhombus** | 3 Cells | Ball Return Sensor + Chute Expander | Widens hopper temporarily on ball return. Mounts near return paths. |
| **Magnet Arc Snare**<br>`magnet_arc_snare` | **3-Cell V-Chevron** | 3 Cells | Magnetic Snare Coil + Spark Terminal | Pulls balls when lightning hits Magnet pegs. Angled shape funnels balls toward magnet. |
| **Spark Trampoline**<br>`spark_trampoline` | **3-Cell Straight Bar** | 3 Cells | Charged Spring Plate + Grounding Wire | Lightning on Trampoline gives extra lift. Mounts beneath Trampoline pegs. |

---

## 3. Single-Type Ball Enhancements & Swarm Relics (2 to 3 Cells)

| Relic Name & Upgrade ID | Shape Geometry | Footprint | Internal Kinetic Machinery | Balance & Placement Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Hyper Elastic**<br>`hyper_elastic` | **1×2 Vertical Bar** | 2 Cells | Upward Boost Accelerator Track | Boosts upward Rubbery speed. Vertical bar launches balls back toward the top. |
| **Overdrive Hits**<br>`overdrive_hits` | **2-Cell Diagonal Skew** | 2 Cells | Overdrive Multiplier Gate | Doubles energy on Overdrive 6. Diagonal shape fits tightly into peg gaps. |
| **Overclock Network**<br>`overclock_network` | **3-Cell V-Chevron** | 3 Cells | Grid Resonance Mesh | Energized pegs gain durability from neighbors. V-shape links 3 neighboring pegs. |
| **Spreading Rot**<br>`spreading_rot` | **3-Cell L-Tromino** | 3 Cells | Spore Dispenser + Rot Siphon | Drain expiry spreads to neighbors. Corner shape spreads across adjacent peg quadrants. |
| **Cluster Grenade**<br>`cluster_grenade` | **3-Cell V-Chevron** | 3 Cells | Sub-Munition Dispenser | Spawns secondary explosions. Angled shape catches incoming blast waves. |
| **Blast Lift**<br>`blast_lift` | **1×2 Vertical Bar** | 2 Cells | Upward Concussion Chute | Blasts push balls upward. Vertical chute directs blast momentum upward. |
| **Fragmentation Tag**<br>`fragmentation_tag` | **2-Cell Diagonal Skew** | 2 Cells | Blast Impact Sensor Core | Counts blast damage as extra peg hits. Small 2-cell footprint. |
| **Storm Feedback**<br>`storm_feedback` | **1×2 Horizontal Bar** | 2 Cells | Energy Feedback Solenoid | Lightning arcs boost peg energy. Bridges two peg columns. |
| **Overcurrent Surge**<br>`overcurrent_surge` | **2-Cell Diagonal Skew** | 2 Cells | Rapid Discharge Resistor | Double lightning hit resets peg HP. Diagonal 2-cell shape. |
| **Fragment Echo**<br>`fragment_echo` | **1×2 Horizontal Bar** | 2 Cells | Exit Funnel + Top Spawner Link | Exiting fragments spawn balls at top. Place at bottom board border. |
| **Mass Cascade**<br>`mass_cascade` | **2-Cell Diagonal Skew** | 2 Cells | Fragment Collision Plate | Fragment collisions boost energy. Small 2-cell size fits into drop corridors. |
| **Ghost Trail**<br>`ghost_trail` | **1×2 Vertical Bar** | 2 Cells | Permeable Trail Emitter | Phantom leaves energized trail. Permeable body allows ball pass-through. |
| **Phase Instability**<br>`phase_instability` | **1×2 Horizontal Bar** | 2 Cells | Zero-Hit Siphon Return Track | Respawns zero-hit Phantoms with speed. Place at lower drain zone. |
| **Plunderer's Cut**<br>`chest_random_ball` | **2-Cell Diagonal Skew** | 2 Cells | Locked Scrap Vault | Chests grant random balls. 2-cell module. |
| **Plain Surge**<br>`plain_surge` | **1×2 Horizontal Bar** | 2 Cells | Plain Kinetic Bumper Array | Multi-stackable plain ball energy buff. 2-cell footprint keeps board open for plain swarm. |
| **Plain Horde**<br>`plain_horde` | **2-Cell Diagonal Skew** | 2 Cells | Horde Sensor Core | Multi-stackable buff based on ball count. 2 cells preserve high ball volume space. |
| **Plain Momentum**<br>`plain_momentum` | **1×2 Vertical Bar** | 2 Cells | Overdrive Kinetic Plate | Multi-stackable Overdrive 7 buff. 2 cells fit into peg gaps. |
| **Volt Primer**<br>`volt_primer` | **1×2 Horizontal Bar** | 2 Cells | Cannon Discount Capacitor | Discounts next cannon shot on Energize gain. 2-cell module. |

---

## 4. Treasure Chest Onboard Passives & Tag Upgrades (2 to 3 Cells)

| Relic Name & Upgrade ID | Shape Geometry | Footprint | Internal Kinetic Machinery | Balance & Placement Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Bigger Blasts** (`explosion_radius`) | **2-Cell Diagonal Skew** | 2 Cells | Blast Expansion Chamber | Passive stat upgrade. Diagonal shape fits into tight peg alleys. |
| **More Explosion Hits** (`explosion_peg_hit_count`) | **1×2 Horizontal Bar** | 2 Cells | Shrapnel Dispersion Tube | Passive stat upgrade. Spans two peg columns. |
| **Stronger Blast Push** (`explosion_impulse`) | **1×2 Vertical Bar** | 2 Cells | Concussion Wave Baffle | Passive stat upgrade. Directs blast impulse vertically. |
| **+1 Chain Jump** (`chain_arc`) | **2-Cell Diagonal Skew** | 2 Cells | Arc Extender Node | Passive stat upgrade. Diagonal orientation matches lightning arc jumps. |
| **Longer Chains** (`chain_range`) | **1×2 Horizontal Bar** | 2 Cells | High-Voltage Spark Rail | Passive stat upgrade. Spans horizontal peg gaps. |
| **Deeper Energize** (`max_energize_stacks`) | **2-Cell Diagonal Skew** | 2 Cells | Dual Capacitor Cell | Passive stat upgrade. Slanted 2-cell shape. |
| **Slower Energize Fade** (`energize_decays_slower`) | **1×2 Vertical Bar** | 2 Cells | Insulation Mesh Core | Passive stat upgrade. Fits between vertical peg lanes. |
| **Fast Heal (Energized)** (`energized_pegs_repair_faster`) | **2-Cell Diagonal Skew** | 2 Cells | Nanite Dispenser Tube | Passive stat upgrade. Small 2-cell footprint. |
| **Tough Pegs** (`global_peg_durability`) | **3-Cell V-Chevron** | 3 Cells | Armor Plating Bracket | Global peg durability buff. V-bracket cups a peg on three sides. |
| **Faster Peg Recovery** (`peg_recovery_speed`) | **3-Cell V-Chevron** | 3 Cells | Rapid Reset Spring Frame | Global peg recovery buff. 3-cell V-frame cradles a peg slot. |
| **Devastating Barrage** (`devastating_barrage`) | **3-Cell L-Tromino** | 3 Cells | Heavy Shell Breech + Ammo Track | Grants +10 cannon damage. 3 cells impose real spatial cost for high weapon damage. |
| **Compressed Charge** (`compressed_charge`) | **3-Cell L-Tromino** | 3 Cells | High-Density Capacitor Bank | Reduces cannon energy cost. 3-cell L-shape balances high weapon value. |
| **Leech Drain Up** (`chest_leech_drain`) | **2-Cell Diagonal Skew** | 2 Cells | Micro Drain Siphon Rail | Multi-stackable chest passive. 2 cells fit into open diagonal grid slots. |
| **Longer Leech** (`chest_leech_duration`) | **1×2 Vertical Bar** | 2 Cells | Leech Sustainer Capsule | Multi-stackable chest passive. 2-cell vertical bar. |
| **Phantom Energy** (`chest_phantom_energy`) | **2-Cell Diagonal Skew** | 2 Cells | Spectral Permeability Siphon | Multi-stackable chest passive. 2 cells permit smooth ball phasing. |
| **Rubbery Energy** (`chest_rubbery_energy`) | **1×2 Horizontal Bar** | 2 Cells | Elastic Impact Siphon | Multi-stackable chest passive. 2-cell horizontal bar. |
| **Plain Energy** (`chest_bounce_energy`) | **2-Cell Diagonal Skew** | 2 Cells | Standard Impact Siphon | Multi-stackable chest passive. 2-cell diagonal shape. |
| **Split Energy** (`chest_split_energy`) | **1×2 Vertical Bar** | 2 Cells | Fragment Impact Siphon | Multi-stackable chest passive. 2-cell vertical bar. |

---

## Acceptance Criteria

- [x] All relics in Campaign 1 have assigned spatial footprint shapes and internal machinery specifications.
- [x] Shape matrix offsets and rotation transforms support regular and irregular polyominos.
- [x] Data resources implement `PolyominoModuleData` in Godot.
- [x] Headless unit tests pass with `tests/run_tests.gd`.

