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

func _rarity_color(rarity: int) -> Color:
	if rarity >= 0 and rarity < RARITY_COLORS.size():
		return RARITY_COLORS[rarity]
	return RARITY_COLORS[0]

func _make_shop_card_layer(panel: PanelContainer, rarity: int) -> VBoxContainer:
	return RewardCardBuilder.make_shop_card_layer(panel, rarity, _rarity_color(rarity), SHOP_CARD_BORDER_WIDTH, SHOP_CARD_RARITY_MARKER_SIZE, SHOP_CARD_BODY_TOP_INSET)

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
	_modal_panel.custom_minimum_size = Vector2(520, 360)
	_modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_panel.add_theme_stylebox_override("panel", RewardDraftLayout.build_modal_panel_style())
	_modal_container.add_child(_modal_panel)
	
	var ui_nodes: Dictionary = RewardDraftLayout.setup_modal_contents(_modal_panel, _on_refresh_pressed, _on_hide_overlay_pressed, _on_done_pressed, SHOP_ROWS_SEPARATION)
	_gold_label = ui_nodes["gold_label"]
	_refresh_btn = ui_nodes["refresh_btn"]
	_top_row_container = ui_nodes["top_row"]
	_bottom_row_container = ui_nodes["bottom_row"]
	_done_btn = ui_nodes["done_btn"]

	_show_rewards_btn = Button.new()
	_show_rewards_btn.text = "Show rewards"
	_show_rewards_btn.visible = false
	_show_rewards_btn.z_index = 10
	_show_rewards_btn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_show_rewards_btn.offset_left = -100.0
	_show_rewards_btn.offset_right = 100.0
	_show_rewards_btn.offset_top = 10.0
	_show_rewards_btn.offset_bottom = 44.0
	var show_styles: Dictionary = RewardDraftLayout.build_show_rewards_button_styles()
	_show_rewards_btn.add_theme_stylebox_override("normal", show_styles["normal"])
	_show_rewards_btn.add_theme_stylebox_override("hover", show_styles["hover"])
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
	RewardDraftLayout.shop_kill_hover_tween(root)

func _wire_shop_offer_interactions(col: Control, index: int) -> void:
	RewardDraftLayout.wire_shop_offer_interactions(col, index, _can_shop_offer_interact, _on_pick_pressed, SHOP_OFFER_HOVER_SCALE, SHOP_OFFER_HOVER_TWEEN_SEC)

func _compute_pick_price(pick: Variant) -> int:
	return RewardCardBuilder.compute_pick_price(pick)

func _shop_category_label(category: String) -> Label:
	return RewardCardBuilder.shop_category_label(category)

func _shop_style_desc_label(desc_label: RichTextLabel) -> void:
	RewardCardBuilder.shop_style_desc_label(desc_label, SHOP_CARD_DESC_FONT, SHOP_CARD_DESC_TWO_LINES_H, SHOP_CARD_WIDTH)

func _shop_vbox_fill_spacer() -> Control:
	return RewardCardBuilder.shop_vbox_fill_spacer()

func _apply_shop_card_mouse_ignore(panel: PanelContainer) -> void:
	RewardCardBuilder.apply_shop_card_mouse_ignore(panel)

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

func _make_ball_preview_icon(alignment: int, shape_type: int, px: int, ability: String = "") -> Control:
	return RewardCardBuilder.make_ball_preview_icon(alignment, shape_type, px, ability)

func _make_basic_batch_ball_row() -> Control:
	return RewardCardBuilder.make_basic_batch_ball_row(RewardGeneration.BASIC_BATCH_SIZE)

## Renders the same peg visuals as the board, for milestone shop peg offers.
## Uses a Control + real Peg node in the main UI viewport; SubViewport + StaticBody2D + Rapier
## often produced an empty (black) render texture.
func _make_peg_shop_sprite_preview(peg_kind: String) -> Control:
	return RewardCardBuilder.make_peg_shop_sprite_preview(peg_kind)

func _make_purchased_overlay() -> Control:
	return RewardCardBuilder.make_purchased_overlay()

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

func _set_overlay_visible(overlay_on: bool) -> void:
	var modal_root: Control = get_node_or_null("ModalRoot") as Control
	if modal_root:
		modal_root.visible = overlay_on
	var peek_btn: Control = get_node_or_null("PeekButton") as Control
	if peek_btn:
		peek_btn.visible = not overlay_on
	mouse_filter = Control.MOUSE_FILTER_STOP if overlay_on else Control.MOUSE_FILTER_IGNORE

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

func _make_card_panel(border_color: Color) -> PanelContainer:
	return RewardCardBuilder.make_card_panel(border_color, SHOP_CARD_BORDER_WIDTH, SHOP_CARD_WIDTH, SHOP_CARD_FRAME_HEIGHT)

func _make_basic_batch_card(index: int, price: int) -> Control:
	var panel: PanelContainer = _make_card_panel(_rarity_color(0))
	var card_vbox: VBoxContainer = _make_shop_card_layer(panel, 0)
	var title_label: Label = Label.new()
	title_label.text = "+%d Plain Balls" % RewardGeneration.BASIC_BATCH_SIZE
	title_label.add_theme_font_size_override("font_size", SHOP_CARD_TITLE_FONT)
	title_label.add_theme_color_override("font_color", MilestoneShopData.TITLE_TEXT_COLOR)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(title_label)
	card_vbox.add_child(_shop_category_label("BALL"))
	card_vbox.add_child(_make_basic_batch_ball_row())
	var desc_label: RichTextLabel = RichTextLabel.new()
	_shop_style_desc_label(desc_label)
	KeywordDatabase.format_and_attach(desc_label, "Adds 10 Plain balls to your hopper for this run.", KeywordDatabase.HIGHLIGHT_COLOR, "[center]", "[/center]")
	card_vbox.add_child(desc_label)
	card_vbox.add_child(_shop_vbox_fill_spacer())
	return _finalize_shop_offer(panel, price, index)

func _make_ball_card(def: BallDefinition, index: int, price: int) -> Control:
	var ability: String = def.ability_name if def else "Ball"
	var alignment: int = def.alignment if def else 0
	var rarity: int = def.rarity if def else 0
	var border_color: Color = _rarity_color(rarity)
	var panel: PanelContainer = _make_card_panel(border_color)
	var card_vbox: VBoxContainer = _make_shop_card_layer(panel, rarity)
	var title_label: Label = Label.new()
	title_label.text = ability
	title_label.add_theme_font_size_override("font_size", SHOP_CARD_TITLE_FONT)
	var ab_for_title: String = def.ability_name if def != null and not def.ability_name.is_empty() else "Plain"
	if ability == "Ball":
		ab_for_title = "Plain"
	title_label.add_theme_color_override("font_color", MilestoneShopData.TITLE_TEXT_COLOR)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(title_label)
	card_vbox.add_child(_shop_category_label("BALL"))
	var preview: Control = Control.new()
	preview.set_script(load("res://scenes/balls/ball_preview_control.gd") as GDScript)
	preview.custom_minimum_size = Vector2(38, 38)
	preview.alignment = alignment
	preview.shape_type = def.shape_type if def != null else -1
	preview.ability_name = def.ability_name if def != null else ""
	var preview_center: CenterContainer = CenterContainer.new()
	preview_center.add_child(preview)
	card_vbox.add_child(preview_center)
	var ball_desc: RichTextLabel = RichTextLabel.new()
	_shop_style_desc_label(ball_desc)
	var raw_blurb: String = MilestoneShopData.shop_blurb_for_ball_ability(ab_for_title)
	KeywordDatabase.format_and_attach(ball_desc, raw_blurb, KeywordDatabase.HIGHLIGHT_COLOR, "[center]", "[/center]")
	card_vbox.add_child(ball_desc)
	card_vbox.add_child(_shop_vbox_fill_spacer())
	return _finalize_shop_offer(panel, price, index)

func _make_peg_card(opt: MilestoneOption, index: int, price: int) -> Control:
	var kind: String = opt.peg_kind if opt else ""
	var info: Dictionary = MilestoneShopData.PEG_SHOP_DISPLAY.get(kind, { "name": "Special Peg", "desc": "Place on the board after purchase." })
	var rarity: int = opt.rarity if opt else 0
	var border_color: Color = _rarity_color(rarity)
	var panel: PanelContainer = _make_card_panel(border_color)
	var card_vbox: VBoxContainer = _make_shop_card_layer(panel, rarity)
	var title_label: Label = Label.new()
	title_label.text = info.get("name", kind)
	title_label.add_theme_font_size_override("font_size", SHOP_CARD_TITLE_FONT)
	title_label.add_theme_color_override("font_color", MilestoneShopData.TITLE_TEXT_COLOR)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(title_label)
	card_vbox.add_child(_shop_category_label("PEG"))
	card_vbox.add_child(_make_peg_shop_sprite_preview(kind))
	var desc_label: RichTextLabel = RichTextLabel.new()
	_shop_style_desc_label(desc_label)
	var raw_desc: String = info.get("desc", "")
	KeywordDatabase.format_and_attach(desc_label, raw_desc, KeywordDatabase.HIGHLIGHT_COLOR, "[center]", "[/center]")
	card_vbox.add_child(desc_label)
	card_vbox.add_child(_shop_vbox_fill_spacer())
	return _finalize_shop_offer(panel, price, index)

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

func _make_stat_upgrade_icon(stat_id: String, _tint_unused: Color) -> Control:
	return RewardCardBuilder.make_stat_upgrade_icon(stat_id, MilestoneShopData.SHOP_ICON_NEUTRAL_TINT, STAT_ICONS)

func _make_stat_card(opt: MilestoneOption, index: int, price: int) -> Control:
	var stat_id: String = opt.stat_id if opt else ""
	var info: Dictionary = MilestoneShopData.STAT_DISPLAY.get(stat_id, { "name": "Stat Up", "desc": "" })
	var rarity: int = opt.rarity if opt else 0
	var border_color: Color = _rarity_color(rarity)
	var panel: PanelContainer = _make_card_panel(border_color)
	var card_vbox: VBoxContainer = _make_shop_card_layer(panel, rarity)
	var title_label: Label = Label.new()
	title_label.text = info.get("name", stat_id)
	title_label.add_theme_font_size_override("font_size", SHOP_CARD_TITLE_FONT)
	title_label.add_theme_color_override("font_color", MilestoneShopData.TITLE_TEXT_COLOR)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(title_label)
	card_vbox.add_child(_shop_category_label("STAT"))
	card_vbox.add_child(_make_stat_upgrade_icon(stat_id, border_color))
	var desc_label: RichTextLabel = RichTextLabel.new()
	_shop_style_desc_label(desc_label)
	var raw_stat_desc: String = info.get("desc", "")
	KeywordDatabase.format_and_attach(desc_label, raw_stat_desc, KeywordDatabase.HIGHLIGHT_COLOR, "[center]", "[/center]")
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
