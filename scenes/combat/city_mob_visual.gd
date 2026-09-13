extends Node2D
class_name CityMobVisual
## Animated mob representing the current city defending its fortifications.
## Marches leftward from the wall toward the player cannon over the siege timer duration.

#region Signals
signal mob_reached_cannon
#endregion

#region Constants
const START_X: float = 1100.0
const TARGET_X: float = 125.0
const MOB_Y: float = 62.0
const WALK_CYCLE_SPEED: float = 5.0
const STEP_BOB_HEIGHT: float = 4.0

const CITY_HALFLING: int = 0
const CITY_HUMAN: int = 1
const CITY_ELF: int = 2

const THEME_HALFLING: Texture2D = preload("res://icons/ffffff/transparent/1x1/delapouite/farmer.svg")
const THEME_HUMAN: Texture2D = preload("res://icons/ffffff/transparent/1x1/cathelineau/swordman.svg")
const THEME_ELF: Texture2D = preload("res://icons/ffffff/transparent/1x1/delapouite/woman-elf-face.svg")
#endregion

#region Variables
var current_city_id: int = 0
var _seconds_remaining: float = 120.0
var _total_phase_seconds: float = 120.0
var _walk_time: float = 0.0
var _is_defeated: bool = false
var _reached_emitted: bool = false
var _base_scale: Vector2 = Vector2(-0.08, 0.08)
var _sprite: Sprite2D = null
var _pushback_offset_x: float = 0.0
var _pushback_tween: Tween = null
#endregion

#region Lifecycle Methods
func _ready() -> void:
	_init_sprite()
	apply_city_theme(current_city_id)
	reset_mob()

func _process(delta: float) -> void:
	if _is_defeated or not visible:
		return
	_update_walk_animation(delta)

func _draw() -> void:
	if not _is_defeated:
		draw_ellipse(Vector2(0, 18), 16.0, 5.0, Color(0.0, 0.0, 0.0, 0.35))
#endregion

#region Public Methods
## Configures the mob appearance, scale, and color tint based on city ID.
func apply_city_theme(city_id: int) -> void:
	current_city_id = city_id
	if _sprite == null:
		return
	match city_id:
		CITY_HALFLING:
			_base_scale = Vector2(-0.08, 0.08)
			_sprite.modulate = Color(0.95, 0.85, 0.55)
			_sprite.texture = THEME_HALFLING
		CITY_HUMAN:
			_base_scale = Vector2(-0.09, 0.09)
			_sprite.modulate = Color(0.90, 0.92, 1.0)
			_sprite.texture = THEME_HUMAN
		CITY_ELF:
			_base_scale = Vector2(-0.085, 0.085)
			_sprite.modulate = Color(0.65, 0.98, 0.80)
			_sprite.texture = THEME_ELF
		_:
			_base_scale = Vector2(-0.08, 0.08)
			_sprite.modulate = Color(1.0, 1.0, 1.0)
			_sprite.texture = THEME_HALFLING
	_sprite.scale = _base_scale

## Updates progress towards the cannon from the current timer remaining.
func set_timer_progress(seconds_remaining: float, total_seconds: float = 120.0) -> void:
	if _is_defeated:
		return
	_seconds_remaining = maxf(0.0, seconds_remaining)
	_total_phase_seconds = maxf(1.0, total_seconds)
	var ratio: float = clampf(_seconds_remaining / _total_phase_seconds, 0.0, 1.0)
	var progress: float = 1.0 - ratio
	var base_x: float = lerpf(START_X, TARGET_X, progress)
	position.x = minf(base_x + _pushback_offset_x, START_X)
	position.y = MOB_Y
	if progress >= 1.0 and not _reached_emitted:
		_reached_emitted = true
		mob_reached_cannon.emit()

## Triggers a reactive knockback and stumble animation when the cannon fires.
func trigger_pushback(pushback_distance: float = 30.0) -> void:
	if _is_defeated:
		return
	if _pushback_tween and _pushback_tween.is_valid():
		_pushback_tween.kill()
	_pushback_offset_x = pushback_distance
	_pushback_tween = create_tween()
	_pushback_tween.set_parallel(true)
	_pushback_tween.tween_property(self, "_pushback_offset_x", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _sprite:
		_pushback_tween.tween_property(_sprite, "rotation", 0.22, 0.12).set_trans(Tween.TRANS_SINE)
		_pushback_tween.chain().tween_property(_sprite, "rotation", 0.0, 0.28).set_trans(Tween.TRANS_SINE)

## Plays defeat sequence when the wall is broken before breach.
func play_defeat() -> void:
	_is_defeated = true
	queue_redraw()
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:x", position.x + 80.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", position.y - 25.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(self, "position:y", position.y + 40.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(func():
		visible = false
	)

## Resets mob state, position, and visibility for the next wall wave.
func reset_mob() -> void:
	_is_defeated = false
	_reached_emitted = false
	_pushback_offset_x = 0.0
	if _pushback_tween and _pushback_tween.is_valid():
		_pushback_tween.kill()
	visible = true
	modulate.a = 1.0
	position = Vector2(START_X, MOB_Y)
	_walk_time = 0.0
	if _sprite:
		_sprite.scale = _base_scale
		_sprite.rotation = 0.0
		_sprite.position = Vector2.ZERO
	queue_redraw()
#endregion

#region Private Methods
func _init_sprite() -> void:
	_sprite = get_node_or_null("Sprite") as Sprite2D
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.name = "Sprite"
		add_child(_sprite)

func _update_walk_animation(delta: float) -> void:
	_walk_time += delta * WALK_CYCLE_SPEED
	var bob_offset: float = absf(sin(_walk_time * PI)) * STEP_BOB_HEIGHT
	var tilt_angle: float = sin(_walk_time * PI) * 0.06
	if _sprite:
		_sprite.position.y = -bob_offset
		_sprite.rotation = tilt_angle
#endregion
