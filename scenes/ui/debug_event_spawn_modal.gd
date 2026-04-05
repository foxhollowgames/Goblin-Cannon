extends Control
## Debug modal: trigger board milestone events and reward flows.

var _coordinator: Node

func setup(coordinator: Node) -> void:
	_coordinator = coordinator
	_build_ui()
	hide()

func show_modal() -> void:
	show()

func hide_modal() -> void:
	hide()

func _build_ui() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.offset_left = 0.0
	dim.offset_top = 0.0
	dim.offset_right = 0.0
	dim.offset_bottom = 0.0
	dim.color = Color(0.02, 0.02, 0.06, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_gui_input)
	add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.14, 0.11, 0.18, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.45, 0.38, 0.55, 1)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = "Spawn / trigger event (debug)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0))
	vbox.add_child(title)

	var hint: Label = Label.new()
	hint.text = "Two board events: milestone peg (shop progress) and treasure chest (passive upgrade draft). Reward rows match normal play."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.7, 0.68, 0.78))
	vbox.add_child(hint)

	vbox.add_child(_make_row_button("Milestone board event", "Preview → timed milestone peg (milestone shop)", "_on_board_milestone"))
	vbox.add_child(_make_row_button("Treasure chest event", "Preview → durable chest peg (onboard passive upgrade draft)", "_on_treasure_chest"))
	vbox.add_child(_make_row_button("Sticky slime event", "Human Kingdom: highlight pegs → sticky coating; other balls wear it down", "_on_sticky_slime"))
	vbox.add_child(_make_row_button("Black hole event", "Elf Palace: preview → black hole pulls balls in; delayed return to hopper", "_on_black_hole"))
	vbox.add_child(_make_row_button("Milestone shop", "Ball/stat/peg draft (gold shop)", "_on_milestone_shop"))
	vbox.add_child(_make_row_button("Wall break reward", "Conquest major-upgrade draft", "_on_wall_break"))
	vbox.add_child(_make_row_button("Boss reward", "Boss amplifier draft", "_on_boss_reward"))

	var close_btn: Button = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, 34)
	close_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_row_button_style(close_btn)
	close_btn.pressed.connect(hide_modal)
	vbox.add_child(close_btn)

func _make_row_button(title_text: String, subtitle: String, handler: StringName) -> VBoxContainer:
	var wrap: VBoxContainer = VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 2)
	var btn: Button = Button.new()
	btn.text = title_text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 32)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_row_button_style(btn)
	var cb: Callable = Callable(self, handler)
	btn.pressed.connect(cb)
	wrap.add_child(btn)
	var sub: Label = Label.new()
	sub.text = subtitle
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.62, 0.58, 0.72))
	wrap.add_child(sub)
	return wrap

func _apply_row_button_style(btn: Button) -> void:
	var st: StyleBoxFlat = StyleBoxFlat.new()
	st.bg_color = Color(0.22, 0.14, 0.2, 0.95)
	st.border_width_left = 1
	st.border_width_right = 1
	st.border_width_top = 1
	st.border_width_bottom = 1
	st.border_color = Color(0.5, 0.35, 0.45, 1)
	st.set_corner_radius_all(4)
	st.content_margin_left = 10
	st.content_margin_right = 10
	btn.add_theme_stylebox_override("normal", st)
	var h: StyleBoxFlat = st.duplicate()
	h.bg_color = Color(0.3, 0.2, 0.28, 0.98)
	btn.add_theme_stylebox_override("hover", h)
	var p: StyleBoxFlat = st.duplicate()
	p.bg_color = Color(0.36, 0.24, 0.32, 1.0)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_font_size_override("font_size", 14)

func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			hide_modal()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		if k.pressed and not k.echo and k.keycode == KEY_ESCAPE:
			hide_modal()
			get_viewport().set_input_as_handled()

func _on_board_milestone() -> void:
	hide_modal()
	if _coordinator and _coordinator.has_method("debug_spawn_board_milestone_event"):
		_coordinator.call_deferred("debug_spawn_board_milestone_event")

func _on_treasure_chest() -> void:
	hide_modal()
	if _coordinator and _coordinator.has_method("debug_spawn_treasure_chest_event"):
		_coordinator.call_deferred("debug_spawn_treasure_chest_event")

func _on_sticky_slime() -> void:
	hide_modal()
	if _coordinator and _coordinator.has_method("debug_spawn_sticky_slime_event"):
		_coordinator.call_deferred("debug_spawn_sticky_slime_event")

func _on_black_hole() -> void:
	hide_modal()
	if _coordinator and _coordinator.has_method("debug_spawn_black_hole_event"):
		_coordinator.call_deferred("debug_spawn_black_hole_event")

func _on_milestone_shop() -> void:
	hide_modal()
	if _coordinator and _coordinator.has_method("debug_trigger_milestone_shop"):
		_coordinator.call_deferred("debug_trigger_milestone_shop")

func _on_wall_break() -> void:
	hide_modal()
	if _coordinator and _coordinator.has_method("debug_trigger_wall_break_reward"):
		_coordinator.call_deferred("debug_trigger_wall_break_reward")

func _on_boss_reward() -> void:
	hide_modal()
	if _coordinator and _coordinator.has_method("debug_trigger_boss_reward"):
		_coordinator.call_deferred("debug_trigger_boss_reward")
