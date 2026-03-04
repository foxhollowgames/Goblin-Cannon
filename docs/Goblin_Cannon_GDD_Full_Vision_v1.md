# Goblin Cannon -- Full Vision Game Design Document (v1)

*Updated to reflect current codebase state.*

## 1. High Concept

A deterministic, physics-driven auto-battler roguelike where players
construct a chaotic goblin siege engine powered by a plinko-style mana
circuit board. The player never directly controls combat; all agency is
expressed through drafting and system architecture.

## 2. Core Pillars

-   Structured Chaos (never unreadable)
-   Visible Systems (hopper, board, attachments)
-   Energy Economy as Core Skill Expression
-   No Hard Counters
-   Difficulty Adds Mechanics, Not Stat Scaling
-   Late Game = Mastered Madness

## 3. Emotional Arc

-   **City 1 -- Discovery** (readable, stable, identity forming)
-   **City 2 -- Escalation** (build pressure increases)
-   **City 3 -- Mastery Through Chaos** (absurd but controlled
    spectacle)

## 4. Core Loop

-   Hopper → Balls fall → Peg interactions → Energy routing → Systems
    fire → Balls return
-   Milestones triggered by total raw energy (XP-like progression)
-   When a wall is destroyed, a conquest (wall-break) reward is shown before advancing to the next wall

## 5. Hopper & Conduit

-   Visible hopper (up to 100 balls shown, overflow invisible)
-   FIFO order preserved; ball identity (ball_id) owned by Hopper
-   Gate opens on a wave interval (sim ticks); door open duration stackable via upgrades
-   No hard cap on wave speed; MAX_ACTIVE_BALLS (e.g. 120) is a safety valve so Conduit stops releasing when active ball count is at cap
-   Hopper width scale from wall-break major upgrade (e.g. +25%)
-   Conduit gate open duration scale from wall-break major upgrade

## 6. Board System

-   Embedded plinko-style circuit board
-   Peg durability, recovery, and vibrancy feedback; pegs can be temporarily disabled (durability 0) then recover after recovery_sim_ticks
-   **Peg types (implemented)**: Standard pegs; **Trampoline** pegs (high restitution, upward launch); **Bomb** pegs (wall-break upgrade); **Goblin reset** pegs (wall-break)
-   **Energize** ball grants pegs temporary extra “energized” durability (crackling aura)
-   **Leech** ball applies a status to pegs: periodic energy drain (e.g. 5 display energy/sec for 10 sec), then expires
-   Board modifications via drafts and wall-break upgrades (extra pegs, explosion/chain bonuses, etc.)

## 7. Ball System & Tiers

-   Base energy: 20 at bottom + 10 per peg hit (display units); internal = display × 100 for routing
-   **Tier 1** (City 1 primary): Bounce, Flame, Frost, Spark, Ember, Chill, Bolt, Flare, Ward, Split, Energize, Explosive, Chain Lightning, Leech, Rubbery, Phantom
-   **Tier 2** (City 2 primary): Surge, Blaze, Aegis, Volt, Inferno, Glacier, Split, Energize, Explosive, Chain Lightning, Leech, Rubbery, Phantom (variants)
-   **Tier 3** (City 3 primary): planned; not yet in reward pool
-   City-weighted rarity distribution: City 1 = Common + Uncommon max; City 2 = through Rare/Purple; City 3 = all rarities (White → Red, 0–5)
-   **Rarity**: 0=Common, 1=Uncommon, 2=Rare, 3=Purple, 4=Orange, 5=Epic (affects draft border and weighting)
-   **Alignment** (Main / Sidearm / Defense) is randomized per pick at draft time (GDD §8 energy split)
-   **Ball abilities (implemented)**:
  - **Status on peg hit / bottom**: Flame/Frost/Spark (fire, frozen, lightning) apply status to minions/fortifications when ball hits pegs or reaches bottom
  - **Split**: spawns a temporary twin ball (same energy path); twin does not return to hopper
  - **Energize**: adds energized durability stacks to pegs hit
  - **Explosive**: hits pegs in a radius (configurable; wall-break can add radius/hit count/impulse bonuses)
  - **Chain Lightning**: chains to N nearest pegs (hit + lightning status); wall-break can add arc/range
  - **Leech**: applies leech status to pegs; pegs drain energy periodically (e.g. 5/sec for 10 sec)
  - **Rubbery**: higher restitution (more bounces, more peg hits)
  - **Phantom**: grants energy on hit but no peg durability damage
-   Balls use **RigidBody2D** (engine-driven physics); anti-vertical nudge prevents infinite straight up/down bounces. Hit reporting: Board calls `step_one_sim_tick()` and reads colliding bodies for peg hits.

## 8. Energy Routing Model

-   Main-aligned: 70% Main / 15% Sidearm / 15% Shield
-   Sidearm-aligned: 80% Sidearm / 20% Main
-   Defense-aligned: 80% Shield / 20% Main
-   Integer deterministic math only; **internal unit = display × 100** (all pools and thresholds in internal; only UI shows display)
-   **Shield pool**: receives Defense share; 50 display energy = 1 shield point. Cannon takes damage first to shield, then to cannon HP (100 + milestone bonus). Shield cap scalable via milestone stat upgrade.

## 9. Systems

-   **Main Cannon**: auto-fire at charge threshold (linear scaling from config); optional status_effects_on_fire (e.g. fire/frozen/lightning) from upgrades
-   **Shield Pool**: shared pool for Defense-aligned energy; converts to shield points; consumed when cannon is damaged
-   **Sidearms (implemented)**:
  - **Rapid Fire**: cooldown-based fire from shared sidearm pool; frontmost minion or wall
  - **Sniper**: single high-damage shot (unlocked via wall-break)
  - **AOE Cannon**: area damage around frontmost minion (unlocked via wall-break)
-   Shared sidearm energy pool; SidearmsContainer holds only **owned** sidearms (unlocked via wall-break major upgrades). Fallback scaling (cooldown/damage) when no new sidearm is available to offer.
-   Abilities that auto-fire when charged (future scope)
-   MainCannonConfig / SidearmConfig: energy_per_shot (internal), cooldown_sim_ticks, damage_per_shot, is_aoe, aoe_radius, status_effects_on_fire

## 10. Status System (Implemented)

-   Independent stack model (value + duration/decay): stacks cap at 5; decay every 120 sim ticks (2 s)
-   **Implemented**: **Fire**, **Frozen**, **Lightning** (Constants.STATUS_FIRE, STATUS_FROZEN, STATUS_LIGHTNING)
-   Applied by: (1) balls (peg hit or ball_reached_bottom) via BallDefinition.status_effects; (2) cannon/sidearm when config has status_effects_on_fire; (3) wall-break ball enhancements (e.g. impact burst, overdrive)
-   Targets: minions, fortification turrets, cannon visual (staging/demo and in combat)
-   BattlefieldView: apply_status_to_frontmost_minion, apply_status_to_minions_in_radius, apply_status_to_active_fortifications; damage_frontmost_minion / damage_minions_in_radius accept status_effects
-   Burn, Regen, Hunger, Siphon: reserved for future/boss-level mechanics

## 11. Cities

-   **City 1 -- Halfling Shire** (slice / implemented): display_name "Halfling Shire", gate_name "Village Gate", wall_names ["Village Gate", "Mill Gate", "Town Hall"], wall_hp_max 50, milestone_thresholds [200, 400, 600]
-   **City 2 -- Human Kingdom** (throughput disruption): resource path present; tuning in progress
-   **City 3 -- Elf Palace** (arcane pressure, cosmic phase 2): resource path present; tuning in progress
-   **CityDefinition** (resource): city_id, display_name, gate_name, wall_names[], wall_hp_max, milestone_thresholds[]; get_wall_hp_max_for_index(wall_index) for scaling (e.g. 50, 100, 300, …)

## 12. Milestone System

-   XP-style progression, never decreases; total accumulated in **display** units
-   **Per milestone**: **5 options** (pick one); mix of **ball** and **stat** upgrades with variance (0–5 balls, rest stats; no identical options)
-   Ball options: city-weighted, unique by ability_name+alignment
-   Stat options: main_charge, sidearm_cap, shield_cap, health_max, shield_max, door_interval, door_duration; rarity (Common/Uncommon/Rare) for weighting and draft border
-   Milestone thresholds: from city (e.g. 200, 400, 600 per wall) or curve (first 5 linear 2k–10k, then exponential)
-   Boss/wall-break rewards introduce rule-breaking synergies (see §12.1)

### 12.1 Wall Break (Conquest) Rewards

When the player destroys a city wall (wall HP reaches 0), they receive a **conquest reward** before advancing to the next wall. This is distinct from milestone rewards (balls + stats).

-   **Reward type**: One **major upgrade** choice (pick 1 of **3**).
-   **Major upgrade categories**: Each draft presents **three** options—one from each category (when available):
  - **Sidearm**: Unlock a new sidearm (Rapid Fire, Sniper, AOE Cannon). If all are owned, fallback options (e.g. cooldown/damage scaling) are offered.
  - **Ball Enhancement**: Upgrade for a specific ball ability (only offered if that ability exists in run—hopper + bag). Examples: impact_burst, hyper_elastic, overdrive_hits, supernova_peg, chain_conduction, spreading_rot, energy_collapse, cluster_grenade, storm_feedback, final_arc_detonation, overcurrent_surge, fragment_echo, mass_cascade, ghost_trail, phase_instability (stack limits per upgrade_id).
  - **Board / Tag**: Board-wide or peg upgrades (e.g. explosion radius, chain arc, bomb pegs, trampoline pegs, goblin reset nodes, peg durability, recovery speed, energize stacks, etc.)
-   **MajorUpgradeDefinition** (resource): display_name, description, upgrade_id, category (SIDEARM, BALL_ENHANCEMENT, BOARD_UPGRADE), ball_type (for ball enhancements, filter by ability in run)
-   GameState tracks: applied_wall_break_upgrades (upgrade_id → stacks), owned_sidearm_ids, ball_ability_names_in_run; and scaling (hopper_width_scale, conduit_open_duration_scale, cannon_charge_reduction, sidearm_pool_cap_scale; explosion_radius_bonus, chain_arc_bonus, bomb_peg_count, trampoline_peg_count, etc.)

| Upgrade (examples) | Effect |
|--------------------|--------|
| **Bonus Balls**    | Add balls to reserve (hopper). |
| **Conduit Size / Door** | +1 ball released per wave or longer open duration (conduit_open_duration_scale). |
| **Cannon Charge**   | Main cannon charge requirement reduced (cannon_charge_reduction). |
| **Fortification**   | Next wall starts with bonus HP (city curve). |
| **Sidearm Energy** | Sidearm pool capacity increased (sidearm_pool_cap_scale). |
| **Wider Hopper**   | Hopper bin width +25% (hopper_width_scale). |
| **New Sidearm**    | Unlock Sniper or AOE Cannon (owned_sidearm_ids). |
| **Ball Enhancement** | Stack for a ball ability in run (impact_burst, chain_conduction, etc.). |
| **Board / Peg**    | Bomb pegs, trampoline pegs, explosion/chain bonuses, peg durability, etc. |

## 13. Difficulty & Ascension

-   Low Ascension: brute force viable
-   High Ascension: layered mechanical pressure
-   No reactive world scaling
-   Ascension levels: not yet implemented

## 14. Vertical Slice Scope (Original vs Current)

-   **Original slice**: Balanced board, City 1 only, Tier 1 & 2 balls, Rapid Fire sidearm only, core milestone (3 balls + 2 stats), debug overlay.
-   **Current implementation** extends the slice:
  - **Board**: Balanced board; trampoline and bomb pegs (wall-break); energize, leech, explosive, chain lightning, split, rubbery, phantom behaviors.
  - **City 1**: Full Halfling Shire with 3 walls (Village Gate, Mill Gate, Town Hall); per-wall milestone thresholds and wall-break major upgrade draft.
  - **Balls**: Tier 1 & 2 with full ability set (status, split, energize, explosive, chain lightning, leech, rubbery, phantom); city-weighted rarity; 5-option milestone draft with variance.
  - **Sidearms**: Rapid Fire (default) + Sniper + AOE Cannon (unlocked via wall-break); shared sidearm pool; SidearmsContainer.
  - **Combat**: Wall HP, cannon HP, shield pool; minions, fortifications (turret); status on minions/turrets/cannon; AOE and muzzle-blast damage.
  - **Milestones**: 5 options (balls + stats mixed); stat ids and rarities; RewardsManager queue (milestone vs wall_break), slow-mo → pause → modal.
  - **Wall break**: Major upgrade draft (1 of 3: sidearm / ball enhancement / board); GameState applied_wall_break_upgrades and scaling.
  - **Status**: Fire, Frozen, Lightning implemented on minions, fortifications, cannon visual.
  - **Debug overlay**: Present; optional debug test run (50% trampoline pegs, all sidearms) via Constants.

## 15. Not Included (Yet)

-   City 2 & 3 full content and tuning
-   Tier 3 balls and abilities
-   Ascension
-   Final art, sound polish, cinematics
-   Full roster of boss rule-breaking synergies

## 16. Long-Term Targets

-   12–15 base abilities total
-   6–8 sidearms (current: 3)
-   6–10 abilities
-   3 cities
-   5 ascension levels
-   30–60 minute full run
-   50–200 ball endgame bag size

## 17. Success Criteria

-   Core loop is enjoyable
-   Players disappointed it ends after City 1
-   Chaos remains readable
-   Build diversity feels meaningful

---

## Implementation Notes (Code Alignment)

-   **Sim clock**: SIM_TICKS_PER_SECOND = 60; gameplay timing in sim ticks; Conduit wave/ door in ticks (seconds converted once).
-   **Energy**: Display for milestones and UI; internal = display × 100 for EnergyRouter and all pools (main, sidearm, shield).
-   **Hit detection**: Board is authority; peg hits from ball collision (RigidBody2D colliding bodies); per-ball-per-peg cooldown (HIT_COOLDOWN_SIM_TICKS); flush once per sim tick.
-   **Run flow**: GameState.RunFlowState (FIGHTING, REWARD_SLOWMO, REWARD_PAUSED, RESUMING); RewardsManager drains milestone and wall_break queues one at a time.
-   **RNG**: Only simulation/reward_generation.gd; RewardHandler and nodes call into it; run seed in GameState.
-   **Architecture**: See `docs/ARCHITECTURE.md` for signals, call-down contracts, and module breakdown.
