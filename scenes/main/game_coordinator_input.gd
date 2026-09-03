class_name GameCoordinatorInput
extends Node
## Keybinding and shortcut key manager for GameCoordinator.

#region State and References
var _coordinator_root: Node = null
#endregion

#region Initialization
## Initializes input manager with reference to root GameCoordinator node.
func setup(coordinator_root: Node) -> void:
	_coordinator_root = coordinator_root
#endregion

#region Input Handling API
## Handles unhandled input events for shortcut keys (debug overlay, inventory, pause, almanac).
func handle_unhandled_input(event: InputEvent) -> void:
	if not _coordinator_root or not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var vp: Viewport = _coordinator_root.get_viewport()
	if key_event.keycode == KEY_F3 or key_event.keycode == KEY_QUOTELEFT:
		if _coordinator_root.has_method("_toggle_debug_overlay"):
			_coordinator_root._toggle_debug_overlay()
		if vp:
			vp.set_input_as_handled()
	elif key_event.keycode == KEY_I or key_event.keycode == KEY_B:
		if _coordinator_root.has_method("_toggle_junk_box"):
			_coordinator_root._toggle_junk_box()
		if vp:
			vp.set_input_as_handled()
	elif key_event.keycode == KEY_ESCAPE:
		if _coordinator_root.has_method("_handle_escape_key"):
			_coordinator_root._handle_escape_key()
		if vp:
			vp.set_input_as_handled()
	elif key_event.keycode == KEY_L or key_event.keycode == KEY_TAB:
		if _coordinator_root.has_method("_on_almanac_pressed"):
			_coordinator_root._on_almanac_pressed()
		if vp:
			vp.set_input_as_handled()
	elif key_event.keycode == KEY_P:
		if _coordinator_root.has_method("_toggle_pause_state"):
			_coordinator_root._toggle_pause_state()
		if vp:
			vp.set_input_as_handled()
#endregion

