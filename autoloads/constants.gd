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

# Conduit (§1.13): convert seconds to ticks with round(seconds * SIM_TICKS_PER_SECOND)
# Default slice: e.g. wave every 5s, open 1s, 3 balls per wave
const WAVE_INTERVAL_SECONDS: float = 5.0
const OPEN_SECONDS: float = 0.5
const CONDUIT_SIZE: int = 3

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
