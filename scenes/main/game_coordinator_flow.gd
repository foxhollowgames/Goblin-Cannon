class_name GameCoordinatorFlow
extends Node
## Static helper class for GameCoordinator wall break, boss reward transitions, and end screen flows.

## Initiates wall destroyed transition and schedules timer for transition end.
static func handle_wall_destroyed(c: Node) -> void:
	c._wall_break_is_last_wall = false
	if c._combat_manager and c._combat_manager.has_method("get_current_wall_index") and c._combat_manager.has_method("get_wall_names"):
		var idx: int = c._combat_manager.get_current_wall_index()
		var names: Array = c._combat_manager.get_wall_names()
		c._wall_break_is_last_wall = (idx >= names.size() - 1)
	if c._hopper and c._hopper.has_method("set_gate_open"):
		c._hopper.set_gate_open(false)
	GameState.set_run_flow_state(GameState.RunFlowState.WALL_BREAK_TRANSITION)
	if c._battlefield and c._battlefield.has_method("play_wall_destroyed_transition"):
		c._battlefield.play_wall_destroyed_transition()
	if c._center_panel_ui and c._center_panel_ui.has_method("animate_wall_cleared"):
		c._center_panel_ui.animate_wall_cleared()
	c.get_tree().create_timer(2.2).timeout.connect(c._on_wall_break_transition_finished)

## Dispatches next reward or boss transition when wall destroyed animation ends.
static func handle_wall_break_transition_finished(c: Node) -> void:
	if c._wall_break_is_last_wall and c._rewards_manager:
		if GameState.endless_mode and c._rewards_manager.has_method("on_wall_break"):
			c._rewards_manager.on_wall_break()
		elif c._rewards_manager.has_method("on_boss_reward"):
			c._rewards_manager.on_boss_reward()
	elif c._rewards_manager and c._rewards_manager.has_method("on_wall_break"):
		c._rewards_manager.on_wall_break()

## Advances to next wall and shows title card after wall break reward completes.
static func handle_wall_break_reward_completed(c: Node) -> void:
	if c._combat_manager and c._combat_manager.has_method("advance_to_next_wall"):
		c._combat_manager.advance_to_next_wall()
	c._refresh_conquest_ui()
	c._sync_battlefield_wall_index()
	GameState.set_run_flow_state(GameState.RunFlowState.WALL_BREAK_TRANSITION)
	var wall_name: String = ""
	if c._combat_manager and c._combat_manager.has_method("get_current_gate_name"):
		wall_name = c._combat_manager.get_current_gate_name()
	if wall_name.is_empty():
		wall_name = "Next Wall"
	c._show_wall_title_card(wall_name, "", c._begin_next_wall_intro)

## Advances city or triggers victory screen when boss reward completes.
static func handle_boss_reward_completed(c: Node) -> void:
	var is_last_city: bool = (GameState.current_city_id >= Constants.CITY_DEFINITION_PATHS.size() - 1)
	if is_last_city:
		c._victory = true
		c._show_victory_screen()
		return
	if c._combat_manager and c._combat_manager.has_method("advance_to_next_wall"):
		c._combat_manager.advance_to_next_wall()
	GameState.current_city_id += 1
	c._init_from_current_city()
	c._refresh_conquest_ui()
	c._sync_battlefield_wall_index()
	GameState.set_run_flow_state(GameState.RunFlowState.WALL_BREAK_TRANSITION)
	var city_name: String = ""
	if c._combat_manager and c._combat_manager.has_method("get_city_display_name"):
		city_name = c._combat_manager.get_city_display_name()
	if city_name.is_empty():
		city_name = "New Territory"
	var wall_name: String = ""
	if c._combat_manager and c._combat_manager.has_method("get_current_gate_name"):
		wall_name = c._combat_manager.get_current_gate_name()
	c._show_wall_title_card(city_name, wall_name, c._begin_next_wall_intro)

## Instantiates and displays fail overlay screen.
static func show_fail_screen(c: Node) -> void:
	GameState.paused = true
	c._fail_screen = c._build_end_screen("TIME'S UP!", MonsterPalette.RUST(), "Restart")
	var main: Node = c.get_parent()
	if main:
		var overlay: CanvasLayer = CanvasLayer.new()
		overlay.layer = 20
		overlay.name = "FailOverlay"
		main.add_child(overlay)
		overlay.add_child(c._fail_screen)

## Instantiates and displays victory overlay screen.
static func show_victory_screen(c: Node) -> void:
	GameState.paused = true
	var screen: Control = c._build_victory_screen()
	var main: Node = c.get_parent()
	if main:
		var overlay: CanvasLayer = CanvasLayer.new()
		overlay.layer = 20
		overlay.name = "VictoryOverlay"
		main.add_child(overlay)
		overlay.add_child(screen)

## Enters endless mode and starts endless wave 1.
static func handle_endless_mode_pressed(c: Node) -> void:
	var main: Node = c.get_parent()
	if main:
		var overlay: Node = main.get_node_or_null("VictoryOverlay")
		if overlay:
			overlay.queue_free()
	GameState.paused = false
	c._victory = false
	GameState.endless_mode = true
	if c._combat_manager and c._combat_manager.has_method("start_endless_wave"):
		c._combat_manager.start_endless_wave(1)
	c._refresh_conquest_ui()
	c._sync_battlefield_wall_index()
	GameState.set_run_flow_state(GameState.RunFlowState.WALL_BREAK_TRANSITION)
	c._show_wall_title_card("Endless Mode", "Wave 1", c._begin_next_wall_intro)
