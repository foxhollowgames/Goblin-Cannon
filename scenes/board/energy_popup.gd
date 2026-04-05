extends Node2D
## Small floating text when a ball gains energy (e.g. peg hit). Floats up and fades to 0% over duration_sec.

const FLOAT_SPEED_PX_PER_SEC: float = 48.0
const DURATION_SEC: float = 1.0

var _elapsed: float = 0.0
var _label: Label
var _pending_text: String = ""
var _pool_release: Callable = Callable()

func _ready() -> void:
	_label = get_node_or_null("Label") as Label
	if _label:
		_label.modulate.a = 1.0
		if _pending_text != "":
			_label.text = _pending_text

## When set, finished popups call this instead of queue_free() (object pooling on Board).
func set_pool_release(release_cb: Callable) -> void:
	_pool_release = release_cb

func setup(text: String) -> void:
	_elapsed = 0.0
	_pending_text = text
	modulate.a = 1.0
	if _label:
		_label.text = text

func _process(delta: float) -> void:
	_elapsed += delta
	position.y -= FLOAT_SPEED_PX_PER_SEC * delta
	var t: float = clampf(_elapsed / DURATION_SEC, 0.0, 1.0)
	modulate.a = 1.0 - t
	if _elapsed >= DURATION_SEC:
		if _pool_release.is_valid():
			_pool_release.call(self)
		else:
			queue_free()
