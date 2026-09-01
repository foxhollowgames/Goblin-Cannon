class_name RewardCardBuilder
extends RefCounted
## Static helper class for constructing and styling shop card UI components in RewardDraftPanel.

# Constants for rarity levels
const RARITY_COMMON = 0
const RARITY_UNCOMMON = 1
const RARITY_RARE = 2
const RARITY_EPIC = 3
const RARITY_LEGENDARY = 4

# ## Build a shop card with the given offer index and pick resource.
static func build_shop_card(offer_index: int, pick: Resource) -> PanelContainer:
	var card = PanelContainer.new()
	card.name = "ShopCard_" + str(offer_index)
	
	# Add card content here (e.g., icons, labels, etc.)
	# Example: var icon = Sprite.new(); card.add_child(icon); icon.texture = pick.icon
	
	return card

# ## Apply styling based on the rarity level to the given card.
static func apply_rarity_style(card: PanelContainer, rarity: int) -> void:
	var color = Color(1, 1, 1)
	
	match rarity:
		RARITY_COMMON:
			color = Color(0.8, 0.8, 0.8)
		RARITY_UNCOMMON:
			color = Color(0.4, 0.7, 0.2)
		RARITY_RARE:
			color = Color(0.3, 0.5, 1.0)
		RARITY_EPIC:
			color = Color(1.0, 0.4, 0.8)
		RARITY_LEGENDARY:
			color = Color(1.0, 0.9, 0.2)
	
## Create a purchased overlay for an already-bought card.
static func make_purchased_overlay() -> Control:
	var overlay: Control = Control.new()
	overlay.name = "PurchasedOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.z_index = 30
	var bg: ColorRect = ColorRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.color = Color(0, 0, 0, 0.35)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	var center: CenterContainer = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var label: Label = Label.new()
	label.text = "PURCHASED"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1))
	center.add_child(label)
	return overlay

## Renders a peg shop sprite preview for milestone shop peg offers.
static func make_peg_shop_sprite_preview(peg_kind: String) -> Control:
	var holder: Control = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.custom_minimum_size = Vector2(36, 36)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.clip_contents = true
	var peg_scene: PackedScene = load("res://scenes/board/peg.tscn") as PackedScene
	if peg_scene:
		var peg: StaticBody2D = peg_scene.instantiate() as StaticBody2D
		if peg:
			peg.set_meta("shop_preview", true)
			peg.peg_extra_kind = peg_kind
			peg.position = Vector2(18, 18)
			holder.add_child(peg)
	return holder
static func make_stat_upgrade_icon(stat_id: String, tint: Color, stat_icons: Dictionary) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size = Vector2(0, 32)
	var tex: Texture2D = stat_icons.get(stat_id) as Texture2D
	if tex == null:
		var gem: Label = Label.new()
		gem.text = "◆"
		gem.add_theme_font_size_override("font_size", 22)
		gem.add_theme_color_override("font_color", tint)
		gem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(gem)
		return row
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(28, 28)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.modulate = tint
	row.add_child(tr)
	return row

## Computes price for a pick resource.
static func compute_pick_price(pick: Variant) -> int:
	if pick is MilestoneOption:
		var opt: MilestoneOption = pick as MilestoneOption
		match opt.option_type:
			MilestoneOption.Type.BASIC_BATCH:
				return Constants.shop_price_for_ball_rarity(Constants.RARITY_COMMON)
			MilestoneOption.Type.BALL_UPGRADE:
				var bd: BallDefinition = opt.ball_definition
				return Constants.shop_price_for_ball_rarity(bd.rarity if bd else 0)
			MilestoneOption.Type.PEG_UPGRADE:
				return Constants.shop_price_for_peg_rarity(opt.rarity)
			_:
				return Constants.shop_price_for_stat_rarity(opt.rarity)
	if pick is BallDefinition:
		return Constants.shop_price_for_ball_rarity((pick as BallDefinition).rarity)
	return Constants.shop_price_for_ball_rarity(Constants.RARITY_COMMON)

## Renders a category label for shop cards.
static func shop_category_label(category: String) -> Label:
	var lbl: Label = Label.new()
	lbl.text = category
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.52, 0.62, 1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

## Styles a description RichTextLabel for shop cards.
static func shop_style_desc_label(desc_label: RichTextLabel, desc_font_size: int, desc_height: int, card_width: int) -> void:
	desc_label.bbcode_enabled = true
	desc_label.fit_content = true
	desc_label.scroll_active = false
	desc_label.mouse_filter = Control.MOUSE_FILTER_PASS
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("normal_font_size", desc_font_size)
	desc_label.add_theme_font_size_override("bold_font_size", desc_font_size)
	desc_label.add_theme_font_size_override("italics_font_size", desc_font_size)
	desc_label.add_theme_font_size_override("bold_italics_font_size", desc_font_size)
	desc_label.add_theme_color_override("default_color", MilestoneShopData.DESC_TEXT_COLOR)
	desc_label.custom_minimum_size = Vector2(max(8, card_width - 16), desc_height)
	KeywordDatabase.attach_rich_text_label(desc_label)

## Returns a vertical fill spacer for card VBoxes.
static func shop_vbox_fill_spacer() -> Control:
	var s: Control = Control.new()
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size = Vector2(0, 0)
	return s

## Recursively sets mouse filter to IGNORE for shop card child controls except RichTextLabels.
static func apply_shop_card_mouse_ignore(panel: PanelContainer) -> void:
	for child in panel.get_children():
		if child.name == "PurchasedOverlay":
			continue
		_shop_ignore_mouse_recursive(child)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func _shop_ignore_mouse_recursive(node: Node) -> void:
	if node is RichTextLabel:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_PASS
	elif node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
## Builds a standard shop card StyleBoxFlat.
static func make_card_stylebox(border_color: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.1, 1)
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	style.set_corner_radius_all(4)
	return style

## Single child of PanelContainer before the purchased overlay: fills content, clips disabled, rarity shape centered on top border.
static func make_shop_card_layer(panel: PanelContainer, rarity: int, border_color: Color, border_width: int, marker_size: float, top_inset: float) -> VBoxContainer:
	var layer: Control = Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.clip_contents = false
	layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(layer)
	var card_vbox: VBoxContainer = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 4)
	card_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_vbox.offset_top = top_inset
	var marker: Control = create_rarity_marker(rarity)
	if marker:
		marker.set("shape_color", border_color)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.z_index = 1
		layer.add_child(marker)
	var half_sz: float = marker_size / 2.0
	var border_center_y: float = -float(border_width) / 2.0
	marker.anchor_left = 0.5
	marker.anchor_right = 0.5
	marker.anchor_top = 0.0
	marker.anchor_bottom = 0.0
	marker.offset_left = -half_sz
	marker.offset_right = half_sz
	marker.offset_top = border_center_y - half_sz
	marker.offset_bottom = border_center_y + half_sz
	return card_vbox

## Creates a ball preview icon control.
static func make_ball_preview_icon(alignment: int, shape_type: int, px: int, ability: String = "") -> Control:
	var preview: Control = Control.new()
	preview.set_script(load("res://scenes/balls/ball_preview_control.gd") as GDScript)
	preview.custom_minimum_size = Vector2(px, px)
	preview.alignment = alignment
	preview.shape_type = shape_type
	preview.ability_name = ability
	return preview

## Creates a horizontal container of plain ball previews for the basic batch card.
static func make_basic_batch_ball_row(batch_size: int) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var px: int = 16
## Constructs card panel container with stylebox and fixed size settings.
static func make_card_panel(border_color: Color, border_width: int, card_width: int, card_height: int) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(card_width, card_height)
	panel.modulate = Color(1, 1, 1, 1)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", make_card_stylebox(border_color, border_width))
	return panel
