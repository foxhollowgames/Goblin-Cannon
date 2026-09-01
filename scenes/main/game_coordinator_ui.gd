class_name GameCoordinatorUI
extends Node
## UI element creation, modals (inventory, almanac, junk box), and debug overlays for GameCoordinator.

#region State and References
var _coordinator_root: Node = null
var _inventory_modal: Control = null
var _almanac_modal: Control = null
var _junk_box_modal: Control = null
var _debug_overlay: Control = null
#endregion

#region Initialization
## Initializes UI manager with reference to root GameCoordinator node.
func setup(coordinator_root: Node) -> void:
	_coordinator_root = coordinator_root
#endregion

#region UI Creation API
## Creates and attaches the inventory UI panel.
func create_inventory_ui() -> void:
	if not _coordinator_root:
		return
	if _coordinator_root.has_method("_create_inventory_ui_internal"):
		_coordinator_root._create_inventory_ui_internal()

## Creates and attaches the debug overlay panel.
func create_debug_overlay() -> void:
	if not _coordinator_root:
		return
	if _coordinator_root.has_method("_create_debug_overlay_internal"):
		_coordinator_root._create_debug_overlay_internal()
#endregion

#region Modal Toggles
## Toggles visibility of the inventory modal panel.
func toggle_inventory_modal() -> void:
	if _coordinator_root and _coordinator_root.has_method("_toggle_inventory_modal"):
		_coordinator_root._toggle_inventory_modal()

## Toggles visibility of the almanac modal panel.
func toggle_almanac_modal() -> void:
	if _coordinator_root and _coordinator_root.has_method("_toggle_almanac_modal"):
		_coordinator_root._toggle_almanac_modal()

## Toggles visibility of the junk box modal panel.
func toggle_junk_box_modal() -> void:
	if _coordinator_root and _coordinator_root.has_method("_toggle_junk_box_modal"):
		_coordinator_root._toggle_junk_box_modal()
#endregion

