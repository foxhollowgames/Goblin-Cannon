extends StaticBody2D
## Peg (§6.4). Durability, recovery, vibrancy. apply_hit() called by Board after sort.
## When durability reaches 0, peg becomes non-colliding (balls pass through) and recovers after recovery_sim_ticks.

var peg_id: int = -1

@export var peg_config: PegConfig = null

var _durability: int = 3
var _max_durability: int = 3
var _recovery_ticks_remaining: int = 0
var _vibrancy_scale: float = 1.0

func _ready() -> void:
	if peg_config:
		_max_durability = peg_config.durability
		_durability = peg_config.durability
		_vibrancy_scale = peg_config.vibrancy_scale
	else:
		_max_durability = 3
		_durability = 3
		_vibrancy_scale = 1.0
	var mat := PhysicsMaterial.new()
	mat.bounce = Constants.RESTITUTION
	mat.friction = Constants.TANGENTIAL_FRICTION
	physics_material_override = mat
	queue_redraw()

func apply_hit() -> void:
	if _recovery_ticks_remaining > 0:
		return
	_subtract_durability(1)
	_update_vibrancy()

func sim_tick(_tick: int) -> void:
	if _recovery_ticks_remaining <= 0:
		return
	_recovery_ticks_remaining -= 1
	if _recovery_ticks_remaining <= 0:
		_durability = peg_config.durability if peg_config else 3
		_max_durability = _durability
		_set_collision_enabled(true)
		queue_redraw()

func _subtract_durability(amount: int) -> void:
	_durability = maxi(0, _durability - amount)
	if _durability <= 0:
		var recovery_ticks: int = peg_config.recovery_sim_ticks if peg_config else 300
		_recovery_ticks_remaining = recovery_ticks
		_set_collision_enabled(false)

func _start_recovery_timer() -> void:
	# Handled in _subtract_durability when durability hits 0
	pass

func _set_collision_enabled(enabled: bool) -> void:
	if enabled:
		collision_layer = 1
	else:
		collision_layer = 0

func _update_vibrancy() -> void:
	queue_redraw()

func _draw() -> void:
	var base_color := Color(0.72, 0.68, 0.55, 1.0)
	var luminance: float
	if _recovery_ticks_remaining > 0:
		luminance = 0.15
	else:
		var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
		luminance = lerpf(0.25, 1.0, ratio * _vibrancy_scale)
	var c := Color(base_color.r * luminance, base_color.g * luminance, base_color.b * luminance, base_color.a)
	draw_circle(Vector2.ZERO, Constants.PEG_RADIUS, c)
