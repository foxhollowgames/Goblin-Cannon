extends StaticBody2D
## Peg (§6.4). Durability, recovery, vibrancy. apply_hit() called by Board after sort.
## When durability reaches 0, peg becomes non-colliding (balls pass through) and recovers after recovery_sim_ticks.

var peg_id: int = -1

@export var peg_config: PegConfig = null

var _durability: int = 3
var _max_durability: int = 3
var _energized_durability: int = 0  ## Extra HP from Energize balls; shown as crackling aura. Drained before base durability.
var _recovery_ticks_remaining: int = 0
var _vibrancy_scale: float = 1.0
const AURA_DURATION_SEC: float = 0.5
var _aura_elapsed: float = 0.0
var _crackle_phase: float = 0.0  ## For animating energized aura
const WOBBLE_DURATION_SEC: float = 0.22
var _wobble_elapsed: float = -1.0
const LIGHTNING_GLOW_DURATION_SEC: float = 0.4
var _lightning_glow_elapsed: float = -1.0

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

## Subtle wobble for pegs hit by explosive (scale/rotation pulse).
func play_wobble() -> void:
	_wobble_elapsed = WOBBLE_DURATION_SEC
	set_process(true)

## Blue glow while peg is shocked by chain lightning.
func play_lightning_shock(duration: float = LIGHTNING_GLOW_DURATION_SEC) -> void:
	_lightning_glow_elapsed = duration
	set_process(true)

## show_aura: if true, peg shows the short yellow hit ring. Only for plain/Bounce balls; attribute balls use their own effect.
## damage: amount of damage (1 = normal hit). Applied after any add_energized; drains energized HP first, then base.
## add_energized: if true, peg gains _max_durability extra HP (twice as durable); shown as crackling energy aura until drained.
func apply_hit(show_aura: bool = true, damage: int = 1, add_energized: bool = false) -> void:
	if _recovery_ticks_remaining > 0:
		return
	if add_energized:
		_energized_durability = mini(_max_durability, _energized_durability + _max_durability)
		set_process(true)
	if damage > 0:
		_apply_damage(damage)
	_update_vibrancy()
	if show_aura:
		_aura_elapsed = AURA_DURATION_SEC
		set_process(true)

func _process(delta: float) -> void:
	_aura_elapsed -= delta
	if _wobble_elapsed >= 0.0:
		_wobble_elapsed -= delta
		var t: float = 1.0 - (_wobble_elapsed / WOBBLE_DURATION_SEC)
		var wobble: float = sin(_wobble_elapsed * 28.0) * (1.0 - t) * 0.06
		scale = Vector2(1.0 + wobble, 1.0 - wobble)
		if _wobble_elapsed <= 0.0:
			_wobble_elapsed = -1.0
			scale = Vector2.ONE
	if _lightning_glow_elapsed >= 0.0:
		_lightning_glow_elapsed -= delta
		queue_redraw()
		if _lightning_glow_elapsed <= 0.0:
			_lightning_glow_elapsed = -1.0
	if _energized_durability > 0:
		_crackle_phase += delta * 8.0
		queue_redraw()
		set_process(true)
	elif _aura_elapsed > 0.0:
		queue_redraw()
	if _aura_elapsed <= 0.0 and _energized_durability <= 0 and _wobble_elapsed < 0.0 and _lightning_glow_elapsed < 0.0:
		set_process(false)

func sim_tick(_tick: int) -> void:
	if _recovery_ticks_remaining <= 0:
		return
	_recovery_ticks_remaining -= 1
	if _recovery_ticks_remaining <= 0:
		_durability = peg_config.durability if peg_config else 3
		_max_durability = _durability
		_energized_durability = 0
		_set_collision_enabled(true)
		queue_redraw()

## Apply damage: drain energized HP first, then base durability. Triggers recovery when base reaches 0.
func _apply_damage(amount: int) -> void:
	while amount > 0 and _energized_durability > 0:
		_energized_durability -= 1
		amount -= 1
		queue_redraw()
	if amount <= 0:
		return
	_durability = clampi(_durability - amount, 0, _max_durability)
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

func _draw_energized_aura() -> void:
	var r: float = Constants.PEG_RADIUS + 6.0
	var segments: int = 16
	var pulse: float = 0.7 + 0.3 * sin(_crackle_phase)
	var alpha: float = 0.45 * pulse
	var color_outer := Color(1.0, 0.75, 0.2, alpha)
	var color_inner := Color(1.0, 0.95, 0.5, alpha * 0.8)
	for i in range(segments):
		var base_angle: float = (float(i) / float(segments)) * TAU + _crackle_phase * 0.5
		var seg_len: float = (0.15 + 0.12 * sin(_crackle_phase + float(i))) * TAU
		if seg_len < 0.05 * TAU:
			seg_len = 0.05 * TAU
		draw_arc(Vector2.ZERO, r + 3.0, base_angle, base_angle + seg_len, 8, color_outer, 2.5)
		draw_arc(Vector2.ZERO, r, base_angle, base_angle + seg_len, 8, color_inner, 2.0)

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
	# Crackling energy aura while peg has extra HP from Energize
	if _energized_durability > 0:
		_draw_energized_aura()
	# Short hit ring when just hit (plain/Bounce)
	elif _aura_elapsed > 0.0:
		var aura_alpha: float = (_aura_elapsed / AURA_DURATION_SEC) * 0.5
		var aura_r: float = Constants.PEG_RADIUS + 4.0 + (1.0 - _aura_elapsed / AURA_DURATION_SEC) * 8.0
		draw_arc(Vector2.ZERO, aura_r, 0.0, TAU, 32, Color(0.95, 0.85, 0.4, aura_alpha), 3.0)
	# Blue glow during chain lightning shock
	if _lightning_glow_elapsed > 0.0:
		var glow_alpha: float = (_lightning_glow_elapsed / LIGHTNING_GLOW_DURATION_SEC) * 0.7
		var glow_r: float = Constants.PEG_RADIUS + 6.0
		draw_arc(Vector2.ZERO, glow_r, 0.0, TAU, 24, Color(0.4, 0.7, 1.0, glow_alpha), 4.0)
		draw_arc(Vector2.ZERO, glow_r + 4.0, 0.0, TAU, 24, Color(0.6, 0.85, 1.0, glow_alpha * 0.5), 2.0)
