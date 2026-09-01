class_name GameCoordinatorScreenBuilder
extends RefCounted
## Static helper class for constructing victory screens, fail screens, and title cards for GameCoordinator.

#region Screen Builders
## Builds the victory screen Control panel.
static func build_victory_screen(restart_cb: Callable, endless_cb: Callable) -> Control:
	var root: ColorRect = ColorRect.new()
	root.color = MonsterPalette.UI_DIM()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.process_mode = Node.PROCESS_MODE_ALWAYS

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	vbox.custom_minimum_size = Vector2(400, 220)
	vbox.position = Vector2(-200, -110)
	root.add_child(vbox)

	var title: Label = Label.new()
	title.text = "VICTORY!"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", MonsterPalette.MINT())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var btn_play: Button = Button.new()
	btn_play.text = "Play Again"
	btn_play.custom_minimum_size = Vector2(220, 56)
	btn_play.add_theme_font_size_override("font_size", 24)
	btn_play.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_play.pressed.connect(restart_cb)
	vbox.add_child(btn_play)

	var btn_endless: Button = Button.new()
	btn_endless.text = "Endless Mode"
	btn_endless.custom_minimum_size = Vector2(160, 36)
	btn_endless.add_theme_font_size_override("font_size", 16)
	btn_endless.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_endless.pressed.connect(endless_cb)
	vbox.add_child(btn_endless)

	return root

## Builds an end screen (fail screen or custom title) Control panel.
static func build_end_screen(title_text: String, title_color: Color, button_text: String, restart_cb: Callable) -> Control:
	var root: ColorRect = ColorRect.new()
	root.color = MonsterPalette.UI_DIM()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.process_mode = Node.PROCESS_MODE_ALWAYS

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 32)
	vbox.custom_minimum_size = Vector2(400, 200)
	vbox.position = Vector2(-200, -100)
	root.add_child(vbox)

	var title: Label = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", title_color)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var btn: Button = Button.new()
	btn.text = button_text
	btn.custom_minimum_size = Vector2(220, 56)
	btn.add_theme_font_size_override("font_size", 24)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(restart_cb)
	vbox.add_child(btn)

	return root
## Displays animated title card banner across screen.
static func show_wall_title_card(parent: Node, title_text: String, subtitle_text: String, on_finished: Callable) -> void:
	if not parent:
		return
	var overlay: CanvasLayer = CanvasLayer.new()
	overlay.layer = 15
	overlay.name = "WallTitleCard"
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS

	var center_y: float = 290.0
	var band_total_height: float = 180.0

	var grad: Gradient = Gradient.new()
	var v: Color = MonsterPalette.VOID()
	grad.colors = PackedColorArray([Color(v.r, v.g, v.b, 0), Color(v.r, v.g, v.b, 0.88), Color(v.r, v.g, v.b, 0.88), Color(v.r, v.g, v.b, 0)])
	grad.offsets = PackedFloat32Array([0.0, 0.22, 0.78, 1.0])
	var grad_tex: GradientTexture2D = GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill_from = Vector2(0.5, 0.0)
	grad_tex.fill_to = Vector2(0.5, 1.0)
	grad_tex.width = 4
	grad_tex.height = 128
	var band: TextureRect = TextureRect.new()
	band.texture = grad_tex
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.position = Vector2(0, center_y)
	band.size = Vector2(1280, band_total_height)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.modulate.a = 0.0
	overlay.add_child(band)

	var line_top: ColorRect = ColorRect.new()
	line_top.color = MonsterPalette.TITLE_CARD_LINE()
	line_top.size = Vector2(340, 1)
	line_top.position = Vector2(470, center_y + 58)
	line_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_top.modulate.a = 0.0
	overlay.add_child(line_top)

	var title_label: Label = Label.new()
	title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", 44)
	title_label.add_theme_color_override("font_color", MonsterPalette.TITLE_CARD_TITLE())
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(40, center_y + 64)
	title_label.size = Vector2(1280, 54)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.modulate.a = 0.0
	overlay.add_child(title_label)

	var line_bottom: ColorRect = ColorRect.new()
	line_bottom.color = MonsterPalette.TITLE_CARD_LINE()
	line_bottom.size = Vector2(340, 1)
	line_bottom.position = Vector2(470, center_y + 122)
	line_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_bottom.modulate.a = 0.0
	overlay.add_child(line_bottom)

	var sub_label: Label = null
	if not subtitle_text.is_empty():
		sub_label = Label.new()
		sub_label.text = subtitle_text
		sub_label.add_theme_font_size_override("font_size", 20)
		sub_label.add_theme_color_override("font_color", MonsterPalette.TITLE_CARD_SUB())
		sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_label.position = Vector2(0, center_y + 126)
		sub_label.size = Vector2(1280, 30)
		sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sub_label.modulate.a = 0.0
		overlay.add_child(sub_label)

	parent.add_child(overlay)

	var tween: Tween = parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(band, "modulate:a", 1.0, 0.7).set_ease(Tween.EASE_OUT)
	tween.tween_property(line_top, "modulate:a", 1.0, 0.6).set_delay(0.15)
	tween.tween_property(line_bottom, "modulate:a", 1.0, 0.6).set_delay(0.15)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.9).set_delay(0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_label, "position:x", 0.0, 0.9).set_delay(0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if sub_label:
		tween.tween_property(sub_label, "modulate:a", 1.0, 0.7).set_delay(0.45).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_interval(1.6)
	tween.set_parallel(true)
	tween.tween_property(band, "modulate:a", 0.0, 0.65).set_ease(Tween.EASE_IN)
	tween.tween_property(title_label, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tween.tween_property(line_top, "modulate:a", 0.0, 0.5)
	tween.tween_property(line_bottom, "modulate:a", 0.0, 0.5)
	if sub_label:
		tween.tween_property(sub_label, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(overlay.queue_free)
	if on_finished.is_valid():
		tween.tween_callback(on_finished)
#endregion

