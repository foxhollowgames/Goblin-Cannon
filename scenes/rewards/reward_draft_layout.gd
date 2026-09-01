class_name RewardDraftLayout
extends RefCounted
## Static styling and UI container builders for RewardDraftPanel cards.

static func create_card_style(border_color: Color, is_purchased: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if is_purchased:
		style.bg_color = Color(0.04, 0.04, 0.05, 0.8)
		style.border_color = Color(0.2, 0.2, 0.2, 0.5)
	else:
		style.bg_color = Color(0.08, 0.07, 0.1, 1)
		style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(6)
	return style

static func build_modal_panel_style() -> StyleBoxFlat:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.1, 0.16, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.5, 0.45, 0.6, 1)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	return panel_style

static func build_done_button_styles() -> Dictionary:
	var done_normal: StyleBoxFlat = StyleBoxFlat.new()
	done_normal.bg_color = Color(0.72, 0.52, 0.12, 1)
	done_normal.border_width_left = 3
	done_normal.border_width_right = 3
	done_normal.border_width_top = 3
	done_normal.border_width_bottom = 3
	done_normal.border_color = Color(0.95, 0.78, 0.25, 1)
	done_normal.set_corner_radius_all(10)
	done_normal.content_margin_left = 24
	done_normal.content_margin_right = 24
	done_normal.content_margin_top = 10
	done_normal.content_margin_bottom = 10

	var done_hover: StyleBoxFlat = done_normal.duplicate()
	done_hover.bg_color = Color(0.82, 0.62, 0.18, 1)

	var done_pressed: StyleBoxFlat = done_normal.duplicate()
	done_pressed.bg_color = Color(0.55, 0.38, 0.08, 1)
	done_pressed.border_color = Color(0.85, 0.68, 0.2, 1)

	return {
		"normal": done_normal,
		"hover": done_hover,
		"pressed": done_pressed
	}

static func build_show_rewards_button_styles() -> Dictionary:
	var show_style: StyleBoxFlat = StyleBoxFlat.new()
	show_style.bg_color = Color(0.14, 0.1, 0.2, 0.95)
	show_style.border_width_left = 2
	show_style.border_width_right = 2
	show_style.border_width_top = 2
	show_style.border_width_bottom = 2
	show_style.border_color = Color(0.55, 0.45, 0.75, 1)
	show_style.set_corner_radius_all(6)

	var show_hover: StyleBoxFlat = show_style.duplicate()
	show_hover.bg_color = Color(0.22, 0.16, 0.32, 0.98)

	return {
		"normal": show_style,
		"hover": show_hover
	}

static func shop_kill_hover_tween(root: Control) -> void:
	if root and root.has_meta("hover_tween"):
		var tw: Tween = root.get_meta("hover_tween") as Tween
		if tw and is_instance_valid(tw):
			tw.kill()
		root.remove_meta("hover_tween")

static func create_rarity_marker(rarity: int) -> Control:
	var shape_control: Control = Control.new()
	shape_control.set_script(load("res://scenes/ui/rarity_shape_control.gd") as GDScript)
	shape_control.set("rarity", rarity)
	return shape_control

static func wire_shop_offer_interactions(col: Control, index: int, can_interact_cb: Callable, on_pick_cb: Callable, hover_scale: float, hover_sec: float) -> void:
	col.mouse_filter = Control.MOUSE_FILTER_STOP
	col.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	col.resized.connect(func() -> void:
		col.pivot_offset = col.size * 0.5
	)
	col.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				on_pick_cb.call(index)
	)
	col.mouse_entered.connect(func() -> void:
		if not can_interact_cb.call(index):
			return
		col.pivot_offset = col.size * 0.5
		shop_kill_hover_tween(col)
		var tw: Tween = col.create_tween()
		tw.set_ignore_time_scale(true)
		col.set_meta("hover_tween", tw)
		tw.tween_property(col, "scale", Vector2(hover_scale, hover_scale), hover_sec).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		col.z_index = 1
	)
	col.mouse_exited.connect(func() -> void:
		shop_kill_hover_tween(col)
		var tw: Tween = col.create_tween()
		tw.set_ignore_time_scale(true)
		col.set_meta("hover_tween", tw)
		tw.tween_property(col, "scale", Vector2(1.0, 1.0), hover_sec)
		col.z_index = 0
	)

static func setup_modal_contents(modal_panel: PanelContainer, on_refresh: Callable, on_hide: Callable, on_done: Callable, shop_rows_sep: int) -> Dictionary:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	modal_panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	var title: Label = Label.new()
	title.text = "Merchant"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var gold_label: Label = Label.new()
	gold_label.text = "Gold: 0"
	gold_label.add_theme_font_size_override("font_size", 18)
	gold_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35, 1))
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(gold_label)
	var refresh_btn: Button = Button.new()
	refresh_btn.text = "Refresh (%d gold)" % Constants.SHOP_REFRESH_COST
	refresh_btn.tooltip_text = "Reroll merchant offers for %d gold." % Constants.SHOP_REFRESH_COST
	refresh_btn.pressed.connect(on_refresh)
	title_row.add_child(refresh_btn)
	var hide_btn: Button = Button.new()
	hide_btn.text = "Hide"
	hide_btn.tooltip_text = "Hide the merchant screen to inspect the board. Press I to open Inventory."
	hide_btn.pressed.connect(on_hide)
	title_row.add_child(hide_btn)
	vbox.add_child(title_row)
	var rows_vbox: VBoxContainer = VBoxContainer.new()
	rows_vbox.add_theme_constant_override("separation", shop_rows_sep)
	vbox.add_child(rows_vbox)
	var top_center: CenterContainer = CenterContainer.new()
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_center.add_child(top_row)
	rows_vbox.add_child(top_center)
	var bottom_center: CenterContainer = CenterContainer.new()
	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 10)
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_center.add_child(bottom_row)
	rows_vbox.add_child(bottom_center)
	var done_row: CenterContainer = CenterContainer.new()
	done_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(done_row)
	var done_btn: Button = Button.new()
	done_btn.text = "Done"
	done_btn.tooltip_text = "Exit the Merchant and resume gameplay."
	done_btn.pressed.connect(on_done)
	done_btn.custom_minimum_size = Vector2(220, 44)
	done_btn.add_theme_font_size_override("font_size", 18)
	var done_styles: Dictionary = build_done_button_styles()
	done_btn.add_theme_stylebox_override("normal", done_styles["normal"])
	done_btn.add_theme_stylebox_override("hover", done_styles["hover"])
	done_btn.add_theme_stylebox_override("pressed", done_styles["pressed"])
	done_btn.add_theme_color_override("font_color", Color(0.12, 0.1, 0.06, 1))
	done_btn.add_theme_color_override("font_hover_color", Color(0.08, 0.06, 0.04, 1))
	done_btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.9, 0.75, 1))
	done_row.add_child(done_btn)
	return {
		"gold_label": gold_label,
		"refresh_btn": refresh_btn,
		"top_row": top_row,
		"bottom_row": bottom_row,
		"done_btn": done_btn
	}
