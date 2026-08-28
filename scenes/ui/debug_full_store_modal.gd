extends Control
## Debug: paginated shop with balls, pegs, wall breaks, boss rewards, and milestone stats + onboard/chest upgrades.

const ITEMS_PER_PAGE: int = 12
const TAB_COUNT: int = 5

## Matches MilestoneShopData.STAT_DISPLAY (merchant stat cards).
const _MILESTONE_STAT_UI: Dictionary = MilestoneShopData.STAT_DISPLAY

## Same strings as MilestoneShopData.PEG_SHOP_DISPLAY (peg merchant shop cards).
const _PEG_SHOP_DISPLAY: Dictionary = MilestoneShopData.PEG_SHOP_DISPLAY

## One-line blurbs for ball rows (matches ability set in BallVisuals).
const _BALL_ABILITY_BLURB: Dictionary = MilestoneShopData.BALL_SHOP_BLURB

const _STAT_ICON_MAIN_CHARGE = preload("res://icons/ffffff/transparent/1x1/lorc/energy-arrow.svg")
const _STAT_ICON_DOOR_INTERVAL = preload("res://icons/ffffff/transparent/1x1/delapouite/speedometer.svg")
const _STAT_ICON_DOOR_DURATION = preload("res://icons/ffffff/transparent/1x1/lorc/hourglass.svg")
const _STAT_ICON_CANNON_DAMAGE = preload("res://icons/ffffff/transparent/1x1/lorc/cannon-shot.svg")
const _STAT_ICON_CANNON_ENERGY = preload("res://icons/ffffff/transparent/1x1/priorblue/battery-100.svg")
const _STAT_ICON_HOPPER_WIDTH = preload("res://icons/ffffff/transparent/1x1/delapouite/expand.svg")
const _STAT_ICONS: Dictionary = {
	"main_charge": _STAT_ICON_MAIN_CHARGE,
	"door_interval": _STAT_ICON_DOOR_INTERVAL,
	"door_duration": _STAT_ICON_DOOR_DURATION,
	"cannon_damage": _STAT_ICON_CANNON_DAMAGE,
	"cannon_energy": _STAT_ICON_CANNON_ENERGY,
	"hopper_width": _STAT_ICON_HOPPER_WIDTH
}

const _ICON_WALL_BREAK = preload("res://icons/ffffff/transparent/1x1/willdabeast/round-shield.svg")
const _ICON_BOSS = preload("res://icons/ffffff/transparent/1x1/lorc/skull-crossed-bones.svg")
const _ICON_ONBOARD = preload("res://icons/ffffff/transparent/1x1/willdabeast/white-book.svg")

var _coordinator: Node
var _reward_handler: Node
var _tab_container: TabContainer
var _page_by_tab: Array[int] = [0, 0, 0, 0, 0]
var _page_labels: Array[Label] = []
var _prev_btns: Array[Button] = []
var _next_btns: Array[Button] = []
var _scroll_hosts: Array[VBoxContainer] = []
var _data_balls: Array = []
var _data_pegs: Array = []
var _data_wall: Array = []
var _data_boss: Array = []
var _data_stat_ids: Array = []
var _data_onboard: Array = []

func setup(coordinator: Node, reward_handler: Node) -> void:
	_coordinator = coordinator
	_reward_handler = reward_handler
	_build_ui()
	hide()

func show_modal() -> void:
	_reload_catalog_arrays()
	for i in range(TAB_COUNT):
		_page_by_tab[i] = 0
	for i in range(TAB_COUNT):
		_refresh_tab(i)
	show()

func hide_modal() -> void:
	hide()

func _reload_catalog_arrays() -> void:
	_data_balls.clear()
	_data_pegs.clear()
	_data_wall.clear()
	_data_boss.clear()
	_data_stat_ids.clear()
	_data_onboard.clear()
	if _coordinator and _coordinator.has_method("get_debug_shop_ball_definitions"):
		_data_balls = _coordinator.get_debug_shop_ball_definitions()
	if _reward_handler and _reward_handler.has_method("get_catalog_peg_milestone_options"):
		_data_pegs = _reward_handler.get_catalog_peg_milestone_options()
	if _reward_handler and _reward_handler.has_method("get_catalog_wall_break_major_definitions"):
		_data_wall = _reward_handler.get_catalog_wall_break_major_definitions()
	if _reward_handler and _reward_handler.has_method("get_catalog_boss_definitions"):
		_data_boss = _reward_handler.get_catalog_boss_definitions()
	if _reward_handler and _reward_handler.has_method("get_catalog_milestone_stat_ids"):
		_data_stat_ids = _reward_handler.get_catalog_milestone_stat_ids()
	if _reward_handler and _reward_handler.has_method("get_catalog_onboard_effect_definitions"):
		_data_onboard = _reward_handler.get_catalog_onboard_effect_definitions()

func _build_ui() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.06, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			hide_modal()
	)
	add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 520)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.1, 0.15, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.45, 0.38, 0.55, 1)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var outer: VBoxContainer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	margin.add_child(outer)

	var title_row: HBoxContainer = HBoxContainer.new()
	var title: Label = Label.new()
	title.text = "Debug — full store (free)"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close_btn: Button = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(72, 28)
	close_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	close_btn.pressed.connect(hide_modal)
	title_row.add_child(close_btn)
	outer.add_child(title_row)

	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.tab_changed.connect(_on_tab_changed)
	outer.add_child(_tab_container)

	var tab_names: Array[String] = ["Balls", "Pegs", "Wall breaks", "Boss rewards", "Stats & upgrades"]
	for i in range(TAB_COUNT):
		var tab_root: VBoxContainer = VBoxContainer.new()
		tab_root.name = tab_names[i]
		tab_root.add_theme_constant_override("separation", 6)
		var page_row: HBoxContainer = HBoxContainer.new()
		var prev: Button = Button.new()
		prev.text = "◀ Prev"
		prev.process_mode = Node.PROCESS_MODE_ALWAYS
		var page_lbl: Label = Label.new()
		page_lbl.text = "Page 1/1"
		page_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var next: Button = Button.new()
		next.text = "Next ▶"
		next.process_mode = Node.PROCESS_MODE_ALWAYS
		var idx: int = i
		prev.pressed.connect(func(): _change_page(idx, -1))
		next.pressed.connect(func(): _change_page(idx, 1))
		page_row.add_child(prev)
		page_row.add_child(page_lbl)
		page_row.add_child(next)
		tab_root.add_child(page_row)
		_prev_btns.append(prev)
		_page_labels.append(page_lbl)
		_next_btns.append(next)
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.custom_minimum_size = Vector2(0, 360)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var host: VBoxContainer = VBoxContainer.new()
		host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		host.add_theme_constant_override("separation", 4)
		scroll.add_child(host)
		tab_root.add_child(scroll)
		_scroll_hosts.append(host)
		_tab_container.add_child(tab_root)

func _on_tab_changed(_tab: int) -> void:
	pass

func _change_page(tab_idx: int, delta: int) -> void:
	var items: Array = _items_for_tab(tab_idx)
	var max_page: int = maxi(0, ceili(float(items.size()) / float(ITEMS_PER_PAGE)) - 1)
	_page_by_tab[tab_idx] = clampi(_page_by_tab[tab_idx] + delta, 0, max_page)
	_refresh_tab(tab_idx)

func _unique_ball_definitions(items: Array) -> Array:
	var seen: Dictionary = {}
	var out: Array = []
	for it in items:
		if not it is BallDefinition:
			continue
		var d: BallDefinition = it as BallDefinition
		var lk: String = d.ability_name if not d.ability_name.is_empty() else "Plain"
		if seen.has(lk):
			continue
		seen[lk] = true
		out.append(d)
	return out

func _items_for_tab(tab_idx: int) -> Array:
	match tab_idx:
		0:
			return _unique_ball_definitions(_data_balls)
		1:
			return _data_pegs
		2:
			return _data_wall
		3:
			return _data_boss
		4:
			return _stats_and_upgrades_items()
		_:
			return []

func _stats_and_upgrades_items() -> Array:
	var list: Array = []
	for sid in _data_stat_ids:
		list.append({"kind": "stat", "id": String(sid)})
	for d in _data_onboard:
		if d is MajorUpgradeDefinition:
			list.append({"kind": "onboard", "def": d})
	return list

func _milestone_stat_rarity_label(stat_id: String) -> String:
	var r: int = int(RewardGeneration.STAT_RARITY.get(stat_id, 0))
	match r:
		0:
			return "Common"
		1:
			return "Uncommon"
		2:
			return "Rare"
		_:
			return "Common"

func _style_desc_label(lbl: RichTextLabel) -> void:
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl.add_theme_font_size_override("normal_font_size", 11)
	lbl.add_theme_font_size_override("bold_font_size", 11)
	lbl.add_theme_font_size_override("italics_font_size", 11)
	lbl.add_theme_font_size_override("bold_italics_font_size", 11)
	lbl.add_theme_color_override("default_color", Color(0.82, 0.8, 0.86, 1))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _ball_blurb(ability_key: String) -> String:
	var k: String = ability_key.strip_edges()
	if k.is_empty():
		k = "Plain"
	return String(_BALL_ABILITY_BLURB.get(k, "Ball upgrade for your hopper."))

func _make_ball_preview(def: BallDefinition) -> Control:
	var preview: Control = Control.new()
	preview.set_script(load("res://scenes/balls/ball_preview_control.gd") as GDScript)
	preview.custom_minimum_size = Vector2(40, 40)
	if def:
		preview.alignment = def.alignment
		preview.shape_type = def.shape_type
		preview.ability_name = def.ability_name
	var wrap: CenterContainer = CenterContainer.new()
	wrap.custom_minimum_size = Vector2(44, 44)
	wrap.add_child(preview)
	return wrap

## Same approach as reward_draft_panel._make_peg_shop_sprite_preview (board peg visuals).
func _make_peg_shop_sprite_preview(peg_kind: String) -> Control:
	var holder: Control = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.custom_minimum_size = Vector2(44, 44)
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

func _make_icon_tile(tex: Texture2D, tint: Color) -> Control:
	var holder: CenterContainer = CenterContainer.new()
	holder.custom_minimum_size = Vector2(44, 44)
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(36, 36)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.modulate = tint
	holder.add_child(tr)
	return holder

func _refresh_tab(tab_idx: int) -> void:
	var host: VBoxContainer = _scroll_hosts[tab_idx]
	if not host:
		return
	for c in host.get_children():
		c.queue_free()
	var items: Array = _items_for_tab(tab_idx)
	var total_pages: int = maxi(1, ceili(float(items.size()) / float(ITEMS_PER_PAGE)))
	_page_by_tab[tab_idx] = clampi(_page_by_tab[tab_idx], 0, total_pages - 1)
	var page: int = _page_by_tab[tab_idx]
	if _page_labels.size() > tab_idx:
		_page_labels[tab_idx].text = "Page %d / %d  (%d items)" % [page + 1, total_pages, items.size()]
	var start: int = page * ITEMS_PER_PAGE
	var end: int = mini(start + ITEMS_PER_PAGE, items.size())
	for j in range(start, end):
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		host.add_child(row)
		var item = items[j]
		match tab_idx:
			0:
				_add_ball_row(row, item as BallDefinition)
			1:
				_add_peg_row(row, item as MilestoneOption)
			2:
				_add_wall_row(row, item as MajorUpgradeDefinition)
			3:
				_add_boss_row(row, item as MajorUpgradeDefinition)
			4:
				var entry: Dictionary = item as Dictionary
				if entry.get("kind") == "stat":
					_add_stat_row(row, String(entry.get("id", "")))
				else:
					_add_onboard_row(row, entry.get("def") as MajorUpgradeDefinition)

func _add_ball_row(row: HBoxContainer, def: BallDefinition) -> void:
	if not def:
		return
	var ab: String = def.ability_name if not def.ability_name.is_empty() else "Plain"
	row.add_child(_make_ball_preview(def))
	var text_col: VBoxContainer = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	var title: Label = Label.new()
	title.text = "%s · %s" % [ab, Constants.ball_rarity_display_name(def.ability_name, def.rarity)]
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", BallVisuals.get_ability_theme_color(ab).lerp(Color(0.92, 0.92, 0.95, 1), 0.35))
	var desc: RichTextLabel = RichTextLabel.new()
	_style_desc_label(desc)
	KeywordDatabase.format_and_attach(desc, _ball_blurb(ab))
	text_col.add_child(title)
	text_col.add_child(desc)
	row.add_child(text_col)
	var btn: Button = Button.new()
	btn.text = "Add"
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var d: BallDefinition = def.duplicate(true) as BallDefinition
	btn.pressed.connect(func(): _on_apply_ball(d))
	row.add_child(btn)

func _on_apply_ball(def: BallDefinition) -> void:
	if not _reward_handler or not def:
		return
	if _reward_handler.has_method("apply_ball_pick"):
		_reward_handler.apply_ball_pick(def.duplicate(true))

func _add_stat_row(row: HBoxContainer, stat_id: String) -> void:
	if stat_id.is_empty():
		return
	var ui: Dictionary = _MILESTONE_STAT_UI.get(stat_id, {"name": stat_id, "desc": ""})
	var icon_tex: Texture2D = _STAT_ICONS.get(stat_id) as Texture2D
	if icon_tex == null:
		icon_tex = _STAT_ICON_MAIN_CHARGE
	var tint: Color = Color(0.85, 0.78, 0.95, 1)
	row.add_child(_make_icon_tile(icon_tex, tint))
	var text_col: VBoxContainer = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	var title: Label = Label.new()
	title.text = "%s · %s" % [ui.get("name", stat_id), _milestone_stat_rarity_label(stat_id)]
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 1.0, 1))
	var desc: RichTextLabel = RichTextLabel.new()
	_style_desc_label(desc)
	KeywordDatabase.format_and_attach(desc, String(ui.get("desc", "")))
	text_col.add_child(title)
	text_col.add_child(desc)
	row.add_child(text_col)
	var btn: Button = Button.new()
	btn.text = "Apply"
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var sid: String = stat_id
	btn.pressed.connect(func(): _on_apply_stat(sid))
	row.add_child(btn)

func _on_apply_stat(stat_id: String) -> void:
	if stat_id.is_empty() or not _reward_handler:
		return
	if _reward_handler.has_method("apply_stat_upgrade"):
		_reward_handler.apply_stat_upgrade(stat_id)

func _add_onboard_row(row: HBoxContainer, def: MajorUpgradeDefinition) -> void:
	if not def:
		return
	row.add_child(_make_icon_tile(_ICON_ONBOARD, Color(0.9, 0.82, 0.55, 1)))
	var text_col: VBoxContainer = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	var title: Label = Label.new()
	title.text = def.display_name
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 1.0, 1))
	var desc: RichTextLabel = RichTextLabel.new()
	_style_desc_label(desc)
	KeywordDatabase.format_and_attach(desc, def.description)
	text_col.add_child(title)
	text_col.add_child(desc)
	row.add_child(text_col)
	var btn: Button = Button.new()
	btn.text = "Apply"
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var d: MajorUpgradeDefinition = def
	btn.pressed.connect(func(): _on_apply_onboard(d))
	row.add_child(btn)

func _on_apply_onboard(def: MajorUpgradeDefinition) -> void:
	if not _reward_handler or not def:
		return
	if _reward_handler.has_method("apply_major_upgrade"):
		_reward_handler.apply_major_upgrade(def)

func _add_peg_row(row: HBoxContainer, opt: MilestoneOption) -> void:
	if not opt:
		return
	var kind: String = opt.peg_kind
	var info: Dictionary = _PEG_SHOP_DISPLAY.get(kind, {"name": kind.capitalize().replace("_", " "), "desc": "Place on the board after purchase."})
	row.add_child(_make_peg_shop_sprite_preview(kind))
	var text_col: VBoxContainer = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	var title: Label = Label.new()
	title.text = String(info.get("name", kind))
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 1.0, 1))
	var desc: RichTextLabel = RichTextLabel.new()
	_style_desc_label(desc)
	KeywordDatabase.format_and_attach(desc, String(info.get("desc", "")))
	text_col.add_child(title)
	text_col.add_child(desc)
	row.add_child(text_col)
	var btn: Button = Button.new()
	btn.text = "Unlock"
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(func(): _on_apply_peg(kind))
	row.add_child(btn)

func _on_apply_peg(kind: String) -> void:
	if kind.is_empty() or not _reward_handler:
		return
	if _reward_handler.has_method("apply_peg_shop_unlock"):
		_reward_handler.apply_peg_shop_unlock(kind)
	var main: Node = _reward_handler.get_parent() if _reward_handler else null
	var board: Node = main.get_node_or_null("Board") if main else null
	if not board:
		return
	if board.has_method("get_nearest_normal_peg_id") and board.get_nearest_normal_peg_id(Vector2(480, 400), 9999.0) < 0:
		if board.has_method("add_extra_pegs_if_needed"):
			board.add_extra_pegs_if_needed()
		return
	var overlay_script: GDScript = load("res://scenes/board/peg_selection_overlay.gd") as GDScript
	if not overlay_script:
		return
	var ov: Node2D = Node2D.new()
	ov.set_script(overlay_script)
	ov.setup(board, kind)
	ov.peg_selected.connect(func(_id: int): ov.queue_free(), CONNECT_ONE_SHOT)
	main.add_child(ov)

func _add_wall_row(row: HBoxContainer, def: MajorUpgradeDefinition) -> void:
	if not def:
		return
	row.add_child(_make_icon_tile(_ICON_WALL_BREAK, Color(0.85, 0.75, 0.95, 1)))
	var text_col: VBoxContainer = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	var title: Label = Label.new()
	title.text = def.display_name
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55, 1))
	var desc: RichTextLabel = RichTextLabel.new()
	_style_desc_label(desc)
	KeywordDatabase.format_and_attach(desc, def.description)
	text_col.add_child(title)
	text_col.add_child(desc)
	row.add_child(text_col)
	var btn: Button = Button.new()
	btn.text = "Apply"
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var d: MajorUpgradeDefinition = def
	btn.pressed.connect(func(): _on_apply_wall(d))
	row.add_child(btn)

func _on_apply_wall(def: MajorUpgradeDefinition) -> void:
	if not _reward_handler or not def:
		return
	if _reward_handler.has_method("apply_major_upgrade"):
		_reward_handler.apply_major_upgrade(def)

func _add_boss_row(row: HBoxContainer, def: MajorUpgradeDefinition) -> void:
	if not def:
		return
	row.add_child(_make_icon_tile(_ICON_BOSS, Color(0.95, 0.55, 0.4, 1)))
	var text_col: VBoxContainer = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	var title: Label = Label.new()
	title.text = def.display_name
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.95, 0.65, 0.45, 1))
	var desc: RichTextLabel = RichTextLabel.new()
	_style_desc_label(desc)
	KeywordDatabase.format_and_attach(desc, def.description)
	text_col.add_child(title)
	text_col.add_child(desc)
	row.add_child(text_col)
	var btn: Button = Button.new()
	btn.text = "Apply"
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var d: MajorUpgradeDefinition = def
	btn.pressed.connect(func(): _on_apply_boss(d))
	row.add_child(btn)

func _on_apply_boss(def: MajorUpgradeDefinition) -> void:
	if not _reward_handler or not def:
		return
	if _reward_handler.has_method("apply_boss_upgrade"):
		_reward_handler.apply_boss_upgrade(def)
