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
func create_inventory_ui() -> void:
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
	btn.custom_minimum_size = Vector2(36, 32)
	btn.position = Vector2(198, 8)
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
	btn.custom_minimum_size = Vector2(36, 32)
	btn.position = Vector2(240, 8)
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
	btn.pressed.connect(pressed_cb)
	return btn

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
#endregion

