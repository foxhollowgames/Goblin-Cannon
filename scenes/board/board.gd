extends Node2D
## Board (§6.3). Single authority for hit detection and per-ball energy. Flush once per sim tick.

signal ball_reached_bottom(ball_id: int, total_energy_display: int, alignment: int, exit_position: Vector2, status_effects: Dictionary)
signal ball_ability_on_peg_hit(status_effects: Dictionary)  ## GDD §8: ball ability triggered on peg hit; apply status to minions.
signal ball_exited_board(ball: Node, reason: int)
signal leech_drain(amount_display: int, alignment: int, peg_id: int)  ## Leech status on peg: periodic energy drain (5/sec for 10 sec).

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
## Leech status: each entry { peg_id, alignment, drains_remaining }; drain 5 energy/sec for 10 sec per peg hit.
var _leeched_pegs: Array = []
## Hard caps (GDD): 1 explosion per peg per sim tick; 1 supernova per peg per sim tick; conduction once per chain event.
var _explosion_triggered_pegs_this_tick: Dictionary = {}  # peg_id -> true
var _supernova_triggered_pegs_this_tick: Dictionary = {}
var _chain_conduction_done_this_event: bool = false
## Empty checkerboard positions for wall-break extra pegs; count already spawned so we can add more mid-run.
var _layout_empty_slots: Array = []
var _extra_pegs_spawned_count: int = 0

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

## Fragment Echo (wall break): re-place fragment at top so it falls again. Call when fragment reaches bottom and upgrade is active; do not reset split state.
func respawn_fragment_at_top(ball: Node) -> void:
	if not ball:
		return
	if ball.get_parent() != _balls_container:
		return
	ball.global_position = _spawn_position
	if "linear_velocity" in ball:
		ball.linear_velocity = Vector2.ZERO
	if "angular_velocity" in ball:
		ball.angular_velocity = 0.0
	if "lock_rotation" in ball:
		ball.lock_rotation = true
	_active_balls.append(ball)

func get_peg_by_id(id: int) -> Node:
	return _peg_by_id.get(id)

## Tag a peg as an explosion source (e.g. bomb peg) so explosion upgrades (Cluster Grenade, radius, etc.) apply.
func _tag_peg_as_explosion_source(peg: Node) -> void:
	if peg and not peg.is_in_group("explosion_source"):
		peg.add_to_group("explosion_source")

func run_ball_steps(sim_tick: int) -> void:
	_explosion_triggered_pegs_this_tick.clear()
	_supernova_triggered_pegs_this_tick.clear()
	for p in get_children():
		if p.has_method("sim_tick"):
			p.sim_tick(sim_tick)
	for b in _active_balls:
		if b.has_method("step_one_sim_tick"):
			var def: Resource = b.get_definition() if b.has_method("get_definition") else null
			var bdef: BallDefinition = def as BallDefinition if def is BallDefinition else null
			var ability_key: String = _ability_key(bdef)
			var peg: Node
			if ability_key == "Phantom":
				peg = _get_peg_overlapping_phantom_ball(b)
			else:
				peg = b.step_one_sim_tick(sim_tick)
			if peg and peg.get("peg_id") != null:
				var pid: int = peg.peg_id
				var bid: int = b.get_ball_id() if b.has_method("get_ball_id") else 0
				if _hit_cooldown.cooldown_ok(bid, pid, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
					_hit_cooldown.record_hit(bid, pid, sim_tick)
					var energy_this_hit: int = PEG_DISPLAY_ENERGY_PER_HIT
					if ability_key == "Leech":
						_leeched_pegs.append({ "peg_id": pid, "alignment": bdef.alignment, "drains_remaining": Constants.LEECH_DURATION_SEC })
						if peg.has_method("add_leech_stack"):
							peg.add_leech_stack()
					if b.has_method("add_peg_energy"):
						b.add_peg_energy(energy_this_hit)
					var has_attribute: bool = bdef != null and (not bdef.status_effects.is_empty() or (ability_key != "" and ability_key != "Bounce"))
					# Phantom: ball gains energy but does not damage peg durability (phantom pass).
					var is_energize: bool = (ability_key == "Energize")
					if ability_key != "Phantom" and peg.has_method("apply_hit"):
						peg.apply_hit(not has_attribute, 0 if is_energize else 1, is_energize)  # Energize: add full bar of extra HP (crackling aura)
					if peg.get("peg_extra_kind") == "trampoline":
						_spawn_trampoline_bounce_effect(peg.global_position)
						# Strong vertical lift: always launch ball upward (Godot Y up = negative).
						if "linear_velocity" in b:
							var v: Vector2 = b.linear_velocity
							v.y = -Constants.TRAMPOLINE_UPWARD_SPEED
							b.linear_velocity = v
					# Bomb peg: any ball hit triggers a primary explosion at this peg (tagged as explosion; Cluster Grenade applies).
					if peg.get("peg_extra_kind") == "bomb":
						_apply_explosive_hits(pid, b, bdef, sim_tick, 0)
						_spawn_explosive_effect_at_ball(peg.global_position)
					# Supernova Peg (hard cap: 1 per peg per sim tick)
					if is_energize and GameState and GameState.has_wall_break_upgrade(&"supernova_peg") and peg.has_method("get_energized_durability") and peg.has_method("get_max_durability") and peg.get_energized_durability() >= peg.get_max_durability() and not _supernova_triggered_pegs_this_tick.get(pid, false):
						_trigger_supernova(pid, b, bdef, sim_tick)
					_spawn_energy_popup(peg, energy_this_hit)
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
							_apply_explosive_hits(pid, b, bdef, sim_tick, 0)
							_spawn_explosive_effect_at_ball(b.global_position)
						elif ability_key == "Chain Lightning":
							_chain_conduction_done_this_event = false
							_apply_chain_lightning_hits(pid, b, bdef, sim_tick)

func flush_tick(sim_tick: int) -> void:
	_process_leech_drains(sim_tick)
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

## GDD: Explosive ball — apply hit to all pegs within radius. Hard cap: 1 explosion per peg per sim tick. Cluster depth cap = 1.
func _apply_explosive_hits(center_peg_id: int, ball: Node, bdef: BallDefinition, sim_tick: int, cluster_depth: int = 0) -> void:
	if _explosion_triggered_pegs_this_tick.get(center_peg_id, false):
		return
	_explosion_triggered_pegs_this_tick[center_peg_id] = true
	var center_peg: Node = _peg_by_id.get(center_peg_id)
	if not center_peg or not center_peg.get("global_position"):
		return
	var center_pos: Vector2 = center_peg.global_position
	var radius_px: float = Constants.EXPLOSIVE_RADIUS_PX
	if GameState:
		radius_px += float(GameState.explosion_radius_bonus) * 12.0
	var damage_per_hit: int = 1 + (GameState.explosion_peg_hit_count_bonus if GameState else 0)
	var add_energize: bool = GameState.has_wall_break_upgrade(&"explosions_apply_energize") if GameState else false
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
	for other_id in _peg_by_id:
		if other_id == center_peg_id:
			continue
		var other_peg: Node = _peg_by_id[other_id]
		if not other_peg or not other_peg.get("global_position"):
			continue
		if center_pos.distance_to(other_peg.global_position) > radius_px:
			continue
		if not _hit_cooldown.cooldown_ok(bid, other_id, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
			continue
		_hit_cooldown.record_hit(bid, other_id, sim_tick)
		if ball.has_method("add_peg_energy"):
			ball.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT)
		if other_peg.has_method("apply_hit"):
			other_peg.apply_hit(true, damage_per_hit, add_energize)
		if other_peg.has_method("play_wobble"):
			other_peg.play_wobble()
		_spawn_energy_popup(other_peg, PEG_DISPLAY_ENERGY_PER_HIT)
	if center_peg.has_method("play_wobble"):
		center_peg.play_wobble()
	# Cluster Grenade (depth cap = 1): primary only; secondary explosions do not spawn further clusters.
	# Primary explosions (cluster_depth 0) include bomb peg hits and Explosive ball hits — both trigger Cluster.
	if cluster_depth == 0 and GameState and GameState.has_wall_break_upgrade(&"cluster_grenade"):
		var nearest: Array = _get_nearest_pegs(center_peg_id, 2)
		for i in range(mini(nearest.size(), 2)):
			var p: Node = nearest[i]
			var pid: int = p.peg_id if p.get("peg_id") != null else -1
			if pid >= 0 and not _explosion_triggered_pegs_this_tick.get(pid, false):
				_apply_explosive_hits(pid, ball, bdef, sim_tick, 1)
				break

## GDD: Chain Lightning ball — apply hit to up to CHAIN_LIGHTNING_COUNT + bonus nearest pegs; conduction once per chain event.
func _apply_chain_lightning_hits(center_peg_id: int, ball: Node, bdef: BallDefinition, sim_tick: int) -> void:
	var center_peg: Node = _peg_by_id.get(center_peg_id)
	if not center_peg or not center_peg.get("global_position"):
		return
	var chain_count: int = Constants.CHAIN_LIGHTNING_COUNT + (GameState.chain_arc_bonus if GameState else 0)
	var nearest: Array = _get_nearest_pegs(center_peg_id, chain_count)
	if GameState and GameState.chain_range_bonus > 0:
		var center_pos: Vector2 = center_peg.global_position
		var max_dist: float = 200.0 + float(GameState.chain_range_bonus) * 30.0
		nearest = nearest.filter(func(p): return center_pos.distance_to(p.global_position) <= max_dist)
	var add_energize: bool = GameState.has_wall_break_upgrade(&"chain_hits_apply_energize") if GameState else false
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
			other_peg.apply_hit(true, 1, add_energize)
		if other_peg.has_method("play_lightning_shock"):
			other_peg.play_lightning_shock()
		ball_ability_on_peg_hit.emit(lightning_status)
		_spawn_energy_popup(other_peg, PEG_DISPLAY_ENERGY_PER_HIT)
		chain_positions.append(other_peg.global_position)
	# Chain Conduction: once per chain event, arc to all energized pegs not already in this chain.
	if GameState and GameState.has_wall_break_upgrade(&"chain_conduction") and not _chain_conduction_done_this_event:
		var chain_peg_ids: Array = [center_peg_id]
		for other_peg in nearest:
			var oid: int = other_peg.peg_id if other_peg.get("peg_id") != null else -1
			if oid >= 0:
				chain_peg_ids.append(oid)
		var energized_pegs: Array = []
		for pid in _peg_by_id:
			var p: Node = _peg_by_id[pid]
			if p.has_method("has_energized_stacks") and p.has_energized_stacks() and pid not in chain_peg_ids:
				energized_pegs.append(p)
		if energized_pegs.size() > 0:
			_chain_conduction_done_this_event = true
			for other_peg in energized_pegs:
				var other_id: int = other_peg.peg_id if other_peg.get("peg_id") != null else -1
				if other_id < 0 or not _hit_cooldown.cooldown_ok(bid, other_id, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
					continue
				_hit_cooldown.record_hit(bid, other_id, sim_tick)
				if ball.has_method("add_peg_energy"):
					ball.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT)
				if other_peg.has_method("apply_hit"):
					other_peg.apply_hit(true, 1, false)
				if other_peg.has_method("play_lightning_shock"):
					other_peg.play_lightning_shock()
				chain_positions.append(other_peg.global_position)
	_spawn_chain_lightning_arcs(chain_positions)

## Supernova Peg: large explosion, release energy, hit nearby pegs, reset center peg. Hard cap: 1 per peg per sim tick.
func _trigger_supernova(center_peg_id: int, ball: Node, bdef: BallDefinition, sim_tick: int) -> void:
	_supernova_triggered_pegs_this_tick[center_peg_id] = true
	var center_peg: Node = _peg_by_id.get(center_peg_id)
	if not center_peg or not center_peg.get("global_position"):
		return
	var center_pos: Vector2 = center_peg.global_position
	var radius_px: float = Constants.EXPLOSIVE_RADIUS_PX * 1.5
	if GameState:
		radius_px += float(GameState.explosion_radius_bonus) * 12.0
	var bid: int = ball.get_ball_id() if ball.has_method("get_ball_id") else 0
	for other_id in _peg_by_id:
		var other_peg: Node = _peg_by_id[other_id]
		if not other_peg or not other_peg.get("global_position"):
			continue
		if center_pos.distance_to(other_peg.global_position) > radius_px:
			continue
		if other_id == center_peg_id:
			if other_peg.has_method("reset_to_full"):
				other_peg.reset_to_full()
			continue
		if not _hit_cooldown.cooldown_ok(bid, other_id, sim_tick, Constants.HIT_COOLDOWN_SIM_TICKS):
			continue
		_hit_cooldown.record_hit(bid, other_id, sim_tick)
		if ball.has_method("add_peg_energy"):
			ball.add_peg_energy(PEG_DISPLAY_ENERGY_PER_HIT * 2)
		if other_peg.has_method("apply_hit"):
			other_peg.apply_hit(true, 1, false)
		if other_peg.has_method("play_wobble"):
			other_peg.play_wobble()
		_spawn_energy_popup(other_peg, PEG_DISPLAY_ENERGY_PER_HIT)
	if center_peg.has_method("play_wobble"):
		center_peg.play_wobble()

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

## Phantom balls don't collide with pegs; use distance overlap to grant energy. Returns one peg within range or null.
func _get_peg_overlapping_phantom_ball(ball: Node) -> Node:
	var pos: Vector2 = ball.global_position if ball.get("global_position") != null else ball.position
	var limit: float = Constants.BALL_RADIUS + Constants.PEG_RADIUS
	var best: Node = null
	var best_dist: float = limit + 1.0
	for pid in _peg_by_id:
		var p: Node = _peg_by_id[pid]
		if not p.get("global_position"):
			continue
		var d: float = pos.distance_to(p.global_position)
		if d <= limit and d < best_dist:
			best_dist = d
			best = p
	return best

## Leech status: every second, each leeched peg drains LEECH_DRAIN_PER_SECOND energy (routed by alignment); 10 sec then expire.
func _process_leech_drains(sim_tick: int) -> void:
	if sim_tick <= 0 or (sim_tick % Constants.SIM_TICKS_PER_SECOND) != 0:
		return
	var to_remove: Array[int] = []
	for i in _leeched_pegs.size():
		var entry: Dictionary = _leeched_pegs[i]
		if entry.get("drains_remaining", 0) <= 0:
			to_remove.append(i)
			continue
		var pid: int = entry.get("peg_id", -1)
		var align: int = entry.get("alignment", Constants.ALIGNMENT_MAIN)
		var peg: Node = _peg_by_id.get(pid)
		if peg:
			_spawn_leech_popup(peg, Constants.LEECH_DRAIN_PER_SECOND)
			if peg.has_method("play_leech_pulse"):
				peg.play_leech_pulse(Constants.LEECH_DRAIN_PER_SECOND)
		leech_drain.emit(Constants.LEECH_DRAIN_PER_SECOND, align, pid)
		entry["drains_remaining"] = entry["drains_remaining"] - 1
		if entry["drains_remaining"] <= 0:
			if peg and peg.has_method("remove_leech_stack"):
				peg.remove_leech_stack()
			to_remove.append(i)
	to_remove.sort()
	for i in range(to_remove.size() - 1, -1, -1):
		_leeched_pegs.remove_at(to_remove[i])

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
	elif key == "Leech":
		effect_type = BallHitEffect.EffectType.LEECH
	elif key == "Rubbery":
		effect_type = BallHitEffect.EffectType.RUBBERY
	elif key == "Phantom":
		effect_type = BallHitEffect.EffectType.PHANTOM
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

func _spawn_trampoline_bounce_effect(world_pos: Vector2) -> void:
	if not _hit_effect_scene:
		return
	var effect: Node2D = _hit_effect_scene.instantiate() as Node2D
	if not effect or not effect is BallHitEffect:
		return
	effect.global_position = world_pos
	effect.z_index = 100
	effect.setup_effect(BallHitEffect.EffectType.TRAMPOLINE)
	get_parent().add_child(effect)

func _spawn_leech_popup(peg: Node, amount_display: int) -> void:
	if not _energy_popup_scene:
		return
	var popup: Node2D = _energy_popup_scene.instantiate() as Node2D
	if not popup:
		return
	popup.setup("+%d" % amount_display)
	popup.position = peg.position + Vector2(0, -16)
	popup.modulate = Color(0.82, 0.55, 1.0, 1.0)  # Purple for leech drain
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
	var empty_slots: Array = []  # Checkerboard empty cells for wall-break extra pegs
	for row in range(num_rows):
		var row_offset_x: float = (col_spacing * 0.5) if (row % 2 == 1) else 0.0
		for col in range(cols_per_row):
			var pos: Vector2 = Vector2(start_x + row_offset_x + col * col_spacing, top + row * row_spacing)
			if (row + col) % 2 != 0:
				empty_slots.append(pos)  # Empty checkerboard slot
				continue
			var p: Node = _peg_scene.instantiate()
			p.position = pos
			p.peg_id = peg_id_counter
			_peg_by_id[peg_id_counter] = p
			peg_id_counter += 1
			add_child(p)
	_layout_empty_slots = empty_slots
	# Debug test variant: all pegs are bombs (every hit triggers an explosion).
	if Constants and Constants.DEBUG_TEST_RUN_ALL_BOMB_PEGS:
		for pid in _peg_by_id:
			var p: Node = _peg_by_id[pid]
			p.peg_extra_kind = "bomb"
			_tag_peg_as_explosion_source(p)
		_extra_pegs_spawned_count = _peg_by_id.size()
	else:
		# Wall break: replace random existing pegs with bomb/trampoline/goblin reset (no new pegs).
		var bomb_count: int = GameState.bomb_peg_count if GameState else 0
		var trampoline_count: int = GameState.trampoline_peg_count if GameState else 0
		var goblin_count: int = GameState.goblin_reset_node_count if GameState else 0
		var peg_ids: Array = []
		for pid in _peg_by_id:
			peg_ids.append(pid)
		peg_ids.shuffle()
		var idx: int = 0
		for i in range(bomb_count):
			if idx < peg_ids.size():
				var p: Node = _peg_by_id[peg_ids[idx]]
				p.peg_extra_kind = "bomb"
				_tag_peg_as_explosion_source(p)
				idx += 1
		for i in range(trampoline_count):
			if idx < peg_ids.size():
				var tramp_peg: Node = _peg_by_id[peg_ids[idx]]
				tramp_peg.peg_extra_kind = "trampoline"
				if tramp_peg.has_method("apply_trampoline_physics"):
					tramp_peg.apply_trampoline_physics()
				idx += 1
		for i in range(goblin_count):
			if idx < peg_ids.size():
				_peg_by_id[peg_ids[idx]].peg_extra_kind = "goblin_reset"
				idx += 1
		_extra_pegs_spawned_count = bomb_count + trampoline_count + goblin_count

## Call after wall break upgrades that add pegs (Add Bomb Peg, Add Trampoline Peg, Add Goblin Reset Node). Converts random normal pegs to the new type.
func add_extra_pegs_if_needed() -> void:
	if not GameState:
		return
	var want_bomb: int = GameState.bomb_peg_count
	var want_trampoline: int = GameState.trampoline_peg_count
	var want_goblin: int = GameState.goblin_reset_node_count
	var normal_pegs: Array = []
	for pid in _peg_by_id:
		var p: Node = _peg_by_id[pid]
		if p.get("peg_extra_kind") == "":
			normal_pegs.append(p)
	var current_bomb: int = 0
	var current_trampoline: int = 0
	var current_goblin: int = 0
	for pid in _peg_by_id:
		var k: String = _peg_by_id[pid].get("peg_extra_kind")
		if k == "bomb":
			current_bomb += 1
		elif k == "trampoline":
			current_trampoline += 1
		elif k == "goblin_reset":
			current_goblin += 1
	var need_bomb: int = maxi(0, want_bomb - current_bomb)
	var need_trampoline: int = maxi(0, want_trampoline - current_trampoline)
	var need_goblin: int = maxi(0, want_goblin - current_goblin)
	var total_convert: int = need_bomb + need_trampoline + need_goblin
	if total_convert <= 0 or normal_pegs.size() < total_convert:
		return
	normal_pegs.shuffle()
	var idx: int = 0
	for i in range(need_bomb):
		var p: Node = normal_pegs[idx]
		p.peg_extra_kind = "bomb"
		_tag_peg_as_explosion_source(p)
		idx += 1
	for i in range(need_trampoline):
		var peg: Node = normal_pegs[idx]
		peg.peg_extra_kind = "trampoline"
		if peg.has_method("apply_trampoline_physics"):
			peg.apply_trampoline_physics()
		idx += 1
	for i in range(need_goblin):
		normal_pegs[idx].peg_extra_kind = "goblin_reset"
		idx += 1
	_extra_pegs_spawned_count = want_bomb + want_trampoline + want_goblin
