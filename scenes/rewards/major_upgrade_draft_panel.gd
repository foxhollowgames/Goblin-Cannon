extends Control
## Modal for wall break / conquest rewards. GDD: major upgrades (not same as milestone balls+stats).

signal pick_selected(pick: Resource)
signal draft_skipped

var _picks: Array = []
var _show_skip: bool = false
var _skip_btn: Button
var _blur_rect: ColorRect
var _dim_layer: ColorRect
var _center_container: CenterContainer
var _cards_container: HBoxContainer
var _title_label: Label
var _show_rewards_btn: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var blur_rect: ColorRect = ColorRect.new()
	_blur_rect = blur_rect
	blur_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader: Shader = load("res://scenes/rewards/blur_background.gdshader") as Shader
	if shader:
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("blur_amount", 1.5)
		blur_rect.material = mat
	add_child(blur_rect)
	var dim: ColorRect = ColorRect.new()
	_dim_layer = dim
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	_center_container = center
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 320)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.08, 0.18, 0.98)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.7, 0.4, 0.2, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = "Conquest Reward — Choose a Relic"
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.7, 0.35, 1))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(_title_label)
	var hide_btn: Button = Button.new()
	hide_btn.text = "Hide"
	hide_btn.tooltip_text = "Hide this draft screen to inspect the board. Press I to open Inventory."
	hide_btn.pressed.connect(_on_hide_overlay_pressed)
	title_row.add_child(hide_btn)
	vbox.add_child(title_row)
	_cards_container = HBoxContainer.new()
	_cards_container.add_theme_constant_override("separation", 24)
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_cards_container)
	_skip_btn = Button.new()
	_skip_btn.text = "Skip"
	_skip_btn.visible = false
	_skip_btn.tooltip_text = "Skip this relic reward."
	_skip_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var skip_style: StyleBoxFlat = StyleBoxFlat.new()
	skip_style.bg_color = Color(0.12, 0.1, 0.14, 1)
	skip_style.border_width_left = 2
	skip_style.border_width_right = 2
	skip_style.border_width_top = 2
	skip_style.border_width_bottom = 2
	skip_style.border_color = Color(0.45, 0.42, 0.5, 1)
	skip_style.set_corner_radius_all(6)
	_skip_btn.add_theme_stylebox_override("normal", skip_style)
	var skip_hover: StyleBoxFlat = skip_style.duplicate()
	skip_hover.bg_color = Color(0.2, 0.16, 0.22, 1)
	_skip_btn.add_theme_stylebox_override("hover", skip_hover)
	_skip_btn.pressed.connect(_on_skip_pressed)
	vbox.add_child(_skip_btn)
	_show_rewards_btn = Button.new()
	_show_rewards_btn.text = "Show rewards"
	_show_rewards_btn.visible = false
	_show_rewards_btn.z_index = 10
	_show_rewards_btn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_show_rewards_btn.offset_left = -100.0
	_show_rewards_btn.offset_right = 100.0
	_show_rewards_btn.offset_top = 10.0
	_show_rewards_btn.offset_bottom = 44.0
	var show_style: StyleBoxFlat = StyleBoxFlat.new()
	show_style.bg_color = Color(0.18, 0.1, 0.22, 0.95)
	show_style.border_width_left = 2
	show_style.border_width_right = 2
	show_style.border_width_top = 2
	show_style.border_width_bottom = 2
	show_style.border_color = Color(0.75, 0.45, 0.25, 1)
	show_style.set_corner_radius_all(6)
	_show_rewards_btn.add_theme_stylebox_override("normal", show_style)
	var show_hover: StyleBoxFlat = show_style.duplicate()
	show_hover.bg_color = Color(0.28, 0.15, 0.2, 0.98)
	_show_rewards_btn.add_theme_stylebox_override("hover", show_hover)
	_show_rewards_btn.pressed.connect(_on_show_overlay_pressed)
	add_child(_show_rewards_btn)
	hide()

func set_title(text: String) -> void:
	if _title_label:
		_title_label.text = text

func set_show_skip_visible(show: bool) -> void:
	_show_skip = show
	if _skip_btn:
		_skip_btn.visible = show

func _set_overlay_visible(overlay_on: bool) -> void:
	if _blur_rect:
		_blur_rect.visible = overlay_on
	if _dim_layer:
		_dim_layer.visible = overlay_on
	if _center_container:
		_center_container.visible = overlay_on
	if _show_rewards_btn:
		_show_rewards_btn.visible = not overlay_on
	mouse_filter = Control.MOUSE_FILTER_STOP if overlay_on else Control.MOUSE_FILTER_IGNORE

func _on_hide_overlay_pressed() -> void:
	_set_overlay_visible(false)

func _on_show_overlay_pressed() -> void:
	_set_overlay_visible(true)

func show_draft(picks: Array) -> bool:
	show()
	_set_overlay_visible(true)
	_picks = picks
	if _skip_btn:
		_skip_btn.visible = _show_skip
	if not _cards_container:
		return false
	for child in _cards_container.get_children():
		child.queue_free()
	for i in picks.size():
		var pick: Resource = picks[i] as Resource
		var card: Control = _make_card(pick, i)
		_cards_container.add_child(card)
	return true

func _make_card(pick: Resource, index: int) -> Control:
	var name_str: String = pick.get("display_name") if pick else "Upgrade"
	var desc_str: String = pick.get("description") if pick else ""
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 220)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.06, 0.14, 1)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.7, 0.4, 0.2, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	var card_vbox: VBoxContainer = VBoxContainer.new()
	card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_vbox.add_theme_constant_override("separation", 12)
	panel.add_child(card_vbox)
	var name_label: Label = Label.new()
	name_label.text = name_str
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.4, 1))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(name_label)
	var desc_label: RichTextLabel = RichTextLabel.new()
	desc_label.bbcode_enabled = true
	desc_label.fit_content = true
	desc_label.scroll_active = false
	desc_label.mouse_filter = Control.MOUSE_FILTER_PASS
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(180, 0)
	desc_label.add_theme_font_size_override("normal_font_size", 14)
	desc_label.add_theme_font_size_override("bold_font_size", 14)
	desc_label.add_theme_font_size_override("italics_font_size", 14)
	desc_label.add_theme_font_size_override("bold_italics_font_size", 14)
	desc_label.add_theme_color_override("default_color", Color(0.8, 0.75, 0.85, 1))
	KeywordDatabase.format_and_attach(desc_label, desc_str, KeywordDatabase.HIGHLIGHT_COLOR, "[center]", "[/center]")
	card_vbox.add_child(desc_label)
	var spacer: Control = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_vbox.add_child(spacer)
	var btn: Button = Button.new()
	btn.text = "Select"
	btn.pressed.connect(_on_pick_pressed.bind(index))
	card_vbox.add_child(btn)

	panel.mouse_entered.connect(func() -> void:
		style.border_color = Color(1.0, 0.85, 0.35, 1.0)
		style.bg_color = Color(0.16, 0.1, 0.22, 1.0)
	)
	panel.mouse_exited.connect(func() -> void:
		style.border_color = Color(0.7, 0.4, 0.2, 1.0)
		style.bg_color = Color(0.1, 0.06, 0.14, 1.0)
	)
	return panel

func _on_pick_pressed(index: int) -> void:
	if index >= 0 and index < _picks.size():
		pick_selected.emit(_picks[index])
	_set_overlay_visible(true)
	hide()

func _on_skip_pressed() -> void:
	draft_skipped.emit()
	_set_overlay_visible(true)
	hide()
