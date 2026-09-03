class_name GameCoordinatorUI
extends Node
## UI element creation, modals (inventory, almanac, junk box), and debug overlays for GameCoordinator.

#region State and References
var _coordinator_root: Node = null
var _inventory_modal: Control = null
var _almanac_modal: Control = null
var _junk_box_modal: Control = null
var _debug_overlay: Control = null
#endregion

#region Initialization
## Initializes UI manager with reference to root GameCoordinator node.
func setup(coordinator_root: Node) -> void:
	_coordinator_root = coordinator_root
#endregion

#region UI Creation API
## Creates and attaches the inventory UI panel.
func setup_inventory_ui() -> void:
	if not _coordinator_root:
		return
	if _coordinator_root.has_method("_create_inventory_ui_internal"):
		_coordinator_root._create_inventory_ui_internal()

## Creates and attaches the debug overlay panel.
func create_debug_overlay() -> void:
	if not _coordinator_root:
		return
	if _coordinator_root.has_method("_create_debug_overlay_internal"):
		_coordinator_root._create_debug_overlay_internal()
#endregion

#region Modal Toggles
## Toggles visibility of the inventory modal panel.
func toggle_inventory_modal() -> void:
	if _coordinator_root and _coordinator_root.has_method("_toggle_inventory_modal"):
		_coordinator_root._toggle_inventory_modal()

## Toggles visibility of the almanac modal panel.
func toggle_almanac_modal() -> void:
	if _coordinator_root and _coordinator_root.has_method("_toggle_almanac_modal"):
		_coordinator_root._toggle_almanac_modal()

## Toggles visibility of the junk box modal panel.
func toggle_junk_box_modal() -> void:
	if _coordinator_root and _coordinator_root.has_method("_toggle_junk_box_modal"):
		_coordinator_root._toggle_junk_box_modal()
#region Button Builders
## Builds the Almanac UI toggle button.
static func build_almanac_button(pressed_cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = ""
	btn.tooltip_text = "Almanac (L): Open the catalog of all balls, pegs, and relics."
	btn.custom_minimum_size = Vector2(38, 36)
	btn.position = Vector2(12, 9)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = MonsterPalette.ALMANAC_BTN_BG()
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = MonsterPalette.ALMANAC_BTN_BORDER()
	btn_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	var hc: Color = MonsterPalette.SLATE().lerp(MonsterPalette.INDIGO(), 0.4)
	btn_hover.bg_color = Color(hc.r, hc.g, hc.b, 0.95)
	btn.add_theme_stylebox_override("hover", btn_hover)
	var btn_pressed_style: StyleBoxFlat = btn_style.duplicate()
	var pc: Color = MonsterPalette.INDIGO().lerp(MonsterPalette.VOID(), 0.2)
	btn_pressed_style.bg_color = Color(pc.r, pc.g, pc.b, 0.95)
	btn.add_theme_stylebox_override("pressed", btn_pressed_style)
	var book_icon: Image = create_book_icon_image()
	if book_icon:
		btn.icon = ImageTexture.create_from_image(book_icon)
	btn.pressed.connect(pressed_cb)
	return btn

## Creates procedural 20x20 pixel book icon image.
static func create_book_icon_image() -> Image:
	var s: int = 20
	var img: Image = Image.create(s, s, false, Image.FORMAT_RGBA8)
	var paper: Color = MonsterPalette.SWATCH_CREAM()
	var ink: Color = MonsterPalette.INDIGO()
	for y in range(4, 17):
		for x in range(5, 10):
			img.set_pixel(x, y, paper)
		for x in range(11, 16):
			img.set_pixel(x, y, paper)
	for x in range(5, 16):
		img.set_pixel(x, 4, ink)
		img.set_pixel(x, 16, ink)
	for y in range(4, 17):
		img.set_pixel(5, y, ink)
		img.set_pixel(15, y, ink)
	for x in range(7, 14):
		img.set_pixel(x, 8, ink)
		img.set_pixel(x, 11, ink)
	return img

## Builds the Junk Box bag UI toggle button.
static func build_bag_button(pressed_cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = ""
	btn.tooltip_text = "Junk Box (I / B / Esc): Open your Junk Box inventory and drag modules to the board."
	btn.custom_minimum_size = Vector2(38, 36)
	btn.position = Vector2(56, 9)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = MonsterPalette.BAG_BTN_BG()
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = MonsterPalette.BAG_BTN_BORDER()
	btn_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	var bag_h: Color = MonsterPalette.INDIGO().lerp(MonsterPalette.TAN(), 0.15)
	btn_hover.bg_color = Color(bag_h.r, bag_h.g, bag_h.b, 0.95)
	btn.add_theme_stylebox_override("hover", btn_hover)
	var btn_pressed_style: StyleBoxFlat = btn_style.duplicate()
	var bag_p: Color = MonsterPalette.WARM_BROWN().lerp(MonsterPalette.INDIGO(), 0.35)
	btn_pressed_style.bg_color = Color(bag_p.r, bag_p.g, bag_p.b, 0.95)
	btn.add_theme_stylebox_override("pressed", btn_pressed_style)
	var bag_icon: Image = create_bag_icon_image()
	if bag_icon:
		btn.icon = ImageTexture.create_from_image(bag_icon)
	var badge: Label = Label.new()
	badge.name = "ItemCountBadge"
	badge.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	badge.anchor_left = 1.0
	badge.anchor_top = 1.0
	badge.anchor_right = 1.0
	badge.anchor_bottom = 1.0
	badge.offset_left = -16.0
	badge.offset_top = -14.0
	badge.offset_right = 2.0
	badge.offset_bottom = 2.0
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", MonsterPalette.SWATCH_CREAM())
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	btn.add_child(badge)
	btn.pressed.connect(pressed_cb)
	return btn

## Updates ItemCountBadge label and CenterPanel Junk label with current item count.
static func update_bag_button_badge(inventory_btn: Button, parent_node: Node) -> void:
	var count: int = GameState.junk_box.get_item_count() if GameState.junk_box != null else 0
	if inventory_btn:
		var badge: Label = inventory_btn.get_node_or_null("ItemCountBadge") as Label
		if badge:
			badge.text = str(count) if count > 0 else ""
	if parent_node:
		var bag_lbl: Label = parent_node.get_node_or_null("UILayer/CenterPanel/BagPanel/BagLabel") as Label
		if bag_lbl:
			bag_lbl.text = "JUNK: %d" % count

## Creates procedural 20x20 pixel bag icon image.
static func create_bag_icon_image() -> Image:
	var s: int = 20
	var img: Image = Image.create(s, s, false, Image.FORMAT_RGBA8)
	var leather: Color = MonsterPalette.TAN()
	var trim: Color = MonsterPalette.WARM_BROWN()
	for y in range(7, 17):
		for x in range(5, 15):
			img.set_pixel(x, y, leather)
	for x in range(5, 15):
		img.set_pixel(x, 7, trim)
		img.set_pixel(x, 16, trim)
	for y in range(7, 17):
		img.set_pixel(5, y, trim)
		img.set_pixel(14, y, trim)
	for x in range(8, 12):
		img.set_pixel(x, 4, trim)
		img.set_pixel(x, 5, trim)
	return img
## Updates center panel fortification, gold, bag count, cannon charge, and timer.
static func update_center_ui(center_panel_ui: Control, combat_manager: Node, systems_container: Node, bag_queue_size: int) -> void:
	if not center_panel_ui:
		return
	var wall_hp: int = 200
	var wall_max: int = 200
	if combat_manager:
		if combat_manager.has_method("get_wall_hp"):
			wall_hp = combat_manager.get_wall_hp()
		if combat_manager.has_method("get_wall_hp_max"):
			wall_max = combat_manager.get_wall_hp_max()
	if center_panel_ui.has_method("set_fortification"):
		center_panel_ui.set_fortification(wall_hp, wall_max)
	if center_panel_ui.has_method("set_run_gold") and GameState:
		center_panel_ui.set_run_gold(GameState.run_gold)
	if center_panel_ui.has_method("set_bag"):
		center_panel_ui.set_bag(bag_queue_size)
	var main_energy: int = 0
	if systems_container:
		var mc: Node = systems_container.get_node_or_null("MainCannon")
		if mc and mc.has_method("get_current_energy"):
			main_energy = mc.get_current_energy()
	var charge_max: int = Constants.main_cannon_charge_internal()
	if systems_container:
		var mc: Node = systems_container.get_node_or_null("MainCannon")
		if mc and mc.has_method("get_charge_threshold"):
			charge_max = mc.get_charge_threshold()
	if center_panel_ui.has_method("set_charge"):
		center_panel_ui.set_charge(main_energy, charge_max)
	if center_panel_ui.has_method("set_timer") and combat_manager and combat_manager.has_method("get_timer_seconds_remaining"):
		center_panel_ui.set_timer(combat_manager.get_timer_seconds_remaining())

## Instantiates inventory overlay, junk box panel, and almanac modal panels.
static func create_inventory_ui(coordinator: Node, reward_handler: Node, board: Node) -> Dictionary:
	var main: Node = coordinator.get_parent() if coordinator else null
	if not main:
		return {}
	var overlay: CanvasLayer = CanvasLayer.new()
	overlay.layer = 20
	overlay.name = "InventoryOverlay"
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(overlay)

	var inv_panel: Control = null
	var panel_scene: PackedScene = load("res://scenes/ui/inventory_panel.tscn") as PackedScene
	if panel_scene:
		inv_panel = panel_scene.instantiate() as Control
		if inv_panel:
			overlay.add_child(inv_panel)
			if inv_panel.has_method("setup"):
				inv_panel.setup(coordinator, reward_handler)

	var jb_panel: Control = null
	var junk_box_scene: PackedScene = load("res://scenes/ui/junk_box/junk_box_panel.tscn") as PackedScene
	if junk_box_scene:
		jb_panel = junk_box_scene.instantiate() as Control
		if jb_panel:
			var right_panel: Control = main.get_node_or_null("UILayer/CenterPanel") as Control
			if right_panel and jb_panel.has_method("integrate_into_sidebar"):
				jb_panel.integrate_into_sidebar(right_panel)
			else:
				overlay.add_child(jb_panel)
			if jb_panel.has_method("setup"):
				jb_panel.setup(coordinator, reward_handler)
			if board and jb_panel.has_method("set_board"):
				jb_panel.set_board(board)

	var alm_panel: Control = null
	var almanac_scene: PackedScene = load("res://scenes/ui/almanac_panel.tscn") as PackedScene
	if almanac_scene:
		alm_panel = almanac_scene.instantiate() as Control
		if alm_panel:
			overlay.add_child(alm_panel)
			if alm_panel.has_method("setup"):
				alm_panel.setup(coordinator, reward_handler)

	var cv_script: Script = load("res://scenes/ui/comic_vignette_panel.gd") as Script
	var cv_panel: Control = null
	if cv_script:
		cv_panel = cv_script.new() as Control
		if cv_panel:
			overlay.add_child(cv_panel)
			var cm: Node = main.get_node_or_null("CombatManager")
			if cm and cm.has_signal("cannon_fired_at_wall") and cv_panel.has_method("trigger_firing_vignette"):
				cm.cannon_fired_at_wall.connect(cv_panel.trigger_firing_vignette)

	var circular_widget: Control = null
	if jb_panel and jb_panel.find_child("CircularCannonWidget", true, false):
		circular_widget = jb_panel.find_child("CircularCannonWidget", true, false) as Control
	else:
		var circular_cannon_script: Script = load("res://scenes/ui/circular_cannon_widget.gd") as Script
		if circular_cannon_script:
			circular_widget = circular_cannon_script.new() as Control
			if circular_widget:
				circular_widget.name = "CircularCannonWidget"
				var ui_layer: Node = main.get_node_or_null("UILayer")
				if ui_layer:
					ui_layer.add_child(circular_widget)
	if circular_widget:
		var cm: Node = main.get_node_or_null("CombatManager")
		if cm and cm.has_signal("cannon_fired_at_wall") and circular_widget.has_method("trigger_firing_anim"):
			cm.cannon_fired_at_wall.connect(func(_dmg, _hp, _max): circular_widget.trigger_firing_anim())
		var bf: Node = main.get_node_or_null("CombatContainer/BattlefieldView")
		if bf:
			if bf.has_signal("terrain_advance_started") and circular_widget.has_method("start_advancing"):
				bf.terrain_advance_started.connect(circular_widget.start_advancing)
			if bf.has_signal("terrain_advance_stopped") and circular_widget.has_method("stop_advancing"):
				bf.terrain_advance_stopped.connect(circular_widget.stop_advancing)

	var takeover_script: Script = load("res://scenes/ui/fullscreen_comic_takeover.gd") as Script
	var takeover_overlay: CanvasLayer = null
	if takeover_script:
		takeover_overlay = takeover_script.new() as CanvasLayer
		if takeover_overlay:
			takeover_overlay.name = "FullscreenComicTakeover"
			main.add_child(takeover_overlay)

	return {
		"inventory_panel": inv_panel,
		"junk_box_panel": jb_panel,
		"almanac_panel": alm_panel,
		"comic_vignette_panel": cv_panel,
		"circular_cannon_widget": circular_widget,
		"fullscreen_takeover": takeover_overlay
	}
#endregion

