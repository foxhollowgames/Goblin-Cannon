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
const RESTITUTION: float = 0.6
const TANGENTIAL_FRICTION: float = 0.1
const LINEAR_DRAG: float = 0.01
const MAX_BALL_SPEED: float = 220.0  # pixels/sec (~3.7 px/tick at 60Hz so one clear ball, no streak)

# Stall despawn (§1.12)
const STALL_PIXELS_EPS: float = 2.0
const STALL_SIM_TICKS: int = SIM_TICKS_PER_SECOND * 10  # 10 seconds

# Energy: internal = display × 100 (§1.7)
const ENERGY_SCALE: int = 100

# Conduit (§1.13): convert seconds to ticks with round(seconds * SIM_TICKS_PER_SECOND)
# Default slice: e.g. wave every 5s, open 2s, 3 balls per wave
const WAVE_INTERVAL_SECONDS: float = 5.0
const OPEN_SECONDS: float = 2.0
const CONDUIT_SIZE: int = 3
