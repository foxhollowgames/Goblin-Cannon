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

#region Physics Step Execution
## Runs physics accumulator iteration for one frame.
func physics_process(delta: float) -> void:
	if not _coordinator_root:
		return
	if _coordinator_root.has_method("_process_sim_accumulator"):
		_coordinator_root._process_sim_accumulator(delta)
#endregion


