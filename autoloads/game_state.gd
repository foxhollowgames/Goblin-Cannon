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

func _ready() -> void:
	run_seed = randi() if run_seed == 0 else run_seed
	seed(run_seed)

func start_run(new_seed: int = 0) -> void:
	run_seed = new_seed if new_seed != 0 else randi()
	seed(run_seed)
	sim_speed = 1.0
	paused = false
	run_flow_state = RunFlowState.FIGHTING

func set_run_flow_state(state: RunFlowState) -> void:
	run_flow_state = state
	match state:
		RunFlowState.FIGHTING:
			sim_speed = 1.0
			paused = false
		RunFlowState.REWARD_SLOWMO:
			sim_speed = 0.03
			paused = false
		RunFlowState.REWARD_PAUSED:
			paused = true
		RunFlowState.RESUMING:
			pass
