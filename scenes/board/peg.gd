extends StaticBody2D
## Peg (§6.4). Durability, recovery, vibrancy. apply_hit() called by Board after sort.
## When durability reaches 0, peg becomes non-colliding (balls pass through) and recovers after recovery_sim_ticks.

var peg_id: int = -1
## Set by Board for wall-break extra pegs: "bomb", "trampoline", or "goblin_reset".
var peg_extra_kind: String = ""

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
var _leech_stacks: int = 0
const LEECH_PULSE_DURATION_SEC: float = 0.4
var _leech_pulse_elapsed: float = -1.0
var _leech_cone_phase: float = 0.0
const TRAMPOLINE_BOUNCE_DURATION_SEC: float = 0.35
var _trampoline_bounce_elapsed: float = -1.0
var _trampoline_squash: float = 1.0  ## 1 = rest, <1 = squashed, >1 = spring overshoot

func _ready() -> void:
	var base_durability: int = 3
	if peg_config:
		base_durability = peg_config.durability
		_vibrancy_scale = peg_config.vibrancy_scale
	else:
		_vibrancy_scale = 1.0
	if GameState:
		base_durability += GameState.global_peg_durability_bonus
	_max_durability = base_durability
	_durability = base_durability
	var mat := PhysicsMaterial.new()
	mat.bounce = Constants.TRAMPOLINE_RESTITUTION if peg_extra_kind == "trampoline" else Constants.RESTITUTION
	mat.friction = Constants.TANGENTIAL_FRICTION
	physics_material_override = mat
	if peg_extra_kind == "trampoline":
		_setup_trampoline_collision()
	queue_redraw()

## Subtle wobble for pegs hit by explosive (scale/rotation pulse).
func play_wobble() -> void:
	_wobble_elapsed = WOBBLE_DURATION_SEC
	set_process(true)

## Blue glow while peg is shocked by chain lightning.
func play_lightning_shock(duration: float = LIGHTNING_GLOW_DURATION_SEC) -> void:
	_lightning_glow_elapsed = duration
	set_process(true)

## Leech status: cone on top, pulse when draining.
func add_leech_stack() -> void:
	_leech_stacks += 1
	set_process(true)

func remove_leech_stack() -> void:
	_leech_stacks = maxi(0, _leech_stacks - 1)
	queue_redraw()

func play_leech_pulse(_amount: int) -> void:
	_leech_pulse_elapsed = LEECH_PULSE_DURATION_SEC
	set_process(true)

## Trampoline peg: squash-and-spring visual when a ball bounces off.
func play_trampoline_bounce() -> void:
	_trampoline_bounce_elapsed = TRAMPOLINE_BOUNCE_DURATION_SEC
	set_process(true)

## Call when this peg is converted to trampoline mid-run (physics material + one-way top collision).
func apply_trampoline_physics() -> void:
	var mat := PhysicsMaterial.new()
	mat.bounce = Constants.TRAMPOLINE_RESTITUTION
	mat.friction = Constants.TANGENTIAL_FRICTION
	physics_material_override = mat
	_setup_trampoline_collision()

## One-way platform: only the top surface collides; balls pass through from below and get lifted when hitting the top.
func _setup_trampoline_collision() -> void:
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not col:
		return
	var r: float = Constants.PEG_RADIUS
	var h: float = Constants.TRAMPOLINE_TOP_COLLISION_HEIGHT
	var rect := RectangleShape2D.new()
	rect.size = Vector2(r * 2.0, h)
	col.shape = rect
	col.position = Vector2(0.0, -r)  # top of peg (Godot Y down, so -r is up)
	col.one_way_collision = true

## True if peg has energized stacks (for Chain Conduction and Overclock Network).
func has_energized_stacks() -> bool:
	return _energized_durability > 0

## Current energized HP (for Supernova Peg threshold check).
func get_energized_durability() -> int:
	return _energized_durability

## Max base durability (for Supernova threshold and display).
func get_max_durability() -> int:
	return _max_durability

## Supernova Peg: reset to full durability and clear energized (called after supernova triggers).
func reset_to_full() -> void:
	_durability = _max_durability
	_energized_durability = 0
	_recovery_ticks_remaining = 0
	_set_collision_enabled(true)
	queue_redraw()

## show_aura: if true, peg shows the short yellow hit ring. Only for plain/Bounce balls; attribute balls use their own effect.
## damage: amount of damage (1 = normal hit). Applied after any add_energized; drains energized HP first, then base.
## add_energized: if true, peg gains _max_durability extra HP (twice as durable); shown as crackling energy aura until drained.
func apply_hit(show_aura: bool = true, damage: int = 1, add_energized: bool = false) -> void:
	if _recovery_ticks_remaining > 0:
		return
	if add_energized:
		var cap: int = _max_durability
		if GameState and GameState.max_energize_stacks_per_peg > 0:
			cap = _max_durability * maxi(1, GameState.max_energize_stacks_per_peg)
		_energized_durability = mini(cap, _energized_durability + _max_durability)
		set_process(true)
	if damage > 0:
		_apply_damage(damage)
	_update_vibrancy()
	if show_aura:
		_aura_elapsed = AURA_DURATION_SEC
		set_process(true)
	if peg_extra_kind == "trampoline":
		play_trampoline_bounce()

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
	if _leech_pulse_elapsed >= 0.0:
		_leech_pulse_elapsed -= delta
		queue_redraw()
		if _leech_pulse_elapsed <= 0.0:
			_leech_pulse_elapsed = -1.0
	if _trampoline_bounce_elapsed >= 0.0:
		_trampoline_bounce_elapsed -= delta
		var t: float = 1.0 - (_trampoline_bounce_elapsed / TRAMPOLINE_BOUNCE_DURATION_SEC)
		# Squash down (0–0.35), then spring back with overshoot (0.35–1)
		if t < 0.4:
			_trampoline_squash = lerpf(1.0, 0.65, t / 0.4)
		else:
			var spring_t: float = (t - 0.4) / 0.6
			_trampoline_squash = lerpf(0.65, 1.15, spring_t) if spring_t < 0.7 else lerpf(1.15, 1.0, (spring_t - 0.7) / 0.3)
		if _trampoline_bounce_elapsed <= 0.0:
			_trampoline_bounce_elapsed = -1.0
			_trampoline_squash = 1.0
		queue_redraw()
	if _leech_stacks > 0:
		_leech_cone_phase += delta * 4.0
		queue_redraw()
		set_process(true)
	if _energized_durability > 0:
		_crackle_phase += delta * 8.0
		queue_redraw()
		set_process(true)
	elif _aura_elapsed > 0.0:
		queue_redraw()
	if _aura_elapsed <= 0.0 and _energized_durability <= 0 and _wobble_elapsed < 0.0 and _lightning_glow_elapsed < 0.0 and _leech_pulse_elapsed < 0.0 and _leech_stacks <= 0 and _trampoline_bounce_elapsed < 0.0:
		set_process(false)

func sim_tick(_tick: int) -> void:
	if _recovery_ticks_remaining <= 0:
		return
	_recovery_ticks_remaining -= 1
	if _recovery_ticks_remaining <= 0:
		var base_d: int = peg_config.durability if peg_config else 3
		if GameState:
			base_d += GameState.global_peg_durability_bonus
		_durability = base_d
		_max_durability = base_d
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
		if GameState:
			if GameState.peg_recovery_speed_scale > 0.0:
				recovery_ticks = int(float(recovery_ticks) / GameState.peg_recovery_speed_scale)
			if GameState.energized_peg_repair_scale > 0.0:
				recovery_ticks = int(float(recovery_ticks) / GameState.energized_peg_repair_scale)
		_recovery_ticks_remaining = maxi(1, recovery_ticks)
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

func _draw_trampoline() -> void:
	var r: float = Constants.PEG_RADIUS
	var luminance: float = 0.25
	if _recovery_ticks_remaining <= 0:
		var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
		luminance = lerpf(0.25, 1.0, ratio * _vibrancy_scale)
	# Frame/rim: dark blue-gray ring
	var rim_color := Color(0.25, 0.35, 0.5, 1.0)
	rim_color = Color(rim_color.r * luminance, rim_color.g * luminance, rim_color.b * luminance, rim_color.a)
	draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 32, rim_color, 4.0)
	# Mat: curved surface (bowl) – green/teal, drawn with vertical squash for bounce
	var mat_color := Color(0.2, 0.7, 0.45, 1.0)
	mat_color = Color(mat_color.r * luminance, mat_color.g * luminance, mat_color.b * luminance, mat_color.a)
	var mat_highlight := Color(0.4, 0.88, 0.6, 0.9 * luminance)
	# Draw mat as filled arc (bottom half of circle), Y scaled by _trampoline_squash for bounce
	var pts: PackedVector2Array = []
	var segs: int = 24
	for i in range(segs + 1):
		var angle: float = (float(i) / float(segs)) * PI  # 0 to PI = bottom half (y down)
		var px: float = cos(angle) * r
		var py: float = sin(angle) * r * _trampoline_squash
		pts.append(Vector2(px, py))
	draw_colored_polygon(pts, mat_color)
	# Net lines (horizontal across the mat)
	var line_color := Color(1.0, 1.0, 1.0, 0.5 * luminance)
	for ly in [3.0, 6.0, 9.0]:
		var half_w: float = sqrt(maxf(0, r * r - (ly / _trampoline_squash) * (ly / _trampoline_squash))) if _trampoline_squash > 0 else 0.0
		draw_line(Vector2(-half_w, ly), Vector2(half_w, ly), line_color)
	# Highlight along curved edge of mat
	draw_arc(Vector2.ZERO, r, 0.0, PI, 16, mat_highlight, 2.0)

func _draw_bomb() -> void:
	var r: float = Constants.PEG_RADIUS
	var luminance: float
	if _recovery_ticks_remaining > 0:
		luminance = 0.15
	else:
		var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
		luminance = lerpf(0.25, 1.0, ratio * _vibrancy_scale)
	# Dark red-black body (bomb)
	var body_color := Color(0.35, 0.12, 0.1, 1.0)
	body_color = Color(body_color.r * luminance, body_color.g * luminance, body_color.b * luminance, body_color.a)
	draw_circle(Vector2.ZERO, r, body_color)
	# Metallic rim
	var rim_color := Color(0.45, 0.4, 0.38, luminance)
	draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, rim_color, 2.0)
	# Fuse on top: small orange/yellow circle + short line
	var fuse_y: float = -r - 2.0
	draw_circle(Vector2(0, fuse_y), 3.0, Color(0.9, 0.5, 0.15, luminance))
	draw_line(Vector2(0, fuse_y - 3.0), Vector2(0, fuse_y - 8.0), Color(0.6, 0.35, 0.1, luminance))

func _draw_goblin_reset() -> void:
	var r: float = Constants.PEG_RADIUS
	var luminance: float
	if _recovery_ticks_remaining > 0:
		luminance = 0.15
	else:
		var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
		luminance = lerpf(0.25, 1.0, ratio * _vibrancy_scale)
	# Goblin green base (matches game's goblin theme)
	var base_color := Color(0.35, 0.55, 0.25, 1.0)
	base_color = Color(base_color.r * luminance, base_color.g * luminance, base_color.b * luminance, base_color.a)
	draw_circle(Vector2.ZERO, r, base_color)
	# Dark green rim
	var rim_color := Color(0.2, 0.4, 0.15, luminance)
	draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, rim_color, 2.0)
	# Reset symbol: circular arrow (arc with arrowhead) on top half - suggests "goblin reset"
	var arrow_r: float = r * 0.55
	var arrow_color := Color(0.95, 0.85, 0.5, 0.95 * luminance)
	draw_arc(Vector2.ZERO, arrow_r, -0.4 * PI, 0.85 * PI, 16, arrow_color, 2.5)
	# Arrowhead at the end of the arc (wings behind tip, following arc direction)
	var tip_angle: float = 0.85 * PI
	var tip := Vector2(cos(tip_angle), sin(tip_angle)) * arrow_r
	var wing: float = 4.0
	var left := tip + Vector2(cos(tip_angle + 0.5), sin(tip_angle + 0.5)) * wing
	var right := tip + Vector2(cos(tip_angle - 0.5), sin(tip_angle - 0.5)) * wing
	draw_colored_polygon(PackedVector2Array([tip, left, right]), arrow_color)

func _draw_leech_cone() -> void:
	var r: float = Constants.PEG_RADIUS
	var tip_y: float = -r - 12.0
	var base_half: float = 6.0 + 2.0 * sin(_leech_cone_phase)
	var base_y: float = -r + 2.0
	var pulse: float = 0.75 + 0.25 * sin(_leech_cone_phase * 2.0)
	var cone_color := Color(0.72, 0.45, 0.95, 0.85 * pulse)
	var cone_dark := Color(0.5, 0.28, 0.75, 0.6 * pulse)
	var pts: PackedVector2Array = [Vector2(0, tip_y), Vector2(-base_half, base_y), Vector2(base_half, base_y)]
	draw_colored_polygon(pts, cone_color)
	draw_polyline(pts, cone_dark)
	draw_line(Vector2(0, tip_y), Vector2(-base_half, base_y), cone_dark)
	draw_line(Vector2(0, tip_y), Vector2(base_half, base_y), cone_dark)

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
	if peg_extra_kind == "trampoline":
		_draw_trampoline()
		# Trampoline overlays (energized, aura, etc.) drawn below
	elif peg_extra_kind == "bomb":
		_draw_bomb()
	elif peg_extra_kind == "goblin_reset":
		_draw_goblin_reset()
	else:
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
	# Leech cone on top of peg (siphon visual)
	if _leech_stacks > 0:
		_draw_leech_cone()
	# Purple pulse when leech drain fires
	if _leech_pulse_elapsed > 0.0:
		var pulse_alpha: float = (_leech_pulse_elapsed / LEECH_PULSE_DURATION_SEC) * 0.75
		var pulse_r: float = Constants.PEG_RADIUS + 6.0
		draw_arc(Vector2.ZERO, pulse_r, 0.0, TAU, 24, Color(0.7, 0.45, 1.0, pulse_alpha), 4.0)
		draw_arc(Vector2.ZERO, pulse_r + 4.0, 0.0, TAU, 24, Color(0.85, 0.65, 1.0, pulse_alpha * 0.5), 2.0)
