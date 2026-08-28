extends Control
## Inventory panel overlay: balls, wall break upgrades, cannon & hopper stats.

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
	panel.custom_minimum_size = Vector2(420, 520)
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
	title.text = "INVENTORY"
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

	var sep: ColorRect = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(MonsterPalette.FOREST().r, MonsterPalette.FOREST().g, MonsterPalette.FOREST().b, 0.8)
	root_vbox.add_child(sep)

	if GameState:
		var gold_lbl: Label = Label.new()
		gold_lbl.text = "Gold: %d  (Merchant)" % GameState.run_gold
		gold_lbl.add_theme_font_size_override("font_size", 16)
		gold_lbl.add_theme_color_override("font_color", MonsterPalette.SWATCH_CREAM())
		root_vbox.add_child(gold_lbl)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)

	_build_balls_section(content)
	_build_upgrades_section(content)
	_build_stats_section(content)

func _build_balls_section(parent: VBoxContainer) -> void:
	var ball_types: Dictionary = {}
	if _game_coordinator and _game_coordinator.has_method("get_ball_inventory"):
		ball_types = _game_coordinator.get_ball_inventory()
	var bag_count: int = 0
	if _game_coordinator and _game_coordinator.has_method("get_bag_count"):
		bag_count = _game_coordinator.get_bag_count()
	var total: int = bag_count
	for count in ball_types.values():
		total += count

	_add_section_header(parent, "BALLS  (Total: %d)" % total)

	if ball_types.is_empty() and bag_count == 0:
		_add_body_text(parent, "  No balls yet")
		return
	var names: Array = ball_types.keys()
	names.sort()
	for ability_name in names:
		var count: int = ball_types[ability_name]
		_add_body_text(parent, "  %s  ×%d" % [ability_name, count])
	if bag_count > 0:
		_add_body_text(parent, "  Bag (overflow)  ×%d" % bag_count, MonsterPalette.TAN())

func _build_upgrades_section(parent: VBoxContainer) -> void:
	var wall_upgrades: Dictionary = GameState.applied_wall_break_upgrades
	var boss_upgrades: Dictionary = GameState.applied_boss_upgrades

	if wall_upgrades.is_empty() and boss_upgrades.is_empty():
		_add_section_header(parent, "RELICS")
		_add_body_text(parent, "  None yet")
		return

	if not wall_upgrades.is_empty():
		_add_section_header(parent, "RELICS")
		var ids: Array = wall_upgrades.keys()
		ids.sort()
		for uid in ids:
			var stacks: int = wall_upgrades[uid]
			var info: Dictionary = _get_upgrade_info(uid)
			var name_str: String = info.get("name", String(uid))
			if stacks > 1:
				name_str += "  ×%d" % stacks
			_add_body_text(parent, "  %s" % name_str, MonsterPalette.SWATCH_CREAM())
			var desc: String = info.get("description", "")
			if not desc.is_empty():
				_add_rich_body_text(parent, "    %s" % desc, MonsterPalette.TAN().lerp(MonsterPalette.INDIGO(), 0.25), 12)

	if not boss_upgrades.is_empty():
		_add_section_header(parent, "BOSS RELICS")
		var ids: Array = boss_upgrades.keys()
		ids.sort()
		for uid in ids:
			var info: Dictionary = _get_upgrade_info(uid)
			var name_str: String = info.get("name", String(uid))
			_add_body_text(parent, "  %s" % name_str, MonsterPalette.RUST())
			var desc: String = info.get("description", "")
			if not desc.is_empty():
				_add_rich_body_text(parent, "    %s" % desc, MonsterPalette.TAN().lerp(MonsterPalette.INDIGO(), 0.25), 12)

func _build_stats_section(parent: VBoxContainer) -> void:
	_add_section_header(parent, "CANNON")
	_add_stat_row(parent, "Damage Bonus", "+%d" % GameState.cannon_base_damage_bonus)
	var cr: float = GameState.cannon_charge_reduction / 100.0
	_add_stat_row(parent, "Charge Reduction", "-%.1f" % cr if cr > 0.001 else "0")
	_add_stat_row(parent, "Main Energy Bonus", "+%d%%" % int(GameState.main_charge_bonus * 100))

	if GameState.plain_surge_stacks > 0 or GameState.plain_horde_stacks > 0 or GameState.plain_momentum_stacks > 0:
		_add_section_header(parent, "PLAIN SWARM")
		if GameState.plain_surge_stacks > 0:
			_add_stat_row(parent, "Plain Surge", "+%d/hit" % GameState.plain_surge_stacks)
		if GameState.plain_horde_stacks > 0:
			_add_stat_row(parent, "Plain Horde", "%d stacks (max +3/hit)" % GameState.plain_horde_stacks)
		if GameState.plain_momentum_stacks > 0:
			_add_stat_row(parent, "Plain Momentum", "+%d/hit (6+ hits)" % GameState.plain_momentum_stacks)

	_add_section_header(parent, "HOPPER & CONDUIT")
	_add_stat_row(parent, "Hopper Width", "%.1fx" % GameState.hopper_width_scale)
	var dur_pct: int = int((GameState.conduit_open_duration_scale - 1.0) * 100)
	_add_stat_row(parent, "Gate Duration", "+%d%%" % dur_pct if dur_pct > 0 else "Base")
	_add_stat_row(parent, "Wave Interval", "%.1fx" % GameState.conduit_wave_interval_scale)

	var board_stats: Array = []
	if GameState.explosion_radius_bonus > 0:
		board_stats.append(["Explosion Radius", "+%d" % GameState.explosion_radius_bonus])
	if GameState.explosion_peg_hit_count_bonus > 0:
		board_stats.append(["Explosion Hit Count", "+%d" % GameState.explosion_peg_hit_count_bonus])
	if GameState.explosion_impulse_bonus > 0.0:
		board_stats.append(["Explosion Impulse", "+%.0f%%" % (GameState.explosion_impulse_bonus * 100)])
	if GameState.chain_arc_bonus > 0:
		board_stats.append(["Chain Arcs", "+%d" % GameState.chain_arc_bonus])
	if GameState.chain_range_bonus > 0:
		board_stats.append(["Chain Range", "+%d" % GameState.chain_range_bonus])
	if GameState.max_energize_stacks_per_peg != 3:
		board_stats.append(["Max Energize Stacks", "%d" % GameState.max_energize_stacks_per_peg])
	if GameState.energize_decay_scale < 1.0:
		board_stats.append(["Energize Decay", "%.0f%%" % (GameState.energize_decay_scale * 100)])
	if GameState.energized_peg_repair_scale > 1.0:
		board_stats.append(["Peg Repair (Energized)", "+%.0f%%" % ((GameState.energized_peg_repair_scale - 1.0) * 100)])
	if GameState.global_peg_durability_bonus > 0:
		board_stats.append(["Peg Durability", "+%d" % GameState.global_peg_durability_bonus])
	if GameState.peg_recovery_speed_scale > 1.0:
		board_stats.append(["Peg Recovery Speed", "+%.0f%%" % ((GameState.peg_recovery_speed_scale - 1.0) * 100)])
	if GameState.chest_leech_drain_stacks > 0:
		board_stats.append(["Chest: Drain Rate", "+%d/sec" % GameState.chest_leech_drain_stacks])
	if GameState.chest_leech_duration_stacks > 0:
		board_stats.append(["Chest: Drain Duration", "+%ds" % GameState.chest_leech_duration_stacks])
	if GameState.chest_phantom_energy_stacks > 0:
		board_stats.append(["Chest: Phantom Hits", "+%d%%" % (GameState.chest_phantom_energy_stacks * 5)])
	if GameState.chest_rubbery_energy_stacks > 0:
		board_stats.append(["Chest: Rubbery Hits", "+%d%%" % (GameState.chest_rubbery_energy_stacks * 5)])
	if GameState.chest_bounce_energy_stacks > 0:
		board_stats.append(["Chest: Plain Hits", "+%d%%" % (GameState.chest_bounce_energy_stacks * 5)])
	if GameState.chest_split_energy_stacks > 0:
		board_stats.append(["Chest: Split Fragments", "+%d%%" % (GameState.chest_split_energy_stacks * 5)])
	if GameState.bomb_peg_count > 0:
		board_stats.append(["Bomb Pegs", "%d" % GameState.bomb_peg_count])
	if GameState.trampoline_peg_count > 0:
		board_stats.append(["Trampoline Pegs", "%d" % GameState.trampoline_peg_count])
	if GameState.goblin_reset_node_count > 0:
		board_stats.append(["Goblin Reset Nodes", "%d" % GameState.goblin_reset_node_count])
	if GameState.eternal_peg_count > 0:
		board_stats.append(["Eternal Pegs", "%d" % GameState.eternal_peg_count])
	if GameState.extreme_bouncer_peg_count > 0:
		board_stats.append(["Extreme Bouncers", "%d" % GameState.extreme_bouncer_peg_count])
	if GameState.magnet_peg_count > 0:
		board_stats.append(["Magnet Pegs", "%d" % GameState.magnet_peg_count])
	if GameState.splitter_peg_count > 0:
		board_stats.append(["Splitter Pegs", "%d" % GameState.splitter_peg_count])
	if GameState.gold_peg_count > 0:
		board_stats.append(["Gold Pegs", "%d" % GameState.gold_peg_count])
	if GameState.lucky_gold_peg_count > 0:
		board_stats.append(["Lucky Gold Pegs", "%d" % GameState.lucky_gold_peg_count])
	if GameState.gravity_well_peg_count > 0:
		board_stats.append(["Gravity Wells", "%d" % GameState.gravity_well_peg_count])
	if GameState.phase_peg_count > 0:
		board_stats.append(["Phase Pegs", "%d" % GameState.phase_peg_count])
	if GameState.wrench_peg_count > 0:
		board_stats.append(["Wrench Pegs", "%d" % GameState.wrench_peg_count])
	if not board_stats.is_empty():
		_add_section_header(parent, "BOARD")
		for stat in board_stats:
			_add_stat_row(parent, stat[0], stat[1])

func _add_section_header(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", MonsterPalette.MINT().lerp(MonsterPalette.SWATCH_CREAM(), 0.35))
	parent.add_child(label)

func _add_body_text(parent: VBoxContainer, text: String, color: Color = Color("#d1a990"), font_size: int = 14) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)

func _add_rich_body_text(parent: VBoxContainer, text: String, color: Color = Color("#d1a990"), font_size: int = 14) -> void:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_font_size_override("bold_font_size", font_size)
	label.add_theme_font_size_override("italics_font_size", font_size)
	label.add_theme_font_size_override("bold_italics_font_size", font_size)
	label.add_theme_color_override("default_color", color)
	KeywordDatabase.format_and_attach(label, text)
	parent.add_child(label)

func _add_stat_row(parent: VBoxContainer, stat_name: String, value: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	parent.add_child(row)
	var name_label: Label = Label.new()
	name_label.text = "  %s" % stat_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", MonsterPalette.TAN())
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var value_label: Label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", MonsterPalette.SWATCH_CREAM())
	row.add_child(value_label)

func _get_upgrade_info(upgrade_id: StringName) -> Dictionary:
	if _reward_handler and _reward_handler.has_method("get_upgrade_display_info"):
		return _reward_handler.get_upgrade_display_info(upgrade_id)
	return {"name": String(upgrade_id), "description": ""}

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_close()
