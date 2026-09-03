extends Node2D
## Per-tick ball step simulation, exit processing, split twin spawning, and active ball array management for Board.

#region Signals
signal ball_exited_board(ball: Node, reason: int)
signal ball_reached_bottom(ball_id: int, total_energy_display: int, alignment: int, exit_position: Vector2, status_effects: Dictionary)
#endregion

#region Constants
const REASON_BOTTOM: int = 0
const REASON_STALL: int = 1
const REASON_OFF_SCREEN: int = 2
const REASON_VOLATILE_BREAK: int = 3
const REASON_BLACK_HOLE: int = 4

const BOTTOM_ZONE_Y: float = 710.0
const OFF_SCREEN_Y: float = 730.0
const OFF_SCREEN_X_LEFT: float = -20.0
const OFF_SCREEN_X_RIGHT: float = 980.0
#endregion

#region State & References
var _active_balls: Array[Node] = []
var _next_split_ball_id: int = 100000
var _board_root: Node2D = null
#endregion

#region Initialization
## Sets up the ball runner manager with reference to root Board node.
func setup(board_root: Node2D) -> void:
	_board_root = board_root

## Registers an active ball node with the runner.
func register_ball(ball: Node) -> void:
	if ball and is_instance_valid(ball) and not _active_balls.has(ball):
		_active_balls.append(ball)

## Unregisters a ball node when removed from play.
func unregister_ball(ball: Node) -> void:
	_active_balls.erase(ball)

## Returns an array of all currently active ball nodes on the board.
func get_active_balls() -> Array[Node]:
	var valid_balls: Array[Node] = []
	for ball in _active_balls:
		if ball and is_instance_valid(ball):
			valid_balls.append(ball)
	return valid_balls
#endregion

#region Ball Lifecycle API
## Removes a ball from active simulation array and frees its scene node.
func remove_ball(ball: Node) -> void:
	unregister_ball(ball)
	if ball and is_instance_valid(ball):
		ball.queue_free()

## Clears all active balls from the board.
func clear_all_balls() -> void:
	for ball in _active_balls.duplicate():
		remove_ball(ball)
	_active_balls.clear()
#endregion

