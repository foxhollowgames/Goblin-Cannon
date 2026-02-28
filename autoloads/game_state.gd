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
