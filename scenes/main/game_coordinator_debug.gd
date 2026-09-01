class_name GameCoordinatorDebug
extends Node
## Debug tools, test scenario overrides, and debug modal handlers for GameCoordinator.

#region State and References
@export var _coordinator_root: Node = null
var _event_spawn_modal: Control = null
var _full_store_modal: Control = null
var _city_jump_modal: Control = null
#endregion

#region Initialization
## Initializes debug manager with root GameCoordinator reference.
func setup(coordinator_root: Node) -> void:
	_coordinator_root = coordinator_root
#endregion

#region Debug Modals API
## Opens the debug event spawn modal.
func open_debug_event_spawn_modal() -> void:
	if _event_spawn_modal:
		_event_spawn_modal.show_modal()
	else:
		_open_modal_by_name("DebugEventSpawnModal")

## Opens the debug full store modal.
func open_debug_store_modal() -> void:
	if _full_store_modal:
		_full_store_modal.show_modal()
	else:
		_open_modal_by_name("DebugFullStoreModal")

## Opens the debug city jump modal.
func open_debug_city_jump_modal() -> void:
	if _city_jump_modal:
		_city_jump_modal.show_modal()
	else:
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
#endregion

#region Debug Modal UI Creation
## Instantiates all debug modals.
func create_all_debug_modals(main: Node, reward_handler: Node) -> Dictionary:
	var modals: Dictionary = {}
	_event_spawn_modal = create_debug_event_spawn_ui(main)
	modals["event_spawn_modal"] = _event_spawn_modal
	_full_store_modal = create_debug_full_store_ui(main, reward_handler)
	modals["full_store_modal"] = _full_store_modal
	_city_jump_modal = create_debug_city_jump_ui(main)
	modals["city_jump_modal"] = _city_jump_modal
	return modals

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
#endregion

#region Debug Event Triggers
## Triggers immediate milestone board event spawn if valid.
func debug_spawn_board_milestone_event(board: Node) -> void:
	var bec: Node = board.get_node_or_null("BoardEventController") if board else null
	if bec and bec.has_method("debug_arm_immediate_spawn"):
		if not bec.debug_arm_immediate_spawn():
			push_warning("Debug: milestone board event not armed.")

## Triggers immediate treasure chest event spawn if valid.
func debug_spawn_treasure_chest_event(board: Node) -> void:
	var tcc: Node = board.get_node_or_null("TreasureChestController") if board else null
	if tcc and tcc.has_method("debug_arm_immediate_spawn"):
		if not tcc.debug_arm_immediate_spawn():
			push_warning("Debug: treasure chest event not armed.")

## Triggers immediate sticky slime event spawn if valid.
func debug_spawn_sticky_slime_event(board: Node) -> void:
	var ssc: Node = board.get_node_or_null("StickySlimeController") if board else null
	if ssc and ssc.has_method("debug_arm_immediate_spawn"):
		if not ssc.debug_arm_immediate_spawn():
			push_warning("Debug: sticky slime event not armed.")

## Debug: set city index and wall index (0 = World 1), refresh combat and UI; does not reset run inventory/upgrades.
static func jump_to_city_and_wall(c: Node, city_index: int, wall_index: int) -> void:
	var main: Node = c.get_parent()
	if main:
		var vo: Node = main.get_node_or_null("VictoryOverlay")
		if vo:
			vo.queue_free()
		var fo: Node = main.get_node_or_null("FailOverlay")
		if fo:
			fo.queue_free()
	GameState.paused = false
	Engine.time_scale = 1.0
	c.get_tree().paused = false
	c._game_over = false
	c._victory = false
	c._fail_screen = null
	if c._rewards_manager and c._rewards_manager.has_method("debug_discard_open_reward_ui"):
		c._rewards_manager.debug_discard_open_reward_ui()
	if c._debug_event_spawn_modal and c._debug_event_spawn_modal.has_method("hide_modal"):
		c._debug_event_spawn_modal.hide_modal()
	if c._debug_full_store_modal and c._debug_full_store_modal.has_method("hide_modal"):
		c._debug_full_store_modal.hide_modal()
	GameState.endless_mode = false
	GameState.current_city_id = clampi(city_index, 0, Constants.CITY_DEFINITION_PATHS.size() - 1)
	var city: CityDefinition = GameState.get_current_city_definition()
	if city == null:
		return
	if c._combat_manager and c._combat_manager.has_method("init_from_city_at_wall"):
		c._combat_manager.init_from_city_at_wall(city, wall_index)
	if c._milestone_tracker and c._milestone_tracker.has_method("set_thresholds_from_city"):
		c._milestone_tracker.set_thresholds_from_city(city.get_milestone_thresholds_int())
	c._refresh_conquest_ui()
	c._sync_battlefield_wall_index()
	GameState.set_run_flow_state(GameState.RunFlowState.FIGHTING)

## Triggers milestone shop reward modal.
static func debug_trigger_milestone_shop(c: Node) -> void:
	if not c._game_over and not c._victory and c._rewards_manager and c._rewards_manager.has_method("on_milestone_reached"):
		c._rewards_manager.on_milestone_reached(0, 0)

## Triggers wall break reward modal.
static func debug_trigger_wall_break_reward(c: Node) -> void:
	if not c._game_over and not c._victory and c._rewards_manager and c._rewards_manager.has_method("on_wall_break"):
		c._rewards_manager.on_wall_break()

## Triggers boss reward modal.
static func debug_trigger_boss_reward(c: Node) -> void:
	if not c._game_over and not c._victory and c._rewards_manager and c._rewards_manager.has_method("on_boss_reward"):
		c._rewards_manager.on_boss_reward()
#endregion

func _open_modal_by_name(modal_name: String) -> void:
	if not _coordinator_root:
		return
	var main: Node = _coordinator_root.get_parent()
	var modal: Node = null
	if main:
		modal = main.find_child(modal_name, true, false)
	if not modal:
		modal = _coordinator_root.find_child(modal_name, true, false)
	if modal:
		if modal.has_method("show_modal"):
			modal.show_modal()
		elif modal.has_method("show"):
			modal.show()

