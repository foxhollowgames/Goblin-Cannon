extends Node
## TestScenario — One-stop shop for gameplay test configurations.
##
## HOW TO USE:
##   1. Set  enabled = true
##   2. Configure whichever fields you need below (leave others at default)
##   3. Run the game — the scenario is applied at run start
##   4. Set  enabled = false  when done testing
##
## Board milestone event at run start:
##   enabled = true
##   board_event_at_start = true
##   (Optional: board_event_force_x = 480.0 to fix spawn X.)
##   GameCoordinator also calls BoardEventController.arm_immediate_spawn_if_test() after load so the timer is not missed.
##
## Full-board leech (perf / visuals): enabled = true  and  all_pegs_start_leeched = true
##
## Everything is optional. Only non-default values are applied.
## No need for dozens of creative boolean flag names.

## ──────────────────────────────────────────────
## MASTER SWITCH
## ──────────────────────────────────────────────
var enabled: bool = false

## ──────────────────────────────────────────────
## STARTING BALLS
## ──────────────────────────────────────────────
## Override which balls the player starts with.
## Each entry: { "ability": "<name>", "count": <n> }
## Abilities: "Split", "Energize", "Explosive",
##            "Chain Lightning", "Leech", "Rubbery", "Phantom", "Volatile", "Constellation", "Binary", "Bloom"
## Use "" for plain (no-ability) balls.
## Empty array = use default (10 plain balls).
##
## Examples:
##   [{"ability": "Explosive", "count": 10}]
##   [{"ability": "Explosive", "count": 5}, {"ability": "Chain Lightning", "count": 5}]
var starting_balls: Array = []

## ──────────────────────────────────────────────
## CITY / STAGE
## ──────────────────────────────────────────────
## Which city to use. -1 = default (0).
## 0 = Halfling Shire, 1 = Human Kingdom, 2 = Elf Palace
var starting_city_id: int = -1

## Which wall to start on. -1 = default (0).
## 0 = first wall, 1 = second wall, 2 = boss wall
var starting_wall_index: int = -1

## ──────────────────────────────────────────────
## TIMER
## ──────────────────────────────────────────────
## Override the wall timer (applies to ALL walls).
## -1 = use per-wall defaults (60s / 180s / 120s)
##  0 = infinite (no timer — play as long as you want)
## >0 = that many seconds per wall
var timer_override_seconds: int = -1

## ──────────────────────────────────────────────
## PRE-APPLIED WALL BREAK UPGRADES
## ──────────────────────────────────────────────
## Upgrade IDs to grant at run start.
## Simple string = 1 stack.  Dictionary = custom stack count.
##
## Examples:
##   ["explosions_apply_energize", "chain_arc"]
##   [{"id": "impact_burst", "stacks": 2}]
##   Legacy peg IDs (add_bomb_peg, etc.) still grant peg counts at run start; pegs are bought in the milestone shop.
##
## Full list of upgrade IDs:
##   Ball enhancements: impact_burst, hyper_elastic, overdrive_hits,
##     supernova_peg, chain_conduction, overclock_network,
##     overcharged_drain, spreading_rot, energy_collapse,
##     cluster_grenade, blast_lift, fragmentation_tag,
##     storm_feedback, final_arc_detonation, overcurrent_surge,
##     fragment_echo, mass_cascade, ghost_trail, phase_instability, chest_random_ball
##   Tag / global scaling (treasure chest onboard rewards): explosion_radius, explosion_peg_hit_count,
##     explosion_impulse, chain_arc, chain_range,
##     max_energize_stacks, energize_decays_slower,
##     energized_pegs_repair_faster, global_peg_durability, peg_recovery_speed
##   Synergy upgrades (conquest / wall break): explosions_apply_energize, chain_hits_apply_energize, cross-links, etc.
##   Plain board (wall break): plain_surge, plain_horde, plain_momentum, volt_primer
var starting_upgrades: Array = []

## ──────────────────────────────────────────────
## STAT BONUSES
## ──────────────────────────────────────────────
## Pre-applied stat bonuses (additive on top of base).
## Keys: "cannon_damage"  (int, +N base damage per shot)
##        "cannon_energy"  (int, legacy internal charge reduction; scaled to current 100-display cannon)
##        "main_charge"    (float, +N% bonus to energy routed to main)
##        "door_interval"  (float, −N from conduit_wave_interval_scale, min 0.5)
##        "door_duration"  (float, +N to conduit_open_duration_scale)
##        "plain_surge" / "plain_horde" / "plain_momentum"  (int, +N stacks to plain-swarm caps)
##
## Example:
##   {"cannon_damage": 20, "main_charge": 0.2}
##   {"plain_surge": 2, "plain_horde": 1}
var starting_stats: Dictionary = {}

## ──────────────────────────────────────────────
## PEG OVERRIDES
## ──────────────────────────────────────────────
## Specific counts of special pegs to pre-place on the board.
## Keys: "bomb", "trampoline", "goblin_reset"
##
## Example: {"bomb": 5, "trampoline": 3}
var starting_peg_counts: Dictionary = {}

## Make ALL pegs into bombs.
var all_pegs_bombs: bool = false

## Make ALL pegs into trampolines.
var all_pegs_trampolines: bool = false

## Apply leech status to every peg when the board spawns (same as a Leech hit: drain timer + cone stack).
## Use with `enabled = true` to stress-test leech visuals / performance on the full peg field.
var all_pegs_start_leeched: bool = false

## Board milestone events: short intervals between spawns (for manual testing).
var board_event_fast: bool = false

## If true (with `enabled`), the first milestone board event starts immediately—short preview, then the peg.
## Requires `enabled = true`. GameCoordinator re-arms this after load so the timer is not missed.
## Later events still use `min_interval_sec` / `max_interval_sec` on BoardEventController (or `board_event_fast`).
var board_event_at_start: bool = false

## If >= 0, the next event preview uses this board X (same coordinate space as peg positions).
var board_event_force_x: float = -1.0

## Treasure chest debugs
## Treasure chest: short intervals for testing.
var treasure_chest_event_fast: bool = false
## First treasure chest preview starts immediately (with `enabled`).
var treasure_chest_event_at_start: bool = false
## If >= 0, treasure chest preview uses this board X.
var treasure_chest_event_force_x: float = -1.0

## Halfling Shire buffet table (same pattern as treasure chest).
var buffet_table_event_fast: bool = false
var buffet_table_event_at_start: bool = false
var buffet_table_event_force_x: float = -1.0

## Human Kingdom sticky slime (highlights pegs → sticky coating).
var sticky_slime_event_fast: bool = false
var sticky_slime_event_at_start: bool = false
## If > 0, overrides peg count for that event (else controller default).
var sticky_slime_event_pegs: int = 0

## Elf Palace black hole (preview → pull + consume; hopper return delayed).
var black_hole_event_fast: bool = false
var black_hole_event_at_start: bool = false
## If >= 0, next preview uses this board X (same space as board events).
var black_hole_event_force_x: float = -1.0

## ──────────────────────────────────────────────
## HELPERS (called by game systems — don't edit below)
## ──────────────────────────────────────────────

const ABILITY_SHAPES: Dictionary = {
	"Split": 5,
	"Energize": 4,
	"Explosive": 3,
	"Chain Lightning": 6,
	"Leech": 2,
	"Rubbery": 0,
	"Phantom": 5,
	"Volatile": 7,
	"Constellation": 7,
	"Binary": 1,
	"Bloom": 4,
}

func get_summary() -> String:
	if not enabled:
		return ""
	var parts: Array[String] = []
	if not starting_balls.is_empty():
		var ball_strs: Array[String] = []
		for entry in starting_balls:
			var ability: String = entry.get("ability", "") if entry is Dictionary else ""
			var count: int = entry.get("count", 1) if entry is Dictionary else 1
			ball_strs.append("%dx %s" % [count, ability if not ability.is_empty() else "Plain"])
		parts.append("balls: %s" % ", ".join(ball_strs))
	if starting_city_id >= 0:
		parts.append("city: %d" % starting_city_id)
	if starting_wall_index >= 0:
		parts.append("wall: %d" % starting_wall_index)
	if timer_override_seconds == 0:
		parts.append("timer: infinite")
	elif timer_override_seconds > 0:
		parts.append("timer: %ds" % timer_override_seconds)
	if not starting_upgrades.is_empty():
		var ids: Array[String] = []
		for entry in starting_upgrades:
			if entry is String:
				ids.append(entry)
			elif entry is Dictionary:
				ids.append(str(entry.get("id", "?")))
		parts.append("upgrades: %s" % ", ".join(ids))
	if not starting_stats.is_empty():
		parts.append("stats: %s" % str(starting_stats))
	if all_pegs_bombs:
		parts.append("ALL pegs = bombs")
	elif all_pegs_trampolines:
		parts.append("ALL pegs = trampolines")
	elif not starting_peg_counts.is_empty():
		parts.append("pegs: %s" % str(starting_peg_counts))
	if all_pegs_start_leeched:
		parts.append("ALL pegs start leeched")
	if board_event_fast:
		parts.append("board events: fast")
	if board_event_at_start:
		parts.append("board event at start")
	if board_event_force_x >= 0.0:
		parts.append("board event X: %.0f" % board_event_force_x)
	if treasure_chest_event_fast:
		parts.append("treasure chest: fast")
	if treasure_chest_event_at_start:
		parts.append("treasure chest at start")
	if treasure_chest_event_force_x >= 0.0:
		parts.append("treasure chest X: %.0f" % treasure_chest_event_force_x)
	if black_hole_event_fast:
		parts.append("black hole: fast")
	if black_hole_event_at_start:
		parts.append("black hole at start")
	if black_hole_event_force_x >= 0.0:
		parts.append("black hole X: %.0f" % black_hole_event_force_x)
	return " | ".join(parts)

func make_ball_definition(ability_name: String) -> BallDefinition:
	var d := BallDefinition.new()
	d.ability_name = ability_name
	d.alignment = Constants.ALIGNMENT_MAIN
	d.tier = 1
	if ability_name.is_empty():
		d.rarity = Constants.RARITY_COMMON
	elif ability_name == "Volatile":
		d.rarity = Constants.RARITY_RARE
	elif ability_name == "Explosive" or ability_name == "Chain Lightning" or ability_name == "Constellation" or ability_name == "Binary" or ability_name == "Bloom":
		d.rarity = Constants.RARITY_LEGENDARY
	else:
		d.rarity = Constants.RARITY_UNCOMMON
	d.base_energy = Constants.legacy_display_energy_to_current(20)
	d.city_weights = {0: 100}
	d.shape_type = ABILITY_SHAPES.get(ability_name, -1)
	d.status_effects = {}
	return d
