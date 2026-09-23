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

signal campaign_run_started(run_index: int, character_archetype: StringName)
signal campaign_run_completed(run_index: int, mcguffin_id: StringName)
signal convergence_event_triggered()

## Campaign progression (TASK-002: 6 distinct playthroughs)
var campaign_run_index: int = 1
var highest_unlocked_campaign_run: int = 1
var unlocked_mcguffins: Array = []
var character_archetype: StringName = &"goblin"
var convergence_active: bool = false

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
## Legacy passive fields remain as inert compatibility properties for old debug data.
## They always read as the baseline and discard writes.
var hopper_width_scale: float:
	get: return 1.0
	set(_value): pass
var conduit_open_duration_scale: float:
	get: return 1.0
	set(_value): pass
var cannon_charge_reduction: int:
	get: return 0
	set(_value): pass
var main_cannon_volt_primer_discount: int:
	get: return 0
	set(_value): pass
var cannon_base_damage_bonus: int:
	get: return 0
	set(_value): pass
var main_charge_bonus: float:
	get: return 0.0
	set(_value): pass
var plain_surge_stacks: int:
	get: return 0
	set(_value): pass
var plain_momentum_stacks: int:
	get: return 0
	set(_value): pass
var plain_horde_stacks: int:
	get: return 0
	set(_value): pass
var conduit_wave_interval_scale: float:
	get: return 1.0
	set(_value): pass
var ball_ability_names_in_run: Array = []
var applied_wall_break_upgrades: Dictionary:
	get: return {}
	set(_value): pass
var explosion_radius_bonus: int:
	get: return 0
	set(_value): pass
var explosion_peg_hit_count_bonus: int:
	get: return 0
	set(_value): pass
var explosion_impulse_bonus: float:
	get: return 0.0
	set(_value): pass
var chain_arc_bonus: int:
	get: return 0
	set(_value): pass
var chain_range_bonus: int:
	get: return 0
	set(_value): pass
var max_energize_stacks_per_peg: int:
	get: return 3
	set(_value): pass
var energize_decay_scale: float:
	get: return 1.0
	set(_value): pass
var energized_peg_repair_scale: float:
	get: return 1.0
	set(_value): pass
var global_peg_durability_bonus: int:
	get: return 0
	set(_value): pass
var peg_recovery_speed_scale: float:
	get: return 1.0
	set(_value): pass
var chest_leech_drain_stacks: int:
	get: return 0
	set(_value): pass
var chest_leech_duration_stacks: int:
	get: return 0
	set(_value): pass
var chest_phantom_energy_stacks: int:
	get: return 0
	set(_value): pass
var chest_rubbery_energy_stacks: int:
	get: return 0
	set(_value): pass
var chest_bounce_energy_stacks: int:
	get: return 0
	set(_value): pass
var chest_split_energy_stacks: int:
	get: return 0
	set(_value): pass
var chest_devastating_barrage_taken: bool:
	get: return false
	set(_value): pass
var chest_compressed_charge_taken: bool:
	get: return false
	set(_value): pass
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
var applied_boss_upgrades: Dictionary:
	get: return {}
	set(_value): pass
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
	campaign_run_index = 1
	highest_unlocked_campaign_run = 1
	unlocked_mcguffins.clear()
	character_archetype = &"goblin"
	convergence_active = false
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
	return false

func get_wall_break_upgrade_stacks(upgrade_id: StringName) -> int:
	return 0

func add_wall_break_upgrade(upgrade_id: StringName, stacks: int = 1) -> void:
	pass

func remove_wall_break_upgrade_stack(upgrade_id: StringName, stacks: int = 1) -> void:
	pass

## Remove one boss pick (almanac / debug). Reverses side effects that apply_boss_upgrade applied.
func remove_boss_upgrade_entry(upgrade_id: StringName) -> void:
	pass

func apply_volt_primer_on_energize() -> void:
	pass

func has_boss_upgrade(upgrade_id: StringName) -> bool:
	return false

func add_boss_upgrade(upgrade_id: StringName, stacks: int = 1) -> void:
	pass

func get_leech_duration_sec() -> int:
	return Constants.LEECH_DURATION_SEC

func get_leech_drain_per_second_display() -> int:
	return Constants.LEECH_DRAIN_PER_SECOND

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

func get_character_archetype_for_run(run_idx: int) -> StringName:
	match run_idx:
		1: return &"goblin"
		2: return &"necromancer"
		3: return &"beastmancer"
		4: return &"mechanic"
		5: return &"astromancer"
		6: return &"goblin_convergence"
		_: return &"goblin"

func is_run_unlocked(run_idx: int) -> bool:
	return run_idx >= 1 and run_idx <= 6 and run_idx <= highest_unlocked_campaign_run

func has_mcguffin(mcguffin_id: StringName) -> bool:
	return mcguffin_id in unlocked_mcguffins

func start_campaign_run(run_idx: int) -> void:
	campaign_run_index = clampi(run_idx, 1, 6)
	character_archetype = get_character_archetype_for_run(campaign_run_index)
	convergence_active = (campaign_run_index == 6)
	if convergence_active:
		convergence_event_triggered.emit()
	campaign_run_started.emit(campaign_run_index, character_archetype)

func complete_campaign_run() -> void:
	var mcg_id: StringName = &"mcguffin_run_%d" % campaign_run_index
	if mcg_id not in unlocked_mcguffins:
		unlocked_mcguffins.append(mcg_id)
	if campaign_run_index < 6:
		highest_unlocked_campaign_run = maxi(highest_unlocked_campaign_run, campaign_run_index + 1)
	campaign_run_completed.emit(campaign_run_index, mcg_id)

func save_campaign_progress() -> Dictionary:
	var mcg_strs: Array = []
	for m in unlocked_mcguffins:
		mcg_strs.append(str(m))
	return {
		"campaign_run_index": campaign_run_index,
		"highest_unlocked_campaign_run": highest_unlocked_campaign_run,
		"unlocked_mcguffins": mcg_strs,
		"character_archetype": str(character_archetype),
		"convergence_active": convergence_active
	}

func load_campaign_progress(data: Dictionary) -> void:
	campaign_run_index = int(data.get("campaign_run_index", 1))
	highest_unlocked_campaign_run = int(data.get("highest_unlocked_campaign_run", 1))
	character_archetype = StringName(data.get("character_archetype", "goblin"))
	convergence_active = bool(data.get("convergence_active", false))
	unlocked_mcguffins.clear()
	var raw_mcg = data.get("unlocked_mcguffins", [])
	if raw_mcg is Array:
		for item in raw_mcg:
			unlocked_mcguffins.append(StringName(str(item)))

