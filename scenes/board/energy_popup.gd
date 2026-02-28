extends Node2D
## Small floating text when a ball gains energy (e.g. peg hit). Floats up and fades to 0% over duration_sec.

const FLOAT_SPEED_PX_PER_SEC: float = 48.0
const DURATION_SEC: float = 1.0

var _elapsed: float = 0.0
var _label: Label
var _pending_text: String = ""

func _ready() -> void:
	_label = get_node_or_null("Label") as Label
	if _label:
		_label.modulate.a = 1.0
		if _pending_text != "":
			_label.text = _pending_text

func setup(text: String) -> void:
	_pending_text = text
	if _label:
		_label.text = text

func _process(delta: float) -> void:
	_elapsed += delta
	position.y -= FLOAT_SPEED_PX_PER_SEC * delta
	var t: float = clampf(_elapsed / DURATION_SEC, 0.0, 1.0)
	modulate.a = 1.0 - t
	if _elapsed >= DURATION_SEC:
		queue_free()
