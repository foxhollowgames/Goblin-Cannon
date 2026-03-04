# Goblin Cannon – Godot Architecture Document

Based on **Goblin_Cannon_GDD_Full_Vision_v1.pdf**. This document defines a modular, signal-driven architecture for Godot 4.x that matches the GDD’s core loop and supports the vertical slice, then expansion.

---

## 0. Design Decisions & Work (Rationale)

- **Core loop as pipeline**: The GDD’s loop (Hopper → Balls → Pegs → Energy → Systems → return) is modeled as a **pipeline of nodes**. Each stage owns one concern and communicates only via signals (up) and public methods (down). This keeps “structured chaos” readable and testable.
- **GameCoordinator + domain managers**: A **GameCoordinator** node handles wiring (signal connections), per-tick event buffering, and resolution order. Domain managers (**EnergyManager**, **CombatManager**, **RewardsManager**) expose small APIs so the coordinator doesn’t become a god object. EventBus is optional for UI/debug.
- **Energy as integers**: GDD specifies “integer deterministic math only.” All energy values, splits, and configs use `int` (or `Vector3i` for main/sidearm/shield). Gameplay timing uses sim ticks (§1.4); floats only for visuals.
- **Board is the single authority for energy**: Peg only reports “was hit” and updates durability; it does not dictate energy math. Board accumulates energy per ball locally (20 base + 10 per peg hit) and emits only `ball_reached_bottom(ball_id, total_energy, alignment)`. This avoids double-counting, ordering bugs, and per-hit signal storms (see §1.4, §4).
- **Sidearm shared pool**: GDD says “shared sidearm energy pool.” One EnergyPool node receives the sidearm share from EnergyRouter; Rapid Fire (and future sidearms) call `consume()` on that pool. Firing logic stays in each sidearm script (small, single-purpose).
- **Milestone never decreases**: “XP-style progression, never decreases” is enforced in MilestoneTracker by only ever adding to a running total and comparing to fixed thresholds. No subtraction or reset of milestone progress.
- **Slice boundaries**: Folder structure and signal contracts are designed so City 2/3, Tier 3, status system, and ascension can be added as new resources and scenes without changing Hopper, Board, EnergyRouter, or the core signal/call-down contracts.

---

## 1. Architecture Goals & Principles

### 1.1 From the GDD

- **Core loop**: Hopper → Balls fall → Peg interactions → Energy routing → Systems fire → Balls return.
- **Structured chaos**: Systems must stay readable; state and flow are explicit.
- **Visible systems**: Hopper, board, pegs, and attachments are first-class nodes.
- **Deterministic**: Integer math only; no floating-point in game logic where it affects outcomes.
- **Vertical slice**: Balanced board, City 1, Tier 1 & 2 balls, Rapid Fire sidearm, milestones, debug overlay.

### 1.2 Godot Conventions We Follow

| Principle | Meaning |
|-----------|--------|
| **Signal up** | Child nodes emit signals when something happens; parent (or autoload) connects and decides what to do. No child calling parent methods for “reporting.” |
| **Call down** | Parents (or coordinators) call methods on children when they need to command or query. Children do not reach up to get data; they receive it via method args or `_ready` injection. |
| **Modular components** | Each gameplay system is one or more scenes. Scripts stay small; one script per primary responsibility. |
| **Small functions** | Functions do one thing, take few parameters, and are easy to name and test. |
| **Resources for data** | Configs, definitions, and tuning live in Resources (e.g. `BallDefinition`, `PegConfig`); scenes and scripts reference them. |
| **No spaghetti** | Systems communicate via signals and explicit public APIs; avoid `get_node()` across unrelated branches. |
| **Signal lifecycle** | Where GameCoordinator or managers connect to child signals, **disconnect in `_exit_tree()`** (or when the child is removed) to avoid leaks and stray calls. See [Godot signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html). |

### 1.3 High-Level Data Flow

```
[Hopper] --ball_entered_board--> [Board]  (Conduit feeds Board)
[Board] --ball_reached_bottom(ball_id, total_energy, alignment)--> [GameCoordinator]
[GameCoordinator] --> [EnergyRouter] --energy_allocated--> [Systems]
[Systems] --main_fired / sidearm_fired--> [CombatManager]
[Milestone] --milestone_reached--> [RewardsManager] --> [Hopper/Bag] + [Stats]
```

Board does **not** emit per-hit signals; it accumulates energy per ball and emits once when a ball reaches the bottom. Peg VFX/audio are handled locally on the Peg.

### 1.4 Determinism & Godot-Specific Pitfalls

- **Physics**: Godot’s `RigidBody2D` and engine collision callbacks are **not** deterministic across machines or runs (ordering can diverge). For determinism, use **CharacterBody2D** or **custom kinematic integration** for balls. Do **not** depend on `body_entered` / `area_entered` signal order.
- **Event order within a tick**: **Board** is the **only** authority that buffers, sorts, and resolves peg-hit events. GameCoordinator does **not** sort peg hits; it only handles higher-level ordering (milestone, rewards, speed state). Board flushes **once per sim tick at end-of-sim-step**—never flush mid-step or you get inconsistent state.
- **Time and floats**: Any gameplay outcome driven by float timers can drift. **Fix**: use **sim ticks** (simulation steps) for all gameplay timing. Define **SIM_TICKS_PER_SECOND = 60** (or your chosen rate) once; that is the simulation clock. Do **not** use `Engine.time_scale` for gameplay. **Game speed** (slow-mo, pause) has a **single authority**—see §1.10.
- **Integer energy**: All energy math is integer. **Remainder handling** is **locked** to one method only—see §1.7.

### 1.5 Ball Physics Model (Deterministic Plinko)

The doc commits to **Approach A: Kinematic + manual bounce**.

- **Implementation**: Balls use **CharacterBody2D** with **`move_and_collide()`**. Reflection is computed manually from the collision normal; no engine bounce randomness. Gravity and movement are applied **once per sim tick** when Board (or BallSystem) calls **`ball.step_one_sim_tick()`**—see §1.10 and §6.5. Balls do **not** move in their own `_physics_process`; that would desync under slow-mo.
- **Pros**: Deterministic, controllable, real Plinko feel. **Cons**: You must tune bounce coefficient and friction (as config or constants) to feel good; Godot’s built-in kinematic response won’t “be” Plinko without that tuning.
- **Alternative (not chosen for slice)**: Approach B—“fake Plinko” with overlap tests + RNG-seeded deflection, no true rigid physics. Use only if Approach A tuning proves too costly; it’s more stable and easier to cap chaos but less physical.

**Commitment**: Slice uses Approach A. All ball motion is driven by your kinematic integration and reflection logic, not RigidBody2D or engine physics for ball movement.

### 1.6 Hit Registration Rules

To avoid multiple hits per sim tick on the same peg, “stuck in peg” spam, and chaos when chain/explosion mechanics are added later, hit registration is **explicitly** defined:

- **When a hit is created**: **move_and_collide()** collision is the **authoritative** hit candidate (§1.9). When Board (or BallSystem) runs `ball.step_one_sim_tick()`, any collision with a peg returned from move_and_collide is recorded as a candidate. Swept segment–circle test is **fallback only** (e.g. when no collision is returned). Do not use Area2D events for hit creation.
- **Per-ball, per-peg cooldown**: A ball can register a hit on a **given peg** at most **once every N sim ticks** (e.g. N = 3). Board keeps `(ball_id, peg_id) → last_hit_sim_tick` and rejects candidates within the cooldown window.
- **Authority**: Board is the **only** authority that buffers, sorts, and resolves peg hits. It flushes **once per sim tick at end-of-sim-step**. GameCoordinator does not sort or buffer peg events.

**peg_id determinism**: **peg_id** must be an **integer index** (0..N-1) assigned at **board construction time**, not a NodePath and not a name string from the scene. If peg ids come from scene node names or paths, they can change when you reorder nodes or rebuild scenes and determinism is lost.

**Concrete spec**: Constant `HIT_COOLDOWN_SIM_TICKS` (e.g. 3). Hit is accepted only if `current_sim_tick - last_hit_sim_tick(ball_id, peg_id) >= HIT_COOLDOWN_SIM_TICKS`.

### 1.7 Energy Routing Remainder (Single Standard)

**Only** one approach is supported: **internal unit = display energy × 100**.

**Convention (locked)**: Designers work in **display energy** (what the GDD uses). **Internal** = display × 100. All pools and **cannon/sidearm** thresholds store **internal only**. Only the **UI** divides by 100 for display.

- **Display ↔ internal examples** (use these; wrong scale = silent 100× bugs):
  - Ball base energy 20 (display) → **2,000** internal.
  - Peg hit +10 (display) → **+1,000** internal per hit.
  - **Cannon fire threshold 800** (display, GDD slice) → **80,000** internal.
  - **Sidearm fire threshold 200** (display) → **20,000** internal.
- All routing math is done in internal units. Splits (70/15/15, etc.) are applied to the internal value; integer division yields exact main/sidearm/shield with no remainder.
- **No** stateful per-pool remainder accumulator. **No** “or use remainder” alternative. EnergyRouter uses only this method.

**Invariant test (use to catch double-multiply or forgot-to-multiply)**: One ball, base 20 + 3 peg hits → display = 50, internal = 5000. Main-aligned split (70/15/15) ⇒ main = 3500, sidearm = 750, shield = 750. If your implementation disagrees, fix the conversion boundary.

**Milestone units (locked)**: **Milestones use display units only.** MilestoneTracker stores the running total in **display** energy. GDD §12: ~3 milestones per wall, 200 scale — thresholds (e.g. 200, 400, 600). Board emits `ball_reached_bottom(…, total_energy_display, …)`; GameCoordinator (or EnergyManager) passes that **display** value to MilestoneTracker as-is and multiplies by 100 when calling EnergyRouter. So: one number from Board (display); MilestoneTracker consumes display; EnergyRouter receives internal (display × 100). Do not store milestone thresholds or milestone total in internal units—that would fork the implementation.

### 1.8 Physics Constants Contract (Slice Defaults)

Determinism and feel require fixed numbers; without a table, implementations will invent values and churn. Use these as **slice defaults** (in constants or a PhysicsConstants resource); all gameplay math uses them consistently.

| Constant | Slice default | Unit / notes |
|----------|----------------|---------------|
| `GRAVITY` | e.g. 24 | pixels per sim tick² (apply once per step_one_sim_tick) |
| `BALL_RADIUS` | e.g. 8 | pixels |
| `PEG_RADIUS` | e.g. 12 | pixels |
| `RESTITUTION` | e.g. 0.6 | bounce coefficient (0–1) |
| `TANGENTIAL_FRICTION` | e.g. 0.1 | energy loss along surface (or equivalent) |
| `LINEAR_DRAG` | e.g. 0.01 | air resistance per sim tick |
| `MAX_BALL_SPEED` | e.g. 600 | pixels per second (or per sim tick × SIM_TICKS_PER_SECOND); **clamp** to avoid tunneling and jitter |
| `SUBSTEPS_RULE` | e.g. “if speed > X, run N micro-steps per sim tick” | optional; only if not using move_and_collide hits (see §1.9) |
| `CELL_SIZE` | e.g. = PEG_SPACING or 2×PEG_RADIUS | spatial hash cell size (§1.9) |
| `SIM_TICKS_PER_SECOND` | e.g. 60 | simulation clock; use for conduit seconds→ticks (§1.13), stall (§1.12), and all gameplay timing |

### 1.9 Hit Detection Mechanism (One Truth Source: move_and_collide)

You have two possible sources of “hit”: **move_and_collide()** (the actual bounce) and **swept segment–circle test**. They can disagree (swept says hit but no collision → “ghost energy”; collision but swept missed → missed energy). **Lock one truth source.**

**Authoritative (locked for slice)**: **move_and_collide() collision is the authoritative hit candidate.** When a ball’s `step_one_sim_tick()` calls `move_and_collide()` and it returns a collision with a peg, that collision **is** the hit—Board records (ball_id, peg_id) from that collision, then applies cooldown/sort/resolve. No separate swept test for that ball’s motion this tick.

**Fallback only**: Use the **spatial hash + segment–circle test** only when you are **not** using move_and_collide for that ball (e.g. custom movement without collision, or a code path that doesn’t get a collision). Do not run both and merge—that invites double-count or desync.

- **Cell size**: **CELL_SIZE = PEG_SPACING** (or **2 × PEG_RADIUS**). **peg_id** = integer index 0..N-1 at board build (§1.6).
- **Query volume** (for fallback): For each ball, query cells overlapped by the ball’s swept AABB (start→end, expanded by BALL_RADIUS).
- **Fallback candidate test**: Segment–circle (ball center path vs peg circle inflated by BALL_RADIUS). Use only when move_and_collide did not supply a collision for that step.
- **Flow**: Board collects hit candidates from move_and_collide (and optionally fallback), applies per-ball-per-peg cooldown, sorts (ball_id, peg_id), resolves, adds +10 (display) per accepted hit.

### 1.10 Game Speed Authority (Committed: Gameplay Slow-Mo)

**Single source of truth**: One owner for “game speed” (slow-mo, pause): **SimClock** (Node) or **GameState.sim_speed** (autoload). All gameplay systems that care about rate **read** from this.

**Committed model (GDD intent)**: **Slow-mo affects gameplay**—e.g. 3% for a few seconds, then hard pause so energy accumulation is negligible. So we **do not** use “visual-only” slow-mo; we commit to **Option B**.

- **What scales by sim_speed**: Ball motion (kinematic delta), conduit door cadence (when the next ball can leave), cooldown ticks (sidearm, abilities), combat wave timers. All of these must advance at the same effective rate when sim_speed < 1.
- **What does NOT scale**: UI animation, debug overlay update cadence (e.g. 1 Hz in real time), audio/VFX playback rate (or scale them separately if desired). These run in real time so the game stays responsive.
- **How timers work under slow-mo**: Use **integer sim ticks** and **run fewer simulation steps per real frame** when slow-mo is on. **Fixed-step accumulator**: each real frame, add `delta * sim_speed` to an accumulator; when accumulator ≥ 1, run **one sim step** and subtract 1. All gameplay state (cooldown “ticks remaining,” door “ticks until open,” stall tick count) is in **sim ticks**. No float in counters. **Balls do not move in their own _physics_process.** Board (or a BallSystem node) calls **`ball.step_one_sim_tick()`** exactly **once per sim tick**; that is the only place ball motion runs. One sim tick = one deterministic integration step. Otherwise balls would keep moving at real-frame rate while sim ticks are sparse and slow-mo would desync.
- **Hard pause**: When paused, do not add to the accumulator; no sim steps run. Energy accumulation and ball motion stop.

**RunFlow state machine (who drives slow-mo/pause)**: The states that cause sim_speed and pause must be explicit. **Owner**: RewardsManager or GameCoordinator (pick one); **UI is never the owner.** Minimal states:
- **FIGHTING**: Normal sim_speed (e.g. 1.0).
- **REWARD_SLOWMO**: sim_speed = 0.03 (or similar) for 5–10 **real** seconds so the player sees the milestone.
- **REWARD_PAUSED**: sim_speed = 0 or paused; player picks rewards.
- **RESUMING** (optional): brief transition back to FIGHTING.

Transitions: milestone_reached → REWARD_SLOWMO → (after timer) REWARD_PAUSED → (after picks) RESUMING → FIGHTING. Without this, slow-mo and pause will be driven ad-hoc and desync.

### 1.11 RNG Seed and Stream Policy

Determinism is only useful if you can **reproduce a run**. Define this now:

- **One seed per run**: Stored in **GameState** (or equivalent) when a run starts. Log this seed (and run config) in the end-of-run summary so debug/replay can reproduce.
- **Separate RNG streams**: Use **distinct** RNGs (or distinct streams from a single RNG) per domain so that adding a new random call in one system does not change others:
  - **Reward RNG**: ball choices, stat upgrade rolls.
  - **Spawn RNG**: e.g. ball spawn position (top position jitter if any).
  - **Combat RNG**: (later) crits, targeting variance.
- **Rule**: Never call “global” RNG for gameplay; always use the stream for that domain. Seed each stream from the run seed in a fixed order (e.g. reward_stream = seed+0, spawn_stream = seed+1, combat_stream = seed+2).

**Enforcement—no RNG in nodes**: **Nodes never call `rand*` (or engine RNG) directly.** Only designated simulation/ or manager code may use RNG:
  - **Only** `simulation/reward_generation.gd` may shuffle rewards and pick ball/stat choices (RewardHandler calls into it).
  - **Only** Board or a dedicated SpawnManager may use spawn RNG (e.g. top entry jitter).
  - Combat RNG (later) lives in CombatManager or simulation.
If you slip RNG into a node, the run seed becomes meaningless for replay. Add this rule to code review / lint.

### 1.12 Stall Despawn Rule (Explicit)

Stall despawn must be **numerically defined** so behavior is consistent and not hand-wavy.

- **STALL_PIXELS_EPS** (e.g. 2): Minimum distance (pixels) the ball must move in a **sim tick** to count as “moving.”
- **Per-ball state**: Track **distance moved this sim tick** (magnitude of position delta after `step_one_sim_tick()`).
- **Stall condition**: If `distance_moved < STALL_PIXELS_EPS` for **N consecutive sim ticks**, the ball is **stalled**. N = **10 seconds** at sim tick rate: `STALL_SIM_TICKS = SIM_TICKS_PER_SECOND * 10` (e.g. 600 at 60 ticks/s).
- **Action**: On stall, Board (or owner) emits `ball_exited_board(ball, stall_despawn)` and returns the ball to the hopper; **no** bottom energy grant. Do not use ad-hoc float timeouts; use this rule only.

**MAX_ACTIVE_BALLS (safety valve)**: **MAX_ACTIVE_BALLS = 120** (example). If the number of balls currently on the board exceeds this, **Conduit stops releasing** until the count drops. This is a deterministic slice safety valve so the vertical slice stays testable when wave speed upgrades are aggressive; it does not contradict “no hard cap on wave speed” as a later design goal if you relax or remove it post-slice.

### 1.13 Conduit Timing: Seconds → Sim Ticks Conversion

Upgrades and design will specify door open/close and wave interval in **seconds**. Gameplay state must use **sim ticks** for determinism. Use a **single conversion rule**:

- **ticks = round(seconds × SIM_TICKS_PER_SECOND)**. Pick one rounding (e.g. **round**); use it everywhere. Do not mix floor/ceil.
- **Designer-facing value (seconds)** lives **only** in config or UI. **Never** store seconds in gameplay state. At load or when applying an upgrade, convert once and store **sim ticks**. Otherwise upgrades will drift.

**Conduit release spec (reconcile door + wave)**: Every **WAVE_INTERVAL_TICKS**, Conduit opens for **OPEN_TICKS**. While open, balls fall out by **physics** (hopper contents, gate width, fall speed); there is no fixed balls-per-wave limit. Gate closes when open duration expires. Upgrades adjust wave interval and open duration only.
---

## 2. Project Folder Structure

```
GoblinCannon/
├── project.godot
├── docs/
│   └── ARCHITECTURE.md          # This file
├── simulation/                   # Pure logic for determinism + testability; Nodes call in
│   ├── energy_routing.gd        # routing pure functions (energy×100, split by alignment)
│   ├── hit_cooldown.gd           # (ball_id, peg_id) → last_hit_sim_tick; cooldown_ok()
│   ├── milestone_curve.gd        # threshold lookup, curve logic
│   └── reward_generation.gd       # candidate list, shuffle, take first N unique
├── assets/
│   ├── audio/
│   ├── textures/
│   └── fonts/
├── autoloads/
│   ├── game_state.gd            # Run state, current city, ascension; run seed; sim_speed / pause (§1.10)
│   ├── event_bus.gd             # Optional: global signals if many cross-tree listeners
│   └── constants.gd             # Integer constants + physics constants (§1.8)
├── resources/
│   ├── balls/
│   │   ├── ball_definition.gd   # Resource: tier, base_energy, city_weights
│   │   └── definitions/        # .tres per ball type
│   ├── board/
│   │   ├── board_archetype.gd   # Resource: peg_layout, archetype enum
│   │   └── peg_config.gd       # Resource: durability, recovery, vibrancy
│   ├── systems/
│   │   ├── main_cannon_config.gd
│   │   └── sidearm_config.gd   # Rapid Fire for slice
│   ├── cities/
│   │   └── city_definition.gd  # Resource: waves, rewards, boss (slice: City 1)
│   └── milestones/
│       └── milestone_definition.gd
├── scenes/
│   ├── main/
│   │   ├── main.tscn            # Root game scene
│   │   ├── game_coordinator.gd  # Wiring, tick buffering, resolution order
│   │   ├── energy_manager.gd   # Small API: receive allocation, feed pools
│   │   ├── combat_manager.gd   # Small API: receive fire events, drive combat
│   │   └── rewards_manager.gd   # Small API: grant balls/stats, call Hopper
│   ├── hopper/
│   │   ├── hopper.tscn
│   │   └── hopper.gd
│   ├── conduit/
│   │   ├── conduit.tscn        # Door + chute from hopper to board
│   │   └── conduit.gd
│   ├── board/
│   │   ├── board.tscn
│   │   ├── board.gd
│   │   ├── peg.tscn
│   │   └── peg.gd
│   ├── balls/
│   │   ├── ball.tscn
│   │   └── ball.gd
│   ├── energy/
│   │   ├── energy_router.gd    # Pure logic; Node under Main (not Autoload for slice)
│   │   └── energy_pool.gd     # Sidearm shared pool
│   ├── systems/
│   │   ├── main_cannon/
│   │   │   ├── main_cannon.tscn
│   │   │   └── main_cannon.gd
│   │   ├── sidearms/
│   │   │   ├── sidearm_base.gd
│   │   │   └── rapid_fire/
│   │   │       ├── rapid_fire.tscn
│   │   │       └── rapid_fire.gd
│   │   └── abilities/          # Slice: placeholder or one simple ability
│   ├── combat/                 # Enemies, projectiles (slice: minimal)
│   │   └── ...
│   ├── milestone/
│   │   ├── milestone_tracker.tscn
│   │   └── milestone_tracker.gd
│   ├── rewards/
│   │   └── reward_handler.gd   # Ball rewards + stat upgrades
│   └── ui/
│       ├── debug_overlay.tscn
│       └── debug_overlay.gd
└── tests/                      # Unit tests call into simulation/ pure code
    ├── test_energy_routing.gd
    ├── test_hit_cooldown.gd
    └── test_reward_generation.gd
```

---

## 3. Main Scene Tree (Conceptual)

```
Main (Node2D or Control)
├── GameCoordinator      # Wiring only; no peg buffering (Board does that)
├── EnergyManager        # Receives energy_allocated, feeds MainCannon + SidearmPool
├── CombatManager        # Owns wall HP, waves, time-since-wave; receives main_fired(damage), sidearm_fired(damage)
├── RewardsManager       # Receives milestone_reached, calls RewardHandler + Hopper
├── Hopper
│   └── (visual representation of ball count / door)
├── Conduit
│   └── Door (timing stack; drive by sim-tick counter, not float timer)
├── Board
│   └── Peg (many; VFX/audio local, no upstream energy signals)
├── BallsContainer (Node2D)
│   └── Ball (CharacterBody2D or kinematic; ball-ball collision disabled)
├── EnergyRouter (Node under Main; energy×100 internal units, §1.7; move to Autoload only if replays/sim export)
├── SystemsContainer
│   ├── MainCannon
│   └── Sidearms
│       └── RapidFire    # Cooldown in sim_ticks_remaining
├── CombatContainer
│   └── (enemies, projectiles)
├── MilestoneTracker
├── RewardHandler
└── UI
    ├── DebugOverlay    # Rolling stats: compute once per second, cache
    └── (HUD, rewards panel, etc.)
```

**Rule**: **GameCoordinator** (child of Main) connects signals and calls into **domain managers** and child systems. **Board** is the **only** authority that buffers, sorts, and resolves **peg-hit** events; GameCoordinator does **not** sort peg hits. **EnergyRouter** is a **Node** under Main for the slice (no Autoload). Children do not hold references to Main or GameCoordinator; they only emit signals and expose small public methods.

**Per-sim-tick order (strict; run in this order every sim step)**  
GameCoordinator (or the single place that runs sim steps) must execute in this order each sim tick, or results will depend on signal timing and you get “cannon fires before unit spawns” bugs:
1. Conduit: maybe release ball(s) (respect MAX_ACTIVE_BALLS).
2. Balls step: Board (or BallSystem) calls `ball.step_one_sim_tick()` for each active ball; collisions/hits resolved from move_and_collide.
3. Board: resolve bottom, emit per-ball energy (`ball_reached_bottom`).
4. EnergyManager: route energy, fill pools.
5. Systems: MainCannon / sidearms attempt fire (possibly multiple times if overflow).
6. CombatManager: apply damage, advance waves.
7. Check victory/defeat (and RunFlow transitions, e.g. milestone → REWARD_SLOWMO).

---

## 4. Signal Contract (Signaling Up)

Children **emit** these; GameCoordinator or domain managers **connect** and react. To avoid event storms (50+ balls × many peg hits), **do not** emit per-hit signals for gameplay; Board accumulates per ball and emits once per ball when it reaches the bottom.

| Signal | Emitter | Args | Meaning |
|--------|---------|------|--------|
| `ball_entered_board` | Conduit | ball: Ball | One ball entered the board; Board spawns and tracks it. |
| `ball_exited_board` | Board | ball: Ball, reason: Enum (bottom \| stall_despawn) | Ball left play. Only `bottom` grants energy; stall despawn returns to hopper, no energy. |
| `ball_reached_bottom` | Board | ball_id: int, total_energy_display: int, alignment: Enum | **Only** energy event from Board. Total in **display** units (20 + 10×peg_hits). EnergyManager multiplies by 100 for routing; MilestoneTracker uses display as-is (§1.7 milestone units). |
| `energy_allocated` | EnergyRouter | main: int, sidearm: int, shield: int | Split in **internal units (×100)**; pools store and compare in same units (§1.7). |
| `main_energy_changed` | MainCannon | current: int | Cannon’s pool (internal units); UI divides by 100 for display. |
| `main_fired` | MainCannon | damage: int (or CombatDamageEvent) | Cannon shot; CombatManager applies damage (owns wall HP, waves). See §6.11 damage contract. |
| `sidearm_energy_changed` | EnergyPool (or Sidearm) | current: int | Shared sidearm pool updated. |
| `sidearm_fired` | Sidearm (e.g. RapidFire) | damage: int (or CombatDamageEvent) | Sidearm shot; CombatManager applies damage. |
| `ability_charged` | Ability | ability_id: StringName | Ability ready to auto-fire (slice: optional). |
| `milestone_reached` | MilestoneTracker | milestone_index: int, total_energy_display: int | XP-style milestone hit; never decreases; total in display units. |
| `door_opened` / `door_closed` | Conduit | — | For stacking door timing (drive by sim-tick counter). |

**Peg**: No upstream **energy** signals. Peg handles hit VFX/audio locally. For future local effects (e.g. bomb peg), Peg can **call** Board with a compact event (e.g. `Board.explode_at(peg_id)`); Board applies durability/area effects and increments affected balls’ peg-hit counts internally. Energy routing still receives only `ball_reached_bottom`. **Hit detection**: **Board** is authoritative (§1.9): **move_and_collide()** collision is the primary hit candidate; spatial hash + segment–circle is fallback only. GameCoordinator does **not** buffer or sort peg events—Board only.

**Optional**: A **throttled** “stats” signal (e.g. once per second) for debug overlay only. EventBus optional for UI/debug.

---

## 5. Call-Down Contract (Parent Commands Children)

Parents (or GameState) call these methods on children. Keep signatures minimal.

| Callee | Method | Caller | Purpose |
|--------|--------|--------|---------|
| Hopper | `add_balls(count: int)` | RewardsManager, wave start | Put balls into hopper (FIFO). |
| Hopper | `release_next_ball() -> Ball \| null` | Conduit | Take one ball from front; null if empty. |
| Conduit | `request_ball()` | Self (sim-tick timer) | Door/wave in **sim ticks**; convert from config seconds once via round(seconds × SIM_TICKS_PER_SECOND) (§1.13). Stops releasing if active balls ≥ MAX_ACTIVE_BALLS. |
| Board | `spawn_ball_at_start(ball: Ball)` | GameCoordinator (on `ball_entered_board`) | Place ball at top of board. |
| Board | `get_peg_by_id(id: StringName) -> Peg` | Board internal (hit resolution) | Resolve peg for durability only. |
| Peg | `apply_hit() -> void` | Board (after sort in _flush_tick) | Updates durability/vibrancy only; Board adds +10 per hit to ball’s running total. |
| EnergyRouter | `route_energy(internal_energy: int, alignment: Enum)` | EnergyManager (on `ball_reached_bottom`) | EnergyManager passes display×100; pure function; emit `energy_allocated` in internal units. |
| MainCannon | `add_energy(amount: int)` | EnergyManager (on `energy_allocated`) | Feed main share. |
| Ball | `step_one_sim_tick()` | Board or BallSystem (once per sim tick) | Single integration step; move_and_collide; no movement in Ball’s own _physics_process. |
| MainCannon | `try_fire() -> bool` | Self (sim-tick) | If enough energy, consume and emit `main_fired`. |
| EnergyPool (sidearm) | `add_energy(amount: int)` | EnergyManager (on `energy_allocated`) | Feed shared sidearm pool. |
| RapidFire | `try_fire() -> bool` | Self (sim_ticks_remaining cooldown) | Consume from pool; emit `sidearm_fired`. |
| MilestoneTracker | `add_display_energy(amount: int)` | GameCoordinator (on `ball_reached_bottom`) | Accumulate in **display**; enqueue milestone indices when crossing thresholds (§6.9); emit `milestone_reached` from queue. |
| RewardHandler | `grant_ball_rewards(count: int)` | RewardsManager (on `milestone_reached`) | Call simulation/reward_generation only (no RNG in node); present 3 picks (slice). |
| RewardHandler | `grant_stat_upgrades(count: int)` | RewardsManager | Present 2 stat upgrades. |
| DebugOverlay | `set_energy(main, sidearm, shield)` / `set_stats_cached(...)` | EnergyManager / throttled (1 Hz) | Update from **cached** values only; never iterate balls. |

---

## 6. Module Breakdown (Small Functions & Responsibilities)

### 6.1 Hopper (Ball Identity Owner)

- **Single responsibility**: Hold ordered list of balls (FIFO); **own ball identity**; expose add/remove. **Ball ID**: Hopper issues and owns `ball_id`. It stores **BallInstance** (or a lightweight struct: ball_id, definition, alignment). When Conduit calls `release_next_ball()`, the returned ball **already has a stable ball_id**; that id is **immutable for the ball’s lifetime**. A ball that is removed and returned to the queue (e.g. stall despawn, or later: elf shock / black hole) is **recycled**—when it re-enters the board, it **keeps the same ball_id**. This keeps ordering and debugging deterministic; future “ball removed and returned” mechanics map to: Board/Conduit return ball to Hopper, Hopper re-queues same instance (same id).
- **Signals**: `ball_requested(count)` (optional).
- **Methods**: `add_balls(count)`, `release_next_ball() -> Ball | null` (ball has stable ball_id), `get_visible_count() -> int` (cap at 100 for display).
- **Small functions**: `_add_single_ball(ball_def: BallDefinition)`, `_remove_from_front() -> Ball | null`, `_next_ball_id() -> int` (or assign id when creating BallInstance).

### 6.2 Conduit & Door

- **Single responsibility**: Control when the hopper gate is open or closed. **Spec** (§1.13): Every **WAVE_INTERVAL_TICKS**, Conduit opens for **OPEN_TICKS**; while open, balls fall out by physics (hopper size, gate open time, fall speed)—no fixed ball count. Gate closes when open duration expires. **Safety**: If active ball count ≥ **MAX_ACTIVE_BALLS** (e.g. 120), do not open / release until count drops.
- **Signals**: `door_opened`, `door_closed`.
- **Methods**: `request_ball()` (only if active balls < MAX_ACTIVE_BALLS; drives gate open/close timing). **Timing**: all in **sim ticks**; convert from seconds once with **round(seconds × SIM_TICKS_PER_SECOND)** (§1.13).
- **Small functions**: `_open_door()`, `_close_door()`, `_on_sim_tick()` (decrement ticks; open when wave timer hits 0); `_can_release() -> bool` (active count < MAX_ACTIVE_BALLS).

### 6.3 Board

- **Single responsibility**: Layout of pegs, spawn position, bottom zone; **single authority** for per-ball energy (20 base + 10 per peg hit) and **for hit detection** (§1.9). **Hit source**: move_and_collide() collision is **authoritative**; when Board (or BallSystem) runs ball.step_one_sim_tick(), collisions returned from move_and_collide become hit candidates. Spatial hash + segment–circle is **fallback only** when there is no collision. Board buffers candidates, applies **hit registration rules** (§1.6: per-ball-per-peg cooldown in **sim ticks**), sorts (ball_id asc, peg_id asc; peg_id = integer index 0..N-1), resolves, then emits **one** `ball_reached_bottom` per ball. **Flush timing**: Board flushes **once per sim tick at end-of-sim-step**—never mid-step. GameCoordinator does **not** buffer or sort peg events.
- **Ball stepping**: Board (or a **BallSystem** node) calls **`ball.step_one_sim_tick()`** for each active ball **exactly once per sim tick**; that is the only place ball motion runs. Balls do not move in their own _physics_process.
- **CellEffects (future-proofing)**: Board maintains a lightweight **CellEffects** map. Peg/board write; ball step reads (e.g. for deflection). **Stall despawn**: §1.12—track distance moved per sim tick; if `distance < STALL_PIXELS_EPS` for `STALL_SIM_TICKS`, emit `ball_exited_board(ball, stall_despawn)` and do not grant base energy.
- **Signals**: `ball_reached_bottom(ball_id, total_energy_display, alignment)`, `ball_exited_board(ball, reason)`.
- **Methods**: `spawn_ball_at_start(ball)`, `get_peg_by_id(id)` (id = integer index), `explode_at(peg_id)` (future). **Stall**: as above.
- **Small functions**: `_run_ball_steps()` (call step_one_sim_tick on each ball; collect move_and_collide hits), `_fallback_hits_from_swept(ball)` (optional), `_buffer_hit(ball_id, peg_id)`, `_buffer_bottom(ball_id)`, `_flush_tick()` (end-of-sim-step: sort, cooldown filter, resolve, accumulate energy, emit). Use **simulation/hit_cooldown.gd** (pure). Hit resolution order (durability vs. recovery) defined here.

### 6.4 Peg

- **Single responsibility**: Durability, recovery, vibrancy feedback. **Does not** dictate energy math—Board adds +10 per hit. Peg only reports “was hit” and updates state. For **future local effects** (e.g. bomb peg): Peg handles the effect locally and calls **Board** with a compact event (e.g. `Board.explode_at(peg_id)`); Board applies durability/area logic and increments ball peg-hit counts; energy routing still sees only `ball_reached_bottom`.
- **Signals**: None for gameplay. Peg handles VFX/audio **locally** when hit (no upstream signal).
- **Methods**: `apply_hit() -> void` (Board calls after sort; Peg updates durability, starts recovery if needed, updates vibrancy). Board always adds +10 to the ball’s running total when it calls this (slice: no “broken = 0” if out of scope).
- **Small functions**: `_subtract_durability(amount)`, `_start_recovery_timer()` (sim-tick based), `_update_vibrancy()`.

### 6.5 Ball

- **Single responsibility**: Visual/kinematic representation (§1.5: kinematic + manual bounce); carry tier, alignment, and running energy total. **ball_id** from Hopper, stable for lifetime. **Motion**: Ball does **not** use `_physics_process` for gameplay movement. **Board (or BallSystem)** calls **`step_one_sim_tick()`** exactly **once per sim tick**; that is the only place ball motion runs (one integration step: gravity, move_and_collide, reflection). This keeps determinism and slow-mo correct. Collision from move_and_collide is the **authoritative** hit candidate (§1.9). **Physics constants**: §1.8 (gravity, restitution, MAX_BALL_SPEED clamp). Disable ball–ball collision (layer/mask). Optionally read Board’s **CellEffects** in step_one_sim_tick for future effects.
- **Methods**: `step_one_sim_tick()` (returns or reports collision with peg if any), `add_peg_energy(amount)`, `get_total_energy() -> int`, `get_definition() -> BallDefinition`, `get_ball_id() -> int`, `get_position()`, `get_velocity()`, `get_radius()`.
- **Small functions**: `_integrate_one_tick()` (apply gravity, move_and_collide, reflect; clamp MAX_BALL_SPEED; return collision data), `_update_display()`.

### 6.6 Energy Router

- **Single responsibility**: Given raw integer energy and alignment, compute main/sidearm/shield split (GDD: 70/15/15, 80/20, etc.); emit result. **Remainder**: **only** supported method is **internal unit = energy × 100** (§1.7). All splits use hundredths; no stateful remainder accumulator; routing is a pure function. Do not implement or document any alternative remainder strategy.
- **Signals**: `energy_allocated(main, sidearm, shield)` — all in **internal units (×100)**. Pools and thresholds store internal only; **only UI** divides by 100 for display.
- **Methods**: `route_energy(internal_energy: int, alignment: Enum)` — caller (EnergyManager) passes display×100; split and emit in internal units.
- **Small functions**: `_split_main_aligned(internal: int) -> Vector3i`, `_split_sidearm_aligned(internal: int) -> Vector3i`, `_split_defense_aligned(internal: int) -> Vector3i`; all use internal only.

### 6.7 Main Cannon

- **Single responsibility**: Accumulate main energy; auto-fire when threshold met; linear scaling (from config). Emit **damage** with fire so CombatManager can apply it.
- **Signals**: `main_energy_changed(current)`, `main_fired(damage: int)`.
- **Methods**: `add_energy(amount)`, `try_fire() -> bool` (emits with damage from config or scaling).
- **Small functions**: `_consume_energy_for_shot() -> int`, `_get_damage_for_shot() -> int`, `_emit_shot()`.

### 6.8 Sidearm Pool & Rapid Fire

- **Single responsibility (pool)**: Shared sidearm energy; deduct on fire.
- **Single responsibility (Rapid Fire)**: Cooldown-based fire; deduct from pool; emit `sidearm_fired`. **Determinism**: cooldown = **sim_ticks_remaining** (int), decremented **once per sim tick**; no float timer.
- **Signals**: `sidearm_energy_changed(current)`, `sidearm_fired(damage: int)`.
- **Methods**: Pool: `add_energy(amount)`, `consume(amount) -> bool`. RapidFire: `try_fire() -> bool` (checks sim_ticks_remaining == 0 and pool; emits damage).
- **Small functions**: `_can_afford(amount) -> bool`, `_decrement_cooldown_ticks()` (once per sim tick).

### 6.9 Milestone Tracker

- **Single responsibility**: Accumulate total energy in **display units** (never decrease). When total crosses one or more thresholds, **enqueue** those milestone indices; do not emit multiple signals at once. **Multi-threshold rule**: MilestoneTracker enqueues **all** milestone indices for which total ≥ threshold (e.g. one ball crosses 200 and 400 → enqueue [0, 1]). **RewardsManager drains the queue one at a time**: slow-mo → pause → show pick → resume → next queued milestone. This prevents overlapping reward UIs or dropped rewards.
- **Units**: display only (§1.7); thresholds in MilestoneDefinition (e.g. 200, 400, 600; GDD §12 ~3 per wall).
- **Signals**: `milestone_reached(milestone_index, total_energy_display)` — emitted **one at a time** when RewardsManager (or owner) drains the queue.
- **Methods**: `add_display_energy(amount: int)`, `get_pending_milestones() -> Array` (or `pop_next_milestone() -> int | null`) so RewardsManager can drain.
- **Small functions**: `_check_thresholds()` (enqueue new indices), `_get_next_threshold() -> int`.

### 6.10 Reward Handler

- **Single responsibility**: Grant 3 ball choices + 2 stat upgrades on milestone; call `Hopper.add_balls()` and stat application. **RNG**: only **simulation/reward_generation.gd** may shuffle and pick; RewardHandler **calls into** it. Nodes never call rand* (§1.11). **Duplicate prevention**: build candidate list from tier weights, shuffle (via simulation), take first N unique.
- **Methods**: `grant_ball_rewards(count)`, `grant_stat_upgrades(count)` (UI calls back with selection; both use simulation layer for RNG).
- **Small functions**: `_apply_ball_to_hopper(ball_def)`, `_apply_stat_upgrade(upgrade)`; candidate building and shuffle live in **simulation/reward_generation.gd**.

### 6.11 CombatManager (Authoritative State + Target Selection + Damage Contract)

CombatManager is **not** a passive visual listener. It **owns**:

- **Wall HP** (or equivalent defensive target).
- **Unit waves** (current wave index, spawn state).
- **Time-since-wave counters** (simulation-step based).
- **List of targets** and **target selection**: CombatManager owns the “list of targets” and provides **`get_target_for(sidearm_id: StringName)`** (or an iterator). Sidearms are **dumb**: they emit “I fired, here is damage + type”; **CombatManager decides what it hit** and applies damage to that target.

**Slice rule (locked)**: RapidFire always hits **frontmost unit** if any, else hits **wall**. Define “frontmost” once (e.g. first in list, or closest to wall). Other sidearms later get their own targeting rule via `get_target_for(sidearm_id)`.

**Damage routing contract (direction for slice and later)**: Define an internal struct **CombatDamageEvent(source_id: StringName, amount: int, damage_type: StringName, tags: Array)**. MainCannon and sidearms can emit this (e.g. `damage_event(damage_event: CombatDamageEvent)`); CombatManager receives it and routes to the target from `get_target_for(source_id)`. For the slice you can keep `main_fired(damage: int)` and `sidearm_fired(damage: int)` and have CombatManager treat them as a single-amount event; document that the **direction** is one unified damage event so you don’t refactor later when adding types/tags.

---

## 7. Resources (Data-Only)

- **BallDefinition**: `tier: int`, `base_energy: int` (20), `city_weights: Dictionary` (city_id → weight), `scene: PackedScene` (optional).
- **PegConfig**: `durability: int`, `recovery_sim_ticks: int` (for determinism), `vibrancy_scale: float` (for feedback).
- **BoardArchetype**: `archetype: Enum (Balanced/Tech/Magic)`, `peg_layout: Array` or `PackedScene`.
- **MainCannonConfig**: `energy_per_shot: int`, `fire_threshold: int` — **both in internal units (×100)**. Optional `status_effects_on_fire: Dictionary` (default `{}`); upgrades can set so cannon applies status when it fires.
- **SidearmConfig**: `energy_per_shot: int`, `cooldown_sim_ticks: int`, `archetype_id: StringName`; optional `status_effects_on_fire: Dictionary` (default `{}`). Energy in internal units (e.g. threshold 200 display → 20,000 internal).
- **MilestoneDefinition**: `threshold: int` in **display** units (e.g. 200, 400, 600; GDD §12 ~3 per wall), `ball_reward_count: int`, `stat_upgrade_count: int` (slice: 3 and 2).

Pools and **cannon/sidearm** thresholds store **internal units (×100)**; **milestone** thresholds and MilestoneTracker total store **display** (§1.7). Only UI divides by 100 for display. Conduit/wave timing: store designer seconds in config; convert to **sim ticks** once with round(seconds × SIM_TICKS_PER_SECOND) (§1.13). **MAX_ACTIVE_BALLS** (§1.12): Conduit stops releasing when active count ≥ cap (e.g. 120). **Version control**: key tunables can live in **JSON or .cfg** for cleaner diffs; keep .tres minimal or enforce consistent property order.

---

## 8. Slice vs. Future Scope

| In slice | Later |
|----------|--------|
| Balanced board, City 1 | Tech/Magic boards, City 2 & 3 |
| Tier 1 & 2 balls | Tier 3, city-weighted rarity |
| Rapid Fire sidearm only | 6–8 sidearms, 6–10 abilities |
| Core milestone (3 balls + 2 stats) | Boss rule-breaking synergies |
| Debug overlay | Status system, Ascension, full art/sound |

The architecture above is designed so that:

- New sidearms = new scenes that conform to `SidearmBase` (same signals/methods).
- New cities = new `CityDefinition` + wave/board data; same Hopper/Board/Energy flow.
- Status system = new nodes/resources and signals (e.g. `status_applied`, `status_tick`) without changing core loop nodes.

**Status effects (GDD)**: Cannon and sidearms do **not** apply status by default. Status comes from **balls** (e.g. ball abilities on peg hit or ball_reached_bottom) or from **upgrades/special sidearms**. MainCannonConfig and SidearmConfig have optional `status_effects_on_fire: Dictionary` (default `{}`); upgrades can set these (e.g. `{ "fire": 1 }`) so that when that weapon fires, the same damage call carries status. BattlefieldView exposes `apply_status_to_frontmost_minion(status_effects)` and `apply_status_to_minions_in_radius(center, radius, status_effects)` for ball abilities or other systems to apply status without dealing damage.

### 8.1 Performance & Caps

- **Active balls**: 100–200 balls in the **bag** (hopper) is fine; 100–200 **active** on the board can tank performance. **MAX_ACTIVE_BALLS** (e.g. 120) is a deterministic safety valve: Conduit stops releasing when exceeded (§1.12, §6.2). **Soft valves**: stall despawn (no energy), peg HP fall-through lanes; disable ball–ball collision (physics layers).
- **Debug overlay**: Do not recompute rolling averages or stats every real frame; **never iterate over all balls** in the overlay. Update **once per second** (or on a throttled tick); managers (EnergyManager, GameCoordinator, etc.) maintain cached counts (e.g. active balls, energy totals). Debug overlay **consumes only these cached values**; it does not query Board, Hopper, or BallsContainer for live counts.

---

## 9. Summary Diagram

```
                    ┌─────────────────┐
                    │       Main      │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │ GameCoordinator │  (wiring only; no peg buffering/sort)
                    └────────┬────────┘
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
   EnergyManager      CombatManager      RewardsManager
         │                   ▲                   ▲
   ┌─────┴─────┐             │                   │
   │ Hopper → Conduit → Board (move_and_collide hits + end-of-sim-step flush)
   └─────┬─────┘             │                   │
         │            ┌──────┴──────┐     ┌──────┴──────┐
         │            │ EnergyRouter │     │ Milestone   │
         │            └──────┬──────┘     └─────────────┘
         │                   │ energy_allocated
         │            MainCannon  SidearmPool → RapidFire
         └──────────────────────────────────────────────────
```

**Signals** flow upward to GameCoordinator or managers. **Calls** flow downward. **Sim clock**: SIM_TICKS_PER_SECOND; all gameplay in **sim ticks**, not “physics frame.” **Board** flushes once per **sim tick** (end-of-sim-step). **Ball motion**: Board/BallSystem calls `ball.step_one_sim_tick()` once per sim tick only. **Hit source**: move_and_collide authoritative (§1.9). **Display vs internal**: §1.7; invariant test 50 display → 5000 internal → 3500/750/750. **Milestones**: enqueue indices; RewardsManager drains one at a time (§6.9). **RunFlow**: FIGHTING / REWARD_SLOWMO / REWARD_PAUSED (§1.10). **MAX_ACTIVE_BALLS** and conduit spec §1.13, §6.2. **No RNG in nodes** (§1.11).

Use this document as the single source of truth for scene layout, signal names, and public method contracts when implementing the vertical slice in Godot.

---

## Appendix A: Evaluation vs Current Godot Best Practices

This section evaluates the architecture against Godot 4.x official and community best practices (scene organization, signals, autoloads, node types, dependency injection). References: [Godot 4.6 (stable) documentation](https://docs.godotengine.org/en/stable/) — [Scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html), [Autoloads vs internal nodes](https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_internal_nodes.html), [Signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html).

### What aligns well

| Practice | How this doc matches |
|--------|-----------------------|
| **Call down, signal up** | §1.2 and the whole design: children emit signals (respond to behavior); parents/coordinator call methods on children (start behavior). Matches Godot’s recommended “connect to signal to respond, call method to start.” |
| **Loose coupling / dependency injection** | Children do not hold references to Main or GameCoordinator; they receive commands via call-down and report via signals. “Avoid get_node() across unrelated branches” (§1.2) matches “nodes should not rely on their external environment” and parent-mediated injection. |
| **Scenes self-contained** | Each system (Hopper, Conduit, Board, Ball, Peg, etc.) is a scene with a single responsibility; config comes from Resources or injectable refs, not hardcoded paths. |
| **Signals for past-tense events** | Signal names are event-like: `ball_entered_board`, `ball_reached_bottom`, `main_fired`, `milestone_reached`—consistent with “respond to behavior” and past-tense naming. |
| **Autoloads only for broad scope** | GameState (run seed, sim_speed, pause) is autoload; EnergyRouter is **not** autoload for the slice and lives under Main. Aligns with “use autoload when managing own info / broad-scoped; prefer keeping logic in the scene when possible.” |
| **Resources for data** | Configs and definitions are Resources (§7); no gameplay data buried in scripts. Matches “use Resource to share data” and keeps scenes reusable. |
| **CharacterBody2D for deterministic control** | §1.5 and §1.4: balls use CharacterBody2D + move_and_collide for kinematic, deterministic motion instead of RigidBody2D. Aligns with “CharacterBody2D for kinematic control” and custom collision response. |
| **Main as entry point** | Main is the root; GameCoordinator (child of Main) is the “primary controller” that wires and drives sim steps. Matches “game should have an entry point (Main)” and “main.gd as primary controller.” |
| **Subsystems in their own section of the tree** | Hopper, Board, Conduit, Systems, Combat, UI are distinct branches; “use parent-child only when children are effectively elements of the parent.” The tree reflects that. |

### Gaps or tensions

| Area | Current doc | Godot practice | Recommendation |
|------|-------------|----------------|-----------------|
| **Signal disconnect** | §1.2 now includes the rule. | Disconnect in `_exit_tree()` to avoid leaks and stray calls when nodes are removed. | **Done**: Signal lifecycle rule in §1.2; coordinator/managers disconnect in `_exit_tree()` (or when child is removed). See [Signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html). |
| **EventBus / signal bubbling** | EventBus is optional for UI/debug. | Avoid re-emitting child signals up many layers; use direct connections or one bus. | Keeping EventBus optional and “direct connections during setup” (GameCoordinator connects to children) is fine. If you add EventBus, document that it does **not** re-emit from every child (e.g. one “energy_changed” from EnergyManager, not every node). |
| **Groups** | Not used. | Use groups to act on sets of nodes (e.g. “balls”, “pegs”) instead of manual lists. | Consider adding: put active balls in a group (e.g. `active_balls`) and pegs in `board_pegs` so Board/Conduit can iterate with `get_tree().get_nodes_in_group()` if that simplifies code. Not required for determinism (your sim tick order is explicit). |
| **Callable injection** | Only “call down” (methods) and signals. | Godot also recommends Callable properties for “start behavior” to keep child agnostic of who provides the behavior. | Your design is already clear (parent calls child methods). Callables are an alternative if you want children to invoke “notify” or “command” without a direct parent reference; optional. |
| **Tool scripts / configuration warnings** | Not mentioned. | Use `_get_configuration_warnings()` in tool scripts when a node has external dependencies so the editor shows a warning if misconfigured. | For nodes that expect to be wired by GameCoordinator (e.g. Board, Conduit), adding a tool script that returns a warning if required refs/signals are unset can help; document in §6 for those modules. |
| **Physics process vs custom loop** | §6.5 now states explicitly. | Normal Godot code uses `_physics_process(delta)` for physics ([Idle and Physics Processing](https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html)). | **Done**: §6.5 states Ball does not use `_physics_process` for gameplay movement; motion runs only in `step_one_sim_tick()`. |

### Summary

- The architecture is **strongly aligned** with Godot’s scene organization, call-down/signal-up, loose coupling, Resources for data, and restrained use of autoloads. It also follows community guidance on signal naming and avoiding global state except where needed (GameState).
- **Implemented**: (1) **Signal lifecycle** — §1.2 requires disconnecting in `_exit_tree()` where coordinator/managers connect to child signals. (2) **Ball movement** — §6.5 explicitly states Ball does not use `_physics_process` for gameplay movement; only `step_one_sim_tick()` runs motion. **Optional later**: **Groups** for "all balls" / "all pegs" ([Groups](https://docs.godotengine.org/en/stable/tutorials/scripting/groups.html)); **tool scripts** with `_get_configuration_warnings()` ([Reporting node configuration warnings](https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html#reporting-node-configuration-warnings)).

- No change to core contracts (signals, call-down, sim ticks, energy units, hit detection).
