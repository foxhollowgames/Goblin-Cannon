extends Resource
class_name RelicBallReward
## Fixed temporary ball reward authored for one deliberate relic.

const VERSION: int = 2
const LEGACY_VERSION: int = 1
const DEFAULT_SPACING_TICKS: int = 6
const DEFAULT_LIFE_TICKS: int = 720
const MAX_ACTIVE_OR_RESERVED: int = 24
const REWARD_TYPES: Array[String] = ["Plain", "Rubbery", "Energize", "Explosive", "Chain Lightning", "Split", "Binary"]
const TIER_BUDGETS: Dictionary = {
	1: {"Plain": 3, "Rubbery": 1, "Energize": 1, "Split": 1},
	2: {"Plain": 6, "Rubbery": 4, "Energize": 3, "Split": 2, "Explosive": 1, "Chain Lightning": 1},
	3: {"Plain": 12, "Rubbery": 10, "Energize": 6, "Split": 4, "Explosive": 3, "Chain Lightning": 3, "Binary": 1}
}

@export var version: int = VERSION
@export var ball_type: String = "Plain"
@export var count: int = 0
@export var minimum_relic_tier: int = 1
@export var spacing_ticks: int = DEFAULT_SPACING_TICKS
@export var life_ticks: int = DEFAULT_LIFE_TICKS
@export var source_id: StringName = &""
@export var spawn_at_relic: bool = false

static var _REWARDS: Dictionary = {}

## Returns the fixed reward for one of the 42 deliberate relics.
static func for_relic(source: StringName, tier: int) -> RelicBallReward:
	_build_rewards()
	var row: Dictionary = _REWARDS.get(source, {})
	if row.is_empty():
		return null
	var reward: RelicBallReward = RelicBallReward.new()
	reward.source_id = source
	reward.ball_type = str(row.get("type", "Plain"))
	reward.count = int(row.get("count", 0))
	reward.minimum_relic_tier = int(row.get("tier", tier))
	return reward if reward.is_valid_for_tier(tier) else null

## Validates the authored count, tier gate, and temporary timing contract.
func is_valid_for_tier(tier: int) -> bool:
	if version != VERSION or life_ticks != DEFAULT_LIFE_TICKS or spacing_ticks != DEFAULT_SPACING_TICKS:
		return false
	if tier < minimum_relic_tier or tier < 1 or tier > 3 or source_id.is_empty():
		return false
	if not REWARD_TYPES.has(ball_type) or count <= 0:
		return false
	var budget: Dictionary = TIER_BUDGETS.get(tier, {})
	return budget.has(ball_type) and count <= int(budget[ball_type])

## Returns the player-facing exact-count description.
func get_description() -> String:
	var suffix: String = "" if count == 1 else "s"
	var location: String = "through the device outlet" if spawn_at_relic else "in the hopper"
	return "Release %d %s ball%s %s. Lasts one visit, up to 12 seconds." % [count, ball_type, suffix, location]

## Serializes authored data for future item saves and migration tools.
func serialize() -> Dictionary:
	return {"version": VERSION, "ball_type": ball_type, "count": count,
		"minimum_relic_tier": minimum_relic_tier, "spacing_ticks": spacing_ticks,
		"life_ticks": life_ticks, "source_id": str(source_id), "spawn_at_relic": spawn_at_relic}

## Loads authored data while keeping safe defaults for old records.
func deserialize(data: Dictionary) -> void:
	var saved_version: int = int(data.get("version", LEGACY_VERSION))
	version = VERSION if saved_version <= VERSION else saved_version
	ball_type = str(data.get("ball_type", "Plain"))
	count = int(data.get("count", 0))
	minimum_relic_tier = int(data.get("minimum_relic_tier", 1))
	spacing_ticks = int(data.get("spacing_ticks", DEFAULT_SPACING_TICKS))
	life_ticks = int(data.get("life_ticks", DEFAULT_LIFE_TICKS))
	source_id = StringName(str(data.get("source_id", "")))
	spawn_at_relic = bool(data.get("spawn_at_relic", false))
	_migrate_saved_values(saved_version)

## Migrates the first saved format without accepting obsolete reward promises.
func _migrate_saved_values(saved_version: int) -> void:
	if saved_version <= LEGACY_VERSION:
		spacing_ticks = DEFAULT_SPACING_TICKS if spacing_ticks <= 0 else spacing_ticks
		life_ticks = DEFAULT_LIFE_TICKS if life_ticks <= 0 else life_ticks
	version = VERSION
	if not REWARD_TYPES.has(ball_type):
		ball_type = "Plain"
		count = 0

static func _build_rewards() -> void:
	if not _REWARDS.is_empty():
		return
	var rows: Array = [
		["bumper_vessel_twin", 1, "Rubbery", 1], ["bumper_vessel_stagger", 1, "Energize", 1],
		["pachinko_bumper_vessel", 2, "Rubbery", 4], ["bumper_vessel_pinball", 2, "Split", 2],
		["mega_pop_bumper", 3, "Chain Lightning", 3], ["cyclone_bounce_vault", 3, "Rubbery", 10],
		["word_bank_gob", 1, "Energize", 1], ["word_bank_pop", 1, "Plain", 3],
		["word_bank_win", 2, "Chain Lightning", 1], ["word_bank_bam", 2, "Explosive", 1],
		["word_bank_boom", 3, "Explosive", 3], ["word_bank_loot", 3, "Plain", 12],
		["wire_gate_cup", 1, "Energize", 1], ["wire_gate_funnel", 1, "Plain", 3],
		["wire_gate_reservoir", 2, "Plain", 6], ["abyssal_maw", 2, "Split", 2],
		["wire_gate_armory", 3, "Explosive", 3], ["fragment_swarm", 3, "Split", 4],
		["detonation_triangle_wedge", 1, "Split", 1], ["detonation_triangle_acute", 1, "Rubbery", 1],
		["corner_slingshot", 2, "Energize", 3], ["detonation_triangle_twin", 2, "Explosive", 1],
		["detonation_triangle_bastion", 3, "Explosive", 3], ["detonation_triangle_apex", 3, "Rubbery", 10],
		["bash_toy_idol", 1, "Rubbery", 1], ["bash_toy_anvil", 1, "Split", 1],
		["bash_toy_bell", 2, "Energize", 3], ["golem_effigy", 2, "Explosive", 1],
		["blood_tithe", 3, "Binary", 1], ["gilded_covenant", 3, "Plain", 12],
		["funneled_spinner_chute", 1, "Split", 1], ["funneled_spinner_v", 1, "Energize", 1],
		["funneled_spinner", 2, "Split", 2], ["funneled_spinner_dual", 2, "Plain", 6],
		["resonant_well", 3, "Chain Lightning", 3], ["funneled_spinner_vortex", 3, "Rubbery", 10],
		["track_stairs_step", 1, "Energize", 1], ["track_right_angle", 1, "Split", 1],
		["track_u_turn", 2, "Rubbery", 4], ["track_zigzag_chute", 2, "Energize", 3],
		["track_grand_orbit", 3, "Split", 4], ["track_cascade_switchback", 3, "Plain", 12]
	]
	for row: Array in rows:
		_REWARDS[StringName(row[0])] = {"tier": int(row[1]), "type": str(row[2]), "count": int(row[3])}
