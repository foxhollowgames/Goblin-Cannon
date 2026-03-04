extends Node
## Constants autoload (§1.8). Physics and sim constants; all gameplay uses these.

const SIM_TICKS_PER_SECOND: int = 60
const MAX_ACTIVE_BALLS: int = 120
const HIT_COOLDOWN_SIM_TICKS: int = 3
# Physics (slice defaults; apply per step_one_sim_tick)
# Tuned so ball is visible and bounces between pegs without motion-blur afterimages
const GRAVITY: float = 12.0  # pixels per sim tick² (gentler fall)
const BALL_RADIUS: float = 8.0
const PEG_RADIUS: float = 12.0
const PEG_DEPENETRATE_MARGIN: float = 2.0  # minimal extra gap so depenetration doesn't look like a bounce
const RESTITUTION: float = 0.82
const TANGENTIAL_FRICTION: float = 0.35
const LINEAR_DRAG: float = 0.01
const MAX_BALL_SPEED: float = 220.0  # pixels/sec (~3.7 px/tick at 60Hz so one clear ball, no streak)

# Stall despawn (§1.12)
const STALL_PIXELS_EPS: float = 2.0
const STALL_SIM_TICKS: int = SIM_TICKS_PER_SECOND * 10  # 10 seconds

# Energy: internal = display × 100 (§1.7)
const ENERGY_SCALE: int = 100

# Conduit (§1.13): wave interval and gate open duration in seconds. How many balls fall is physics-driven (hopper size, open duration, fall speed).
const WAVE_INTERVAL_SECONDS: float = 5.0
const OPEN_SECONDS: float = 0.5

# Ball alignments (GDD §8): 0=Main, 1=Sidearm, 2=Defense. Must match EnergyRouting.Alignment.
const ALIGNMENT_MAIN: int = 0
const ALIGNMENT_SIDEARM: int = 1
const ALIGNMENT_DEFENSE: int = 2

# Rarity tiers (GDD §7 city-weighted): 0=Common .. 5=Epic (White, Green, Blue, Purple, Orange, Red).
const RARITY_COMMON: int = 0
const RARITY_UNCOMMON: int = 1
const RARITY_RARE: int = 2
const RARITY_EPIC: int = 5

# GDD §7: Max rarity index allowed per city (city-weighted rarity scale). Only balls with rarity <= this can appear.
# City 0 = Halfling Shire: Common + Uncommon only. City 1 = Kingdom: through Rare/Purple. City 2 = Elf Palace: all.
const MAX_RARITY_BY_CITY: Array = [1, 3, 5]  # [City 1 max, City 2 max, City 3 max]

# GDD §11: City definitions by index (0 = Halfling Shire, 1 = Human Kingdom, 2 = Elf Palace). Slice: City 1 only.
const CITY_DEFINITION_PATHS: Array[String] = [
	"res://resources/cities/halfling_shire.tres",
	"res://resources/cities/human_kingdom.tres",
	"res://resources/cities/elf_palace.tres"
]

# Status effect IDs (§8 status system). Used for stacking and visuals (fire, frozen, lightning, etc.).
const STATUS_FIRE: StringName = &"fire"
const STATUS_FROZEN: StringName = &"frozen"
const STATUS_LIGHTNING: StringName = &"lightning"

# GDD: Explosive ball — hit pegs in radius; Chain Lightning — chain to N nearest pegs (apply hit + lightning status).
const EXPLOSIVE_RADIUS_PX: float = 90.0
const CHAIN_LIGHTNING_COUNT: int = 2

# Leech ball: status on pegs hit — drains energy each second, then expires.
const LEECH_DRAIN_PER_SECOND: int = 5   # display energy per second per leeched peg
const LEECH_DURATION_SEC: int = 10      # status lasts 10 seconds (10 drains of 5)

# Rubbery ball: higher restitution so it bounces more and can hit more pegs.
const RUBBERY_RESTITUTION: float = 0.94

# Trampoline peg: higher restitution and strong upward launch on contact (upward = negative Y).
const TRAMPOLINE_RESTITUTION: float = 0.98
const TRAMPOLINE_UPWARD_SPEED: float = 340.0  ## px/s; ball is launched upward with at least this speed on trampoline contact
const TRAMPOLINE_TOP_COLLISION_HEIGHT: float = 5.0  ## thickness of top-only collision strip (one-way platform)

# Debug: test run with 50% trampoline pegs and all sidearms (Rapid Fire, Sniper, AOE Cannon). Set false for normal play.
const DEBUG_TEST_RUN_50_TRAMPOLINE_ALL_SIDEARMS: bool = false
# Default board has 8 rows × 16 cols checkerboard = 64 pegs; 50% = 32 trampolines.
const TEST_RUN_TRAMPOLINE_PEG_COUNT: int = 32
# Debug: test run with all pegs as bombs (every hit triggers an explosion). Set false for normal play.
const DEBUG_TEST_RUN_ALL_BOMB_PEGS: bool = true
