extends Node
## GameState autoload. Single source of truth for run state, sim_speed, pause.

const JunkBoxData = preload("res://resources/inventory/junk_box_data.gd")

enum RunFlowState {
	FIGHTING,
	REWARD_SLOWMO,
	REWARD_PAUSED,
	RESUMING,
	WALL_BREAK_TRANSITION
}

var run_seed: int = 0
var sim_speed: float = 1.0
var paused: bool = false
var run_flow_state: RunFlowState = RunFlowState.FIGHTING
var sim_step_alpha: float = 1.0
var current_city_id: int = 0
## After clearing Elf Palace (last city), player can continue in endless testing mode.
var endless_mode: bool = false
## Spendable gold for milestone shop (earned from stash pegs, etc.).
var run_gold: int = 0
var hopper_width_scale: float = 1.0
var conduit_open_duration_scale: float = 1.0
var cannon_charge_reduction: int = 0
## Volt Primer: extra threshold reduction until next main shot (internal units); stacks on energize, cleared on fire.
var main_cannon_volt_primer_discount: int = 0
var cannon_base_damage_bonus: int = 0
## Milestone stat upgrades. Stacking bonuses.
var main_charge_bonus: float = 0.0
## Plain-ball swarm (archetype C): balls with empty ability_name only; see RewardHandler.apply_stat_upgrade.
var plain_surge_stacks: int = 0  ## +1 energy per peg hit per stack, max 5 from wall rewards / tests
var plain_momentum_stacks: int = 0  ## After 6+ hits in one fall: +1 per stack per hit, max 3
var plain_horde_stacks: int = 0  ## +floor(plain_count/5)*stacks per hit, bonus capped at +3
var conduit_wave_interval_scale: float = 1.0
var ball_ability_names_in_run: Array = []
## Wall break: applied upgrade_id -> stack count. Board/ball/peg logic reads via has_wall_break_upgrade / get_wall_break_upgrade_stacks.
var applied_wall_break_upgrades: Dictionary = {}
## Board/peg scaling from treasure chest and conquest picks (tag upgrades, global durability, etc.).
var explosion_radius_bonus: int = 0
var explosion_peg_hit_count_bonus: int = 0
var explosion_impulse_bonus: float = 0.0
var chain_arc_bonus: int = 0
var chain_range_bonus: int = 0
var max_energize_stacks_per_peg: int = 3
var energize_decay_scale: float = 1.0
var energized_peg_repair_scale: float = 1.0
var global_peg_durability_bonus: int = 0
var peg_recovery_speed_scale: float = 1.0
## Treasure chest numeric passives (not wall-break upgrade IDs).
var chest_leech_drain_stacks: int = 0
var chest_leech_duration_stacks: int = 0
var chest_phantom_energy_stacks: int = 0
var chest_rubbery_energy_stacks: int = 0
var chest_bounce_energy_stacks: int = 0
var chest_split_energy_stacks: int = 0
## Treasure chest: main cannon +10 wall damage (once per run).
var chest_devastating_barrage_taken: bool = false
## Treasure chest: main cannon charge reduction tier (once per run; same magnitude as milestone cannon_energy).
var chest_compressed_charge_taken: bool = false
var bomb_peg_count: int = 0
var trampoline_peg_count: int = 0
var goblin_reset_node_count: int = 0
var eternal_peg_count: int = 0
var extreme_bouncer_peg_count: int = 0
var magnet_peg_count: int = 0
var splitter_peg_count: int = 0
var gold_peg_count: int = 0
## Gold peg + guaranteed stash (1 or 5 run gold); higher chance of 5 than random stash pegs.
var lucky_gold_peg_count: int = 0
var gravity_well_peg_count: int = 0
var phase_peg_count: int = 0
var wrench_peg_count: int = 0
## Boss amplifier upgrades: upgrade_id -> stack count. Applied after clearing a city.
var applied_boss_upgrades: Dictionary = {}
## Junk Box backpack inventory
var junk_box: JunkBoxData = null

func get_current_city_definition() -> CityDefinition:
	var idx: int = clampi(current_city_id, 0, Constants.CITY_DEFINITION_PATHS.size() - 1)
	for i in range(2):
		var path: String = Constants.CITY_DEFINITION_PATHS[idx]
		var res: Resource = load(path) as Resource
		if res is CityDefinition:
			return res as CityDefinition
		idx = 0
	return null

func _ready() -> void:
	if junk_box == null:
		junk_box = JunkBoxData.new()
	run_seed = randi() if run_seed == 0 else run_seed
	seed(run_seed)

func start_run(new_seed: int = 0) -> void:
	junk_box = JunkBoxData.new()
	run_seed = new_seed if new_seed != 0 else randi()
	seed(run_seed)
	sim_speed = 1.0
	paused = false
	run_flow_state = RunFlowState.FIGHTING
	Engine.time_scale = 1.0
	hopper_width_scale = 1.0
	conduit_open_duration_scale = 1.0
	cannon_charge_reduction = 0
	main_cannon_volt_primer_discount = 0
	cannon_base_damage_bonus = 0
	main_charge_bonus = 0.0
	plain_surge_stacks = 0
	plain_momentum_stacks = 0
	plain_horde_stacks = 0
	conduit_wave_interval_scale = 1.0
	ball_ability_names_in_run.clear()
	applied_wall_break_upgrades.clear()
	explosion_radius_bonus = 0
	explosion_peg_hit_count_bonus = 0
	explosion_impulse_bonus = 0.0
	chain_arc_bonus = 0
	chain_range_bonus = 0
	max_energize_stacks_per_peg = 3
	energize_decay_scale = 1.0
	energized_peg_repair_scale = 1.0
	global_peg_durability_bonus = 0
	peg_recovery_speed_scale = 1.0
	chest_leech_drain_stacks = 0
	chest_leech_duration_stacks = 0
	chest_phantom_energy_stacks = 0
	chest_rubbery_energy_stacks = 0
	chest_bounce_energy_stacks = 0
	chest_split_energy_stacks = 0
	chest_devastating_barrage_taken = false
	chest_compressed_charge_taken = false
	bomb_peg_count = 0
	trampoline_peg_count = 0
	goblin_reset_node_count = 0
	eternal_peg_count = 0
	extreme_bouncer_peg_count = 0
	magnet_peg_count = 0
	splitter_peg_count = 0
	gold_peg_count = 0
	lucky_gold_peg_count = 0
	gravity_well_peg_count = 0
	phase_peg_count = 0
	wrench_peg_count = 0
	applied_boss_upgrades.clear()
	endless_mode = false
	run_gold = 10

func record_ball_ability_in_run(ability_name: String) -> void:
	if ability_name.is_empty():
		return
	if ability_name not in ball_ability_names_in_run:
		ball_ability_names_in_run.append(ability_name)

func has_ball_ability_in_run(ability_name: String) -> bool:
	return ability_name in ball_ability_names_in_run

func has_wall_break_upgrade(upgrade_id: StringName) -> bool:
	return applied_wall_break_upgrades.get(upgrade_id, 0) > 0

func get_wall_break_upgrade_stacks(upgrade_id: StringName) -> int:
	return applied_wall_break_upgrades.get(upgrade_id, 0)

func add_wall_break_upgrade(upgrade_id: StringName, stacks: int = 1) -> void:
	applied_wall_break_upgrades[upgrade_id] = applied_wall_break_upgrades.get(upgrade_id, 0) + stacks

func remove_wall_break_upgrade_stack(upgrade_id: StringName, stacks: int = 1) -> void:
	var v: int = applied_wall_break_upgrades.get(upgrade_id, 0) - stacks
	if v <= 0:
		applied_wall_break_upgrades.erase(upgrade_id)
	else:
		applied_wall_break_upgrades[upgrade_id] = v

## Remove one boss pick (almanac / debug). Reverses side effects that apply_boss_upgrade applied.
func remove_boss_upgrade_entry(upgrade_id: StringName) -> void:
	if not has_boss_upgrade(upgrade_id):
		return
	match upgrade_id:
		&"renewal_pact":
			peg_recovery_speed_scale = maxf(1.0, peg_recovery_speed_scale - 0.12)
	applied_boss_upgrades.erase(upgrade_id)

func apply_volt_primer_on_energize() -> void:
	if not has_wall_break_upgrade(&"volt_primer"):
		return
	var inc: int = Constants.main_cannon_volt_primer_discount_internal()
	var base: int = Constants.main_cannon_charge_internal()
	var max_disc: int = maxi(0, base - cannon_charge_reduction - 1)
	main_cannon_volt_primer_discount = mini(max_disc, main_cannon_volt_primer_discount + inc)

func has_boss_upgrade(upgrade_id: StringName) -> bool:
	return applied_boss_upgrades.get(upgrade_id, 0) > 0

func add_boss_upgrade(upgrade_id: StringName, stacks: int = 1) -> void:
	applied_boss_upgrades[upgrade_id] = applied_boss_upgrades.get(upgrade_id, 0) + stacks

func get_leech_duration_sec() -> int:
	return Constants.LEECH_DURATION_SEC + chest_leech_duration_stacks

func get_leech_drain_per_second_display() -> int:
	return Constants.LEECH_DRAIN_PER_SECOND + chest_leech_drain_stacks

func add_run_gold(amount: int) -> void:
	run_gold = maxi(0, run_gold + amount)

func set_run_flow_state(state: RunFlowState) -> void:
	run_flow_state = state
	match state:
		RunFlowState.FIGHTING:
			sim_speed = 1.0
			paused = false
			Engine.time_scale = 1.0
		RunFlowState.REWARD_SLOWMO:
			sim_speed = 0.03
			paused = false
			Engine.time_scale = 0.03
		RunFlowState.REWARD_PAUSED:
			paused = true
			Engine.time_scale = 0.0
		RunFlowState.RESUMING:
			pass
		RunFlowState.WALL_BREAK_TRANSITION:
			paused = true
			Engine.time_scale = 1.0
