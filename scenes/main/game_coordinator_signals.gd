class_name GameCoordinatorSignals
extends Node
## Signal wiring and event dispatcher helper for GameCoordinator.

#region State and References
var _coordinator_root: Node = null
#endregion

#region Initialization
## Initializes signals manager with reference to root GameCoordinator node.
func setup(coordinator_root: Node) -> void:
	_coordinator_root = coordinator_root

## Wires child component signals to coordinator event handlers.
func wire_signals() -> void:
	if not _coordinator_root:
		return
	if _coordinator_root.has_method("_wire_all_signals"):
		_coordinator_root._wire_all_signals()
#endregion

#region Event Handlers API
## Dispatches peg hit events.
func on_peg_hit(peg: Node, ball: Node) -> void:
	if _coordinator_root and _coordinator_root.has_method("_on_peg_hit"):
		_coordinator_root._on_peg_hit(peg, ball)

## Dispatches ball exited events.
func on_ball_exited(ball: Node) -> void:
	if _coordinator_root and _coordinator_root.has_method("_on_ball_exited"):
		_coordinator_root._on_ball_exited(ball)

## Dispatches milestone reached events.
func on_milestone_reached(milestone_index: int) -> void:
	if _coordinator_root and _coordinator_root.has_method("_on_milestone_reached"):
		_coordinator_root._on_milestone_reached(milestone_index)
#endregion

