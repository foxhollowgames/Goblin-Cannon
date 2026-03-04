extends Node2D
## Conduit (§6.2). Door + wave timing in sim ticks. Opens gate; Hopper emits ball_entered_board when balls fall out.

signal door_opened
signal door_closed

var _wave_interval_ticks: int = 0
var _open_ticks: int = 0
var _ticks_until_open: int = 0
var _ticks_door_open: int = 0  # elapsed while gate is open; close after _open_ticks
var _hopper: Node
var _board: Node

func _ready() -> void:
	_update_wave_interval_ticks()
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
	_ticks_door_open += 1
	if _ticks_door_open >= _open_ticks:
		_close_door()
		return
	# Balls fall out by physics when gate is open; Hopper emits ball_entered_board when one exits

func _can_release() -> bool:
	if not _board or not _board.has_method("get_active_ball_count"):
		return true
	return _board.get_active_ball_count() < Constants.MAX_ACTIVE_BALLS

func _open_door() -> void:
	_ticks_door_open = 0
	var scale: float = GameState.conduit_open_duration_scale if GameState else 1.0
	_open_ticks = ceili(Constants.OPEN_SECONDS * Constants.SIM_TICKS_PER_SECOND * scale)
	if _hopper and _hopper.has_method("set_gate_open"):
		_hopper.set_gate_open(true)
	door_opened.emit()

func _close_door() -> void:
	if _hopper and _hopper.has_method("set_gate_open"):
		_hopper.set_gate_open(false)
	_update_wave_interval_ticks()
	_ticks_until_open = _wave_interval_ticks
	door_closed.emit()

func _update_wave_interval_ticks() -> void:
	var scale: float = GameState.conduit_wave_interval_scale if GameState else 1.0
	_wave_interval_ticks = ceili(Constants.WAVE_INTERVAL_SECONDS * Constants.SIM_TICKS_PER_SECOND * scale)
