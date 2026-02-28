extends Node2D
## Board (§6.3). Single authority for hit detection and per-ball energy. Flush once per sim tick.

signal ball_reached_bottom(ball_id: int, total_energy_display: int, alignment: int, exit_position: Vector2, status_effects: Dictionary)
signal ball_ability_on_peg_hit(status_effects: Dictionary)  ## GDD §8: ball ability triggered on peg hit; apply status to minions.
signal ball_exited_board(ball: Node, reason: int)

const REASON_BOTTOM: int = 0
const REASON_STALL: int = 1
const REASON_OFF_SCREEN: int = 2

## Bottom 10px of viewport (720 - 10): balls that enter this band turn into energy.
const BOTTOM_ZONE_Y: float = 710.0
const OFF_SCREEN_Y: float = 730.0
## Horizontal bounds: match play area (board 0..960) so balls that bounce out left/right are returned to hopper instead of staying in _active_balls.
const OFF_SCREEN_X_LEFT: float = -20.0
const OFF_SCREEN_X_RIGHT: float = 980.0
const PEG_DISPLAY_ENERGY_PER_HIT: int = 10  # display units (§1.7)

var _active_balls: Array[Node] = []
var _hit_cooldown: HitCooldown
var _spawn_position: Vector2 = Vector2(480, 80)  # At gate height so ball falls naturally from hopper
var _peg_by_id: Dictionary = {}
var _balls_container: Node2D
var _peg_scene: PackedScene
var _energy_popup_scene: PackedScene
var _hit_effect_scene: PackedScene
var _chain_lightning_arc_scene: PackedScene
var _ball_scene: PackedScene
var _next_split_ball_id: int = 100000

func _ready() -> void:
	_hit_cooldown = HitCooldown.new()
	var main: Node = get_parent()
	_balls_container = main.get_node_or_null("BallsContainer") as Node2D
	if not _balls_container:
		_balls_container = self
	_peg_scene = load("res://scenes/board/peg.tscn") as PackedScene
	_energy_popup_scene = load("res://scenes/board/energy_popup.tscn") as PackedScene
	_hit_effect_scene = load("res://scenes/board/ball_hit_effect.tscn") as PackedScene
	_chain_lightning_arc_scene = load("res://scenes/board/chain_lightning_arc_effect.tscn") as PackedScene
	_ball_scene = load("res://scenes/balls/ball.tscn") as PackedScene
	_spawn_peg_layout()

func get_active_ball_count() -> int:
	return _active_balls.size()

func spawn_ball_at_start(ball: Node) -> void:
	if not ball:
		return
	# Ball may already be in the world (fell out of hopper); only reparent/place if not
	if ball.get_parent() == _balls_container:
		if ball.has_method("reset_split_for_new_visit"):
			ball.reset_split_for_new_visit()
		_active_balls.append(ball)
		return
	if "freeze" in ball:
		ball.freeze = false
	if ball.has_method("reset_split_for_new_visit"):
		ball.reset_split_for_new_visit()
	ball.global_position = _spawn_position
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO
	_balls_container.add_child(ball)
	_active_balls.append(ball)

func get_peg_by_id(id: int) -> Node:
	return _peg_by_id.get(id)

func run_ball_steps(sim_tick: int) -> void:
	for p in get_children():
		if p.has_method("sim_tick"):
			p.sim_tick(sim_tick)
	for b in _active_balls:
		if b.has_method("step_one_sim_tick"):
			var peg: Node = b.step_one_sim_tick(sim_tick)
			if peg and peg.get("peg_id") != null:
				var pid: int = peg.peg_id
				var bid: int = b.get_ball_id() if b.has_method("get_ball_id") else 0
				if _hit_cooldown.cooldown_ok(bid, pid, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
					_hit_cooldown.record_hit(bid, pid, sim_tick)
					if b.has_method("add_peg_energy"):
						b.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT)
					var def: Resource = b.get_definition() if b.has_method("get_definition") else null
					var bdef: BallDefinition = def as BallDefinition if def is BallDefinition else null
					var ability_key: String = _ability_key(bdef)
					var has_attribute: bool = bdef != null and (not bdef.status_effects.is_empty() or (ability_key != "" and ability_key != "Bounce"))
					if peg.has_method("apply_hit"):
						var is_energize: bool = (ability_key == "Energize")
						peg.apply_hit(not has_attribute, 0 if is_energize else 1, is_energize)  # Energize: add full bar of extra HP (crackling aura)
					_spawn_energy_popup(peg, PEG_DISPLAY_ENERGY_PER_HIT)
					# Status-themed burst at peg (flame, ice, lightning, energize, split)
					if bdef != null:
						if not bdef.status_effects.is_empty():
							ball_ability_on_peg_hit.emit(bdef.status_effects)
						var allow_split_effect: bool = (ability_key == "Split" and b.has_method("has_split_triggered") and not b.has_split_triggered())
						# Explosive/Chain Lightning use their own centered/arc effects; skip peg burst
						if ability_key != "Explosive" and ability_key != "Chain Lightning":
							_spawn_hit_effect(peg.global_position, bdef.status_effects, ability_key, allow_split_effect)
						# Split: spawn second real ball (mirror velocity), split energy, both spin briefly
						if ability_key == "Split" and b.has_method("has_split_triggered") and not b.has_split_triggered():
							b.mark_split_triggered()
							var ball_vel: Vector2 = b.linear_velocity if "linear_velocity" in b else Vector2.ZERO
							var total: int = b.get_total_energy() if b.has_method("get_total_energy") else 20
							var half: int = total / 2
							b.set_total_energy_display(half)
							var second: Node = _spawn_split_ball(b.global_position, -ball_vel, bdef, half)
							if second != null:
								_active_balls.append(second)
							b.start_split_spin()
							if second != null and second.has_method("start_split_spin"):
								second.start_split_spin()
						# GDD: Explosive — one large explosion at ball, wobble hit pegs; Chain Lightning — arcs peg-to-peg, pegs glow blue.
						if ability_key == "Explosive":
							_apply_explosive_hits(pid, b, bdef, sim_tick)
							_spawn_explosive_effect_at_ball(b.global_position)
						elif ability_key == "Chain Lightning":
							_apply_chain_lightning_hits(pid, b, bdef, sim_tick)

func flush_tick(sim_tick: int) -> void:
	for b in _active_balls.duplicate():
		var pos: Vector2 = b.get_global_sim_position() if b.has_method("get_global_sim_position") else b.global_position
		if pos.y >= BOTTOM_ZONE_Y:
			var ball_id: int = b.get_ball_id() if b.has_method("get_ball_id") else 0
			var total: int = b.get_total_energy() if b.has_method("get_total_energy") else 20
			var alignment: int = 0
			var status_effects: Dictionary = {}
			var ability_name: String = ""
			if b.has_method("get_definition"):
				var def = b.get_definition()
				if def is BallDefinition:
					var bd: BallDefinition = def as BallDefinition
					alignment = bd.alignment
					ability_name = _ability_key(bd)
					if bd.status_effects != null and not bd.status_effects.is_empty():
						status_effects = bd.status_effects
			_spawn_hit_effect(pos, status_effects, ability_name, false)
			ball_reached_bottom.emit(ball_id, total, alignment, pos, status_effects)
			_active_balls.erase(b)
			ball_exited_board.emit(b, REASON_BOTTOM)
		elif pos.y > OFF_SCREEN_Y or pos.x < OFF_SCREEN_X_LEFT or pos.x > OFF_SCREEN_X_RIGHT:
			_active_balls.erase(b)
			ball_exited_board.emit(b, REASON_OFF_SCREEN)

func explode_at(_peg_id: int) -> void:
	pass  # future: bomb peg or external trigger; ball-triggered explosive uses _apply_explosive_hits

## GDD: Explosive ball — apply hit to all pegs within EXPLOSIVE_RADIUS_PX; same ball gets +10 per hit.
func _apply_explosive_hits(center_peg_id: int, ball: Node, bdef: BallDefinition, sim_tick: int) -> void:
	var center_peg: Node = _peg_by_id.get(center_peg_id)
	if not center_peg or not center_peg.get("global_position"):
		return
	var center_pos: Vector2 = center_peg.global_position
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
	for other_id in _peg_by_id:
		if other_id == center_peg_id:
			continue
		var other_peg: Node = _peg_by_id[other_id]
		if not other_peg or not other_peg.get("global_position"):
			continue
		if center_pos.distance_to(other_peg.global_position) > Constants.EXPLOSIVE_RADIUS_PX:
			continue
		if not _hit_cooldown.cooldown_ok(bid, other_id, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
			continue
		_hit_cooldown.record_hit(bid, other_id, sim_tick)
		if ball.has_method("add_peg_energy"):
			ball.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT)
		if other_peg.has_method("apply_hit"):
			other_peg.apply_hit(true, 1, false)
		if other_peg.has_method("play_wobble"):
			other_peg.play_wobble()
		_spawn_energy_popup(other_peg, PEG_DISPLAY_ENERGY_PER_HIT)
	if center_peg.has_method("play_wobble"):
		center_peg.play_wobble()

## GDD: Chain Lightning ball — apply hit to up to CHAIN_LIGHTNING_COUNT nearest pegs; lightning arcs peg-to-peg; pegs glow blue.
func _apply_chain_lightning_hits(center_peg_id: int, ball: Node, bdef: BallDefinition, sim_tick: int) -> void:
	var center_peg: Node = _peg_by_id.get(center_peg_id)
	if not center_peg or not center_peg.get("global_position"):
		return
	var nearest: Array = _get_nearest_pegs(center_peg_id, Constants.CHAIN_LIGHTNING_COUNT)
	var lightning_status: Dictionary = { Constants.STATUS_LIGHTNING: 1 }
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
	var chain_positions: Array = [center_peg.global_position]
	if center_peg.has_method("play_lightning_shock"):
		center_peg.play_lightning_shock()
	for other_peg in nearest:
		var other_id: int = other_peg.peg_id if other_peg.get("peg_id") != null else -1
		if other_id < 0:
			continue
		if not _hit_cooldown.cooldown_ok(bid, other_id, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
			continue
		_hit_cooldown.record_hit(bid, other_id, sim_tick)
		if ball.has_method("add_peg_energy"):
			ball.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT)
		if other_peg.has_method("apply_hit"):
			other_peg.apply_hit(true, 1, false)
		if other_peg.has_method("play_lightning_shock"):
			other_peg.play_lightning_shock()
		ball_ability_on_peg_hit.emit(lightning_status)
		_spawn_energy_popup(other_peg, PEG_DISPLAY_ENERGY_PER_HIT)
		chain_positions.append(other_peg.global_position)
	_spawn_chain_lightning_arcs(chain_positions)

func _get_nearest_pegs(center_peg_id: int, count: int) -> Array:
	var center_peg: Node = _peg_by_id.get(center_peg_id)
	if not center_peg or not center_peg.get("global_position") or count <= 0:
		return []
	var center_pos: Vector2 = center_peg.global_position
	var with_dist: Array = []
	for pid in _peg_by_id:
		if pid == center_peg_id:
			continue
		var p: Node = _peg_by_id[pid]
		if not p or not p.get("global_position"):
			continue
		with_dist.append({ "peg": p, "dist": center_pos.distance_to(p.global_position) })
	with_dist.sort_custom(func(a, b): return a.dist < b.dist)
	var out: Array = []
	for i in range(mini(count, with_dist.size())):
		out.append(with_dist[i].peg)
	return out

## Spawn a real second ball when Split triggers; add to BallsContainer and return it. Caller adds to _active_balls.
func _spawn_split_ball(global_pos: Vector2, velocity: Vector2, definition: BallDefinition, energy_half: int) -> Node:
	if not _ball_scene or not _balls_container:
		return null
	var new_ball: Node = _ball_scene.instantiate()
	if not new_ball:
		return null
	_next_split_ball_id += 1
	new_ball.set_ball_id(_next_split_ball_id)
	var def_copy: BallDefinition = definition.duplicate(true) as BallDefinition
	if def_copy:
		new_ball.set_definition(def_copy)
	new_ball.mark_split_triggered()
	if new_ball.has_method("mark_as_split_twin"):
		new_ball.mark_as_split_twin()
	_balls_container.add_child(new_ball)
	new_ball.set_total_energy_display(energy_half)
	new_ball.global_position = global_pos
	new_ball.linear_velocity = velocity
	return new_ball

func _ability_key(bdef: BallDefinition) -> String:
	if bdef == null:
		return ""
	return str(bdef.ability_name).strip_edges()

func _spawn_hit_effect(world_pos: Vector2, status_effects: Dictionary, ability_name: String = "", allow_split_effect: bool = true) -> void:
	if not _hit_effect_scene:
		return
	var key: String = str(ability_name).strip_edges()
	var effect_type: int = BallHitEffect.EffectType.FIRE
	if key == "Energize":
		effect_type = BallHitEffect.EffectType.ENERGIZE
	elif key == "Split" and allow_split_effect:
		effect_type = BallHitEffect.EffectType.SPLIT
	elif key == "Split":
		return
	elif key == "Explosive":
		effect_type = BallHitEffect.EffectType.EXPLOSIVE
	elif key == "Chain Lightning":
		effect_type = BallHitEffect.EffectType.CHAIN_LIGHTNING
	elif status_effects.get(Constants.STATUS_FROZEN, 0) > 0 or status_effects.get("frozen", 0) > 0:
		effect_type = BallHitEffect.EffectType.ICE
	elif status_effects.get(Constants.STATUS_LIGHTNING, 0) > 0 or status_effects.get("lightning", 0) > 0:
		effect_type = BallHitEffect.EffectType.LIGHTNING
	elif status_effects.get(Constants.STATUS_FIRE, 0) > 0 or status_effects.get("fire", 0) > 0:
		effect_type = BallHitEffect.EffectType.FIRE
	else:
		return
	var effect: Node2D = _hit_effect_scene.instantiate() as Node2D
	if not effect or not effect is BallHitEffect:
		return
	effect.global_position = world_pos
	effect.z_index = 100
	effect.setup_effect(effect_type)
	get_parent().add_child(effect)

func _spawn_explosive_effect_at_ball(ball_world_pos: Vector2) -> void:
	if not _hit_effect_scene:
		return
	var effect: Node2D = _hit_effect_scene.instantiate() as Node2D
	if not effect or not effect is BallHitEffect:
		return
	effect.global_position = ball_world_pos
	effect.z_index = 100
	effect.setup_effect(BallHitEffect.EffectType.EXPLOSIVE, Constants.EXPLOSIVE_RADIUS_PX)
	get_parent().add_child(effect)

func _spawn_chain_lightning_arcs(global_positions: Array) -> void:
	if not _chain_lightning_arc_scene or global_positions.size() < 2:
		return
	var effect: Node2D = _chain_lightning_arc_scene.instantiate() as Node2D
	if not effect or not effect.has_method("setup_chain"):
		return
	effect.global_position = Vector2.ZERO
	effect.setup_chain(global_positions)
	get_parent().add_child(effect)

func _spawn_energy_popup(peg: Node, amount_display: int) -> void:
	if not _energy_popup_scene:
		return
	var popup: Node2D = _energy_popup_scene.instantiate() as Node2D
	if not popup:
		return
	popup.setup("+%d" % amount_display)
	popup.position = peg.position + Vector2(0, -16)
	add_child(popup)

func _spawn_peg_layout() -> void:
	if not _peg_scene:
		return
	# Full-width offset rows: each row has the same number of pegs across the board; odd rows offset by half spacing.
	var peg_id_counter: int = 0
	var row_spacing: float = 56.0
	var col_spacing: float = 52.0
	var center_x: float = 480.0
	var top: float = 200.0  # Well below hopper exit
	var num_rows: int = 8
	var peg_field_width: float = 800.0  # Total width to fill
	var cols_per_row: int = ceili(peg_field_width / col_spacing)
	var row_width: float = (cols_per_row - 1) * col_spacing
	var start_x: float = center_x - row_width * 0.5
	for row in range(num_rows):
		var row_offset_x: float = (col_spacing * 0.5) if (row % 2 == 1) else 0.0
		for col in range(cols_per_row):
			if (row + col) % 2 != 0:
				continue  # Skip every other peg (checkerboard)
			var p: Node = _peg_scene.instantiate()
			p.position = Vector2(start_x + row_offset_x + col * col_spacing, top + row * row_spacing)
			p.peg_id = peg_id_counter
			_peg_by_id[peg_id_counter] = p
			peg_id_counter += 1
			add_child(p)
