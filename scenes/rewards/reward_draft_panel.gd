extends Control
## Modal ball reward draft: centered panel, blurred dim background, cards with "<Ability> <Alignment>", rarity border, gem icon.

signal pick_selected(pick: Resource)

const RARITY_COLORS: Array[Color] = [
	Color(0.95, 0.95, 0.95, 1),   # 0 common: White
	Color(0.2, 0.85, 0.35, 1),    # 1: Green
	Color(0.25, 0.5, 1.0, 1),     # 2: Blue
	Color(0.65, 0.35, 0.95, 1),   # 3: Purple
	Color(1.0, 0.55, 0.15, 1),    # 4: Orange
	Color(0.95, 0.25, 0.2, 1),    # 5 epic: Red
]

const ALIGNMENT_NAMES: Array[String] = ["Main", "Sidearm", "Defense"]

var _picks: Array = []
var _dim_layer: ColorRect
var _modal_container: CenterContainer
var _modal_panel: PanelContainer
var _cards_container: HBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Blurred background (samples screen; must be first so it sees game behind)
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
	# Dim overlay
	_dim_layer = ColorRect.new()
	_dim_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim_layer.color = Color(0.0, 0.0, 0.0, 0.45)
	_dim_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim_layer)
	# Centered modal
	_modal_container = CenterContainer.new()
	_modal_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_modal_container)
	_modal_panel = PanelContainer.new()
	_modal_panel.custom_minimum_size = Vector2(720, 320)
	_modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
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
	_modal_panel.add_theme_stylebox_override("panel", panel_style)
	_modal_container.add_child(_modal_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_modal_panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	var title: Label = Label.new()
	title.text = "Choose a ball reward"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	_cards_container = HBoxContainer.new()
	_cards_container.add_theme_constant_override("separation", 24)
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_cards_container)
	hide()

func _alignment_name(alignment: int) -> String:
	if alignment >= 0 and alignment < ALIGNMENT_NAMES.size():
		return ALIGNMENT_NAMES[alignment]
	return "Main"

func _rarity_color(rarity: int) -> Color:
	if rarity >= 0 and rarity < RARITY_COLORS.size():
		return RARITY_COLORS[rarity]
	return RARITY_COLORS[0]

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
	var def: BallDefinition = pick as BallDefinition
	var ability: String = def.ability_name if def else "Ball"
	var alignment: int = def.alignment if def else 0
	var rarity: int = def.rarity if def else 0
	var border_color: Color = _rarity_color(rarity)
	# Card panel with rarity border
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 220)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.1, 1)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = border_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	var card_vbox: VBoxContainer = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 8)
	panel.add_child(card_vbox)
	# Title: "<Ability> <Alignment>"
	var title_label: Label = Label.new()
	title_label.text = "%s %s" % [ability, _alignment_name(alignment)]
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", border_color)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(title_label)
	# Ball preview (per-ability shape + alignment color, same as on board)
	var preview: Control = Control.new()
	preview.set_script(load("res://scenes/balls/ball_preview_control.gd") as GDScript)
	preview.custom_minimum_size = Vector2(56, 56)
	preview.alignment = alignment
	preview.shape_type = def.shape_type if def != null else -1
	var preview_center: CenterContainer = CenterContainer.new()
	preview_center.add_child(preview)
	card_vbox.add_child(preview_center)
	# Gem icon under preview
	var gem: Label = Label.new()
	gem.text = "◆"
	gem.add_theme_font_size_override("font_size", 36)
	gem.add_theme_color_override("font_color", border_color)
	gem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(gem)
	# Spacer
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	card_vbox.add_child(spacer)
	# Select button
	var btn: Button = Button.new()
	btn.text = "Select"
	btn.pressed.connect(_on_pick_pressed.bind(index))
	card_vbox.add_child(btn)
	return panel

func _on_pick_pressed(index: int) -> void:
	if index >= 0 and index < _picks.size():
		pick_selected.emit(_picks[index])
	hide()
