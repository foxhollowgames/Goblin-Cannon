extends Control
## Full catalog of balls and upgrades with run tallies (×0 / ×N).

signal closed

var _game_coordinator: Node
var _reward_handler: Node
var _paused_before_open: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func setup(coordinator: Node, reward_handler: Node) -> void:
	_game_coordinator = coordinator
	_reward_handler = reward_handler

func toggle() -> void:
	if visible:
		_close()
	else:
		_open()

func _open() -> void:
	_paused_before_open = GameState.paused
	if not _paused_before_open:
		GameState.paused = true
	_rebuild()
	show()

func _close() -> void:
	hide()
	if not _paused_before_open:
		GameState.paused = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			_close()
			get_viewport().set_input_as_handled()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(MonsterPalette.VOID().r, MonsterPalette.VOID().g, MonsterPalette.VOID().b, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 540)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = MonsterPalette.UI_PANEL_BG()
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = MonsterPalette.UI_PANEL_BORDER()
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(root_vbox)

	var title_row: HBoxContainer = HBoxContainer.new()
	root_vbox.add_child(title_row)
	var title: Label = Label.new()
	title.text = "ALMANAC"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", MonsterPalette.SWATCH_CREAM())
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close_btn: Button = Button.new()
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	close_btn.pressed.connect(_close)
	title_row.add_child(close_btn)

	var hint: Label = Label.new()
	hint.text = "Catalog of all run content. Quantities show owned balls, unlocked pegs, or upgrade stacks."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", MonsterPalette.TAN())
	root_vbox.add_child(hint)

	var sep: ColorRect = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(MonsterPalette.FOREST().r, MonsterPalette.FOREST().g, MonsterPalette.FOREST().b, 0.8)
	root_vbox.add_child(sep)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	_build_balls_section(content)
	_build_pegs_section(content)
	_build_wall_section(content)
	_build_boss_section(content)

func _build_balls_section(parent: VBoxContainer) -> void:
	_add_section_header(parent, "BALLS")
	var defs: Array = []
	if _game_coordinator and _game_coordinator.has_method("get_debug_shop_ball_definitions"):
		defs = _game_coordinator.get_debug_shop_ball_definitions()
	var first_def_by_ability: Dictionary = {}
	for def in defs:
		if not def is BallDefinition:
			continue
		var d: BallDefinition = def as BallDefinition
		var lk: String = d.ability_name if not d.ability_name.is_empty() else "Plain"
		if first_def_by_ability.has(lk):
			continue
		first_def_by_ability[lk] = d
	var order: Array = first_def_by_ability.keys()
	order.sort()
	for lk in order:
		var d: BallDefinition = first_def_by_ability[lk] as BallDefinition
		var n: int = 0
		if _game_coordinator and _game_coordinator.has_method("get_ball_total_count_for_ability"):
			n = _game_coordinator.get_ball_total_count_for_ability(lk)
		var display_name: String = lk
		var label: String = "%s · %s" % [display_name, Constants.ball_rarity_display_name(d.ability_name, d.rarity)]
		var remove_cb: Callable = Callable()
		if n > 0 and _game_coordinator and _game_coordinator.has_method("remove_one_ball_for_ability"):
			var ledger_key: String = lk
			remove_cb = func():
				if _game_coordinator:
					_game_coordinator.remove_one_ball_for_ability(ledger_key)
				_rebuild()
		var name_color: Color = BallVisuals.get_ability_theme_color(lk).lerp(MonsterPalette.SWATCH_CREAM(), 0.38)
		_add_tally_row(parent, label, n, remove_cb, name_color)

func _build_pegs_section(parent: VBoxContainer) -> void:
	_add_section_header(parent, "PEG UNLOCKS (Merchant)")
	var pegs: Array = []
	if _reward_handler and _reward_handler.has_method("get_catalog_peg_milestone_options"):
		pegs = _reward_handler.get_catalog_peg_milestone_options()
	pegs.sort_custom(func(a: Variant, b: Variant) -> bool:
		var pa: MilestoneOption = a as MilestoneOption
		var pb: MilestoneOption = b as MilestoneOption
		if not pa or not pb:
			return false
		if pa.peg_kind != pb.peg_kind:
			return pa.peg_kind < pb.peg_kind
		return pa.rarity < pb.rarity
	)
	for p in pegs:
		if not p is MilestoneOption:
			continue
		var opt: MilestoneOption = p as MilestoneOption
		if opt.peg_kind.is_empty():
			continue
		var n: int = _peg_unlock_count(opt.peg_kind)
		var label: String = "%s · %s" % [opt.peg_kind.capitalize().replace("_", " "), _rarity_label(opt.rarity)]
		var remove_cb: Callable = Callable()
		if n > 0:
			var pk: String = opt.peg_kind
			remove_cb = func():
				if _game_coordinator and _game_coordinator.has_method("remove_one_peg_unlock_for_almanac"):
					_game_coordinator.remove_one_peg_unlock_for_almanac(pk)
				_rebuild()
		_add_tally_row(parent, label, n, remove_cb)

func _build_wall_section(parent: VBoxContainer) -> void:
	_add_section_header(parent, "RELICS")
	var list: Array = []
	if _reward_handler and _reward_handler.has_method("get_catalog_wall_break_major_definitions"):
		list = _reward_handler.get_catalog_wall_break_major_definitions()
	list.sort_custom(func(a: Variant, b: Variant) -> bool:
		var ma: MajorUpgradeDefinition = a as MajorUpgradeDefinition
		var mb: MajorUpgradeDefinition = b as MajorUpgradeDefinition
		if not ma or not mb:
			return false
		return String(ma.upgrade_id) < String(mb.upgrade_id)
	)
	for item in list:
		if not item is MajorUpgradeDefinition:
			continue
		var def: MajorUpgradeDefinition = item as MajorUpgradeDefinition
		var stacks: int = _wall_break_display_count(def)
		var label: String = def.display_name
		var remove_cb: Callable = Callable()
		if stacks > 0:
			var uid: StringName = def.upgrade_id
			remove_cb = func():
				if _game_coordinator and _game_coordinator.has_method("remove_one_wall_break_for_almanac"):
					_game_coordinator.remove_one_wall_break_for_almanac(uid)
				_rebuild()
		_add_tally_row(parent, label, stacks, remove_cb)

func _wall_break_display_count(def: MajorUpgradeDefinition) -> int:
	if not def or not GameState:
		return 0
	var uid: StringName = def.upgrade_id
	match uid:
		&"plain_surge":
			return GameState.plain_surge_stacks
		&"plain_horde":
			return GameState.plain_horde_stacks
		&"plain_momentum":
			return GameState.plain_momentum_stacks
		_:
			return GameState.get_wall_break_upgrade_stacks(uid)

func _build_boss_section(parent: VBoxContainer) -> void:
	_add_section_header(parent, "BOSS RELICS")
	var list: Array = []
	if _reward_handler and _reward_handler.has_method("get_catalog_boss_definitions"):
		list = _reward_handler.get_catalog_boss_definitions()
	list.sort_custom(func(a: Variant, b: Variant) -> bool:
		var ma: MajorUpgradeDefinition = a as MajorUpgradeDefinition
		var mb: MajorUpgradeDefinition = b as MajorUpgradeDefinition
		if not ma or not mb:
			return false
		return String(ma.upgrade_id) < String(mb.upgrade_id)
	)
	for item in list:
		if not item is MajorUpgradeDefinition:
			continue
		var def: MajorUpgradeDefinition = item as MajorUpgradeDefinition
		var stacks: int = 0
		if GameState:
			stacks = GameState.applied_boss_upgrades.get(def.upgrade_id, 0)
		var remove_cb: Callable = Callable()
		if stacks > 0:
			var uid: StringName = def.upgrade_id
			remove_cb = func():
				if _game_coordinator and _game_coordinator.has_method("remove_one_boss_for_almanac"):
					_game_coordinator.remove_one_boss_for_almanac(uid)
				_rebuild()
		_add_tally_row(parent, def.display_name, stacks, remove_cb)

func _peg_unlock_count(kind: String) -> int:
	if not GameState:
		return 0
	match kind:
		"bomb":
			return GameState.bomb_peg_count
		"trampoline":
			return GameState.trampoline_peg_count
		"goblin_reset":
			return GameState.goblin_reset_node_count
		"gold":
			return GameState.gold_peg_count
		"splitter":
			return GameState.splitter_peg_count
		"eternal":
			return GameState.eternal_peg_count
		"extreme_bouncer":
			return GameState.extreme_bouncer_peg_count
		"magnet":
			return GameState.magnet_peg_count
		"lucky_gold":
			return GameState.lucky_gold_peg_count
		"phase":
			return GameState.phase_peg_count
		"wrench":
			return GameState.wrench_peg_count
		"gravity_well":
			return GameState.gravity_well_peg_count
		_:
			return 0

func _rarity_label(r: int) -> String:
	match r:
		Constants.RARITY_COMMON:
			return "Common"
		Constants.RARITY_UNCOMMON:
			return "Uncommon"
		Constants.RARITY_RARE:
			return "Rare"
		Constants.RARITY_EPIC:
			return "Epic"
		_:
			return "Tier %d" % r

func _add_section_header(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", MonsterPalette.MINT().lerp(MonsterPalette.SWATCH_CREAM(), 0.4))
	parent.add_child(label)

func _add_tally_row(parent: VBoxContainer, label_text: String, count: int, on_remove: Callable = Callable(), label_color: Color = Color("#ffec99")) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	parent.add_child(row)
	var name_label: Label = Label.new()
	name_label.text = "  %s" % label_text
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", label_color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(name_label)
	var tally: Label = Label.new()
	tally.text = "×%d" % count
	tally.add_theme_font_size_override("font_size", 13)
	tally.add_theme_color_override("font_color", MonsterPalette.MINT() if count > 0 else MonsterPalette.UI_TEXT_MUTED())
	row.add_child(tally)
	if count > 0 and on_remove.is_valid():
		var del_btn: Button = Button.new()
		del_btn.text = "✕"
		del_btn.tooltip_text = "Remove 1 stack from your current run."
		del_btn.flat = true
		del_btn.custom_minimum_size = Vector2(28, 24)
		del_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		del_btn.add_theme_font_size_override("font_size", 16)
		del_btn.add_theme_color_override("font_color", MonsterPalette.RUST())
		del_btn.add_theme_color_override("font_hover_color", MonsterPalette.DUSTY_ROSE().lerp(MonsterPalette.SWATCH_CREAM(), 0.35))
		del_btn.pressed.connect(on_remove)
		row.add_child(del_btn)
	else:
		var spacer: Control = Control.new()
		spacer.custom_minimum_size = Vector2(28, 24)
		row.add_child(spacer)

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_close()
