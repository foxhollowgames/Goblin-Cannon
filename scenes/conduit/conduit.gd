extends Node2D
## Conduit (§6.2). Door + wave timing in sim ticks. request_ball() -> emits ball_entered_board.

signal ball_entered_board(ball: Node)
signal door_opened
signal door_closed

var _wave_interval_ticks: int = 0
var _open_ticks: int = 0
var _ticks_until_open: int = 0
var _balls_to_release: int = 0
var _hopper: Node
var _board: Node

func _ready() -> void:
	_wave_interval_ticks = ceili(Constants.WAVE_INTERVAL_SECONDS * Constants.SIM_TICKS_PER_SECOND)
	_open_ticks = ceili(Constants.OPEN_SECONDS * Constants.SIM_TICKS_PER_SECOND)
	_ticks_until_open = 1  # First wave after 1 tick so something is visible immediately
	var main: Node = get_parent()
	_hopper = main.get_node_or_null("Hopper")
	_board = main.get_node_or_null("Board")

func request_ball() -> void:
	if not _can_release():
		return
	if _ticks_until_open > 0:
		_ticks_until_open -= 1
		if _ticks_until_open == 0:
			_open_door()
		return
	if _balls_to_release <= 0:
		return
	var ball: Node = _hopper.release_next_ball() if _hopper else null
	if ball:
		_balls_to_release -= 1
		ball_entered_board.emit(ball)
		if _balls_to_release <= 0:
			_close_door()

func _can_release() -> bool:
	if not _board or not _board.has_method("get_active_ball_count"):
		return true
	return _board.get_active_ball_count() < Constants.MAX_ACTIVE_BALLS

func _open_door() -> void:
	_balls_to_release = Constants.CONDUIT_SIZE
	door_opened.emit()

func _close_door() -> void:
	_ticks_until_open = _wave_interval_ticks
	door_closed.emit()
