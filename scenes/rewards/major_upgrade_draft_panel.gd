extends Control
## Modal for wall break / conquest rewards. GDD: major upgrades (not same as milestone balls+stats).

signal pick_selected(pick: Resource)

var _picks: Array = []
var _cards_container: HBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var blur_rect: ColorRect = ColorRect.new()
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
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
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
	var title: Label = Label.new()
	title.name = "Title"
	title.text = "Conquest reward – Choose a major upgrade"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.7, 0.35, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	_cards_container = HBoxContainer.new()
	_cards_container.add_theme_constant_override("separation", 24)
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_cards_container)
	hide()

func show_draft(picks: Array) -> bool:
	_picks = picks
	if not _cards_container:
		return false
	for child in _cards_container.get_children():
		child.queue_free()
	for i in picks.size():
		var pick: Resource = picks[i] as Resource
		var card: Control = _make_card(pick, i)
		_cards_container.add_child(card)
	show()
	return true

func _make_card(pick: Resource, index: int) -> Control:
	var name_str: String = pick.get("display_name") if pick else "Upgrade"
	var desc_str: String = pick.get("description") if pick else ""
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 220)
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
	card_vbox.add_theme_constant_override("separation", 12)
	panel.add_child(card_vbox)
	var name_label: Label = Label.new()
	name_label.text = name_str
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.4, 1))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(name_label)
	var desc_label: Label = Label.new()
	desc_label.text = desc_str
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.85, 1))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(180, 0)
	card_vbox.add_child(desc_label)
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	card_vbox.add_child(spacer)
	var btn: Button = Button.new()
	btn.text = "Select"
	btn.pressed.connect(_on_pick_pressed.bind(index))
	card_vbox.add_child(btn)
	return panel

func _on_pick_pressed(index: int) -> void:
	if index >= 0 and index < _picks.size():
		pick_selected.emit(_picks[index])
	hide()
