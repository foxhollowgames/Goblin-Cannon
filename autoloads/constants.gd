extends Node
## Constants autoload (§1.8). Physics and sim constants; all gameplay uses these.

const SIM_TICKS_PER_SECOND: int = 60
## Per-wall round length (seconds) by wall index within a city. Wall 0 = 3 min baseline; same 1:3:2 ratio as legacy 60/180/120s tuning.
const WALL_TIME_SECONDS: Array[int] = [180, 540, 360]
const MAX_ACTIVE_BALLS: int = 120
const HIT_COOLDOWN_SIM_TICKS: int = 3
## Binary ball: min sim ticks between splitting the same ball pair on collision (ball–ball).
const BINARY_BALL_PAIR_COOLDOWN_SIM_TICKS: int = 30
## Constellation laser line: same peg cannot retrigger from the laser within this many sim ticks (0.5s at 60 Hz).
const CONSTELLATION_LASER_PEG_RETRIGGER_SIM_TICKS: int = SIM_TICKS_PER_SECOND / 2
## After Goblin Reset releases the ball at the hopper line, ignore that peg until grace ends (hit cooldown alone is far shorter than the grab tween).
const GOBLIN_RESET_POST_RELEASE_GRACE_TICKS: int = SIM_TICKS_PER_SECOND / 2
# Physics (slice defaults; apply per step_one_sim_tick)
# Tuned so ball is visible and bounces between pegs without motion-blur afterimages
const GRAVITY: float = 12.0  # pixels per sim tick² (gentler fall)
const BALL_RADIUS: float = 8.0
const PEG_RADIUS: float = 12.0
## Treasure chest board event: high durability peg before onboard passive reward draft.
const TREASURE_CHEST_BASE_DURABILITY: int = 5
## Human Kingdom sticky slime event: distinct balls that hit the peg wear down the coating; at 0 the peg breaks.
const STICKY_SLIME_RESCUE_HITS: int = 5
## Max stacks per treasure-chest numeric passive (Leech/Phantom/etc.).
const CHEST_PASSIVE_MAX_STACKS: int = 5

## Milestone / chest / buffet / sticky: objectives you clear — no Energize extra durability or Overclock-on-energize.
static func peg_extra_kind_blocks_energize(kind: String) -> bool:
	match kind:
		"milestone_event", "treasure_chest", "buffet_table", "sticky_slime":
			return true
		_:
			return false

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
## Main cannon: display units needed to charge before firing (internal = × ENERGY_SCALE).
const MAIN_CANNON_CHARGE_DISPLAY: int = 100
## Volt Primer wall upgrade: each peg energize reduces next main shot cost by this many display units (stacks; resets on fire).
const MAIN_CANNON_VOLT_PRIMER_DISCOUNT_DISPLAY: int = 5
## Pre-rebalance main cannon charge in display units (tuning reference for scaling legacy values).
const LEGACY_MAIN_CANNON_CHARGE_DISPLAY: int = 800

static func main_cannon_charge_internal() -> int:
	return MAIN_CANNON_CHARGE_DISPLAY * ENERGY_SCALE

static func main_cannon_volt_primer_discount_internal() -> int:
	return MAIN_CANNON_VOLT_PRIMER_DISCOUNT_DISPLAY * ENERGY_SCALE

## Map a legacy display energy amount (from 800-base tuning) to the current 100-base scale.
static func legacy_display_energy_to_current(legacy_display: int) -> int:
	if legacy_display <= 0:
		return 0
	return maxi(1, int(round(float(legacy_display) * float(MAIN_CANNON_CHARGE_DISPLAY) / float(LEGACY_MAIN_CANNON_CHARGE_DISPLAY))))

## Map legacy internal energy (e.g. sidearm costs, charge reduction) to current scale.
static func legacy_internal_energy_to_current(legacy_internal: int) -> int:
	return int(round(float(legacy_internal) * float(MAIN_CANNON_CHARGE_DISPLAY) / float(LEGACY_MAIN_CANNON_CHARGE_DISPLAY)))

# Conduit (§1.13): wave interval and gate open duration in seconds. How many balls fall is physics-driven (hopper size, open duration, fall speed).
const WAVE_INTERVAL_SECONDS: float = 5.0
const OPEN_SECONDS: float = 0.5

# Ball alignments (GDD §8): 0=Main, 1=Sidearm, 2=Defense. Must match EnergyRouting.Alignment.
const ALIGNMENT_MAIN: int = 0
const ALIGNMENT_SIDEARM: int = 1
const ALIGNMENT_DEFENSE: int = 2

# Rarity tiers (GDD §7 city-weighted): 0=Common .. 5=top shop tier (White, Green, Blue, Purple, Orange, Red).
# Pegs use 5 as Epic. Balls use 5 only for Explosive / Chain Lightning (displayed as Legendary).
const RARITY_COMMON: int = 0
const RARITY_UNCOMMON: int = 1
const RARITY_RARE: int = 2
const RARITY_EPIC: int = 5
const RARITY_LEGENDARY: int = RARITY_EPIC

# GDD §7: Max rarity index allowed per city (city-weighted rarity scale). Only balls with rarity <= this can appear.
# City 0 = Halfling Shire: common–rare (epic still gated by milestone weights). City 1 = Kingdom: through purple. City 2 = Elf Palace: all.
const MAX_RARITY_BY_CITY: Array = [2, 3, 5]  # [City 1 max, City 2 max, City 3 max] — RARITY_RARE=2, etc.

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
const LEECH_DRAIN_PER_SECOND: int = 1   # display energy per second per leeched peg (scaled from legacy 5 @ 800 charge)
const LEECH_DURATION_SEC: int = 10      # status lasts 10 seconds (10 drains of 5)

# Rubbery ball: higher restitution so it bounces more and can hit more pegs.
const RUBBERY_RESTITUTION: float = 0.94

# Trampoline peg: higher restitution and strong upward launch on contact (upward = negative Y).
const TRAMPOLINE_RESTITUTION: float = 0.98
const TRAMPOLINE_UPWARD_SPEED: float = 340.0  ## px/s; ball is launched upward with at least this speed on trampoline contact
const TRAMPOLINE_TOP_COLLISION_HEIGHT: float = 5.0  ## thickness of top-only collision strip (one-way platform)

# Goblin Reset peg: grabs the ball and sends it back to the top of the board.
# (No radius constant needed — behavior is ball grab only.)

# Wrench peg: resets nearby recovering pegs to full durability on hit.
const WRENCH_REPAIR_RADIUS_PX: float = 100.0

# Eternal peg: never goes on cooldown; instantly restores when depleted.
# (No tuning constant needed — behavior is in peg.gd.)

# Extreme Bouncer peg: much stronger bounce in all directions.
const EXTREME_BOUNCER_RESTITUTION: float = 1.15
const EXTREME_BOUNCER_SPEED_MULTIPLIER: float = 1.8

# Magnet peg: attracts nearby balls toward it each sim tick (velocity delta, same units as gravity integration).
# Tuned to be clearly visible vs default gravity (~980 px/s²) and typical ball speeds (~MAX_BALL_SPEED).
const MAGNET_PEG_RADIUS_PX: float = 300.0
const MAGNET_PEG_PULL_STRENGTH: float = 14.0

# Splitter peg: splits any ball that hits it into two (once per ball per visit).
const SPLITTER_PEG_SPLIT_ANGLE: float = 0.5

## Volatile ball: buff gas cloud radius, 10s lifetime, peg-hit damage / energy bonuses (display units per cloud stack).
const GAS_CLOUD_RADIUS_PX: float = 95.0
const GAS_CLOUD_DURATION_TICKS: int = SIM_TICKS_PER_SECOND * 10
const GAS_BUFF_DAMAGE_PER_CLOUD_STACK: int = 1
## Per stack; scaled like other peg-hit bonuses (legacy display → current display).
const GAS_BUFF_ENERGY_LEGACY_PER_STACK: int = 8

# Gold peg: multiplied energy on hit.
const GOLD_PEG_ENERGY_MULTIPLIER: int = 3
## Stash run gold (released when peg breaks): 4% for 5 gold, 10% for 1 gold (mutually exclusive tiers).
const STASH_GOLD_CHANCE_FIVE: float = 0.04
const STASH_GOLD_CHANCE_ONE: float = 0.10
## Lucky Gold peg: always 1 or 5 stash gold; five-gold rate is higher than normal stash rolls.
const STASH_GOLD_LUCKY_PEG_FIVE_CHANCE: float = 0.12
## Milestone shop: pay gold to take a card or refresh offers.
const SHOP_REFRESH_COST: int = 5
## Price by ball/stat rarity index (0=common … 5=epic).
const SHOP_PRICE_COMMON: int = 5
const SHOP_PRICE_UNCOMMON: int = 10
const SHOP_PRICE_RARE: int = 15
const SHOP_PRICE_EPIC: int = 20
## Peg shop: always more expensive than a ball at the same tier (ball common 5 → peg common 10).
const SHOP_PEG_PRICE_COMMON: int = 10
const SHOP_PEG_PRICE_UNCOMMON: int = 15
const SHOP_PEG_PRICE_RARE: int = 20
const SHOP_PEG_PRICE_EPIC: int = 25

## Conquest milestone shop: rarity roll weights [common%, uncommon%, rare%, epic%] by progression step.
## Step = city_index * WALLS_PER_CITY + wall_index (0 = first city first wall). Rows sum to 100.
const WALLS_PER_CITY_FOR_MILESTONE: int = 3
const MILESTONE_RARITY_WEIGHTS_BY_STEP: Array = [
	[85, 10, 5, 0],
	[80, 10, 5, 5],
	[70, 20, 8, 2],
	[60, 25, 10, 5],
	[52, 28, 12, 8],
	[45, 30, 15, 10],
	[40, 28, 18, 14],
	[35, 25, 22, 18],
	[30, 22, 25, 23],
]

static func shop_price_for_peg_rarity(rarity: int) -> int:
	match rarity:
		RARITY_COMMON:
			return SHOP_PEG_PRICE_COMMON
		RARITY_UNCOMMON:
			return SHOP_PEG_PRICE_UNCOMMON
		RARITY_RARE:
			return SHOP_PEG_PRICE_RARE
		RARITY_EPIC:
			return SHOP_PEG_PRICE_EPIC
		_:
			return clampi(SHOP_PEG_PRICE_COMMON + rarity * 5, SHOP_PEG_PRICE_COMMON, SHOP_PEG_PRICE_EPIC)

## Rarity weights for milestone shop rolls. Endless uses the last (max) row.
static func milestone_reward_rarity_weights(city_id: int, wall_index: int, endless_mode: bool) -> Array:
	if endless_mode and MILESTONE_RARITY_WEIGHTS_BY_STEP.size() > 0:
		return (MILESTONE_RARITY_WEIGHTS_BY_STEP[MILESTONE_RARITY_WEIGHTS_BY_STEP.size() - 1] as Array).duplicate()
	var step: int = clampi(city_id * WALLS_PER_CITY_FOR_MILESTONE + wall_index, 0, MILESTONE_RARITY_WEIGHTS_BY_STEP.size() - 1)
	return (MILESTONE_RARITY_WEIGHTS_BY_STEP[step] as Array).duplicate()

## Map milestone tier index 0..3 (common→epic) to BallDefinition / shop rarity constants.
static func milestone_tier_to_rarity_constant(tier: int) -> int:
	match clampi(tier, 0, 3):
		0:
			return RARITY_COMMON
		1:
			return RARITY_UNCOMMON
		2:
			return RARITY_RARE
		_:
			return RARITY_EPIC

static func shop_price_for_ball_rarity(rarity: int) -> int:
	match rarity:
		RARITY_COMMON:
			return SHOP_PRICE_COMMON
		RARITY_UNCOMMON:
			return SHOP_PRICE_UNCOMMON
		RARITY_RARE:
			return SHOP_PRICE_RARE
		RARITY_EPIC, RARITY_LEGENDARY:
			return SHOP_PRICE_EPIC
		_:
			return clampi(SHOP_PRICE_COMMON + rarity * 5, SHOP_PRICE_COMMON, SHOP_PRICE_EPIC)


## Human-readable ball rarity (one tier per ability: Plain common; Split/Rubbery/Phantom/Energize/Leech uncommon; Volatile rare; Explosive, Chain Lightning, Constellation, Binary, Bloom legendary).
static func ball_rarity_display_name(ability_name: String, rarity: int) -> String:
	if ability_name == "Explosive" or ability_name == "Chain Lightning" or ability_name == "Constellation" or ability_name == "Binary" or ability_name == "Bloom":
		return "Legendary"
	match rarity:
		RARITY_COMMON:
			return "Common"
		RARITY_UNCOMMON:
			return "Uncommon"
		RARITY_RARE:
			return "Rare"
		RARITY_EPIC, RARITY_LEGENDARY:
			return "Legendary"
		_:
			return "Tier %d" % rarity

## Stat draft options use rarity 0..2 (common/rare in design — map to same tiers).
static func shop_price_for_stat_rarity(rarity: int) -> int:
	match rarity:
		0:
			return SHOP_PRICE_COMMON
		1:
			return SHOP_PRICE_UNCOMMON
		2:
			return SHOP_PRICE_RARE
		_:
			return shop_price_for_ball_rarity(rarity)

# Gravity Well peg: slows balls in its radius.
const GRAVITY_WELL_RADIUS_PX: float = 100.0
const GRAVITY_WELL_DRAG: float = 0.94

## Elf Palace board event: large black hole pulls balls in; consumed balls respawn to hopper after a delay.
const BLACK_HOLE_PULL_RADIUS_PX: float = 260.0
const BLACK_HOLE_CONSUME_RADIUS_PX: float = 38.0
const BLACK_HOLE_PULL_STRENGTH: float = 17.0
const BLACK_HOLE_RESPAWN_DELAY_SEC: float = 5.0

# Phase peg: cycles between solid and ghost every N ticks.
const PHASE_PEG_CYCLE_TICKS: int = 180

## Upgrade-related constants
const ENERGIZE_DECAY_INTERVAL_TICKS: int = 90  ## ~1.5 sec: base interval between energize HP decay ticks
const ADJACENT_PEG_RADIUS_PX: float = 70.0  ## Proximity threshold for adjacency checks (overclock_network, spreading_rot)
const HYPER_ELASTIC_SPEED_MULTIPLIER: float = 1.3  ## Speed boost when Rubbery ball rebounds upward
const STORM_FEEDBACK_DURATION_TICKS: int = 180  ## 3 sec: energy boost after chain hits multiple energized pegs
const MASS_CASCADE_DURATION_TICKS: int = 120  ## 2 sec: bonus energy while two fragments are near each other
const MASS_CASCADE_PROXIMITY_PX: float = 50.0  ## Two fragments must be within this distance

## Debug peg/ball overrides have moved to TestScenario autoload.
## Edit autoloads/test_scenario.gd and set enabled = true.

# -----------------------------------------------------------------------------
# Monsters Also Die — Lospec palette (canonical UI / theme colors)
# https://lospec.com/palette-list/monsters-also-die
# Index order matches the Lospec page listing (top → bottom): 0 .. 11.
# -----------------------------------------------------------------------------

const MONSTERS_ALSO_DIE_PALETTE_COUNT: int = 12

## Lowercase hex without "#" — use with Color.html("#" + s) via monsters_also_die_color().
const MONSTERS_ALSO_DIE_PALETTE_HEX: Array[String] = [
	"061217",
	"301c10",
	"222640",
	"22343d",
	"364f48",
	"5d7545",
	"4e997f",
	"ffec99",
	"d1a990",
	"9e7368",
	"a1422d",
	"403920",
]

## Named indices (same order as MONSTERS_ALSO_DIE_PALETTE_HEX).
const MAD_IDX_BG_DEEP: int = 0
const MAD_IDX_SURFACE_WARM: int = 1
const MAD_IDX_INDIGO: int = 2
const MAD_IDX_SLATE: int = 3
const MAD_IDX_MUTED_GREEN: int = 4
const MAD_IDX_OLIVE: int = 5
const MAD_IDX_TEAL: int = 6
const MAD_IDX_CREAM: int = 7
const MAD_IDX_TAN: int = 8
const MAD_IDX_DUST: int = 9
const MAD_IDX_RUST: int = 10
const MAD_IDX_MUD: int = 11

## Shop card / draft rarity tier 0..5 → Lospec indices (distinct on-screen tiers).
const MAD_SHOP_RARITY_PALETTE_INDEX: Array[int] = [7, 5, 6, 2, 4, 10]

static func monsters_also_die_color(index: int) -> Color:
	var i: int = clampi(index, 0, MONSTERS_ALSO_DIE_PALETTE_COUNT - 1)
	return Color.html("#" + String(MONSTERS_ALSO_DIE_PALETTE_HEX[i]))

static func shop_rarity_accent_color(tier: int) -> Color:
	var t: int = clampi(tier, 0, MAD_SHOP_RARITY_PALETTE_INDEX.size() - 1)
	return monsters_also_die_color(MAD_SHOP_RARITY_PALETTE_INDEX[t])

## Ball alignment display: Main / Sidearm / Defense → cream / rust / indigo. Out-of-range → main (cream).
static func ball_alignment_color(alignment: int) -> Color:
	if alignment < 0 or alignment > 2:
		return monsters_also_die_color(MAD_IDX_CREAM)
	match alignment:
		1:
			return monsters_also_die_color(MAD_IDX_RUST)
		2:
			return monsters_also_die_color(MAD_IDX_INDIGO)
		_:
			return monsters_also_die_color(MAD_IDX_CREAM)

## One Lospec index per ability for BallVisuals.get_ability_theme_color (0..11 cover all swatches).
static func ball_ability_theme_palette_index(ability_key: String) -> int:
	var k: String = ability_key.strip_edges()
	if k.is_empty():
		k = "Plain"
	match k:
		"Plain":
			return MAD_IDX_SLATE
		"Split":
			return MAD_IDX_SURFACE_WARM
		"Energize":
			return MAD_IDX_INDIGO
		"Explosive":
			return MAD_IDX_MUTED_GREEN
		"Chain Lightning":
			return MAD_IDX_OLIVE
		"Leech":
			return MAD_IDX_TEAL
		"Rubbery":
			return MAD_IDX_CREAM
		"Phantom":
			return MAD_IDX_TAN
		"Volatile":
			return MAD_IDX_DUST
		"Constellation":
			return MAD_IDX_RUST
		"Binary":
			return MAD_IDX_MUD
		"Bloom":
			return MAD_IDX_BG_DEEP
		_:
			return MAD_IDX_TAN

static func ball_ability_theme_color(ability_key: String) -> Color:
	return monsters_also_die_color(ball_ability_theme_palette_index(ability_key))

## Multiply RGB by luminance; keeps alpha unless alpha_scale >= 0 (then sets alpha).
static func color_with_luminance(base: Color, luminance: float, alpha_scale: float = -1.0) -> Color:
	var a: float = base.a if alpha_scale < 0.0 else alpha_scale
	return Color(base.r * luminance, base.g * luminance, base.b * luminance, a)

static func ui_main_background() -> Color:
	return monsters_also_die_color(MAD_IDX_BG_DEEP)

static func ui_main_panel_left() -> Color:
	return monsters_also_die_color(MAD_IDX_SURFACE_WARM)

static func ui_main_panel_right() -> Color:
	return monsters_also_die_color(MAD_IDX_INDIGO)

static func ui_buckets_panel_bg() -> Color:
	return monsters_also_die_color(MAD_IDX_SLATE)

static func ui_buckets_panel_border() -> Color:
	return monsters_also_die_color(MAD_IDX_INDIGO)

static func ui_run_gold_text() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM)

static func ui_bag_label_text() -> Color:
	return monsters_also_die_color(MAD_IDX_TAN)

static func ui_wall_value_text() -> Color:
	return monsters_also_die_color(MAD_IDX_RUST)

static func ui_charge_accent() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM)

static func ui_charge_vfx_particle() -> Color:
	var b: Color = ui_charge_accent()
	return Color(b.r, b.g, b.b, 0.95)

static func ui_charge_value_text() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM)

static func ui_sidearm_label_text() -> Color:
	return monsters_also_die_color(MAD_IDX_RUST)

static func ui_sidearm_value_text() -> Color:
	return monsters_also_die_color(MAD_IDX_RUST)

static func ui_health_label_text() -> Color:
	return monsters_also_die_color(MAD_IDX_TEAL)

static func ui_health_value_text() -> Color:
	return monsters_also_die_color(MAD_IDX_OLIVE)

static func ui_conquest_goal_text() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM)

static func ui_debug_energy_hud_text() -> Color:
	return monsters_also_die_color(MAD_IDX_SLATE)

static func ui_milestone_shop_title_text() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM)

static func ui_milestone_shop_desc_text() -> Color:
	return monsters_also_die_color(MAD_IDX_DUST)

static func ui_shop_icon_neutral_tint() -> Color:
	return monsters_also_die_color(MAD_IDX_TAN)

static func ui_shop_price_normal() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM)

static func ui_shop_price_error() -> Color:
	return monsters_also_die_color(MAD_IDX_RUST)

static func ui_shop_price_purchased() -> Color:
	return monsters_also_die_color(MAD_IDX_DUST)

static func ui_wall_health_bar_fill() -> Color:
	return monsters_also_die_color(MAD_IDX_RUST)

static func ui_progress_bar_track() -> Color:
	return monsters_also_die_color(MAD_IDX_SLATE)

static func ui_timer_critical() -> Color:
	return monsters_also_die_color(MAD_IDX_RUST)

static func ui_timer_warning() -> Color:
	return monsters_also_die_color(MAD_IDX_TAN)

static func ui_timer_normal() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM)

static func ui_conquest_wall_current_text() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM)

static func ui_conquest_wall_cleared_text() -> Color:
	return monsters_also_die_color(MAD_IDX_OLIVE)

static func ui_conquest_wall_cleared_text_dim() -> Color:
	var c: Color = ui_conquest_wall_cleared_text()
	return Color(c.r, c.g, c.b, 0.6)

static func ui_conquest_bubble_pulse_fade_modulate() -> Color:
	var c: Color = ui_conquest_wall_current_text()
	return Color(c.r, c.g, c.b, 0.5)

static func ui_wall_cleared_flash_fill() -> Color:
	return monsters_also_die_color(MAD_IDX_TEAL)

static func ui_conquest_bubble_current() -> Color:
	return monsters_also_die_color(MAD_IDX_TAN)

static func ui_conquest_bubble_current_ring() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM)

static func ui_conquest_bubble_default() -> Color:
	return monsters_also_die_color(MAD_IDX_RUST)

static func ui_conquest_bubble_default_ring() -> Color:
	return monsters_also_die_color(MAD_IDX_DUST)

static func ui_conquest_segment_fill() -> Color:
	return monsters_also_die_color(MAD_IDX_RUST)

static func ui_conquest_segment_border() -> Color:
	return monsters_also_die_color(MAD_IDX_DUST)

## Board peg “plain” body: tan/cream stone.
static func gameplay_peg_plain_body() -> Color:
	return monsters_also_die_color(MAD_IDX_TAN).lerp(monsters_also_die_color(MAD_IDX_DUST), 0.35)

static func gameplay_chain_lightning_glow_outer() -> Color:
	return monsters_also_die_color(MAD_IDX_INDIGO).lerp(monsters_also_die_color(MAD_IDX_TEAL), 0.45)

static func gameplay_chain_lightning_glow_inner() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM).lerp(monsters_also_die_color(MAD_IDX_TEAL), 0.5)

static func gameplay_leech_pulse_outer() -> Color:
	return monsters_also_die_color(MAD_IDX_INDIGO).lerp(monsters_also_die_color(MAD_IDX_RUST), 0.4)

static func gameplay_leech_pulse_inner() -> Color:
	return monsters_also_die_color(MAD_IDX_DUST).lerp(monsters_also_die_color(MAD_IDX_CREAM), 0.35)

static func gameplay_board_popup_gold() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM).lerp(monsters_also_die_color(MAD_IDX_SURFACE_WARM), 0.25)

static func gameplay_board_energy_popup() -> Color:
	return monsters_also_die_color(MAD_IDX_INDIGO).lerp(monsters_also_die_color(MAD_IDX_DUST), 0.3)

static func gameplay_wall_flash() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM)

static func gameplay_cannon_metal_dark() -> Color:
	return monsters_also_die_color(MAD_IDX_MUD).lerp(monsters_also_die_color(MAD_IDX_SURFACE_WARM), 0.35)

static func gameplay_cannon_metal_mid() -> Color:
	return monsters_also_die_color(MAD_IDX_SURFACE_WARM).lerp(monsters_also_die_color(MAD_IDX_DUST), 0.4)

static func gameplay_cannon_barrel_accent() -> Color:
	return monsters_also_die_color(MAD_IDX_RUST).lerp(monsters_also_die_color(MAD_IDX_TAN), 0.35)

static func gameplay_cannon_muzzle_glow() -> Color:
	return monsters_also_die_color(MAD_IDX_DUST).lerp(monsters_also_die_color(MAD_IDX_CREAM), 0.45)

static func gameplay_cannon_shot_core() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM)

static func gameplay_cannon_shot_ring() -> Color:
	return monsters_also_die_color(MAD_IDX_TAN).lerp(monsters_also_die_color(MAD_IDX_CREAM), 0.4)

static func gameplay_wall_impact_core() -> Color:
	return monsters_also_die_color(MAD_IDX_RUST).lerp(monsters_also_die_color(MAD_IDX_CREAM), 0.25)

static func gameplay_wall_impact_ring() -> Color:
	return monsters_also_die_color(MAD_IDX_CREAM).lerp(monsters_also_die_color(MAD_IDX_TAN), 0.35)

static func gameplay_minion_body() -> Color:
	return monsters_also_die_color(MAD_IDX_MUTED_GREEN).lerp(monsters_also_die_color(MAD_IDX_SLATE), 0.35)

static func gameplay_black_hole_warning_arc() -> Color:
	return monsters_also_die_color(MAD_IDX_INDIGO).lerp(monsters_also_die_color(MAD_IDX_BG_DEEP), 0.2)
