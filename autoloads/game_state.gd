extends Node
## GameState autoload (§1.10). Single source of truth for run state, sim_speed, pause.
## Run seed stored here for replay; all gameplay systems read from this.

enum RunFlowState {
	FIGHTING,
	REWARD_SLOWMO,
	REWARD_PAUSED,
	RESUMING
}

var run_seed: int = 0
var sim_speed: float = 1.0
var paused: bool = false
var run_flow_state: RunFlowState = RunFlowState.FIGHTING
## 0..1: how far through the current sim step we are (1 = just stepped). Used for smooth ball rendering.
var sim_step_alpha: float = 1.0
## Current city index for city-weighted ball rarity (GDD §7). 0=City 1 Halfling Shire (slice), 1=City 2, 2=City 3.
var current_city_id: int = 0
## Hopper width scale from major upgrade (wall break). 1.0 = default; 1.25 = +25% width.
var hopper_width_scale: float = 1.0
## Conduit: gate open duration scale (wall break major upgrade). 1.0 = default; e.g. 1.25 = 25% longer open.
var conduit_open_duration_scale: float = 1.0
## Main cannon: amount subtracted from required charge (internal units; 100 = 1 display). Milestone "Energy -20" adds 2000.
var cannon_charge_reduction: int = 0
## Main cannon: bonus base damage per shot (milestone). main_cannon uses 10 + this.
var cannon_base_damage_bonus: int = 0
## Sidearm pool capacity scale (GDD §12.1 Sidearm Energy). 1.0 = default; e.g. 1.5 = 50% more cap.
var sidearm_pool_cap_scale: float = 1.0
## Milestone stat upgrades (GDD §12: 2 per milestone). Stacking bonuses.
var main_charge_bonus: float = 0.0   # added to effective main energy per ball (e.g. 0.05 = +5%)
var sidearm_cap_bonus: float = 0.0   # added to sidearm pool cap scale (e.g. 0.1 = +10%)
var shield_cap_bonus: float = 0.0    # added to shield cap scale (e.g. 0.1 = +10%)
## Cannon max HP bonus (milestone). CombatManager uses 100 + this for get_cannon_hp_max().
var cannon_hp_max_bonus: int = 0
## Wave interval scale (milestone): time between hopper doors opening. <1 = faster waves (e.g. 0.9 = 10% faster).
var conduit_wave_interval_scale: float = 1.0
## Wall break: ball ability names that exist in run (hopper + bag). Used to offer ball enhancements only for types in bag.
var ball_ability_names_in_run: Array = []  # [String]
## Wall break: sidearm archetype ids the player has unlocked (rapid_fire, aoe_cannon, sniper). Fallback = cooldown/damage scaling.
var owned_sidearm_ids: Array = []  # [StringName]
## Wall break: applied upgrade_id -> stack count. Board/ball/peg logic reads via has_wall_break_upgrade / get_wall_break_upgrade_stacks.
var applied_wall_break_upgrades: Dictionary = {}  # StringName -> int
## Board/peg scaling from wall break upgrades (tag + board).
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
var bomb_peg_count: int = 0
var trampoline_peg_count: int = 0
var goblin_reset_node_count: int = 0

## Returns the CityDefinition for the current run (by current_city_id). GDD §11. Falls back to city 0 if load fails (slice: only Halfling Shire exists).
func get_current_city_definition() -> CityDefinition:
	var idx: int = clampi(current_city_id, 0, Constants.CITY_DEFINITION_PATHS.size() - 1)
	for i in range(2):  # Try current, then 0
		var path: String = Constants.CITY_DEFINITION_PATHS[idx]
		var res: Resource = load(path) as Resource
		if res is CityDefinition:
			return res as CityDefinition
		idx = 0
	return null

func _ready() -> void:
	run_seed = randi() if run_seed == 0 else run_seed
	seed(run_seed)

func start_run(new_seed: int = 0) -> void:
	run_seed = new_seed if new_seed != 0 else randi()
	seed(run_seed)
	sim_speed = 1.0
	paused = false
	run_flow_state = RunFlowState.FIGHTING
	Engine.time_scale = 1.0
	hopper_width_scale = 1.0
	conduit_open_duration_scale = 1.0
	cannon_charge_reduction = 0
	cannon_base_damage_bonus = 0
	sidearm_pool_cap_scale = 1.0
	main_charge_bonus = 0.0
	sidearm_cap_bonus = 0.0
	shield_cap_bonus = 0.0
	cannon_hp_max_bonus = 0
	conduit_wave_interval_scale = 1.0
	ball_ability_names_in_run.clear()
	owned_sidearm_ids.clear()
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
	bomb_peg_count = 0
	trampoline_peg_count = 0
	goblin_reset_node_count = 0
	# Debug test run: 50% trampoline pegs + all sidearms (Rapid Fire, Sniper, AOE Cannon).
	if Constants and Constants.DEBUG_TEST_RUN_50_TRAMPOLINE_ALL_SIDEARMS:
		owned_sidearm_ids = [&"rapid_fire", &"sniper", &"aoe_cannon"]
		trampoline_peg_count = Constants.TEST_RUN_TRAMPOLINE_PEG_COUNT

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

func owns_sidearm(sidearm_id: StringName) -> bool:
	return owned_sidearm_ids.has(sidearm_id)

signal owned_sidearm_added(sidearm_id: StringName)

func add_owned_sidearm(sidearm_id: StringName) -> void:
	if not owned_sidearm_ids.has(sidearm_id):
		owned_sidearm_ids.append(sidearm_id)
		owned_sidearm_added.emit(sidearm_id)

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
			Engine.time_scale = 0.03  # Balls (RigidBody) and minions (_process) slow with engine
		RunFlowState.REWARD_PAUSED:
			paused = true
			Engine.time_scale = 0.0  # Freeze all motion while reward window is open
		RunFlowState.RESUMING:
			pass
