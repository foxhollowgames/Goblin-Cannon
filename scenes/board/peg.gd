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
## Leech cone/pulse redraw at limited FPS so many leeched pegs do not queue_redraw() every frame.
const LEECH_VISUAL_REDRAW_PERIOD_SEC: float = 1.0 / 12.0
var _leech_visual_redraw_accum: float = 0.0
const TRAMPOLINE_BOUNCE_DURATION_SEC: float = 0.35
var _trampoline_bounce_elapsed: float = -1.0
var _trampoline_squash: float = 1.0  ## 1 = rest, <1 = squashed, >1 = spring overshoot
var _hover_highlight: bool = false
var _hover_kind: String = ""
var _phase_peg_counter: int = 0
var _phase_peg_solid: bool = true
var _ghost_trail_active: bool = false
var _ghost_trail_phase: float = 0.0
var _gravity_vortex_phase: float = 0.0
var _just_destroyed: bool = false
var _had_energize_on_destroy: bool = false
var _energize_decay_counter: int = 0
## Milestone board event peg: 1 = full time, 0 = about to expire (visual urgency).
var _milestone_event_urgency: float = 1.0
## Treasure chest peg: visual urgency when event timer is low.
var _treasure_chest_urgency: float = 1.0
## Buffet table (Halfling): visual urgency when event timer is low.
var _buffet_table_urgency: float = 1.0
## Human Kingdom sticky slime event: coating over a normal/special peg.
var sticky_slime_saved_kind: String = ""
var _sticky_rescue_hits_remaining: int = 0
var _sticky_slime_urgency: float = 1.0
var _sticky_slime_phase: float = 0.0
## Random stash: run gold released to GameState when peg breaks (see Constants.STASH_GOLD_*).
var stash_gold_amount: int = 0
## Increments each stash roll so spawn vs respawn (and repeats) get distinct RNG.
var _stash_roll_counter: int = 0
var _is_ghost_placement: bool = false

func set_ghost_placement(ghost: bool) -> void:
	_is_ghost_placement = ghost
	modulate.a = 0.5 if _is_ghost_placement else 1.0
	_set_collision_enabled(not _is_ghost_placement and _phase_peg_solid and _recovery_ticks_remaining <= 0)
	queue_redraw()

func is_ghost_placement_active() -> bool:
	return _is_ghost_placement

func is_area_clear_of_balls(active_balls: Array, ball_radius: float = Constants.BALL_RADIUS) -> bool:
	var peg_pos: Vector2 = global_position if is_inside_tree() else position
	var clear_radius: float = Constants.PEG_RADIUS + ball_radius + 2.0
	var clear_radius_sq: float = clear_radius * clear_radius
	for ball in active_balls:
		if not is_instance_valid(ball):
			continue
		var b_pos: Vector2 = ball.global_position if (ball.is_inside_tree() and "global_position" in ball) else (ball.position if "position" in ball else Vector2.ZERO)
		if peg_pos.distance_squared_to(b_pos) <= clear_radius_sq:
			return false
	return true

func _ready() -> void:
	if _is_ghost_placement:
		modulate.a = 0.5
		_set_collision_enabled(false)
	if peg_extra_kind == "milestone_event":
		_max_durability = 1
		_durability = 1
		_vibrancy_scale = 1.0
		var mat_ms := PhysicsMaterial.new()
		mat_ms.bounce = Constants.RESTITUTION
		mat_ms.friction = Constants.TANGENTIAL_FRICTION
		physics_material_override = mat_ms
		set_process(true)
		queue_redraw()
		return
	if peg_extra_kind == "treasure_chest":
		_max_durability = Constants.TREASURE_CHEST_BASE_DURABILITY
		_durability = _max_durability
		_vibrancy_scale = 1.0
		var mat_tc := PhysicsMaterial.new()
		mat_tc.bounce = Constants.RESTITUTION
		mat_tc.friction = Constants.TANGENTIAL_FRICTION
		physics_material_override = mat_tc
		set_process(true)
		queue_redraw()
		return
	if peg_extra_kind == "buffet_table":
		_max_durability = 999
		_durability = 999
		_vibrancy_scale = 1.0
		var mat_bt := PhysicsMaterial.new()
		mat_bt.bounce = Constants.RESTITUTION
		mat_bt.friction = Constants.TANGENTIAL_FRICTION
		physics_material_override = mat_bt
		set_process(true)
		queue_redraw()
		return
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
	if peg_extra_kind == "goblin_reset":
		refresh_goblin_reset_durability()
	var mat := PhysicsMaterial.new()
	match peg_extra_kind:
		"trampoline":
			mat.bounce = Constants.TRAMPOLINE_RESTITUTION
		"extreme_bouncer":
			mat.bounce = Constants.EXTREME_BOUNCER_RESTITUTION
		_:
			mat.bounce = Constants.RESTITUTION
	mat.friction = Constants.TANGENTIAL_FRICTION
	physics_material_override = mat
	if peg_extra_kind == "trampoline":
		_setup_trampoline_collision()
	if peg_extra_kind == "extreme_bouncer":
		mat.friction = 0.05
		physics_material_override = mat
	if peg_extra_kind == "gravity_well":
		set_process(true)
	_roll_stash_gold_if_eligible()
	if get_meta("shop_preview", false):
		collision_layer = 0
		collision_mask = 0
		var cs_shop: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
		if cs_shop:
			cs_shop.disabled = true
		_gravity_vortex_phase = 0.0
		set_process(false)
	queue_redraw()

func _roll_stash_gold_if_eligible() -> void:
	if peg_extra_kind == "milestone_event" or peg_extra_kind == "treasure_chest" or peg_extra_kind == "buffet_table" or peg_extra_kind == "sticky_slime":
		return
	if peg_extra_kind == "lucky_gold":
		var rng_lucky := RandomNumberGenerator.new()
		_stash_roll_counter += 1
		rng_lucky.seed = (GameState.run_seed if GameState else 1) ^ (peg_id * 2654435761) ^ int(position.x * 997.0) ^ int(position.y * 1009.0) ^ (_stash_roll_counter * 1315423911)
		var u_lucky: float = rng_lucky.randf()
		stash_gold_amount = 5 if u_lucky < Constants.STASH_GOLD_LUCKY_PEG_FIVE_CHANCE else 1
		return
	if peg_extra_kind == "gold":
		return
	if peg_extra_kind == "eternal":
		return
	var rng := RandomNumberGenerator.new()
	_stash_roll_counter += 1
	rng.seed = (GameState.run_seed if GameState else 1) ^ (peg_id * 2654435761) ^ int(position.x * 997.0) ^ int(position.y * 1009.0) ^ (_stash_roll_counter * 1315423911)
	var u: float = rng.randf()
	if u < Constants.STASH_GOLD_CHANCE_FIVE:
		stash_gold_amount = 5
	elif u < Constants.STASH_GOLD_CHANCE_FIVE + Constants.STASH_GOLD_CHANCE_ONE:
		stash_gold_amount = 1
	else:
		stash_gold_amount = 0


## Call after peg_extra_kind is set to a kind that uses stash (e.g. board spawn / peg picker).
func refresh_stash_gold_for_current_kind() -> void:
	_roll_stash_gold_if_eligible()
	queue_redraw()

func _release_stash_gold_if_any() -> void:
	if stash_gold_amount <= 0:
		return
	var amount: int = stash_gold_amount
	stash_gold_amount = 0
	var parent_node: Node = get_parent()
	if parent_node and parent_node.has_signal("gold_gained"):
		parent_node.emit_signal("gold_gained", amount, global_position)
	elif GameState:
		GameState.add_run_gold(amount)

## Goblin Reset pegs are always 1 hit then recovery (not affected by global durability bonus).
func refresh_goblin_reset_durability() -> void:
	if peg_extra_kind != "goblin_reset":
		return
	_max_durability = 1
	_durability = 1
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
	queue_redraw()

func remove_leech_stack() -> void:
	_leech_stacks = maxi(0, _leech_stacks - 1)
	queue_redraw()

## Matches number of active leech timer entries on Board for this peg (used for O(1) checks vs scanning _leeched_pegs).
func get_leech_stack_count() -> int:
	return _leech_stacks

func play_leech_pulse(_amount: int) -> void:
	_leech_pulse_elapsed = LEECH_PULSE_DURATION_SEC
	set_process(true)
	queue_redraw()

## Trampoline peg: squash-and-spring visual when a ball bounces off.
func play_trampoline_bounce() -> void:
	_trampoline_bounce_elapsed = TRAMPOLINE_BOUNCE_DURATION_SEC
	set_process(true)

func set_hover_highlight(enabled: bool, kind: String = "") -> void:
	_hover_highlight = enabled
	_hover_kind = kind
	if enabled:
		set_process(true)
	queue_redraw()

func set_ghost_trail(active: bool) -> void:
	_ghost_trail_active = active
	if active:
		set_process(true)
	queue_redraw()

## Reset collision + material to a normal round peg (after removing trampoline / shop kinds).
func apply_default_peg_collision_and_physics() -> void:
	var mat := PhysicsMaterial.new()
	mat.bounce = Constants.RESTITUTION
	mat.friction = Constants.TANGENTIAL_FRICTION
	physics_material_override = mat
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		var circle := CircleShape2D.new()
		circle.radius = Constants.PEG_RADIUS
		col.shape = circle
		col.position = Vector2.ZERO
		col.one_way_collision = false

## Revert a milestone-shop special peg (bomb, magnet, …) back to a normal peg. No-op for event pegs.
func revert_milestone_shop_kind_to_normal() -> void:
	if peg_extra_kind == "milestone_event" or peg_extra_kind == "treasure_chest" or peg_extra_kind == "buffet_table" or peg_extra_kind == "sticky_slime":
		return
	if peg_extra_kind == "bomb" and is_in_group("explosion_source"):
		remove_from_group("explosion_source")
	if peg_extra_kind == "gravity_well":
		set_process(false)
		_gravity_vortex_phase = 0.0
	peg_extra_kind = ""
	stash_gold_amount = 0
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
	apply_default_peg_collision_and_physics()
	queue_redraw()

## Call when this peg is converted to trampoline mid-run (physics material + one-way top collision).
func apply_trampoline_physics() -> void:
	var mat := PhysicsMaterial.new()
	mat.bounce = Constants.TRAMPOLINE_RESTITUTION
	mat.friction = Constants.TANGENTIAL_FRICTION
	physics_material_override = mat
	_setup_trampoline_collision()

## Call when this peg is converted to extreme bouncer mid-run.
func apply_extreme_bouncer_physics() -> void:
	var mat := PhysicsMaterial.new()
	mat.bounce = Constants.EXTREME_BOUNCER_RESTITUTION
	mat.friction = 0.05
	physics_material_override = mat

## True when phase peg is in solid mode (or peg is not a phase peg).
func is_phase_solid() -> bool:
	if peg_extra_kind != "phase":
		return true
	return _phase_peg_solid

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

## True if peg has energized stacks (for Chain Conduction, Overclock Network, etc.).
func has_energized_stacks() -> bool:
	return _energized_durability > 0

## Number of energize stacks (measured in multiples of max_durability) for Resonant Bounce.
func get_energize_stacks() -> int:
	if _max_durability <= 0:
		return 0
	return ceili(float(_energized_durability) / float(_max_durability))

## Drain 1 energize stack worth of durability. Used by Phase Siphon.
func consume_energize_stack() -> void:
	_energized_durability = maxi(0, _energized_durability - _max_durability)
	queue_redraw()

## Current base durability.
func get_durability() -> int:
	return _durability

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

## show_aura: if true, peg shows the short yellow hit ring. Only for plain balls; attribute balls use their own effect.
## damage: amount of damage (1 = normal hit). Applied after any add_energized; drains energized HP first, then base.
## add_energized: if true, peg gains _max_durability extra HP (twice as durable); shown as crackling energy aura until drained.
func apply_hit(show_aura: bool = true, damage: int = 1, add_energized: bool = false) -> void:
	if _is_ghost_placement:
		return
	if peg_extra_kind == "buffet_table" or peg_extra_kind == "sticky_slime":
		return
	if _recovery_ticks_remaining > 0:
		return
	if add_energized and Constants.peg_extra_kind_blocks_energize(peg_extra_kind):
		add_energized = false
	if add_energized:
		var cap: int = _max_durability
		if GameState and GameState.max_energize_stacks_per_peg > 0:
			cap = _max_durability * maxi(1, GameState.max_energize_stacks_per_peg)
		var before_ed: int = _energized_durability
		_energized_durability = mini(cap, _energized_durability + _max_durability)
		if GameState and _energized_durability > before_ed:
			GameState.apply_volt_primer_on_energize()
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
		if _leech_pulse_elapsed <= 0.0:
			_leech_pulse_elapsed = -1.0
			queue_redraw()
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
	var leech_visual_active: bool = _leech_stacks > 0 or _leech_pulse_elapsed >= 0.0
	if leech_visual_active:
		_leech_visual_redraw_accum += delta
		if _leech_visual_redraw_accum >= LEECH_VISUAL_REDRAW_PERIOD_SEC:
			_leech_visual_redraw_accum = fposmod(_leech_visual_redraw_accum, LEECH_VISUAL_REDRAW_PERIOD_SEC)
			queue_redraw()
		set_process(true)
	if _hover_highlight:
		queue_redraw()
	if _ghost_trail_active:
		_ghost_trail_phase += delta * 5.0
		queue_redraw()
		set_process(true)
	if peg_extra_kind == "gravity_well":
		_gravity_vortex_phase += delta * 1.4
		queue_redraw()
		set_process(true)
	if _energized_durability > 0:
		_crackle_phase += delta * 8.0
		queue_redraw()
		set_process(true)
	elif _aura_elapsed > 0.0:
		queue_redraw()
	if peg_extra_kind == "milestone_event" or peg_extra_kind == "treasure_chest" or peg_extra_kind == "buffet_table" or peg_extra_kind == "sticky_slime":
		if peg_extra_kind == "sticky_slime":
			_sticky_slime_phase += delta * 3.6
		queue_redraw()
		set_process(true)
	if _aura_elapsed <= 0.0 and _energized_durability <= 0 and _wobble_elapsed < 0.0 and _lightning_glow_elapsed < 0.0 and _leech_pulse_elapsed < 0.0 and _leech_stacks <= 0 and _trampoline_bounce_elapsed < 0.0 and not _hover_highlight and not _ghost_trail_active and peg_extra_kind != "gravity_well" and peg_extra_kind != "milestone_event" and peg_extra_kind != "treasure_chest" and peg_extra_kind != "buffet_table" and peg_extra_kind != "sticky_slime":
		set_process(false)

func was_just_destroyed() -> bool:
	return _just_destroyed

func had_energize_on_destroy() -> bool:
	return _had_energize_on_destroy

func add_overclock_durability(amount: int) -> void:
	if Constants.peg_extra_kind_blocks_energize(peg_extra_kind):
		return
	_energized_durability += amount
	queue_redraw()

func set_milestone_event_urgency(frac: float) -> void:
	_milestone_event_urgency = clampf(frac, 0.0, 1.0)
	queue_redraw()

func set_treasure_chest_urgency(frac: float) -> void:
	_treasure_chest_urgency = clampf(frac, 0.0, 1.0)
	queue_redraw()

func set_buffet_table_urgency(frac: float) -> void:
	_buffet_table_urgency = clampf(frac, 0.0, 1.0)
	queue_redraw()

func set_sticky_slime_urgency(frac: float) -> void:
	_sticky_slime_urgency = clampf(frac, 0.0, 1.0)
	queue_redraw()

func get_sticky_rescue_hits_remaining() -> int:
	return _sticky_rescue_hits_remaining

## Human Kingdom event: wrap the peg in sticky slime (saved_kind = previous peg_extra_kind).
func configure_sticky_slime_overlay(saved_kind: String) -> void:
	sticky_slime_saved_kind = saved_kind
	_sticky_rescue_hits_remaining = Constants.STICKY_SLIME_RESCUE_HITS
	peg_extra_kind = "sticky_slime"
	var mat_sl := PhysicsMaterial.new()
	mat_sl.bounce = Constants.RESTITUTION * 0.45
	mat_sl.friction = 0.92
	physics_material_override = mat_sl
	set_process(true)
	queue_redraw()

func consume_sticky_slime_ball_hit() -> bool:
	_sticky_rescue_hits_remaining = maxi(0, _sticky_rescue_hits_remaining - 1)
	return _sticky_rescue_hits_remaining <= 0

## Remove slime overlay; restored_kind is the peg type underneath (same as sticky_slime_saved_kind before clear).
func end_sticky_slime_overlay(restored_kind: String) -> void:
	sticky_slime_saved_kind = ""
	_sticky_rescue_hits_remaining = 0
	_sticky_slime_urgency = 1.0
	peg_extra_kind = restored_kind
	queue_redraw()

func reset_collision_shape_to_default_circle() -> void:
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not col:
		return
	var circle := CircleShape2D.new()
	circle.radius = Constants.PEG_RADIUS
	col.shape = circle

## After slime clears, peg enters normal broken/recovery (same as durability hit 0).
func enter_break_recovery_after_sticky_slime() -> void:
	_durability = 0
	_energized_durability = 0
	_release_stash_gold_if_any()
	_just_destroyed = true
	_had_energize_on_destroy = (_energized_durability > 0)
	var recovery_ticks: int = peg_config.recovery_sim_ticks if peg_config else 360
	if GameState:
		if GameState.peg_recovery_speed_scale > 0.0:
			recovery_ticks = int(float(recovery_ticks) / GameState.peg_recovery_speed_scale)
		if GameState.energized_peg_repair_scale > 0.0:
			recovery_ticks = int(float(recovery_ticks) / GameState.energized_peg_repair_scale)
	_recovery_ticks_remaining = maxi(1, recovery_ticks)
	_set_collision_enabled(false)
	queue_redraw()

func sim_tick(_tick: int) -> void:
	_just_destroyed = false
	if peg_extra_kind == "phase":
		_phase_peg_counter += 1
		if _phase_peg_counter >= Constants.PHASE_PEG_CYCLE_TICKS:
			_phase_peg_counter = 0
			_phase_peg_solid = not _phase_peg_solid
			_set_collision_enabled(_phase_peg_solid and _recovery_ticks_remaining <= 0)
			queue_redraw()
	if _energized_durability > 0 and _recovery_ticks_remaining <= 0:
		_energize_decay_counter += 1
		var interval: int = Constants.ENERGIZE_DECAY_INTERVAL_TICKS
		if GameState and GameState.energize_decay_scale > 0.0 and GameState.energize_decay_scale < 1.0:
			interval = int(float(interval) / GameState.energize_decay_scale)
		if _energize_decay_counter >= interval:
			_energize_decay_counter = 0
			_energized_durability = maxi(0, _energized_durability - 1)
			queue_redraw()
	elif _energize_decay_counter > 0:
		_energize_decay_counter = 0
	if _recovery_ticks_remaining <= 0:
		return
	_recovery_ticks_remaining -= 1
	if _recovery_ticks_remaining <= 0:
		var base_d: int = peg_config.durability if peg_config else 3
		if GameState:
			base_d += GameState.global_peg_durability_bonus
		_durability = base_d
		_max_durability = base_d
		if peg_extra_kind == "goblin_reset":
			refresh_goblin_reset_durability()
		_energized_durability = 0
		_set_collision_enabled(true)
		_roll_stash_gold_if_eligible()
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
		_release_stash_gold_if_any()
		if peg_extra_kind == "eternal":
			_durability = _max_durability
			_energized_durability = 0
			queue_redraw()
			return
		if peg_extra_kind == "milestone_event":
			_just_destroyed = true
			_had_energize_on_destroy = false
			_recovery_ticks_remaining = 0
			_set_collision_enabled(false)
			queue_redraw()
			return
		if peg_extra_kind == "treasure_chest":
			_just_destroyed = true
			_had_energize_on_destroy = false
			_recovery_ticks_remaining = 0
			_set_collision_enabled(false)
			queue_redraw()
			return
		_just_destroyed = true
		_had_energize_on_destroy = (_energized_durability > 0)
		var recovery_ticks: int = peg_config.recovery_sim_ticks if peg_config else 360
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
	if enabled and not _is_ghost_placement:
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
	# Frame/rim: slate / indigo (Lospec)
	var rim_base: Color = Constants.monsters_also_die_color(Constants.MAD_IDX_SLATE).lerp(
		Constants.monsters_also_die_color(Constants.MAD_IDX_INDIGO), 0.45
	)
	var rim_color: Color = Constants.color_with_luminance(rim_base, luminance)
	draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 32, rim_color, 4.0)
	# Mat: teal / olive bowl
	var mat_base: Color = Constants.monsters_also_die_color(Constants.MAD_IDX_TEAL).lerp(
		Constants.monsters_also_die_color(Constants.MAD_IDX_OLIVE), 0.5
	)
	var mat_color: Color = Constants.color_with_luminance(mat_base, luminance)
	var mat_hi_base: Color = Constants.monsters_also_die_color(Constants.MAD_IDX_CREAM).lerp(
		Constants.monsters_also_die_color(Constants.MAD_IDX_TEAL), 0.55
	)
	var mat_highlight: Color = Color(mat_hi_base.r, mat_hi_base.g, mat_hi_base.b, 0.9 * luminance)
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

func _draw_eternal() -> void:
	var r: float = Constants.PEG_RADIUS
	var luminance: float = 1.0
	if _recovery_ticks_remaining > 0:
		luminance = 0.15
	else:
		var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
		luminance = lerpf(0.5, 1.0, ratio * _vibrancy_scale)
	var base_color := Color(0.85, 0.85, 0.95, 1.0)
	base_color = Color(base_color.r * luminance, base_color.g * luminance, base_color.b * luminance, base_color.a)
	draw_circle(Vector2.ZERO, r, base_color)
	var rim_color := Color(0.6, 0.7, 1.0, luminance)
	draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, rim_color, 2.5)
	var infinity_color := Color(0.4, 0.5, 1.0, 0.9 * luminance)
	var inf_r: float = r * 0.35
	draw_arc(Vector2(-inf_r * 0.5, 0), inf_r, 0.0, TAU, 12, infinity_color, 2.0)
	draw_arc(Vector2(inf_r * 0.5, 0), inf_r, 0.0, TAU, 12, infinity_color, 2.0)

func _draw_extreme_bouncer() -> void:
	var r: float = Constants.PEG_RADIUS
	var luminance: float
	if _recovery_ticks_remaining > 0:
		luminance = 0.15
	else:
		var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
		luminance = lerpf(0.25, 1.0, ratio * _vibrancy_scale)
	var body_color := Color(1.0, 0.55, 0.1, 1.0)
	body_color = Color(body_color.r * luminance, body_color.g * luminance, body_color.b * luminance, body_color.a)
	draw_circle(Vector2.ZERO, r, body_color)
	var rim_color := Color(1.0, 0.8, 0.3, luminance)
	draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 24, rim_color, 3.0)
	var arrow_color := Color(1.0, 1.0, 0.7, 0.9 * luminance)
	for i in range(4):
		var angle: float = float(i) * TAU / 4.0 + TAU / 8.0
		var dir := Vector2(cos(angle), sin(angle))
		var base_pt := dir * (r * 0.2)
		var tip := dir * (r * 0.75)
		draw_line(base_pt, tip, arrow_color, 2.0)
		var wing_l := tip - dir * 4.0 + Vector2(-dir.y, dir.x) * 3.0
		var wing_r := tip - dir * 4.0 - Vector2(-dir.y, dir.x) * 3.0
		draw_colored_polygon(PackedVector2Array([tip, wing_l, wing_r]), arrow_color)

func _draw_magnet() -> void:
	var r: float = Constants.PEG_RADIUS
	var luminance: float
	if _recovery_ticks_remaining > 0:
		luminance = 0.15
	else:
		var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
		luminance = lerpf(0.25, 1.0, ratio * _vibrancy_scale)
	var body_color := Color(0.55, 0.15, 0.15, 1.0)
	body_color = Color(body_color.r * luminance, body_color.g * luminance, body_color.b * luminance, body_color.a)
	draw_circle(Vector2.ZERO, r, body_color)
	var rim_color := Color(0.7, 0.3, 0.3, luminance)
	draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, rim_color, 2.0)
	var u_color := Color(0.9, 0.2, 0.2, 0.9 * luminance)
	draw_arc(Vector2.ZERO, r * 0.55, PI, TAU, 12, u_color, 2.5)
	draw_line(Vector2(-r * 0.55, 0), Vector2(-r * 0.55, -r * 0.4), u_color, 2.5)
	draw_line(Vector2(r * 0.55, 0), Vector2(r * 0.55, -r * 0.4), u_color, 2.5)
	var cap_silver := Color(0.8, 0.8, 0.85, luminance)
	draw_circle(Vector2(-r * 0.55, -r * 0.4), 2.5, cap_silver)
	draw_circle(Vector2(r * 0.55, -r * 0.4), 2.5, cap_silver)

func _draw_splitter() -> void:
	var r: float = Constants.PEG_RADIUS
	var luminance: float
	if _recovery_ticks_remaining > 0:
		luminance = 0.15
	else:
		var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
		luminance = lerpf(0.25, 1.0, ratio * _vibrancy_scale)
	var body_color := Color(0.6, 0.25, 0.65, 1.0)
	body_color = Color(body_color.r * luminance, body_color.g * luminance, body_color.b * luminance, body_color.a)
	draw_circle(Vector2.ZERO, r, body_color)
	var rim_color := Color(0.75, 0.45, 0.8, luminance)
	draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, rim_color, 2.0)
	var split_color := Color(1.0, 0.85, 1.0, 0.9 * luminance)
	draw_line(Vector2(0, -r * 0.6), Vector2(0, 0), split_color, 2.0)
	draw_line(Vector2(0, 0), Vector2(-r * 0.5, r * 0.5), split_color, 2.0)
	draw_line(Vector2(0, 0), Vector2(r * 0.5, r * 0.5), split_color, 2.0)
	draw_circle(Vector2(-r * 0.5, r * 0.5), 2.5, split_color)
	draw_circle(Vector2(r * 0.5, r * 0.5), 2.5, split_color)

func _draw_gold() -> void:
	var r: float = Constants.PEG_RADIUS
	var luminance: float
	if _recovery_ticks_remaining > 0:
		luminance = 0.15
	else:
		var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
		luminance = lerpf(0.35, 1.0, ratio * _vibrancy_scale)
	var body_color := Color(0.78, 0.48, 0.14, 1.0)
	body_color = Color(body_color.r * luminance, body_color.g * luminance, body_color.b * luminance, body_color.a)
	draw_circle(Vector2.ZERO, r, body_color)
	var rim_color := Color(0.86, 0.56, 0.18, luminance)
	draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 24, rim_color, 3.0)
	var inner_color := Color(0.82, 0.58, 0.22, 0.75 * luminance)
	draw_circle(Vector2.ZERO, r * 0.5, inner_color)
	var sparkle := Color(0.95, 0.76, 0.40, 0.85 * luminance)
	draw_circle(Vector2(-r * 0.25, -r * 0.25), 1.5, sparkle)

func _draw_lucky_gold() -> void:
	_draw_gold()
	var r: float = Constants.PEG_RADIUS
	var luminance: float
	if _recovery_ticks_remaining > 0:
		luminance = 0.15
	else:
		var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
		luminance = lerpf(0.35, 1.0, ratio * _vibrancy_scale)
	var luck := Color(0.2, 0.85, 0.55, 0.9 * luminance)
	draw_arc(Vector2.ZERO, r + 5.0, 0.0, TAU, 28, luck, 2.0)

func _draw_gravity_well_vortex(luminance: float) -> void:
	var R: float = Constants.GRAVITY_WELL_RADIUS_PX
	var pulse: float = (0.82 + 0.18 * sin(_gravity_vortex_phase * 1.15)) * luminance
	# Slow zone — matches Board gravity-well radius
	draw_circle(Vector2.ZERO, R, Color(0.42, 0.08, 0.72, 0.14 * pulse))
	draw_arc(Vector2.ZERO, R - 1.5, 0.0, TAU, 64, Color(0.55, 0.2, 0.92, 0.42 * pulse), 2.5)
	draw_arc(Vector2.ZERO, R * 0.65, 0.0, TAU, 48, Color(0.65, 0.3, 1.0, 0.12 * pulse), 1.5)
	var arms: int = 6
	var inner_r: float = Constants.PEG_RADIUS + 10.0
	var outer_r: float = R - 5.0
	for i in arms:
		var base_cw: float = _gravity_vortex_phase * 1.25 + float(i) * TAU / float(arms)
		var pts_cw: PackedVector2Array = PackedVector2Array()
		var steps: int = 28
		for s in steps + 1:
			var u: float = float(s) / float(steps)
			var rad: float = lerpf(inner_r, outer_r, u)
			var ang: float = base_cw + u * TAU * 2.2
			pts_cw.append(Vector2(cos(ang) * rad, sin(ang) * rad))
		draw_polyline(pts_cw, Color(0.72, 0.38, 1.0, 0.55 * pulse), 3.0)
	for j in arms:
		var base_ccw: float = -_gravity_vortex_phase * 0.95 + float(j) * TAU / float(arms) + TAU / 12.0
		var pts_ccw: PackedVector2Array = PackedVector2Array()
		for s2 in 18 + 1:
			var u2: float = float(s2) / 18.0
			var rad2: float = lerpf(inner_r + 8.0, outer_r - 4.0, u2)
			var ang2: float = base_ccw - u2 * TAU * 1.6
			pts_ccw.append(Vector2(cos(ang2) * rad2, sin(ang2) * rad2))
		draw_polyline(pts_ccw, Color(0.5, 0.2, 0.85, 0.28 * pulse), 2.0)

func _draw_gravity_well() -> void:
	var r: float = Constants.PEG_RADIUS
	var luminance: float
	if _recovery_ticks_remaining > 0:
		luminance = 0.15
	else:
		var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
		luminance = lerpf(0.25, 1.0, ratio * _vibrancy_scale)
	_draw_gravity_well_vortex(luminance)
	var body_color := Color(0.15, 0.1, 0.35, 1.0)
	body_color = Color(body_color.r * luminance, body_color.g * luminance, body_color.b * luminance, body_color.a)
	draw_circle(Vector2.ZERO, r, body_color)
	var rim_color := Color(0.4, 0.25, 0.7, luminance)
	draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, rim_color, 2.0)
	var ring_alpha: float = 0.5 * luminance
	draw_arc(Vector2.ZERO, r * 0.7, 0.0, TAU, 16, Color(0.5, 0.3, 0.8, ring_alpha), 1.5)
	draw_arc(Vector2.ZERO, r * 0.4, 0.0, TAU, 12, Color(0.6, 0.4, 0.9, ring_alpha * 0.8), 1.5)
	draw_circle(Vector2.ZERO, 2.5, Color(0.8, 0.6, 1.0, luminance))

func _draw_phase() -> void:
	var r: float = Constants.PEG_RADIUS
	var luminance: float
	if _recovery_ticks_remaining > 0:
		luminance = 0.15
	else:
		var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
		luminance = lerpf(0.25, 1.0, ratio * _vibrancy_scale)
	var alpha: float = 1.0 if _phase_peg_solid else 0.3
	var body_color := Color(0.3, 0.8, 0.85, alpha)
	body_color = Color(body_color.r * luminance, body_color.g * luminance, body_color.b * luminance, body_color.a)
	draw_circle(Vector2.ZERO, r, body_color)
	var rim_color := Color(0.5, 0.9, 0.95, alpha * luminance)
	draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, rim_color, 2.0)
	if not _phase_peg_solid:
		var dash_color := Color(0.5, 0.9, 0.95, 0.4 * luminance)
		for i in range(8):
			var a1: float = float(i) * TAU / 8.0
			var a2: float = a1 + TAU / 16.0
			draw_arc(Vector2.ZERO, r * 0.6, a1, a2, 4, dash_color, 1.5)

func _draw_wrench() -> void:
	var r: float = Constants.PEG_RADIUS
	var luminance: float
	if _recovery_ticks_remaining > 0:
		luminance = 0.15
	else:
		var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
		luminance = lerpf(0.25, 1.0, ratio * _vibrancy_scale)
	var body_color := Color(0.45, 0.42, 0.38, 1.0)
	body_color = Color(body_color.r * luminance, body_color.g * luminance, body_color.b * luminance, body_color.a)
	draw_circle(Vector2.ZERO, r, body_color)
	var rim_color := Color(0.6, 0.55, 0.45, luminance)
	draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 24, rim_color, 2.0)
	var wrench_color := Color(0.85, 0.7, 0.3, 0.95 * luminance)
	draw_line(Vector2(0, -r * 0.6), Vector2(0, r * 0.5), wrench_color, 2.5)
	draw_line(Vector2(-r * 0.35, -r * 0.6), Vector2(r * 0.35, -r * 0.6), wrench_color, 2.5)
	draw_line(Vector2(-r * 0.35, -r * 0.6), Vector2(-r * 0.35, -r * 0.3), wrench_color, 2.0)
	draw_line(Vector2(r * 0.35, -r * 0.6), Vector2(r * 0.35, -r * 0.3), wrench_color, 2.0)
	draw_circle(Vector2(0, r * 0.5), 3.0, wrench_color)

func _draw_treasure_chest() -> void:
	var r: float = Constants.PEG_RADIUS
	var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
	var t: float = float(Time.get_ticks_msec()) * 0.006
	var pulse: float = 0.78 + 0.22 * sin(t * 2.0)
	var alpha: float = clampf(0.45 + 0.55 * _treasure_chest_urgency, 0.35, 1.0) * pulse
	var wood := Color(0.38, 0.24, 0.12, alpha)
	var trim := Color(0.9, 0.72, 0.2, alpha)
	var glow := Color(0.95, 0.55, 0.15, 0.28 * alpha * ratio)
	draw_circle(Vector2.ZERO, r + 5.0, glow)
	var bw: float = r * 1.35
	var bh: float = r * 1.25
	draw_rect(Rect2(-bw * 0.5, -bh * 0.5, bw, bh * 0.52), wood)
	draw_rect(Rect2(-bw * 0.5, bh * 0.02, bw, bh * 0.48), wood.darkened(0.1))
	draw_line(Vector2(-bw * 0.5, bh * 0.02), Vector2(bw * 0.5, bh * 0.02), trim, 2.5)
	draw_arc(Vector2(0, -bh * 0.5), bw * 0.48, PI, TAU, 18, trim, 2.5, true)
	draw_circle(Vector2(0, 0), 4.5, trim.lightened(0.05))
	draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 28, Color(trim.r, trim.g, trim.b, alpha * 0.85), 2.0)

func _draw_buffet_table() -> void:
	var r: float = Constants.PEG_RADIUS
	var t: float = float(Time.get_ticks_msec()) * 0.0065
	var pulse: float = 0.78 + 0.22 * sin(t * 2.0)
	var alpha: float = clampf(0.4 + 0.6 * _buffet_table_urgency, 0.35, 1.0) * pulse
	var cloth := Color(0.78, 0.62, 0.42, alpha)
	var trim := Color(0.55, 0.38, 0.22, alpha)
	var plate := Color(0.96, 0.94, 0.9, alpha)
	var steam := Color(0.88, 0.92, 0.95, 0.22 * alpha)
	draw_circle(Vector2.ZERO, r + 4.0, steam)
	var tw: float = r * 2.45
	var th: float = r * 0.95
	draw_rect(Rect2(-tw * 0.5, -th * 0.5, tw, th * 0.55), cloth)
	draw_rect(Rect2(-tw * 0.5, th * 0.02, tw, th * 0.48), cloth.darkened(0.08))
	draw_line(Vector2(-tw * 0.5, th * 0.02), Vector2(tw * 0.5, th * 0.02), trim, 2.0)
	for px in [-r * 0.65, r * 0.65]:
		draw_circle(Vector2(px, -r * 0.15), r * 0.42, plate)
		draw_arc(Vector2(px, -r * 0.15), r * 0.42, 0.0, TAU, 20, trim.darkened(0.1), 1.5)
	draw_arc(Vector2(0, -r * 0.35), r * 0.5, PI * 1.05, TAU * 0.95, 14, Color(0.7, 0.75, 0.78, 0.55 * alpha), 2.0)
	draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 28, Color(trim.r, trim.g, trim.b, alpha * 0.85), 2.0)

func _draw_sticky_slime() -> void:
	var r: float = Constants.PEG_RADIUS
	var pulse: float = 0.72 + 0.28 * sin(_sticky_slime_phase)
	var alpha: float = clampf(0.42 + 0.58 * _sticky_slime_urgency, 0.35, 1.0) * pulse
	var slime := Color(0.25, 0.72, 0.38, alpha)
	var slime_dark := Color(0.12, 0.45, 0.22, alpha * 0.92)
	var drip := Color(0.35, 0.85, 0.5, 0.55 * alpha)
	draw_circle(Vector2.ZERO, r + 3.5, slime_dark)
	draw_circle(Vector2.ZERO, r + 1.0, slime)
	for i in range(5):
		var ang: float = _sticky_slime_phase * 0.8 + float(i) * TAU / 5.0
		var drip_len: float = 4.0 + 3.0 * sin(_sticky_slime_phase + float(i))
		var outer: Vector2 = Vector2(cos(ang), sin(ang)) * (r + 1.5)
		draw_line(outer, outer + Vector2(0, drip_len), drip, 2.2)
	draw_arc(Vector2.ZERO, r + 2.5, 0.0, TAU, 28, Color(0.5, 1.0, 0.65, alpha * 0.35), 2.0)

func _draw_milestone_event() -> void:
	var r: float = Constants.PEG_RADIUS
	var t: float = float(Time.get_ticks_msec()) * 0.008
	var pulse: float = 0.75 + 0.25 * sin(t * 3.0)
	var alpha: float = clampf(0.35 + 0.65 * _milestone_event_urgency, 0.15, 1.0) * pulse
	var gold := Color(0.95, 0.82, 0.25, alpha)
	var rim := Color(0.55, 0.4, 0.1, alpha)
	draw_circle(Vector2.ZERO, r + 3.0, Color(0.45, 0.25, 0.95, 0.35 * alpha))
	draw_circle(Vector2.ZERO, r, gold)
	draw_arc(Vector2.ZERO, r + 1.0, 0.0, TAU, 32, rim, 2.5)
	# Bag silhouette
	var bw: float = r * 1.1
	var bh: float = r * 1.15
	draw_rect(Rect2(-bw * 0.45, -bh * 0.35, bw * 0.9, bh * 0.7), Color(0.35, 0.28, 0.08, alpha * 0.9))
	draw_arc(Vector2(0, -bh * 0.35), bw * 0.45, PI, TAU, 14, gold.darkened(0.15), 2.0, true)

func _draw_leech_cone() -> void:
	var r: float = Constants.PEG_RADIUS
	# Global-time phase avoids storing per-peg animation state in _process.
	var phase: float = float(Time.get_ticks_msec()) * 0.001 * 4.0
	var tip_y: float = -r - 12.0
	var base_half: float = 6.0 + 2.0 * sin(phase)
	var base_y: float = -r + 2.0
	var pulse: float = 0.75 + 0.25 * sin(phase * 2.0)
	var cone_color := Color(0.72, 0.45, 0.95, 0.85 * pulse)
	var cone_dark := Color(0.5, 0.28, 0.75, 0.6 * pulse)
	var tip := Vector2(0, tip_y)
	var bl := Vector2(-base_half, base_y)
	var br := Vector2(base_half, base_y)
	var pts: PackedVector2Array = [tip, bl, br]
	draw_colored_polygon(pts, cone_color)
	var outline: PackedVector2Array = [tip, bl, br, tip]
	draw_polyline(outline, cone_dark, 1.5, true)

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
	elif peg_extra_kind == "bomb":
		_draw_bomb()
	elif peg_extra_kind == "goblin_reset":
		_draw_goblin_reset()
	elif peg_extra_kind == "eternal":
		_draw_eternal()
	elif peg_extra_kind == "extreme_bouncer":
		_draw_extreme_bouncer()
	elif peg_extra_kind == "magnet":
		_draw_magnet()
	elif peg_extra_kind == "splitter":
		_draw_splitter()
	elif peg_extra_kind == "gold":
		_draw_gold()
	elif peg_extra_kind == "lucky_gold":
		_draw_lucky_gold()
	elif peg_extra_kind == "gravity_well":
		_draw_gravity_well()
	elif peg_extra_kind == "phase":
		_draw_phase()
	elif peg_extra_kind == "wrench":
		_draw_wrench()
	elif peg_extra_kind == "milestone_event":
		_draw_milestone_event()
	elif peg_extra_kind == "treasure_chest":
		_draw_treasure_chest()
	elif peg_extra_kind == "buffet_table":
		_draw_buffet_table()
	elif peg_extra_kind == "sticky_slime":
		_draw_sticky_slime()
	else:
		var base_color: Color = Constants.gameplay_peg_plain_body()
		var luminance: float
		if _recovery_ticks_remaining > 0:
			luminance = 0.15
		else:
			var ratio: float = 1.0 if _max_durability <= 0 else (float(_durability) / float(_max_durability))
			luminance = lerpf(0.25, 1.0, ratio * _vibrancy_scale)
		var c: Color = Constants.color_with_luminance(base_color, luminance)
		draw_circle(Vector2.ZERO, Constants.PEG_RADIUS, c)
	# Crackling energy aura while peg has extra HP from Energize
	if _energized_durability > 0:
		_draw_energized_aura()
	# Short hit ring when just hit (plain)
	elif _aura_elapsed > 0.0:
		var aura_alpha: float = (_aura_elapsed / AURA_DURATION_SEC) * 0.5
		var aura_r: float = Constants.PEG_RADIUS + 4.0 + (1.0 - _aura_elapsed / AURA_DURATION_SEC) * 8.0
		var aura_col: Color = Constants.monsters_also_die_color(Constants.MAD_IDX_CREAM).lerp(
			Constants.monsters_also_die_color(Constants.MAD_IDX_TAN), 0.35
		)
		draw_arc(Vector2.ZERO, aura_r, 0.0, TAU, 32, Color(aura_col.r, aura_col.g, aura_col.b, aura_alpha), 3.0)
	# Blue glow during chain lightning shock
	if _lightning_glow_elapsed > 0.0:
		var glow_alpha: float = (_lightning_glow_elapsed / LIGHTNING_GLOW_DURATION_SEC) * 0.7
		var glow_r: float = Constants.PEG_RADIUS + 6.0
		var g1: Color = Constants.gameplay_chain_lightning_glow_outer()
		var g2: Color = Constants.gameplay_chain_lightning_glow_inner()
		draw_arc(Vector2.ZERO, glow_r, 0.0, TAU, 24, Color(g1.r, g1.g, g1.b, glow_alpha), 4.0)
		draw_arc(Vector2.ZERO, glow_r + 4.0, 0.0, TAU, 24, Color(g2.r, g2.g, g2.b, glow_alpha * 0.5), 2.0)
	# Leech cone on top of peg (siphon visual)
	if _leech_stacks > 0:
		_draw_leech_cone()
	# Purple pulse when leech drain fires (fewer segments than lightning glow — many pegs can pulse together)
	if _leech_pulse_elapsed > 0.0:
		var pulse_alpha: float = (_leech_pulse_elapsed / LEECH_PULSE_DURATION_SEC) * 0.75
		var pulse_r: float = Constants.PEG_RADIUS + 6.0
		var p1: Color = Constants.gameplay_leech_pulse_outer()
		var p2: Color = Constants.gameplay_leech_pulse_inner()
		draw_arc(Vector2.ZERO, pulse_r, 0.0, TAU, 16, Color(p1.r, p1.g, p1.b, pulse_alpha), 4.0)
		draw_arc(Vector2.ZERO, pulse_r + 4.0, 0.0, TAU, 16, Color(p2.r, p2.g, p2.b, pulse_alpha * 0.5), 2.0)
	if _ghost_trail_active:
		_draw_ghost_trail_glow()
	if _hover_highlight:
		_draw_hover_highlight()
	if stash_gold_amount > 0 and _recovery_ticks_remaining <= 0:
		_draw_stash_gold_overlay()

func _draw_stash_gold_overlay() -> void:
	if stash_gold_amount >= 5:
		_draw_stash_gold_overlay_five()
	else:
		_draw_stash_gold_overlay_one()

func _draw_stash_gold_overlay_one() -> void:
	var p := Vector2(7.0, 7.0)
	var coin_r: float = 5.5
	draw_circle(p, coin_r, Color(0.80, 0.50, 0.14, 1.0))
	draw_arc(p, coin_r - 1.0, 0.0, TAU, 24, Color(0.48, 0.26, 0.06, 1.0), 1.2)
	draw_line(p + Vector2(-2.0, -1.0), p + Vector2(1.0, 2.0), Color(0.92, 0.68, 0.32, 0.9), 1.0)

func _draw_stash_gold_overlay_five() -> void:
	## Stacked coins + warm ring: reads clearly vs single small stash coin.
	var back := Vector2(4.5, 5.0)
	var front := Vector2(9.0, 8.5)
	var r_back: float = 5.0
	var r_front: float = 5.8
	var gold_deep := Color(0.72, 0.44, 0.12, 1.0)
	var gold_mid := Color(0.82, 0.54, 0.18, 1.0)
	var rim := Color(0.44, 0.22, 0.05, 1.0)
	var highlight := Color(0.92, 0.70, 0.35, 0.95)
	draw_circle(back, r_back + 2.0, Color(0.80, 0.35, 0.08, 0.35))
	draw_circle(front, r_front + 2.5, Color(0.82, 0.38, 0.08, 0.45))
	draw_circle(back, r_back, gold_deep.darkened(0.08))
	draw_arc(back, r_back - 0.5, 0.0, TAU, 20, rim, 1.5, true)
	draw_circle(front, r_front, gold_mid)
	draw_arc(front, r_front - 1.0, 0.0, TAU, 24, rim, 1.8, true)
	draw_line(front + Vector2(-2.2, -1.0), front + Vector2(1.2, 2.2), highlight, 1.2)
	var bag_center: Vector2 = (back + front) * 0.5
	draw_arc(bag_center, 12.0, 0.0, TAU, 40, Color(0.82, 0.35, 0.06, 0.55), 2.0, true)

func _draw_ghost_trail_glow() -> void:
	var r: float = Constants.PEG_RADIUS
	var pulse: float = 0.65 + 0.35 * sin(_ghost_trail_phase)
	draw_circle(Vector2.ZERO, r, Color(0.3, 0.75, 0.9, 0.35 * pulse))
	draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 32, Color(0.35, 0.85, 0.95, 0.7 * pulse), 3.5)
	draw_arc(Vector2.ZERO, r + 8.0, 0.0, TAU, 32, Color(0.45, 0.9, 1.0, 0.35 * pulse), 2.5)
	var wisp_count: int = 4
	for i in wisp_count:
		var a: float = _ghost_trail_phase * 0.8 + float(i) * TAU / float(wisp_count)
		var wisp_r: float = r + 6.0 + 3.0 * sin(_ghost_trail_phase * 1.5 + float(i))
		var wisp_pos: Vector2 = Vector2(cos(a) * wisp_r, sin(a) * wisp_r)
		draw_circle(wisp_pos, 2.5, Color(0.6, 0.95, 1.0, 0.5 * pulse))

func _draw_hover_highlight() -> void:
	var r: float = Constants.PEG_RADIUS + 4.0
	var time_sec: float = float(Time.get_ticks_msec()) / 1000.0
	var pulse: float = 0.6 + 0.4 * sin(time_sec * 5.0)
	var color: Color
	match _hover_kind:
		"bomb":
			color = Color(1.0, 0.3, 0.1, pulse * 0.85)
		"trampoline":
			color = Color(0.2, 0.9, 0.5, pulse * 0.85)
		"goblin_reset":
			color = Color(0.5, 0.8, 0.3, pulse * 0.85)
		"eternal":
			color = Color(0.7, 0.8, 1.0, pulse * 0.85)
		"extreme_bouncer":
			color = Color(1.0, 0.6, 0.15, pulse * 0.85)
		"magnet":
			color = Color(0.9, 0.25, 0.25, pulse * 0.85)
		"splitter":
			color = Color(0.75, 0.4, 0.85, pulse * 0.85)
		"gold":
			color = Color(1.0, 0.9, 0.3, pulse * 0.85)
		"lucky_gold":
			color = Color(0.45, 0.95, 0.55, pulse * 0.85)
		"gravity_well":
			color = Color(0.5, 0.3, 0.8, pulse * 0.85)
		"phase":
			color = Color(0.4, 0.85, 0.9, pulse * 0.85)
		"wrench":
			color = Color(0.85, 0.7, 0.3, pulse * 0.85)
		"sticky_preview":
			color = Color(0.35, 0.95, 0.55, pulse * 0.88)
		_:
			color = Color(1.0, 0.9, 0.4, pulse * 0.85)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, color, 3.0)
	draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 32, Color(color.r, color.g, color.b, color.a * 0.35), 2.0)
	draw_circle(Vector2.ZERO, Constants.PEG_RADIUS, Color(color.r, color.g, color.b, 0.12))
