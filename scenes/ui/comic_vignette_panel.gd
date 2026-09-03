extends Control
class_name ComicVignettePanel
## Right side panel comic cutout vignette overlay component (TASK-004).

#region Signals
signal vignette_triggered(damage: int, remaining_wall_hp: int)
signal vignette_dismissed
#endregion

#region Constants
const TEXTURE_FOCUSED: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Platformer Characters 1/PNG/Zombie/Poses/zombie_stand.png")
const TEXTURE_DETERMINED: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Platformer Characters 1/PNG/Zombie/Poses/zombie_action1.png")
const TEXTURE_CHEERING: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Platformer Characters 1/PNG/Zombie/Poses/zombie_cheer2.png")
const TEXTURE_ECSTATIC: Texture2D = preload("res://assets/Kenney Game Assets All-in-1 3.4.0/2D assets/Platformer Characters 1/PNG/Zombie/Poses/zombie_cheer1.png")
#endregion

#region Variables
@export var auto_dismiss_seconds: float = 1.2

var is_active: bool = false
var current_damage: int = 0
var remaining_hp: int = 0
var max_hp: int = 200

var _timer: SceneTreeTimer = null
var _character_rect: TextureRect = null
#endregion

#region Engine Callbacks
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_character_rect()
	hide()
#endregion

#region Public Methods
## Triggers comic cutout vignette with damage and wall health values.
func trigger_firing_vignette(p_damage: int, p_wall_hp: int, p_wall_hp_max: int = 200) -> void:
	current_damage = p_damage
	remaining_hp = maxi(0, p_wall_hp)
	max_hp = maxi(1, p_wall_hp_max)
	is_active = true
	_update_character_texture()
	show()
	vignette_triggered.emit(current_damage, remaining_hp)

	if is_inside_tree():
		var tree: SceneTree = get_tree()
		if tree != null:
			_timer = tree.create_timer(auto_dismiss_seconds)
			_timer.timeout.connect(dismiss_vignette)

## Dismisses current vignette panel.
func dismiss_vignette() -> void:
	if not is_active:
		return
	is_active = false
	hide()
	vignette_dismissed.emit()

## Calculates normalized wall degradation ratio between 0.0 and 1.0.
func get_wall_degradation_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return 1.0 - (float(remaining_hp) / float(max_hp))

## Returns mood state identifier based on wall degradation ratio.
func get_goblin_mood_state() -> StringName:
	var ratio: float = get_wall_degradation_ratio()
	if ratio >= 0.8:
		return &"ecstatic"
	elif ratio >= 0.5:
		return &"cheering"
	elif ratio >= 0.2:
		return &"determined"
	return &"focused"

## Returns matching character texture for given mood state.
func get_goblin_texture_for_mood(mood: StringName) -> Texture2D:
	match mood:
		&"ecstatic":
			return TEXTURE_ECSTATIC
		&"cheering":
			return TEXTURE_CHEERING
		&"determined":
			return TEXTURE_DETERMINED
		_:
			return TEXTURE_FOCUSED
#endregion

#region Private Methods
func _setup_character_rect() -> void:
	_character_rect = TextureRect.new()
	_character_rect.name = "CharacterRect"
	_character_rect.anchors_preset = Control.PRESET_FULL_RECT
	_character_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_character_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_character_rect.texture = TEXTURE_FOCUSED
	add_child(_character_rect)

func _update_character_texture() -> void:
	if _character_rect:
		var mood: StringName = get_goblin_mood_state()
		_character_rect.texture = get_goblin_texture_for_mood(mood)
#endregion
