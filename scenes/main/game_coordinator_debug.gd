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

#region Debug Tools UI
## Builds the left panel debug tools button column.
func build_debug_tools_column() -> Control:
	var col: VBoxContainer = VBoxContainer.new()
	col.name = "DebugTools"
	col.position = Vector2(8, 8)
	col.add_theme_constant_override("separation", 4)
	col.process_mode = Node.PROCESS_MODE_ALWAYS
	col.add_child(_build_tool_button("+100 Gold", "Add +100 gold", "_on_add_gold_pressed"))
	col.add_child(_build_tool_button("Merchant", "Trigger merchant shop", "_on_shop_pressed"))
	col.add_child(_build_tool_button("Events", "Spawn board event", "open_debug_event_spawn_modal"))
	col.add_child(_build_tool_button("Full store", "Open item catalog", "open_debug_store_modal"))
	col.add_child(_build_tool_button("Go to city…", "Jump to city/wall", "open_debug_city_jump_modal"))
	return col

func _build_tool_button(text: String, tooltip: String, handler_name: String) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.tooltip_text = tooltip
	btn.custom_minimum_size = Vector2(112, 28)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var st: StyleBoxFlat = StyleBoxFlat.new()
	st.bg_color = MonsterPalette.DEBUG_BTN_BG()
	st.border_width_left = 1
	st.border_width_right = 1
	st.border_width_top = 1
	st.border_width_bottom = 1
	st.border_color = MonsterPalette.DEBUG_BTN_BORDER()
	st.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", st)
	var h: StyleBoxFlat = st.duplicate()
	h.bg_color = MonsterPalette.DEBUG_BTN_HOVER()
	btn.add_theme_stylebox_override("hover", h)
	var p: StyleBoxFlat = st.duplicate()
	p.bg_color = MonsterPalette.RUST().lerp(MonsterPalette.WARM_BROWN(), 0.25)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_font_size_override("font_size", 13)
	if has_method(handler_name):
		btn.pressed.connect(Callable(self, handler_name))
	elif _coordinator_root and _coordinator_root.has_method(handler_name):
		btn.pressed.connect(Callable(_coordinator_root, handler_name))
	return btn

func _on_add_gold_pressed() -> void:
	if GameState:
		GameState.add_run_gold(100)

func _on_shop_pressed() -> void:
	if _coordinator_root and _coordinator_root.has_method("debug_trigger_milestone_shop"):
		_coordinator_root.debug_trigger_milestone_shop()
#region Debug Modal UI Creation
## Instantiates debug event spawn modal overlay layer.
func create_debug_event_spawn_ui(main: Node) -> Control:
	if not main:
		return null
	var event_layer: CanvasLayer = CanvasLayer.new()
	event_layer.layer = 11
	event_layer.name = "DebugEventSpawnLayer"
	event_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(event_layer)
	var modal_script: GDScript = load("res://scenes/ui/debug_event_spawn_modal.gd") as GDScript
	if not modal_script:
		return null
	var modal: Control = modal_script.new() as Control
	event_layer.add_child(modal)
	if modal.has_method("setup"):
		modal.setup(_coordinator_root)
	return modal

## Instantiates debug full store modal overlay layer.
func create_debug_full_store_ui(main: Node, reward_handler: Node) -> Control:
	if not main:
		return null
	var store_layer: CanvasLayer = CanvasLayer.new()
	store_layer.layer = 12
	store_layer.name = "DebugFullStoreLayer"
	store_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(store_layer)
	var store_script: GDScript = load("res://scenes/ui/debug_full_store_modal.gd") as GDScript
	if not store_script:
		return null
	var modal: Control = store_script.new() as Control
	store_layer.add_child(modal)
	if modal.has_method("setup"):
		modal.setup(_coordinator_root, reward_handler)
	return modal

## Instantiates debug city jump modal overlay layer.
func create_debug_city_jump_ui(main: Node) -> Control:
	if not main:
		return null
	var jump_layer: CanvasLayer = CanvasLayer.new()
	jump_layer.layer = 13
	jump_layer.name = "DebugCityJumpLayer"
	jump_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(jump_layer)
	var jump_script: GDScript = load("res://scenes/ui/debug_city_jump_modal.gd") as GDScript
	if not jump_script:
		return null
	var modal: Control = jump_script.new() as Control
	jump_layer.add_child(modal)
	if modal.has_method("setup"):
		modal.setup(_coordinator_root)
	return modal
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





