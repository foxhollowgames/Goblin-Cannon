extends Control
## Debug modal: jump to any city and wall ("world") without reloading the scene.

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
	panel.custom_minimum_size = Vector2(420, 0)
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

	var outer: VBoxContainer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)

	var title: Label = Label.new()
	title.text = "Go to city & world (debug)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0))
	outer.add_child(title)

	var hint: Label = Label.new()
	hint.text = "Instantly sets GameState city, combat wall index, timer, and UI. Closes reward drafts and victory/fail overlays. Does not reset your balls or upgrades."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.7, 0.68, 0.78))
	outer.add_child(hint)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 320)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for cidx in range(Constants.CITY_DEFINITION_PATHS.size()):
		var path: String = Constants.CITY_DEFINITION_PATHS[cidx]
		var res: Resource = load(path) as Resource
		if not res is CityDefinition:
			continue
		var city: CityDefinition = res as CityDefinition
		var wall_names: Array = city.get_effective_wall_names()
		for w in range(wall_names.size()):
			var gate: String = str(wall_names[w])
			var row_title: String = "%s — World %d" % [city.display_name, w + 1]
			list.add_child(_make_row_button(row_title, gate, cidx, w))

	var close_btn: Button = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, 34)
	close_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_row_button_style(close_btn)
	close_btn.pressed.connect(hide_modal)
	outer.add_child(close_btn)

func _make_row_button(title_text: String, subtitle: String, city_index: int, wall_index: int) -> VBoxContainer:
	var wrap: VBoxContainer = VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 2)
	var btn: Button = Button.new()
	btn.text = title_text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 30)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_row_button_style(btn)
	btn.pressed.connect(_on_jump_pressed.bind(city_index, wall_index))
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
	st.border_color = Color(0.4, 0.32, 0.45, 1)
	st.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", st)
	var h: StyleBoxFlat = st.duplicate()
	h.bg_color = Color(0.3, 0.2, 0.28, 0.98)
	btn.add_theme_stylebox_override("hover", h)
	var p: StyleBoxFlat = st.duplicate()
	p.bg_color = Color(0.35, 0.24, 0.32, 1)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_font_size_override("font_size", 13)

func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_modal()

func _on_jump_pressed(city_index: int, wall_index: int) -> void:
	if _coordinator and _coordinator.has_method("debug_jump_to_city_and_wall"):
		_coordinator.call_deferred("debug_jump_to_city_and_wall", city_index, wall_index)
	hide_modal()
