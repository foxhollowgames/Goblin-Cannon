extends Node2D
## Overlay for selecting which peg to convert to a special type.
## Dims the screen, shows instruction text, highlights hovered peg, converts on click.
## Works while Engine.time_scale = 0 by using process_mode ALWAYS and real-time animation.

signal peg_selected(peg_id: int)

var _board: Node = null
var _peg_kind: String = ""
var _hovered_peg_id: int = -1
var _active: bool = false
var _dim_layer: CanvasLayer = null

func setup(board: Node, peg_kind: String) -> void:
	_board = board
	_peg_kind = peg_kind
	_active = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 50
	_create_ui()

func _create_ui() -> void:
	_dim_layer = CanvasLayer.new()
	_dim_layer.layer = 12
	_dim_layer.process_mode = Node.PROCESS_MODE_ALWAYS

	var dim_rect := ColorRect.new()
	dim_rect.color = Color(0.0, 0.0, 0.05, 0.4)
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_layer.add_child(dim_rect)

	var label: Label = Label.new()
	label.text = _get_instruction_text()
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", _get_kind_ui_color())
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.offset_left = 140.0
	label.offset_top = 150.0
	label.offset_right = 820.0
	label.offset_bottom = 190.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim_layer.add_child(label)

	add_child(_dim_layer)

func _get_instruction_text() -> String:
	match _peg_kind:
		"bomb":
			return "Click a peg to place a BOMB"
		"trampoline":
			return "Click a peg to place a TRAMPOLINE"
		"goblin_reset":
			return "Click a peg to place a GOBLIN RESET"
		"eternal":
			return "Click a peg to place an ETERNAL PEG"
		"extreme_bouncer":
			return "Click a peg to place an EXTREME BOUNCER"
		"magnet":
			return "Click a peg to place a MAGNET PEG"
		"splitter":
			return "Click a peg to place a SPLITTER PEG"
		"gold":
			return "Click a peg to place a GOLD PEG"
		"lucky_gold":
			return "Click a peg to place a LUCKY GOLD PEG"
		"gravity_well":
			return "Click a peg to place a GRAVITY WELL"
		"phase":
			return "Click a peg to place a PHASE PEG"
		"wrench":
			return "Click a peg to place a WRENCH PEG"
	return "Click a peg to convert"

func _get_kind_ui_color() -> Color:
	match _peg_kind:
		"bomb":
			return Color(1.0, 0.45, 0.2)
		"trampoline":
			return Color(0.35, 0.95, 0.6)
		"goblin_reset":
			return Color(0.65, 0.9, 0.45)
		"eternal":
			return Color(0.75, 0.8, 1.0)
		"extreme_bouncer":
			return Color(1.0, 0.65, 0.2)
		"magnet":
			return Color(0.9, 0.3, 0.3)
		"splitter":
			return Color(0.8, 0.5, 0.9)
		"gold":
			return Color(1.0, 0.9, 0.35)
		"lucky_gold":
			return Color(0.45, 0.95, 0.55)
		"gravity_well":
			return Color(0.55, 0.35, 0.85)
		"phase":
			return Color(0.45, 0.9, 0.95)
		"wrench":
			return Color(0.85, 0.7, 0.35)
	return Color(1.0, 0.9, 0.5)

func _process(_delta: float) -> void:
	if not _active or not _board:
		return
	var mouse_pos: Vector2 = get_global_mouse_position()
	_update_hovered_peg(mouse_pos)

func _update_hovered_peg(mouse_pos: Vector2) -> void:
	var best_id: int = -1
	if _board.has_method("get_nearest_normal_peg_id"):
		best_id = _board.get_nearest_normal_peg_id(mouse_pos)
	if best_id == _hovered_peg_id:
		return
	# Clear old
	if _hovered_peg_id >= 0:
		var old_peg: Node = _board.get_peg_by_id(_hovered_peg_id) if _board.has_method("get_peg_by_id") else null
		if old_peg and old_peg.has_method("set_hover_highlight"):
			old_peg.set_hover_highlight(false)
	_hovered_peg_id = best_id
	# Set new
	if _hovered_peg_id >= 0:
		var new_peg: Node = _board.get_peg_by_id(_hovered_peg_id) if _board.has_method("get_peg_by_id") else null
		if new_peg and new_peg.has_method("set_hover_highlight"):
			new_peg.set_hover_highlight(true, _peg_kind)

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _hovered_peg_id >= 0:
			_select_peg(_hovered_peg_id)
		get_viewport().set_input_as_handled()

func _select_peg(peg_id: int) -> void:
	_active = false
	var peg: Node = _board.get_peg_by_id(peg_id) if _board.has_method("get_peg_by_id") else null
	if peg:
		# Clear hover
		if peg.has_method("set_hover_highlight"):
			peg.set_hover_highlight(false)
		# Spawn transform effect
		var effect: Node2D = PegTransformEffect.new()
		effect.setup(_peg_kind)
		effect.global_position = peg.global_position
		get_parent().add_child(effect)
		# Convert the peg
		if _board.has_method("convert_specific_peg"):
			_board.convert_specific_peg(peg_id, _peg_kind)
	peg_selected.emit(peg_id)
	call_deferred("queue_free")
