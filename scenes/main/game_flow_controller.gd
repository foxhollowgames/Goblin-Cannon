class_name GameFlowController
extends Node
## City progression, wall transitions, title cards, and campaign game state handlers for GameCoordinator.

#region Signals
signal wall_advanced(city_index: int, wall_index: int)
signal city_completed(city_index: int)
signal campaign_failed()
#endregion

#region State and References
var _current_city_index: int = 0
var _current_wall_index: int = 0
var _coordinator_root: Node = null
#endregion

#region Initialization
## Initializes flow controller with root GameCoordinator reference.
func setup(coordinator_root: Node) -> void:
	_coordinator_root = coordinator_root

## Returns the current active city index.
func get_current_city_index() -> int:
	return _current_city_index

## Returns the current active wall index.
func get_current_wall_index() -> int:
	return _current_wall_index
#endregion

#region Campaign Flow API
## Starts a city campaign by index.
func start_city(city_index: int) -> void:
	_current_city_index = city_index
	_current_wall_index = 0
	if _coordinator_root and _coordinator_root.has_method("_init_from_current_city"):
		_coordinator_root._init_from_current_city()

## Advances to the next wall in the active city.
func advance_to_next_wall() -> void:
	_current_wall_index += 1
	wall_advanced.emit(_current_city_index, _current_wall_index)

## Shows the victory screen and triggers city completion.
func show_victory_screen() -> void:
	city_completed.emit(_current_city_index)
	if _coordinator_root and _coordinator_root.has_method("_show_victory_screen"):
		_coordinator_root._show_victory_screen()

## Shows the run failure screen on time expiry or defeat.
func show_fail_screen() -> void:
	campaign_failed.emit()
	if _coordinator_root and _coordinator_root.has_method("_show_fail_screen"):
		_coordinator_root._show_fail_screen()
#endregion



