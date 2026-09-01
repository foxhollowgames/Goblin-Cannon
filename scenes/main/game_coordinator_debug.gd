extends Node
## Debug tools, test scenario overrides, and debug modal handlers for GameCoordinator.

#region State and References
var _coordinator_root: Node = null
#endregion

#region Initialization
## Initializes debug manager with root GameCoordinator reference.
func setup(coordinator_root: Node) -> void:
	_coordinator_root = coordinator_root
#endregion

#region Debug Modals API
## Opens the debug event spawn modal.
func open_debug_event_spawn_modal() -> void:
	_open_modal_by_name("DebugEventSpawnModal")

## Opens the debug full store modal.
func open_debug_store_modal() -> void:
	_open_modal_by_name("DebugFullStoreModal")

## Opens the debug city jump modal.
func open_debug_city_jump_modal() -> void:
	_open_modal_by_name("DebugCityJumpModal")

## Applies TestScenario autoload overrides if enabled.
func apply_test_scenario_overrides() -> void:
	if TestScenario and TestScenario.enabled:
		if _coordinator_root and _coordinator_root.has_method("_apply_test_scenario"):
			_coordinator_root._apply_test_scenario()

#region Helper Methods
func _open_modal_by_name(modal_name: String) -> void:
	if not _coordinator_root:
		return
	var modal: Node = _coordinator_root.find_child(modal_name, true, false)
	if modal:
		if modal.has_method("show_modal"):
			modal.show_modal()
		elif modal.has_method("show"):
			modal.show()
#endregion
#endregion


