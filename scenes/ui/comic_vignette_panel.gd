extends Control
class_name ComicVignettePanel
## Right side panel comic cutout vignette overlay component (TASK-004).

signal vignette_triggered(damage: int, remaining_wall_hp: int)
signal vignette_dismissed

@export var auto_dismiss_seconds: float = 1.2

var is_active: bool = false
var current_damage: int = 0
var remaining_hp: int = 0
var max_hp: int = 200

var _timer: SceneTreeTimer = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func trigger_firing_vignette(p_damage: int, p_wall_hp: int, p_wall_hp_max: int = 200) -> void:
	current_damage = p_damage
	remaining_hp = maxi(0, p_wall_hp)
	max_hp = maxi(1, p_wall_hp_max)
	is_active = true
	show()
	vignette_triggered.emit(current_damage, remaining_hp)

	if is_inside_tree():
		var tree: SceneTree = get_tree()
		if tree != null:
			_timer = tree.create_timer(auto_dismiss_seconds)
			_timer.timeout.connect(dismiss_vignette)

func dismiss_vignette() -> void:
	if not is_active:
		return
	is_active = false
	hide()
	vignette_dismissed.emit()

func get_wall_degradation_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return 1.0 - (float(remaining_hp) / float(max_hp))

func get_goblin_mood_state() -> StringName:
	var ratio: float = get_wall_degradation_ratio()
	if ratio >= 0.8:
		return &"ecstatic"
	elif ratio >= 0.5:
		return &"cheering"
	elif ratio >= 0.2:
		return &"determined"
	return &"focused"
