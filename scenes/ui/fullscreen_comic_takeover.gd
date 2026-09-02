extends CanvasLayer
class_name FullscreenComicTakeover
## Full-screen comic book takeover cutscene overlay (TASK-005 & TASK-014).

signal takeover_started
signal panel_advanced(panel_index: int)
signal takeover_completed

@export var auto_advance_seconds: float = 1.5

var is_playing: bool = false
var current_panel_index: int = 0
var total_panels: int = 3

var _color_rect: ColorRect = null
var _label: Label = null
var _timer: SceneTreeTimer = null

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui_nodes()
	hide()

func _create_ui_nodes() -> void:
	_color_rect = ColorRect.new()
	_color_rect.anchors_preset = Control.PRESET_FULL_RECT
	_color_rect.color = Color(0.05, 0.05, 0.08, 0.92)
	add_child(_color_rect)

	_label = Label.new()
	_label.anchors_preset = Control.PRESET_CENTER
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 36)
	_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	add_child(_label)

func play_takeover(title_text: String = "WALL DESTROYED!") -> void:
	is_playing = true
	current_panel_index = 0
	show()
	takeover_started.emit()
	_show_panel(title_text)

func _show_panel(title_text: String) -> void:
	current_panel_index += 1
	panel_advanced.emit(current_panel_index)

	if _label:
		_label.text = "%s\n[ COMIC PANEL %d / %d ]" % [title_text, current_panel_index, total_panels]

	if is_inside_tree() and get_tree() != null:
		_timer = get_tree().create_timer(auto_advance_seconds)
		_timer.timeout.connect(_on_timer_timeout.bind(title_text))

func _on_timer_timeout(title_text: String) -> void:
	if current_panel_index < total_panels:
		_show_panel(title_text)
	else:
		dismiss_takeover()

func dismiss_takeover() -> void:
	is_playing = false
	hide()
	takeover_completed.emit()
