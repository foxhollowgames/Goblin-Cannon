extends Node2D
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
	if not _coordinator_root:
		return
	var modal: Node = _coordinator_root.get_node_or_null("UI/DebugEventSpawnModal")
	if modal and modal.has_method("open_modal"):
		modal.open_modal()

## Opens the debug full store modal.
func open_debug_store_modal() -> void:
	if not _coordinator_root:
		return
	var modal: Node = _coordinator_root.get_node_or_null("UI/DebugFullStoreModal")
	if modal and modal.has_method("open_modal"):
		modal.open_modal()

## Opens the debug city jump modal.
func open_debug_city_jump_modal() -> void:
	if not _coordinator_root:
		return
	var modal: Node = _coordinator_root.get_node_or_null("UI/DebugCityJumpModal")
	if modal and modal.has_method("open_modal"):
		modal.open_modal()

## Applies TestScenario autoload overrides if enabled.
func apply_test_scenario_overrides() -> void:
	if TestScenario and TestScenario.enabled:
		if _coordinator_root and _coordinator_root.has_method("_apply_test_scenario"):
			_coordinator_root._apply_test_scenario()
#endregion

