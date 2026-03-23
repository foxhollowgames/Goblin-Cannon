extends Node
## TestScenario — One-stop shop for gameplay test configurations.
##
## HOW TO USE:
##   1. Set  enabled = true
##   2. Configure whichever fields you need below (leave others at default)
##   3. Run the game — the scenario is applied at run start
##   4. Set  enabled = false  when done testing
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
## Abilities: "Bounce", "Split", "Energize", "Explosive",
##            "Chain Lightning", "Leech", "Rubbery", "Phantom"
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
## -1 = use per-wall defaults (300s / 180s / 120s)
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
##   [{"id": "impact_burst", "stacks": 2}, "add_bomb_peg"]
##
## Full list of upgrade IDs:
##   Ball enhancements: impact_burst, hyper_elastic, overdrive_hits,
##     supernova_peg, chain_conduction, overclock_network,
##     overcharged_drain, spreading_rot, energy_collapse,
##     cluster_grenade, blast_lift, fragmentation_tag,
##     storm_feedback, final_arc_detonation, overcurrent_surge,
##     fragment_echo, mass_cascade, ghost_trail, phase_instability
##   Tag upgrades: explosion_radius, explosion_peg_hit_count,
##     explosion_impulse, explosions_apply_energize,
##     chain_arc, chain_range, chain_hits_apply_energize,
##     max_energize_stacks, energize_decays_slower,
##     energized_pegs_repair_faster
##   Board upgrades: add_bomb_peg, add_trampoline_peg,
##     add_goblin_reset_node, global_peg_durability, peg_recovery_speed
var starting_upgrades: Array = []

## ──────────────────────────────────────────────
## STAT BONUSES
## ──────────────────────────────────────────────
## Pre-applied stat bonuses (additive on top of base).
## Keys: "cannon_damage"  (int, +N base damage per shot)
##        "cannon_energy"  (int, −N charge threshold in internal units)
##        "main_charge"    (float, +N% bonus to energy routed to main)
##        "door_interval"  (float, −N from conduit_wave_interval_scale, min 0.5)
##        "door_duration"  (float, +N to conduit_open_duration_scale)
##
## Example:
##   {"cannon_damage": 20, "main_charge": 0.2}
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

## ──────────────────────────────────────────────
## HELPERS (called by game systems — don't edit below)
## ──────────────────────────────────────────────

const ABILITY_SHAPES: Dictionary = {
	"Bounce": 0,
	"Split": 5,
	"Energize": 4,
	"Explosive": 3,
	"Chain Lightning": 6,
	"Leech": 2,
	"Rubbery": 0,
	"Phantom": 5,
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
	return " | ".join(parts)

func make_ball_definition(ability_name: String) -> BallDefinition:
	var d := BallDefinition.new()
	d.ability_name = ability_name
	d.alignment = Constants.ALIGNMENT_MAIN
	d.tier = 1
	d.rarity = Constants.RARITY_UNCOMMON if not ability_name.is_empty() else Constants.RARITY_COMMON
	d.base_energy = 20
	d.city_weights = {0: 100}
	d.shape_type = ABILITY_SHAPES.get(ability_name, -1)
	d.status_effects = {}
	return d
