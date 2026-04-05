extends Control
## Modal ball reward draft: centered panel, blurred dim background, cards with rarity border and top rarity shape (square/diamond/triangle/circle).

signal pick_selected(pick: Resource)
signal refresh_requested
## Emitted when the player leaves the milestone shop (Done). Finishes reward flow.
signal shop_done

const RARITY_COLORS: Array[Color] = [
	Color(0.95, 0.95, 0.95, 1),   # 0 common: White
	Color(0.2, 0.85, 0.35, 1),    # 1: Green
	Color(0.25, 0.5, 1.0, 1),     # 2: Blue
	Color(0.65, 0.35, 0.95, 1),   # 3: Purple
	Color(1.0, 0.55, 0.15, 1),    # 4: Orange
	Color(0.95, 0.25, 0.2, 1),    # 5 epic: Red
]

const ALIGNMENT_NAMES: Array[String] = ["Main"]

## Must match StyleBoxFlat border_width_* on shop cards (used to center rarity on the border line).
const SHOP_CARD_BORDER_WIDTH: int = 2
const SHOP_CARD_RARITY_MARKER_SIZE: float = 11.0
## Space below the border so body text clears the marker (marker overlaps into content slightly).
const SHOP_CARD_BODY_TOP_INSET: float = 5.0
## Bordered frame width/height only (price sits below the frame; click the row to buy).
const SHOP_CARD_WIDTH: int = 152
const SHOP_CARD_FRAME_HEIGHT: int = 136
## Reserved height for description (two lines at SHOP_CARD_DESC_FONT; ~2× line height + spacing). Longer copy clips.
const SHOP_CARD_DESC_TWO_LINES_H: int = 34
const SHOP_CARD_TITLE_FONT: int = 14
const SHOP_CARD_DESC_FONT: int = 11
const SHOP_OFFER_HOVER_SCALE: float = 1.08
## Real-time seconds; tweens use ignore_time_scale so hover works while REWARD_PAUSED (Engine.time_scale = 0).
const SHOP_OFFER_HOVER_TWEEN_SEC: float = 0.04
const SHOP_PRICE_TEXT_COLOR_NORMAL: Color = Color(0.95, 0.82, 0.35, 1)
const SHOP_PRICE_TEXT_COLOR_ERROR: Color = Color(0.92, 0.28, 0.28, 1)
const SHOP_PRICE_TEXT_COLOR_PURCHASED: Color = Color(0.55, 0.52, 0.48, 1)
## Gap between the two shop rows so each card’s price reads with the frame above.
const SHOP_ROWS_SEPARATION: int = 16

## Drawn at top of shop cards. Rarity → shape: 0 common = square, 1 uncommon = diamond, 2 rare = triangle, 3+ epic = circle.
class RarityShapeMarker extends Control:
	var rarity: int = 0
	var shape_color: Color = Color.WHITE

	func _draw() -> void:
		var kind: int = 3
		if rarity <= 0:
			kind = 0
		elif rarity == 1:
			kind = 1
		elif rarity == 2:
			kind = 2
		var s: float = minf(size.x, size.y)
		var cx: float = size.x * 0.5
		var cy: float = size.y * 0.5
		match kind:
			0:
				var half: float = s * 0.38
				draw_rect(Rect2(cx - half, cy - half, half * 2.0, half * 2.0), shape_color)
			1:
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(cx, cy - s * 0.45),
					Vector2(cx + s * 0.45, cy),
					Vector2(cx, cy + s * 0.45),
					Vector2(cx - s * 0.45, cy),
				])
				draw_colored_polygon(pts, shape_color)
			2:
				var pts2: PackedVector2Array = PackedVector2Array([
					Vector2(cx, cy - s * 0.42),
					Vector2(cx + s * 0.45, cy + s * 0.45),
					Vector2(cx - s * 0.45, cy + s * 0.45),
				])
				draw_colored_polygon(pts2, shape_color)
			3:
				draw_circle(Vector2(cx, cy), s * 0.44, shape_color)

var _picks: Array = []
var _purchased_flags: Array = []
var _shop_offer_roots_by_index: Array = []
var _shop_price_labels_by_index: Array = []
var _purchased_overlays_by_index: Array = []
var _card_panels_by_index: Array = []
var _blur_rect: ColorRect
var _dim_layer: ColorRect
var _modal_container: CenterContainer
var _modal_panel: PanelContainer
var _show_rewards_btn: Button
var _top_row_container: HBoxContainer   ## 3 cards, centered
var _bottom_row_container: HBoxContainer ## 2 cards, centered
var _gold_label: Label
var _refresh_btn: Button
var _done_btn: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Blurred background (samples screen; must be first so it sees game behind)
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
	# Dim overlay
	_dim_layer = ColorRect.new()
	_dim_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim_layer.color = Color(0.0, 0.0, 0.0, 0.45)
	_dim_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim_layer)
	# Centered modal
	_modal_container = CenterContainer.new()
	_modal_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	# STOP so the modal subtree is included in GUI hit-testing; IGNORE can prevent children from receiving input.
	_modal_container.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_modal_container)
	_modal_panel = PanelContainer.new()
	# 3 top + 2 bottom + bottom Done row (height driven by content; rows may scroll)
	_modal_panel.custom_minimum_size = Vector2(520, 360)
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
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_modal_panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	var title: Label = Label.new()
	title.text = "Milestone shop"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	_gold_label = Label.new()
	_gold_label.text = "Gold: 0"
	_gold_label.add_theme_font_size_override("font_size", 18)
	_gold_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35, 1))
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(_gold_label)
	_refresh_btn = Button.new()
	_refresh_btn.text = "Refresh (%d gold)" % Constants.SHOP_REFRESH_COST
	_refresh_btn.tooltip_text = "Reroll all five offers. Costs gold."
	_refresh_btn.pressed.connect(_on_refresh_pressed)
	title_row.add_child(_refresh_btn)
	var hide_btn: Button = Button.new()
	hide_btn.text = "Hide"
	hide_btn.tooltip_text = "Hide this screen to view the board or open inventory (I)."
	hide_btn.pressed.connect(_on_hide_overlay_pressed)
	title_row.add_child(hide_btn)
	vbox.add_child(title_row)
	var rows_vbox: VBoxContainer = VBoxContainer.new()
	rows_vbox.add_theme_constant_override("separation", SHOP_ROWS_SEPARATION)
	vbox.add_child(rows_vbox)
	# Top row: 3 cards, centered
	var top_center: CenterContainer = CenterContainer.new()
	_top_row_container = HBoxContainer.new()
	_top_row_container.add_theme_constant_override("separation", 10)
	_top_row_container.alignment = BoxContainer.ALIGNMENT_CENTER
	top_center.add_child(_top_row_container)
	rows_vbox.add_child(top_center)
	# Bottom row: 2 cards, centered
	var bottom_center: CenterContainer = CenterContainer.new()
	_bottom_row_container = HBoxContainer.new()
	_bottom_row_container.add_theme_constant_override("separation", 10)
	_bottom_row_container.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_center.add_child(_bottom_row_container)
	rows_vbox.add_child(bottom_center)
	var done_row: CenterContainer = CenterContainer.new()
	done_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(done_row)
	_done_btn = Button.new()
	_done_btn.text = "Done"
	_done_btn.tooltip_text = "Leave the shop. You can buy multiple offers before this."
	_done_btn.pressed.connect(_on_done_pressed)
	_done_btn.custom_minimum_size = Vector2(220, 44)
	_done_btn.add_theme_font_size_override("font_size", 18)
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
	_done_btn.add_theme_stylebox_override("normal", done_normal)
	var done_hover: StyleBoxFlat = done_normal.duplicate()
	done_hover.bg_color = Color(0.82, 0.62, 0.18, 1)
	_done_btn.add_theme_stylebox_override("hover", done_hover)
	var done_pressed: StyleBoxFlat = done_normal.duplicate()
	done_pressed.bg_color = Color(0.55, 0.38, 0.08, 1)
	done_pressed.border_color = Color(0.85, 0.68, 0.2, 1)
	_done_btn.add_theme_stylebox_override("pressed", done_pressed)
	_done_btn.add_theme_color_override("font_color", Color(0.12, 0.1, 0.06, 1))
	_done_btn.add_theme_color_override("font_hover_color", Color(0.08, 0.06, 0.04, 1))
	_done_btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.9, 0.75, 1))
	done_row.add_child(_done_btn)
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
	show_style.bg_color = Color(0.14, 0.1, 0.2, 0.95)
	show_style.border_width_left = 2
	show_style.border_width_right = 2
	show_style.border_width_top = 2
	show_style.border_width_bottom = 2
	show_style.border_color = Color(0.55, 0.45, 0.75, 1)
	show_style.set_corner_radius_all(6)
	_show_rewards_btn.add_theme_stylebox_override("normal", show_style)
	var show_hover: StyleBoxFlat = show_style.duplicate()
	show_hover.bg_color = Color(0.22, 0.16, 0.32, 0.98)
	_show_rewards_btn.add_theme_stylebox_override("hover", show_hover)
	_show_rewards_btn.pressed.connect(_on_show_overlay_pressed)
	add_child(_show_rewards_btn)
	hide()
	set_process(false)

func _process(_delta: float) -> void:
	if not visible:
		return
	_update_shop_header()

func _update_shop_header() -> void:
	if _gold_label and GameState:
		_gold_label.text = "Gold: %d" % GameState.run_gold
	if _refresh_btn and GameState:
		_refresh_btn.disabled = GameState.run_gold < Constants.SHOP_REFRESH_COST
	_update_shop_offer_interactivity()

func _can_shop_offer_interact(index: int) -> bool:
	if index < 0 or index >= _picks.size():
		return false
	if index < _purchased_flags.size() and _purchased_flags[index]:
		return false
	if not GameState:
		return false
	return GameState.run_gold >= _compute_pick_price(_picks[index])

func _update_shop_offer_interactivity() -> void:
	if not GameState:
		return
	for i in range(_shop_offer_roots_by_index.size()):
		var root: Control = _shop_offer_roots_by_index[i]
		if root == null or not is_instance_valid(root):
			continue
		var price_lbl: Label = null
		if i < _shop_price_labels_by_index.size():
			var pl: Variant = _shop_price_labels_by_index[i]
			if pl is Label and is_instance_valid(pl):
				price_lbl = pl as Label
		if i < _purchased_flags.size() and _purchased_flags[i]:
			root.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.mouse_default_cursor_shape = Control.CURSOR_ARROW
			root.scale = Vector2.ONE
			root.z_index = 0
			_shop_kill_hover_tween(root)
			if price_lbl:
				price_lbl.add_theme_color_override("font_color", SHOP_PRICE_TEXT_COLOR_PURCHASED)
			continue
		if i < 0 or i >= _picks.size():
			continue
		var can: bool = _can_shop_offer_interact(i)
		root.mouse_filter = Control.MOUSE_FILTER_STOP
		root.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can else Control.CURSOR_ARROW
		if price_lbl:
			price_lbl.add_theme_color_override("font_color", SHOP_PRICE_TEXT_COLOR_NORMAL if can else SHOP_PRICE_TEXT_COLOR_ERROR)
		if not can:
			root.scale = Vector2.ONE
			root.z_index = 0
			_shop_kill_hover_tween(root)

func _shop_kill_hover_tween(root: Control) -> void:
	if root.has_meta("hover_tween"):
		var tw: Tween = root.get_meta("hover_tween") as Tween
		if tw and is_instance_valid(tw):
			tw.kill()
		root.remove_meta("hover_tween")

func _wire_shop_offer_interactions(col: Control, index: int) -> void:
	col.mouse_filter = Control.MOUSE_FILTER_STOP
	col.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	col.resized.connect(func() -> void:
		col.pivot_offset = col.size * 0.5
	)
	col.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_on_pick_pressed(index)
	)
	col.mouse_entered.connect(func() -> void:
		if not _can_shop_offer_interact(index):
			return
		col.pivot_offset = col.size * 0.5
		_shop_kill_hover_tween(col)
		var tw: Tween = col.create_tween()
		tw.set_ignore_time_scale(true)
		col.set_meta("hover_tween", tw)
		tw.tween_property(col, "scale", Vector2(SHOP_OFFER_HOVER_SCALE, SHOP_OFFER_HOVER_SCALE), SHOP_OFFER_HOVER_TWEEN_SEC).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		col.z_index = 1
	)
	col.mouse_exited.connect(func() -> void:
		_shop_kill_hover_tween(col)
		var tw: Tween = col.create_tween()
		tw.set_ignore_time_scale(true)
		col.set_meta("hover_tween", tw)
		tw.tween_property(col, "scale", Vector2(1.0, 1.0), SHOP_OFFER_HOVER_TWEEN_SEC)
		col.z_index = 0
	)

func _compute_pick_price(pick: Variant) -> int:
	if pick is MilestoneOption:
		var opt: MilestoneOption = pick as MilestoneOption
		match opt.option_type:
			MilestoneOption.Type.BASIC_BATCH:
				return Constants.SHOP_PRICE_COMMON
			MilestoneOption.Type.BALL_UPGRADE:
				var bd: BallDefinition = opt.ball_definition
				return Constants.shop_price_for_ball_rarity(bd.rarity if bd else 0)
			MilestoneOption.Type.PEG_UPGRADE:
				return Constants.shop_price_for_peg_rarity(opt.rarity)
			_:
				return Constants.shop_price_for_stat_rarity(opt.rarity)
	if pick is BallDefinition:
		return Constants.shop_price_for_ball_rarity((pick as BallDefinition).rarity)
	return Constants.SHOP_PRICE_COMMON

func _shop_category_label(category: String) -> Label:
	var lbl: Label = Label.new()
	lbl.text = category
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.52, 0.62, 1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

func _shop_style_desc_label(desc_label: Label) -> void:
	desc_label.add_theme_font_size_override("font_size", SHOP_CARD_DESC_FONT)
	desc_label.custom_minimum_size = Vector2(max(8, SHOP_CARD_WIDTH - 16), SHOP_CARD_DESC_TWO_LINES_H)
	desc_label.clip_text = true

func _shop_desc_placeholder() -> Label:
	var lbl: Label = Label.new()
	lbl.text = ""
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_style_desc_label(lbl)
	return lbl

func _shop_vbox_fill_spacer() -> Control:
	var s: Control = Control.new()
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size = Vector2(0, 0)
	return s

## Labels/icons default to STOP and steal hits from the card PanelContainer; ignore so panel receives gui_input + hover.
func _shop_ignore_mouse_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in node.get_children():
		_shop_ignore_mouse_recursive(c)

func _apply_shop_card_mouse_ignore(panel: PanelContainer) -> void:
	for child in panel.get_children():
		if child.name == "PurchasedOverlay":
			continue
		_shop_ignore_mouse_recursive(child)
	# Panel must not steal hits from the offer column; children already IGNORE where needed.
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _apply_shop_card_fixed_size(panel: PanelContainer) -> void:
	panel.custom_minimum_size = Vector2(SHOP_CARD_WIDTH, SHOP_CARD_FRAME_HEIGHT)

## Price below the bordered panel (Slay the Spire–style); VBox column receives hover + gui_input (panel is IGNORE for hits).
func _finalize_shop_offer(panel: PanelContainer, price: int, index: int) -> Control:
	var overlay: Control = _make_purchased_overlay()
	panel.add_child(overlay)
	if index >= _shop_offer_roots_by_index.size():
		_shop_offer_roots_by_index.resize(index + 1)
	if index >= _purchased_overlays_by_index.size():
		_purchased_overlays_by_index.resize(index + 1)
	if index >= _card_panels_by_index.size():
		_card_panels_by_index.resize(index + 1)
	var price_lbl: Label = Label.new()
	price_lbl.text = "%d gold" % price
	price_lbl.add_theme_font_size_override("font_size", 11)
	price_lbl.add_theme_color_override("font_color", SHOP_PRICE_TEXT_COLOR_NORMAL)
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if index >= _shop_price_labels_by_index.size():
		_shop_price_labels_by_index.resize(index + 1)
	_shop_price_labels_by_index[index] = price_lbl
	_purchased_overlays_by_index[index] = overlay
	_card_panels_by_index[index] = panel
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.custom_minimum_size = Vector2(SHOP_CARD_WIDTH, 0)
	col.add_child(panel)
	col.add_child(price_lbl)
	_apply_shop_card_mouse_ignore(panel)
	_shop_offer_roots_by_index[index] = col
	_wire_shop_offer_interactions(col, index)
	return col

func _make_ball_preview_icon(alignment: int, shape_type: int, px: int) -> Control:
	var preview: Control = Control.new()
	preview.set_script(load("res://scenes/balls/ball_preview_control.gd") as GDScript)
	preview.custom_minimum_size = Vector2(px, px)
	preview.alignment = alignment
	preview.shape_type = shape_type
	return preview

## Renders the same peg visuals as the board, for milestone shop peg offers.
## Uses a Control + real Peg node in the main UI viewport; SubViewport + StaticBody2D + Rapier
## often produced an empty (black) render texture.
func _make_peg_shop_sprite_preview(peg_kind: String) -> Control:
	var holder: Control = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.custom_minimum_size = Vector2(36, 36)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.clip_contents = true
	var peg_scene: PackedScene = load("res://scenes/board/peg.tscn") as PackedScene
	var peg: StaticBody2D = peg_scene.instantiate() as StaticBody2D
	if peg:
		peg.set_meta("shop_preview", true)
		peg.peg_extra_kind = peg_kind
		peg.position = Vector2(18, 18)
		holder.add_child(peg)
	return holder

func _make_basic_batch_ball_row() -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var px: int = 16
	for _i in RewardGeneration.BASIC_BATCH_SIZE:
		row.add_child(_make_ball_preview_icon(Constants.ALIGNMENT_MAIN, -1, px))
	var wrap: CenterContainer = CenterContainer.new()
	wrap.add_child(row)
	return wrap

func _alignment_name(alignment: int) -> String:
	if alignment >= 0 and alignment < ALIGNMENT_NAMES.size():
		return ALIGNMENT_NAMES[alignment]
	return "Main"

func _rarity_color(rarity: int) -> Color:
	if rarity >= 0 and rarity < RARITY_COLORS.size():
		return RARITY_COLORS[rarity]
	return RARITY_COLORS[0]

## Single child of PanelContainer before the purchased overlay: fills content, clips disabled, rarity shape centered on top border.
func _make_shop_card_layer(panel: PanelContainer, rarity: int) -> VBoxContainer:
	var border_color: Color = _rarity_color(rarity)
	var layer: Control = Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.clip_contents = false
	layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(layer)
	var card_vbox: VBoxContainer = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 4)
	card_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_vbox.offset_top = SHOP_CARD_BODY_TOP_INSET
	layer.add_child(card_vbox)
	var marker: RarityShapeMarker = RarityShapeMarker.new()
	marker.rarity = rarity
	marker.shape_color = border_color
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.z_index = 1
	layer.add_child(marker)
	var half_sz: float = SHOP_CARD_RARITY_MARKER_SIZE / 2.0
	var border_center_y: float = -float(SHOP_CARD_BORDER_WIDTH) / 2.0
	marker.anchor_left = 0.5
	marker.anchor_right = 0.5
	marker.anchor_top = 0.0
	marker.anchor_bottom = 0.0
	marker.offset_left = -half_sz
	marker.offset_right = half_sz
	marker.offset_top = border_center_y - half_sz
	marker.offset_bottom = border_center_y + half_sz
	return card_vbox

func _set_overlay_visible(overlay_on: bool) -> void:
	if _blur_rect:
		_blur_rect.visible = overlay_on
	if _dim_layer:
		_dim_layer.visible = overlay_on
	if _modal_container:
		_modal_container.visible = overlay_on
	if _show_rewards_btn:
		_show_rewards_btn.visible = not overlay_on
	mouse_filter = Control.MOUSE_FILTER_STOP if overlay_on else Control.MOUSE_FILTER_IGNORE

func _make_purchased_overlay() -> Control:
	# Visual "lock" for already-bought offers; kept in-place to avoid UI jumps.
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

func _set_card_purchased(index: int) -> void:
	if index < 0:
		return
	if index >= _picks.size():
		return
	if index < _purchased_flags.size() and _purchased_flags[index]:
		return
	if index < _purchased_flags.size():
		_purchased_flags[index] = true

	if index < _shop_offer_roots_by_index.size():
		var root: Control = _shop_offer_roots_by_index[index]
		if root and is_instance_valid(root):
			_shop_kill_hover_tween(root)
			root.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.mouse_default_cursor_shape = Control.CURSOR_ARROW
			root.scale = Vector2.ONE
			root.z_index = 0

	if index < _purchased_overlays_by_index.size():
		var overlay: Control = _purchased_overlays_by_index[index]
		if overlay:
			overlay.visible = true

	if index < _card_panels_by_index.size():
		var panel: PanelContainer = _card_panels_by_index[index]
		if panel:
			# Subtle gray so the card stays readable while being clearly "used".
			panel.modulate = Color(0.75, 0.75, 0.75, 1)

func _on_hide_overlay_pressed() -> void:
	set_process(false)
	_set_overlay_visible(false)

func _on_show_overlay_pressed() -> void:
	_set_overlay_visible(true)

## Same as Hide: pass clicks to the board (e.g. milestone peg placement).
func hide_overlay_for_board_interaction() -> void:
	set_process(false)
	_set_overlay_visible(false)

func restore_overlay_after_board_interaction() -> void:
	if not visible:
		return
	_set_overlay_visible(true)
	set_process(true)

func show_draft(picks: Array) -> bool:
	# Must be visible before building peg SubViewports: UPDATE_WHEN_VISIBLE skips
	# rendering while ancestors are hidden, and the texture may never update.
	show()
	_set_overlay_visible(true)
	_picks = picks
	if not _top_row_container or not _bottom_row_container:
		return false
	_rebuild_cards_from_picks()
	set_process(true)
	return true

func _rebuild_cards_from_picks() -> void:
	for child in _top_row_container.get_children():
		child.queue_free()
	for child in _bottom_row_container.get_children():
		child.queue_free()

	_purchased_flags = []
	_shop_offer_roots_by_index = []
	_shop_price_labels_by_index = []
	_purchased_overlays_by_index = []
	_card_panels_by_index = []
	for _i in range(_picks.size()):
		_purchased_flags.append(false)
	for i in _picks.size():
		var pick: Variant = _picks[i]
		var price: int = _compute_pick_price(pick)
		var card: Control = _make_card(pick, i, price)
		if i < 3:
			_top_row_container.add_child(card)
		else:
			_bottom_row_container.add_child(card)
	_update_shop_header()

func _make_card(pick: Variant, index: int, price: int) -> Control:
	if pick is MilestoneOption:
		var opt: MilestoneOption = pick as MilestoneOption
		match opt.option_type:
			MilestoneOption.Type.BASIC_BATCH:
				return _make_basic_batch_card(index, price)
			MilestoneOption.Type.BALL_UPGRADE:
				return _make_ball_card(opt.ball_definition, index, price)
			MilestoneOption.Type.PEG_UPGRADE:
				return _make_peg_card(opt, index, price)
			_:
				return _make_stat_card(opt, index, price)
	# Legacy: raw BallDefinition
	if pick is BallDefinition:
		return _make_ball_card(pick as BallDefinition, index, price)
	return _make_ball_card(null, index, price)

func _make_basic_batch_card(index: int, price: int) -> Control:
	var border_color: Color = _rarity_color(0)
	var panel: PanelContainer = PanelContainer.new()
	_apply_shop_card_fixed_size(panel)
	panel.modulate = Color(1, 1, 1, 1)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.1, 1)
	style.border_width_left = SHOP_CARD_BORDER_WIDTH
	style.border_width_right = SHOP_CARD_BORDER_WIDTH
	style.border_width_top = SHOP_CARD_BORDER_WIDTH
	style.border_width_bottom = SHOP_CARD_BORDER_WIDTH
	style.border_color = border_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	var card_vbox: VBoxContainer = _make_shop_card_layer(panel, 0)
	var title_label: Label = Label.new()
	title_label.text = "+%d Plain Balls" % RewardGeneration.BASIC_BATCH_SIZE
	title_label.add_theme_font_size_override("font_size", SHOP_CARD_TITLE_FONT)
	title_label.add_theme_color_override("font_color", border_color)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(title_label)
	card_vbox.add_child(_shop_category_label("BALL"))
	card_vbox.add_child(_make_basic_batch_ball_row())
	var desc_label: Label = Label.new()
	desc_label.text = "Adds plain balls to your hopper for the rest of this run."
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_style_desc_label(desc_label)
	card_vbox.add_child(desc_label)
	card_vbox.add_child(_shop_vbox_fill_spacer())
	return _finalize_shop_offer(panel, price, index)

func _make_ball_card(def: BallDefinition, index: int, price: int) -> Control:
	var ability: String = def.ability_name if def else "Ball"
	var alignment: int = def.alignment if def else 0
	var rarity: int = def.rarity if def else 0
	var border_color: Color = _rarity_color(rarity)
	# Card panel with rarity border
	var panel: PanelContainer = PanelContainer.new()
	_apply_shop_card_fixed_size(panel)
	panel.modulate = Color(1, 1, 1, 1)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.1, 1)
	style.border_width_left = SHOP_CARD_BORDER_WIDTH
	style.border_width_right = SHOP_CARD_BORDER_WIDTH
	style.border_width_top = SHOP_CARD_BORDER_WIDTH
	style.border_width_bottom = SHOP_CARD_BORDER_WIDTH
	style.border_color = border_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	var card_vbox: VBoxContainer = _make_shop_card_layer(panel, rarity)
	var title_label: Label = Label.new()
	title_label.text = ability
	title_label.add_theme_font_size_override("font_size", SHOP_CARD_TITLE_FONT)
	title_label.add_theme_color_override("font_color", border_color)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(title_label)
	card_vbox.add_child(_shop_category_label("BALL"))
	# Ball preview (per-ability shape + alignment color, same as on board)
	var preview: Control = Control.new()
	preview.set_script(load("res://scenes/balls/ball_preview_control.gd") as GDScript)
	preview.custom_minimum_size = Vector2(38, 38)
	preview.alignment = alignment
	preview.shape_type = def.shape_type if def != null else -1
	var preview_center: CenterContainer = CenterContainer.new()
	preview_center.add_child(preview)
	card_vbox.add_child(preview_center)
	card_vbox.add_child(_shop_desc_placeholder())
	card_vbox.add_child(_shop_vbox_fill_spacer())
	return _finalize_shop_offer(panel, price, index)

func _make_peg_card(opt: MilestoneOption, index: int, price: int) -> Control:
	var kind: String = opt.peg_kind if opt else ""
	var info: Dictionary = PEG_SHOP_DISPLAY.get(kind, { "name": "Special Peg", "desc": "Place on the board after purchase." })
	var rarity: int = opt.rarity if opt else 0
	var border_color: Color = _rarity_color(rarity)
	var panel: PanelContainer = PanelContainer.new()
	_apply_shop_card_fixed_size(panel)
	panel.modulate = Color(1, 1, 1, 1)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.1, 1)
	style.border_width_left = SHOP_CARD_BORDER_WIDTH
	style.border_width_right = SHOP_CARD_BORDER_WIDTH
	style.border_width_top = SHOP_CARD_BORDER_WIDTH
	style.border_width_bottom = SHOP_CARD_BORDER_WIDTH
	style.border_color = border_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	var card_vbox: VBoxContainer = _make_shop_card_layer(panel, rarity)
	var title_label: Label = Label.new()
	title_label.text = info.get("name", kind)
	title_label.add_theme_font_size_override("font_size", SHOP_CARD_TITLE_FONT)
	title_label.add_theme_color_override("font_color", border_color)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(title_label)
	card_vbox.add_child(_shop_category_label("PEG"))
	card_vbox.add_child(_make_peg_shop_sprite_preview(kind))
	var desc_label: Label = Label.new()
	desc_label.text = info.get("desc", "")
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_style_desc_label(desc_label)
	card_vbox.add_child(desc_label)
	card_vbox.add_child(_shop_vbox_fill_spacer())
	return _finalize_shop_offer(panel, price, index)

const STAT_DISPLAY: Dictionary = {
	"main_charge": {
		"name": "Main Charge",
		"desc": "+5% energy to the main cannon per ball"
	},
	"door_interval": {
		"name": "Faster Waves",
		"desc": "10% less wait between waves"
	},
	"door_duration": {
		"name": "Longer Gate",
		"desc": "Gate stays open 10% longer"
	},
	"cannon_damage": {
		"name": "Cannon Damage",
		"desc": "+5 damage per wall shot"
	},
	"cannon_energy": {
		"name": "Cannon Energy",
		"desc": "Main cannon needs less energy to fire"
	},
	"hopper_width": {
		"name": "Wider Hopper",
		"desc": "+10% hopper width (max 2×)"
	}
}

## Preloaded so icons always resolve in editor/export (runtime load() on SVG paths can fail).
const _STAT_ICON_MAIN_CHARGE = preload("res://icons/ffffff/transparent/1x1/lorc/energy-arrow.svg")
const _STAT_ICON_DOOR_INTERVAL = preload("res://icons/ffffff/transparent/1x1/delapouite/speedometer.svg")
const _STAT_ICON_DOOR_DURATION = preload("res://icons/ffffff/transparent/1x1/lorc/hourglass.svg")
const _STAT_ICON_CANNON_DAMAGE = preload("res://icons/ffffff/transparent/1x1/lorc/cannon-shot.svg")
const _STAT_ICON_CANNON_ENERGY = preload("res://icons/ffffff/transparent/1x1/priorblue/battery-100.svg")
const _STAT_ICON_HOPPER_WIDTH = preload("res://icons/ffffff/transparent/1x1/delapouite/expand.svg")

const STAT_ICONS: Dictionary = {
	"main_charge": _STAT_ICON_MAIN_CHARGE,
	"door_interval": _STAT_ICON_DOOR_INTERVAL,
	"door_duration": _STAT_ICON_DOOR_DURATION,
	"cannon_damage": _STAT_ICON_CANNON_DAMAGE,
	"cannon_energy": _STAT_ICON_CANNON_ENERGY,
	"hopper_width": _STAT_ICON_HOPPER_WIDTH
}

const PEG_SHOP_DISPLAY: Dictionary = {
	"bomb": { "name": "Bomb Peg", "desc": "Blasts on hit. Place on an empty peg." },
	"trampoline": { "name": "Trampoline Peg", "desc": "Launches balls upward hard." },
	"goblin_reset": { "name": "Goblin Reset", "desc": "Catches balls and sends them to the top." },
	"gold": { "name": "Gold Peg", "desc": "3× energy when hit." },
	"splitter": { "name": "Splitter Peg", "desc": "Splits any ball into two." },
	"eternal": { "name": "Eternal Peg", "desc": "At 0 HP: refills at once (no rest)." },
	"extreme_bouncer": { "name": "Extreme Bouncer", "desc": "Very strong bounce." },
	"magnet": { "name": "Magnet Peg", "desc": "Pulls nearby balls in." },
	"lucky_gold": { "name": "Lucky Gold Peg", "desc": "Extra gold (1 or 5; better odds for 5)." },
	"phase": { "name": "Phase Peg", "desc": "Turns solid and ghost on a timer." },
	"wrench": { "name": "Wrench Peg", "desc": "Fixes nearby broken pegs when hit." },
	"gravity_well": { "name": "Gravity Well Peg", "desc": "Slows balls near it." }
}

func _make_stat_upgrade_icon(stat_id: String, tint: Color) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size = Vector2(0, 32)
	var tex: Texture2D = STAT_ICONS.get(stat_id) as Texture2D
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

func _make_stat_card(opt: MilestoneOption, index: int, price: int) -> Control:
	var stat_id: String = opt.stat_id if opt else ""
	var info: Dictionary = STAT_DISPLAY.get(stat_id, { "name": "Stat Up", "desc": "" })
	var rarity: int = opt.rarity if opt else 0
	var border_color: Color = _rarity_color(rarity)
	var panel: PanelContainer = PanelContainer.new()
	_apply_shop_card_fixed_size(panel)
	panel.modulate = Color(1, 1, 1, 1)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.1, 1)
	style.border_width_left = SHOP_CARD_BORDER_WIDTH
	style.border_width_right = SHOP_CARD_BORDER_WIDTH
	style.border_width_top = SHOP_CARD_BORDER_WIDTH
	style.border_width_bottom = SHOP_CARD_BORDER_WIDTH
	style.border_color = border_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	var card_vbox: VBoxContainer = _make_shop_card_layer(panel, rarity)
	var title_label: Label = Label.new()
	title_label.text = info.get("name", stat_id)
	title_label.add_theme_font_size_override("font_size", SHOP_CARD_TITLE_FONT)
	title_label.add_theme_color_override("font_color", border_color)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(title_label)
	card_vbox.add_child(_shop_category_label("STAT"))
	card_vbox.add_child(_make_stat_upgrade_icon(stat_id, border_color))
	var desc_label: Label = Label.new()
	desc_label.text = info.get("desc", "")
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_style_desc_label(desc_label)
	card_vbox.add_child(desc_label)
	card_vbox.add_child(_shop_vbox_fill_spacer())
	return _finalize_shop_offer(panel, price, index)

func _on_refresh_pressed() -> void:
	if not GameState or GameState.run_gold < Constants.SHOP_REFRESH_COST:
		return
	refresh_requested.emit()

func _on_done_pressed() -> void:
	set_process(false)
	_set_overlay_visible(false)
	hide()
	shop_done.emit()

func _on_pick_pressed(index: int) -> void:
	if index < 0 or index >= _picks.size():
		return
	if index < _purchased_flags.size() and _purchased_flags[index]:
		return
	var price: int = _compute_pick_price(_picks[index])
	if GameState == null or GameState.run_gold < price:
		return
	GameState.add_run_gold(-price)
	pick_selected.emit(_picks[index])
	_set_card_purchased(index)
