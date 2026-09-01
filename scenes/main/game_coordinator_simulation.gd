class_name GameCoordinatorSimulation
extends Node
## Per-sim-tick accumulator and physics tick runner for GameCoordinator.

#region State and References
var _coordinator_root: Node = null
#endregion

#region Initialization
## Initializes simulation manager with reference to root GameCoordinator node.
func setup(coordinator_root: Node) -> void:
	_coordinator_root = coordinator_root
#endregion

## Advances fixed sim step accumulator and runs sim tick loop.
static func physics_process(c: Node, delta: float) -> void:
	if c.get_tree().paused:
		return
	if GameState.paused:
		return
	if c._game_over or c._victory:
		return
	c._sim_accumulator += delta * GameState.sim_speed * float(Constants.SIM_TICKS_PER_SECOND)
	var max_steps: int = 4
	while c._sim_accumulator >= 1.0 and max_steps > 0:
		run_one_sim_tick(c)
		c._sim_accumulator -= 1.0
		max_steps -= 1
	GameState.sim_step_alpha = clampf(c._sim_accumulator, 0.0, 1.0)

## Executes one simulation tick across hopper, conduit, board, systems, and combat manager.
static func run_one_sim_tick(c: Node) -> void:
	c._sim_tick += 1
	if c._hopper and c._hopper.has_method("get_stored_ball_count") and c._hopper.get_stored_ball_count() < c.HOPPER_MAX_BALLS and not c._bag_queue.is_empty():
		var gate_open: bool = c._hopper.is_gate_open() if c._hopper.has_method("is_gate_open") else false
		if not gate_open and c._hopper.has_method("add_balls_with_definition"):
			var next_def: Resource = c._bag_queue.pop_front()
			c._hopper.add_balls_with_definition(1, next_def)
	if c._conduit and c._conduit.has_method("request_ball"):
		c._conduit.request_ball()
	if c._board and c._board.has_method("run_ball_steps"):
		c._board.run_ball_steps(c._sim_tick)
	if c._board and c._board.has_method("flush_tick"):
		c._board.flush_tick(c._sim_tick)
	if c._systems_container:
		for child in c._systems_container.get_children():
			if child.has_method("sim_tick"):
				child.sim_tick(c._sim_tick)
	if c._combat_manager and c._combat_manager.has_method("sim_tick"):
		c._combat_manager.sim_tick(c._sim_tick)
	c._update_center_ui()


